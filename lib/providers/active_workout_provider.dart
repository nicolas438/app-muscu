import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'workout_provider.dart';

enum ActiveWorkoutStatus {
  notStarted,
  inProgress,
  completed,
}

/// Gère la séance en cours : exercices, séries prévues et validées,
/// et minuteur de repos entre les séries.
///
/// Chaque modification est immédiatement enregistrée dans le stockage local,
/// ce qui permet de reprendre la séance si l'application est fermée
/// (mise en arrière-plan prolongée, appel, batterie vide…).
class ActiveWorkoutProvider with ChangeNotifier {
  /// Nombre de séries prévues pour un exercice jamais réalisé.
  static const int defaultPlannedSets = 3;

  final StorageService _storage = StorageService();
  final RestAlarmService _alarm = RestAlarmService();

  CompletedWorkout? _currentWorkout;
  ActiveWorkoutStatus _status = ActiveWorkoutStatus.notStarted;
  ActiveRest? _rest;
  RestSettings _restSettings = const RestSettings();

  // ===========================================================================
  // ACCESSEURS
  // ===========================================================================

  CompletedWorkout? get currentWorkout => _currentWorkout;
  ActiveWorkoutStatus get status => _status;
  bool get hasActiveWorkout => _status == ActiveWorkoutStatus.inProgress;

  /// Repos en cours, ou `null` si aucun minuteur n'est lancé.
  ActiveRest? get rest => _rest;

  RestSettings get restSettings => _restSettings;

  Duration get elapsedTime {
    final workout = _currentWorkout;
    if (workout == null) return Duration.zero;
    return DateTime.now().difference(workout.startTime);
  }

  // ===========================================================================
  // CYCLE DE VIE DE LA SÉANCE
  // ===========================================================================

  /// Charge les réglages et restaure une séance interrompue lors d'une
  /// précédente exécution. À appeler au démarrage, après l'initialisation
  /// du stockage.
  void restoreActiveWorkout() {
    _restSettings = _storage.getRestSettings();

    final saved = _storage.getActiveWorkout();
    if (saved != null) {
      _currentWorkout = saved.workout;
      _status = ActiveWorkoutStatus.inProgress;
      // Un repos terminé pendant que l'application était fermée est ignoré.
      final rest = saved.rest;
      _rest = (rest != null && rest.isRunningAt(DateTime.now())) ? rest : null;
    }
    notifyListeners();
  }

  /// Démarre une séance : chaque exercice reçoit autant de séries prévues
  /// que lors de sa dernière réalisation (trois par défaut).
  void startWorkout(WorkoutSession session, WorkoutProvider workoutProvider) {
    final now = DateTime.now();
    final refs = List.of(session.exerciseRefs)..sort((a, b) => a.order.compareTo(b.order));

    final exerciseLogs = <ExerciseLog>[];
    for (final ref in refs) {
      final exercise = workoutProvider.getGlobalExerciseById(ref.exerciseId);
      if (exercise == null) continue;

      final previous = workoutProvider.getPreviousSetsForExercise(exercise.name);
      exerciseLogs.add(ExerciseLog(
        id: _storage.generateId(),
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        isUnilateral: exercise.isUnilateral,
        sets: _plannedSets(
          previous.isEmpty ? defaultPlannedSets : previous.length,
          unilateral: exercise.isUnilateral,
        ),
      ));
    }

    _currentWorkout = CompletedWorkout(
      id: _storage.generateId(),
      sessionId: session.id,
      sessionName: session.name,
      date: now,
      startTime: now,
      exerciseLogs: exerciseLogs,
    );
    _status = ActiveWorkoutStatus.inProgress;
    _rest = null;
    unawaited(_alarm.cancel());

    _persist();
    notifyListeners();
  }

  /// Termine la séance et l'enregistre dans l'historique.
  ///
  /// Les séries prévues mais non validées sont retirées, ainsi que les
  /// exercices restés sans aucune série validée.
  Future<CompletedWorkout?> completeWorkout({String? notes}) async {
    final workout = _currentWorkout;
    if (workout == null) return null;

    final logs = <ExerciseLog>[];
    for (final log in workout.exerciseLogs) {
      final done = log.completedSets;
      if (done.isEmpty) continue;
      logs.add(log.copyWith(sets: [
        for (var i = 0; i < done.length; i++) done[i].copyWith(setNumber: i + 1),
      ]));
    }

    final completed = workout.copyWith(
      endTime: DateTime.now(),
      notes: notes,
      exerciseLogs: logs,
    );

    _currentWorkout = completed;
    _status = ActiveWorkoutStatus.completed;
    _rest = null;

    await _alarm.cancel();
    await _storage.saveCompletedWorkout(completed);
    // La séance fait désormais partie de l'historique : elle ne doit plus
    // être proposée à la reprise au prochain lancement.
    await _storage.clearActiveWorkout();

    notifyListeners();
    return completed;
  }

  /// Abandonne la séance en cours sans l'enregistrer.
  void cancelWorkout() => _clear();

  /// Libère la séance une fois terminée et enregistrée.
  void reset() => _clear();

  void _clear() {
    _currentWorkout = null;
    _status = ActiveWorkoutStatus.notStarted;
    _rest = null;
    unawaited(_alarm.cancel());
    unawaited(_storage.clearActiveWorkout());
    notifyListeners();
  }

  // ===========================================================================
  // SÉRIES
  // ===========================================================================

  ExerciseLog? _log(int logIndex) {
    final logs = _currentWorkout?.exerciseLogs;
    if (logs == null || logIndex < 0 || logIndex >= logs.length) return null;
    return logs[logIndex];
  }

  /// Met à jour la charge ou les répétitions saisies sur une série.
  ///
  /// Appelée à chaque frappe : l'état est enregistré sans reconstruire
  /// l'écran, le champ de saisie affichant déjà la valeur.
  void updateSet(int logIndex, int setIndex, {double? weight, int? reps, int? repsRight}) {
    final log = _log(logIndex);
    if (log == null || setIndex < 0 || setIndex >= log.sets.length) return;

    log.sets[setIndex] = log.sets[setIndex].copyWith(
      weight: weight,
      reps: reps,
      repsRight: repsRight,
    );
    _persist();
  }

  /// Valide (ou dé-valide) une série avec la charge et les répétitions
  /// réellement effectuées. La validation lance le minuteur de repos si
  /// l'option est activée.
  void setCompleted(
    int logIndex,
    int setIndex, {
    required bool completed,
    double? weight,
    int? reps,
    int? repsRight,
  }) {
    final log = _log(logIndex);
    if (log == null || setIndex < 0 || setIndex >= log.sets.length) return;

    log.sets[setIndex] = log.sets[setIndex].copyWith(
      weight: weight,
      reps: reps,
      repsRight: repsRight,
      isCompleted: completed,
    );

    if (completed && _restSettings.autoStart) {
      startRest(log.exerciseName);
    } else {
      _persist();
      notifyListeners();
    }
  }

  /// Ajoute une série prévue à un exercice, pré-remplie avec les valeurs
  /// de la série précédente.
  void addSet(int logIndex) {
    final log = _log(logIndex);
    if (log == null) return;

    final last = log.sets.isEmpty ? null : log.sets.last;
    log.sets.add(ExerciseSet(
      id: _storage.generateId(),
      weight: last?.weight ?? 0,
      reps: last?.reps ?? 0,
      // Exercice unilatéral : répétitions du côté droit saisies à part.
      repsRight: log.isUnilateral ? (last?.repsRight ?? last?.reps ?? 0) : null,
      setNumber: log.sets.length + 1,
    ));

    _persist();
    notifyListeners();
  }

  /// Supprime une série et renumérote les suivantes.
  void deleteSet(int logIndex, int setIndex) {
    final log = _log(logIndex);
    if (log == null || setIndex < 0 || setIndex >= log.sets.length) return;

    log.sets.removeAt(setIndex);
    for (var i = 0; i < log.sets.length; i++) {
      log.sets[i] = log.sets[i].copyWith(setNumber: i + 1);
    }

    _persist();
    notifyListeners();
  }

  /// Ajoute un exercice hors séance, en fin de liste.
  ///
  /// Il est préparé comme les autres à partir de sa dernière réalisation.
  void addOffSessionExercise(String exerciseName, WorkoutProvider workoutProvider) {
    final workout = _currentWorkout;
    if (workout == null) return;

    final previous = workoutProvider.getPreviousSetsForExercise(exerciseName);
    final known = workoutProvider.findExerciseByName(exerciseName);
    final unilateral = known?.isUnilateral ?? false;
    final id = _storage.generateId();
    workout.exerciseLogs.add(ExerciseLog(
      id: id,
      exerciseId: known?.id ?? id,
      exerciseName: exerciseName,
      sets: _plannedSets(previous.isEmpty ? 1 : previous.length, unilateral: unilateral),
      isOffSession: true,
      isUnilateral: unilateral,
    ));

    _persist();
    notifyListeners();
  }

  /// Retire un exercice de la séance en cours.
  void removeExercise(int logIndex) {
    final workout = _currentWorkout;
    if (workout == null || _log(logIndex) == null) return;

    workout.exerciseLogs.removeAt(logIndex);
    _persist();
    notifyListeners();
  }

  /// Séries prévues, vides : les valeurs de la séance précédente
  /// s'affichent en indication tant que rien n'est saisi.
  ///
  /// Pour un exercice unilatéral, [ExerciseSet.repsRight] vaut 0 au lieu de
  /// `null` : la série est ainsi identifiée comme réalisée côté par côté.
  List<ExerciseSet> _plannedSets(int count, {bool unilateral = false}) {
    return [
      for (var i = 0; i < count; i++)
        ExerciseSet(
          id: _storage.generateId(),
          weight: 0,
          reps: 0,
          repsRight: unilateral ? 0 : null,
          setNumber: i + 1,
        ),
    ];
  }

  // ===========================================================================
  // MINUTEUR DE REPOS
  // ===========================================================================

  /// Lance le repos après une série de [exerciseName], avec la durée
  /// réglée pour cet exercice, et programme l'alerte de fin.
  void startRest(String exerciseName) {
    final seconds = _restSettings.secondsFor(exerciseName);
    _rest = ActiveRest(
      endsAt: DateTime.now().add(Duration(seconds: seconds)),
      totalSeconds: seconds,
      exerciseName: exerciseName,
    );

    unawaited(_scheduleAlarm(_rest!));
    _persist();
    notifyListeners();
  }

  /// Allonge ou raccourcit le repos en cours de [deltaSeconds] secondes.
  void adjustRest(int deltaSeconds) {
    final rest = _rest;
    if (rest == null) return;

    final endsAt = rest.endsAt.add(Duration(seconds: deltaSeconds));
    if (!endsAt.isAfter(DateTime.now())) {
      skipRest();
      return;
    }

    _rest = rest.copyWith(
      endsAt: endsAt,
      totalSeconds: (rest.totalSeconds + deltaSeconds).clamp(1, 3600).toInt(),
    );
    unawaited(_scheduleAlarm(_rest!));
    _persist();
    notifyListeners();
  }

  /// Interrompt le repos et annule l'alerte.
  void skipRest() {
    if (_rest == null) return;
    _rest = null;
    unawaited(_alarm.cancel());
    _persist();
    notifyListeners();
  }

  /// Appelée par l'écran quand le compte à rebours atteint zéro : l'alerte
  /// système se déclenche d'elle-même, il suffit d'effacer le repos.
  void onRestElapsed() {
    if (_rest == null) return;
    _rest = null;
    _persist();
    notifyListeners();
  }

  Future<void> _scheduleAlarm(ActiveRest rest) async {
    await _alarm.requestPermissions();
    await _alarm.schedule(rest);
  }

  // ===========================================================================
  // RÉGLAGES DU REPOS
  // ===========================================================================

  /// Règle la durée de repos propre à un exercice.
  Future<void> setRestSecondsFor(String exerciseName, int seconds) async {
    _restSettings = _restSettings.withExerciseSeconds(exerciseName, seconds);
    notifyListeners();
    await _storage.saveRestSettings(_restSettings);
  }

  /// Règle la durée de repos par défaut.
  Future<void> setDefaultRestSeconds(int seconds) async {
    _restSettings = _restSettings.copyWith(defaultSeconds: seconds);
    notifyListeners();
    await _storage.saveRestSettings(_restSettings);
  }

  /// Active ou désactive le lancement automatique du repos.
  Future<void> setAutoStartRest(bool enabled) async {
    _restSettings = _restSettings.copyWith(autoStart: enabled);
    notifyListeners();
    await _storage.saveRestSettings(_restSettings);
  }

  // ===========================================================================
  // PERSISTANCE
  // ===========================================================================

  /// Enregistre la séance en cours sans bloquer l'interface.
  void _persist() {
    final workout = _currentWorkout;
    if (workout == null || _status != ActiveWorkoutStatus.inProgress) return;
    unawaited(_storage.saveActiveWorkout(workout, rest: _rest));
  }
}
