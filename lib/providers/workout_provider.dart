import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/models.dart';
import '../services/services.dart';

/// Dernière performance connue sur un exercice, utilisée comme repère
/// au moment de saisir une nouvelle série.
typedef LastPerformance = ({
  /// Meilleure série de la dernière séance contenant l'exercice.
  ExerciseSet bestSet,

  /// Nombre de séries réalisées lors de cette séance.
  int setCount,

  /// Date de cette séance.
  DateTime date,
});

/// Statistiques agrégées sur une période.
typedef PeriodStats = ({
  int totalWorkouts,
  int totalSets,
  int totalReps,
  double totalVolume,
});

/// Données de l'application : bibliothèque d'exercices, séances, planning,
/// historique et objectif hebdomadaire (flammes).
class WorkoutProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<GlobalExercise> _globalExercises = [];
  List<WorkoutSession> _sessions = [];
  WeeklySchedule _schedule = WeeklySchedule();
  List<CompletedWorkout> _completedWorkouts = [];
  UserStreak _streak = UserStreak();
  bool _isLoading = false;

  // ===========================================================================
  // ACCESSEURS
  // ===========================================================================

  List<GlobalExercise> get globalExercises => _globalExercises;
  List<WorkoutSession> get sessions => _sessions;
  WeeklySchedule get schedule => _schedule;
  List<CompletedWorkout> get completedWorkouts => _completedWorkouts;
  UserStreak get streak => _streak;
  bool get isLoading => _isLoading;

  /// Séances comptabilisées pour l'objectif de la semaine en cours.
  ///
  /// Seules les séances contenant au moins une série sont prises en compte :
  /// lancer puis terminer une séance vide ne doit pas valider la semaine.
  int get workoutsThisWeek => workoutsInWeekOf(DateTime.now()).length;

  /// Séances (non vides) réalisées pendant la semaine contenant [date].
  List<CompletedWorkout> workoutsInWeekOf(DateTime date) {
    final monday = UserStreak.getStartOfWeek(date);
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    return _completedWorkouts
        .where((w) => w.totalSets > 0 && !w.date.isBefore(monday) && w.date.isBefore(nextMonday))
        .toList();
  }

  /// Nombre total de séances terminées.
  int get totalCompletedWorkouts => _completedWorkouts.length;

  WorkoutSession? getSessionById(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  /// Séance prévue aujourd'hui dans le planning, le cas échéant.
  WorkoutSession? getTodaySession() {
    final sessionId = _schedule.getSession(DateTime.now().weekday);
    if (sessionId == null) return null;
    return getSessionById(sessionId);
  }

  /// Séances les plus récentes, de la plus récente à la plus ancienne.
  List<CompletedWorkout> getRecentWorkouts({int limit = 5}) {
    return _completedWorkouts.take(limit).toList();
  }

  /// Dernière séance réalisée portant le même nom que [session].
  CompletedWorkout? getLastWorkoutOfSession(WorkoutSession session) {
    for (final workout in _completedWorkouts) {
      if (workout.sessionName == session.name) return workout;
    }
    return null;
  }

  /// Dernière performance enregistrée sur un exercice.
  ///
  /// Renvoie la meilleure série (au sens du 1RM estimé) de la séance la plus
  /// récente contenant l'exercice, et non la dernière série saisie, souvent
  /// plus légère (série dégressive, fatigue).
  LastPerformance? getLastPerformanceForExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();

    // L'historique est trié de la séance la plus récente à la plus ancienne.
    for (final workout in _completedWorkouts) {
      for (final log in workout.exerciseLogs) {
        if (log.exerciseName.toLowerCase() != name) continue;
        final best = log.bestSet;
        if (best == null) continue;
        return (bestSet: best, setCount: log.sets.length, date: workout.date);
      }
    }
    return null;
  }

  /// Séries réalisées sur un exercice lors de la séance la plus récente qui
  /// le contient, pour afficher la colonne « Précédent » et préparer la
  /// séance suivante.
  List<ExerciseSet> getPreviousSetsForExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    for (final workout in _completedWorkouts) {
      for (final log in workout.exerciseLogs) {
        if (log.exerciseName.toLowerCase() == name && log.sets.isNotEmpty) {
          return log.sets;
        }
      }
    }
    return const [];
  }

  // ===========================================================================
  // CHARGEMENT
  // ===========================================================================

  /// Charge toutes les données depuis le stockage local.
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _globalExercises = await _storage.getAllGlobalExercises();
      _sessions = await _storage.getAllSessions();
      _schedule = await _storage.getWeeklySchedule();
      _completedWorkouts = await _storage.getAllCompletedWorkouts();
      _streak = await _storage.getUserStreak();

      await _checkAndUpdateStreak();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données : $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ===========================================================================
  // BIBLIOTHÈQUE D'EXERCICES
  // ===========================================================================

  GlobalExercise? getGlobalExerciseById(String id) {
    for (final exercise in _globalExercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  List<GlobalExercise> searchGlobalExercises(String query) {
    if (query.isEmpty) return _globalExercises;
    final lowerQuery = query.toLowerCase();
    return _globalExercises.where((e) => e.name.toLowerCase().contains(lowerQuery)).toList();
  }

  Future<void> addGlobalExercise(GlobalExercise exercise) async {
    _globalExercises.add(exercise);
    _sortExercises();
    await _storage.saveGlobalExercise(exercise);
    notifyListeners();
  }

  Future<void> updateGlobalExercise(GlobalExercise exercise) async {
    final index = _globalExercises.indexWhere((e) => e.id == exercise.id);
    if (index == -1) return;

    _globalExercises[index] = exercise;
    _sortExercises();
    await _storage.saveGlobalExercise(exercise);
    notifyListeners();
  }

  /// Supprime un exercice de la bibliothèque et le retire de toutes les séances.
  ///
  /// L'historique n'est pas modifié : les séances passées conservent le nom
  /// de l'exercice et restent visibles dans les statistiques.
  Future<void> deleteGlobalExercise(String id) async {
    _globalExercises.removeWhere((e) => e.id == id);
    for (final session in _sessions) {
      final before = session.exerciseRefs.length;
      session.exerciseRefs.removeWhere((ref) => ref.exerciseId == id);
      if (session.exerciseRefs.length != before) {
        await _storage.saveSession(session);
      }
    }
    await _storage.deleteGlobalExercise(id);
    notifyListeners();
  }

  void _sortExercises() {
    _globalExercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ===========================================================================
  // OBJECTIF HEBDOMADAIRE (FLAMMES)
  // ===========================================================================

  /// Remet la série à zéro si une semaine complète s'est écoulée sans que
  /// l'objectif soit atteint.
  ///
  /// La série reste active tant que la dernière semaine validée est la
  /// semaine en cours ou la précédente (la semaine en cours n'est pas finie).
  Future<void> _checkAndUpdateStreak() async {
    final lastCompleted = _streak.lastWeekCompleted;
    if (lastCompleted == null || _streak.currentStreak == 0) return;

    if (UserStreak.weeksBetween(lastCompleted, DateTime.now()) > 1) {
      _streak = _streak.copyWith(currentStreak: 0);
      await _storage.saveUserStreak(_streak);
    }
  }

  /// Met à jour l'objectif hebdomadaire.
  Future<void> updateWeeklyGoal(int goal) async {
    _streak = _streak.copyWith(weeklyGoal: goal);
    await _storage.saveUserStreak(_streak);
    notifyListeners();
    // Un objectif revu à la baisse peut être atteint immédiatement.
    await checkWeeklyGoal();
  }

  /// Valide la semaine en cours si l'objectif est atteint (une seule fois
  /// par semaine) et met à jour la série et le record de série.
  Future<void> checkWeeklyGoal() async {
    final now = DateTime.now();
    if (workoutsThisWeek < _streak.weeklyGoal) return;

    final weekNumber = UserStreak.getWeekNumber(now);
    final weekYear = UserStreak.getWeekYear(now);
    final alreadyValidated = _streak.weekHistory.any(
      (w) => w.weekNumber == weekNumber && w.year == weekYear,
    );
    if (alreadyValidated) return;

    // La série continue si la semaine précédente avait été validée,
    // sinon elle repart de 1.
    final lastCompleted = _streak.lastWeekCompleted;
    final continuesStreak =
        lastCompleted != null && UserStreak.weeksBetween(lastCompleted, now) == 1;
    final newStreak = continuesStreak ? _streak.currentStreak + 1 : 1;

    _streak = _streak.copyWith(
      currentStreak: newStreak,
      bestStreak: newStreak > _streak.bestStreak ? newStreak : _streak.bestStreak,
      lastWeekCompleted: now,
      weekHistory: [
        ..._streak.weekHistory,
        WeekRecord(
          weekNumber: weekNumber,
          year: weekYear,
          workoutsCompleted: workoutsThisWeek,
          goalAtTime: _streak.weeklyGoal,
          goalMet: true,
        ),
      ],
    );

    await _storage.saveUserStreak(_streak);
    notifyListeners();
  }

  // ===========================================================================
  // SÉANCES
  // ===========================================================================

  Future<void> addSession(WorkoutSession session) async {
    await _storage.saveSession(session);
    _sessions.add(session);
    notifyListeners();
  }

  Future<void> updateSession(WorkoutSession session) async {
    await _storage.saveSession(session);
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      notifyListeners();
    }
  }

  /// Supprime une séance et la retire du planning.
  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);

    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      if (_schedule.getSession(day) == id) {
        _schedule.setSession(day, null);
      }
    }
    await _storage.saveWeeklySchedule(_schedule);

    notifyListeners();
  }

  // ===========================================================================
  // PLANNING
  // ===========================================================================

  Future<void> updateSchedule(int dayOfWeek, String? sessionId) async {
    _schedule.setSession(dayOfWeek, sessionId);
    await _storage.saveWeeklySchedule(_schedule);
    notifyListeners();
  }

  // ===========================================================================
  // HISTORIQUE
  // ===========================================================================

  /// Enregistre une séance terminée puis vérifie l'objectif hebdomadaire.
  Future<void> saveCompletedWorkout(CompletedWorkout workout) async {
    await _storage.saveCompletedWorkout(workout);

    final index = _completedWorkouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _completedWorkouts[index] = workout;
    } else {
      _completedWorkouts.add(workout);
    }
    _completedWorkouts.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    await checkWeeklyGoal();
  }

  Future<void> deleteCompletedWorkout(String id) async {
    await _storage.deleteCompletedWorkout(id);
    _completedWorkouts.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  // ===========================================================================
  // STATISTIQUES
  // ===========================================================================

  /// Évolution d'un exercice séance après séance, de la plus ancienne à la
  /// plus récente, sur la période donnée.
  Future<List<Map<String, dynamic>>> getExerciseProgression(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _storage.getExerciseProgressionData(
      exerciseName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Noms de tous les exercices connus (bibliothèque et historique), triés.
  List<String> getAllExerciseNames() {
    final names = <String>{
      for (final exercise in _globalExercises) exercise.name,
      for (final workout in _completedWorkouts)
        for (final log in workout.exerciseLogs)
          if (log.sets.isNotEmpty) log.exerciseName,
    };
    return names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Statistiques agrégées des séances comprises dans [period] (bornes incluses).
  PeriodStats getStatsForPeriod(DateTimeRange period) {
    final start = DateTime(period.start.year, period.start.month, period.start.day);
    final endExclusive = DateTime(period.end.year, period.end.month, period.end.day + 1);

    var totalWorkouts = 0;
    var totalSets = 0;
    var totalReps = 0;
    var totalVolume = 0.0;

    for (final workout in _completedWorkouts) {
      if (workout.date.isBefore(start) || !workout.date.isBefore(endExclusive)) continue;
      if (workout.totalSets == 0) continue;
      totalWorkouts++;
      totalSets += workout.totalSets;
      totalReps += workout.totalReps;
      totalVolume += workout.totalVolume;
    }

    return (
      totalWorkouts: totalWorkouts,
      totalSets: totalSets,
      totalReps: totalReps,
      totalVolume: totalVolume,
    );
  }

  /// Charge maximale jamais soulevée, par exercice.
  Map<String, double> getAllPreviousPRs() {
    final prs = <String, double>{};
    for (final workout in _completedWorkouts) {
      for (final log in workout.exerciseLogs) {
        final current = prs[log.exerciseName] ?? 0;
        if (log.maxWeight > current) prs[log.exerciseName] = log.maxWeight;
      }
    }
    return prs;
  }

  /// Records battus lors de [workout], comparés aux séances antérieures.
  ///
  /// Deux types de records sont détectés, par ordre de priorité :
  /// 1. la charge maximale (plus lourd que jamais) ;
  /// 2. le 1RM estimé (par exemple plus de répétitions à charge égale).
  ///
  /// Un exercice réalisé pour la première fois n'établit pas de record :
  /// il n'y a rien à battre.
  List<PersonalRecord> checkForNewPRs(CompletedWorkout workout) {
    // Meilleures valeurs antérieures à la séance, par exercice.
    final previousMaxWeight = <String, double>{};
    final previousBestOneRepMax = <String, double>{};

    for (final past in _completedWorkouts) {
      if (past.id == workout.id || !past.date.isBefore(workout.date)) continue;

      for (final log in past.exerciseLogs) {
        if (log.sets.isEmpty) continue;
        final name = log.exerciseName;
        if (log.maxWeight > (previousMaxWeight[name] ?? 0)) {
          previousMaxWeight[name] = log.maxWeight;
        }
        if (log.bestEstimatedOneRepMax > (previousBestOneRepMax[name] ?? 0)) {
          previousBestOneRepMax[name] = log.bestEstimatedOneRepMax;
        }
      }
    }

    final records = <PersonalRecord>[];

    for (final log in workout.exerciseLogs) {
      final bestSet = log.bestSet;
      if (bestSet == null) continue;

      final name = log.exerciseName;
      final oldWeight = previousMaxWeight[name];
      final oldOneRepMax = previousBestOneRepMax[name];
      if (oldWeight == null || oldOneRepMax == null) continue;

      if (log.maxWeight > oldWeight) {
        records.add(PersonalRecord(
          exerciseName: name,
          kind: PersonalRecordKind.heaviestWeight,
          previousValue: oldWeight,
          newValue: log.maxWeight,
          recordSet: log.sets.firstWhere((s) => s.weight == log.maxWeight),
        ));
      } else if (log.bestEstimatedOneRepMax > oldOneRepMax) {
        records.add(PersonalRecord(
          exerciseName: name,
          kind: PersonalRecordKind.estimatedOneRepMax,
          previousValue: oldOneRepMax,
          newValue: log.bestEstimatedOneRepMax,
          recordSet: bestSet,
        ));
      }
    }

    return records;
  }
}
