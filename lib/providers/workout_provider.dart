import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/models.dart';
import '../services/services.dart';

class WorkoutProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<GlobalExercise> _globalExercises = [];
  List<WorkoutSession> _sessions = [];
  WeeklySchedule _schedule = WeeklySchedule();
  List<CompletedWorkout> _completedWorkouts = [];
  UserStreak _streak = UserStreak();
  bool _isLoading = false;

  // Getters
  List<GlobalExercise> get globalExercises => _globalExercises;
  List<WorkoutSession> get sessions => _sessions;
  WeeklySchedule get schedule => _schedule;
  List<CompletedWorkout> get completedWorkouts => _completedWorkouts;
  UserStreak get streak => _streak;
  bool get isLoading => _isLoading;

  /// Nombre de séances cette semaine
  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = UserStreak.getStartOfWeek(now);
    return _completedWorkouts.where((w) => 
      w.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))
    ).length;
  }

  /// Total de séances effectuées
  int get totalCompletedWorkouts => _completedWorkouts.length;

  /// Date de la première séance
  DateTime? get firstWorkoutDate {
    if (_completedWorkouts.isEmpty) return null;
    final sorted = List<CompletedWorkout>.from(_completedWorkouts)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.first.date;
  }

  WorkoutSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  WorkoutSession? getTodaySession() {
    final today = DateTime.now().weekday;
    final sessionId = _schedule.getSession(today);
    if (sessionId == null) return null;
    return getSessionById(sessionId);
  }

  List<CompletedWorkout> getRecentWorkouts({int limit = 5}) {
    final sorted = List<CompletedWorkout>.from(_completedWorkouts)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  /// Retourne la dernière séance complétée du même type que celle d'aujourd'hui
  CompletedWorkout? getLastWorkoutOfTodayType() {
    final todaySession = getTodaySession();
    if (todaySession == null) return null;
    
    // Chercher les séances complétées avec le même nom
    final sameTypeWorkouts = _completedWorkouts
        .where((w) => w.sessionName == todaySession.name)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return sameTypeWorkouts.isNotEmpty ? sameTypeWorkouts.first : null;
  }

  /// Retourne la dernière performance connue pour un exercice donné.
  /// Renvoie null si aucune perf trouvée.
  /// Structure de retour: { 'weight': double, 'reps': int, 'date': DateTime, 'workoutId': String }
  Map<String, dynamic>? getLastPerformanceForExercise(String exerciseName) {
    final sorted = List<CompletedWorkout>.from(_completedWorkouts)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var workout in sorted) {
      for (var log in workout.exerciseLogs) {
        if (log.exerciseName.toLowerCase() == exerciseName.toLowerCase() && log.sets.isNotEmpty) {
          final lastSet = log.sets.last;
          return {
            'weight': lastSet.weight,
            'reps': lastSet.reps,
            'date': workout.date,
            'workoutId': workout.id,
          };
        }
      }
    }

    return null;
  }

  // Initialize
  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _globalExercises = await _storage.getAllGlobalExercises();
      _sessions = await _storage.getAllSessions();
      _schedule = await _storage.getWeeklySchedule();
      _completedWorkouts = await _storage.getAllCompletedWorkouts();
      _streak = await _storage.getUserStreak();
      
      // Migration: create global exercises from old session exercises
      await _migrateExercisesToGlobal();
      
      // Vérifier et mettre à jour le streak
      await _checkAndUpdateStreak();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Migre les anciens exercices des séances vers la bibliothèque globale
  Future<void> _migrateExercisesToGlobal() async {
    // Collecter tous les exercices uniques des anciennes séances
    final existingExerciseIds = _globalExercises.map((e) => e.id).toSet();
    bool needsSave = false;

    for (var session in _sessions) {
      // Si la séance utilise encore l'ancien format (exerciseRefs vide mais exercises non vide)
      if (session.exerciseRefs.isEmpty && session.exercises.isNotEmpty) {
        for (var exercise in session.exercises) {
          // Créer un exercice global si il n'existe pas déjà
          if (!existingExerciseIds.contains(exercise.id)) {
            final globalExercise = GlobalExercise(
              id: exercise.id,
              name: exercise.name,
              notes: exercise.notes,
            );
            _globalExercises.add(globalExercise);
            existingExerciseIds.add(exercise.id);
            needsSave = true;
          }
          
          // Ajouter la référence dans la séance
          session.exerciseRefs.add(SessionExerciseRef(
            exerciseId: exercise.id,
            order: exercise.order,
          ));
        }
      }
    }

    if (needsSave) {
      await _storage.saveAllGlobalExercises(_globalExercises);
      // Sauvegarder les séances mises à jour
      for (var session in _sessions) {
        await _storage.saveSession(session);
      }
    }
  }

  // ===== GLOBAL EXERCISES CRUD =====
  
  GlobalExercise? getGlobalExerciseById(String id) {
    try {
      return _globalExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GlobalExercise> searchGlobalExercises(String query) {
    if (query.isEmpty) return _globalExercises;
    final lowerQuery = query.toLowerCase();
    return _globalExercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<void> addGlobalExercise(GlobalExercise exercise) async {
    _globalExercises.add(exercise);
    await _storage.saveAllGlobalExercises(_globalExercises);
    notifyListeners();
  }

  Future<void> updateGlobalExercise(GlobalExercise exercise) async {
    final index = _globalExercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      _globalExercises[index] = exercise;
      await _storage.saveAllGlobalExercises(_globalExercises);
      notifyListeners();
    }
  }

  Future<void> deleteGlobalExercise(String id) async {
    _globalExercises.removeWhere((e) => e.id == id);
    // Retirer également des séances
    for (var session in _sessions) {
      session.exerciseRefs.removeWhere((ref) => ref.exerciseId == id);
      await _storage.saveSession(session);
    }
    await _storage.saveAllGlobalExercises(_globalExercises);
    notifyListeners();
  }


  /// Vérifie et met à jour le streak en fonction des semaines passées
  Future<void> _checkAndUpdateStreak() async {
    final now = DateTime.now();
    final currentWeekNumber = UserStreak.getWeekNumber(now);
    final currentYear = now.year;
    
    // Si on a une semaine enregistrée comme dernière complétée
    if (_streak.lastWeekCompleted != null) {
      final lastWeekNumber = UserStreak.getWeekNumber(_streak.lastWeekCompleted!);
      final lastYear = _streak.lastWeekCompleted!.year;
      
      // Calculer le nombre de semaines écoulées
      int weeksDiff = 0;
      if (currentYear == lastYear) {
        weeksDiff = currentWeekNumber - lastWeekNumber;
      } else {
        // Années différentes
        weeksDiff = (52 - lastWeekNumber) + currentWeekNumber + ((currentYear - lastYear - 1) * 52);
      }
      
      // Si plus d'une semaine s'est écoulée sans valider, on perd le streak
      if (weeksDiff > 1) {
        _streak = _streak.copyWith(currentStreak: 0);
        await _storage.saveUserStreak(_streak);
      }
    }
  }

  /// Met à jour l'objectif hebdomadaire
  Future<void> updateWeeklyGoal(int goal) async {
    _streak = _streak.copyWith(weeklyGoal: goal);
    await _storage.saveUserStreak(_streak);
    notifyListeners();
  }

  /// Appelé après chaque entraînement pour vérifier si on atteint l'objectif
  Future<void> checkWeeklyGoal() async {
    final now = DateTime.now();
    final currentWeekNumber = UserStreak.getWeekNumber(now);
    final currentYear = now.year;
    
    // Vérifier si l'objectif de cette semaine est atteint
    if (workoutsThisWeek >= _streak.weeklyGoal) {
      // Vérifier si on n'a pas déjà validé cette semaine
      final alreadyValidated = _streak.weekHistory.any(
        (w) => w.weekNumber == currentWeekNumber && w.year == currentYear
      );
      
      if (!alreadyValidated) {
        // Ajouter à l'historique
        final weekRecord = WeekRecord(
          weekNumber: currentWeekNumber,
          year: currentYear,
          workoutsCompleted: workoutsThisWeek,
          goalAtTime: _streak.weeklyGoal,
          goalMet: true,
        );
        
        final newHistory = [..._streak.weekHistory, weekRecord];
        final newStreak = _streak.currentStreak + 1;
        final newBest = newStreak > _streak.bestStreak ? newStreak : _streak.bestStreak;
        
        _streak = _streak.copyWith(
          currentStreak: newStreak,
          bestStreak: newBest,
          lastWeekCompleted: now,
          weekHistory: newHistory,
        );
        
        await _storage.saveUserStreak(_streak);
        notifyListeners();
      }
    }
  }

  // =====================
  // SESSIONS
  // =====================

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

  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);

    // Also remove from schedule
    for (var day = 1; day <= 7; day++) {
      if (_schedule.getSession(day) == id) {
        _schedule.setSession(day, null);
      }
    }
    await _storage.saveWeeklySchedule(_schedule);

    notifyListeners();
  }

  // =====================
  // SCHEDULE
  // =====================

  Future<void> updateSchedule(int dayOfWeek, String? sessionId) async {
    _schedule.setSession(dayOfWeek, sessionId);
    await _storage.saveWeeklySchedule(_schedule);
    notifyListeners();
  }

  // =====================
  // COMPLETED WORKOUTS
  // =====================

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
    
    // Vérifier si on atteint l'objectif hebdomadaire
    await checkWeeklyGoal();
  }

  Future<void> deleteCompletedWorkout(String id) async {
    await _storage.deleteCompletedWorkout(id);
    _completedWorkouts.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  // =====================
  // ANALYTICS
  // =====================

  Future<List<Map<String, dynamic>>> getExerciseProgression(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _storage.getExerciseProgressionData(
      exerciseName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  List<String> getAllExerciseNames() {
    final names = <String>{};
    // Get names from global exercises
    for (var globalExercise in _globalExercises) {
      names.add(globalExercise.name);
    }
    for (var workout in _completedWorkouts) {
      for (var log in workout.exerciseLogs) {
        names.add(log.exerciseName);
      }
    }
    return names.toList()..sort();
  }

  Map<String, dynamic> getMonthlyStats(int year, int month) {
    final monthWorkouts = _completedWorkouts.where(
      (w) => w.date.year == year && w.date.month == month,
    ).toList();

    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int totalWorkouts = monthWorkouts.length;

    for (var workout in monthWorkouts) {
      totalVolume += workout.totalVolume;
      totalSets += workout.totalSets;
      totalReps += workout.totalReps;
    }

    return {
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'avgVolumePerWorkout': totalWorkouts > 0 ? totalVolume / totalWorkouts : 0,
    };
  }

  Map<String, dynamic> getStatsForPeriod(DateTimeRange period) {
    final periodWorkouts = _completedWorkouts.where(
      (w) => w.date.isAfter(period.start.subtract(const Duration(days: 1))) && 
             w.date.isBefore(period.end.add(const Duration(days: 1))),
    ).toList();

    double totalVolume = 0;
    int totalSets = 0;
    int totalReps = 0;
    int totalWorkouts = periodWorkouts.length;

    for (var workout in periodWorkouts) {
      totalVolume += workout.totalVolume;
      totalSets += workout.totalSets;
      totalReps += workout.totalReps;
    }

    return {
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'avgVolumePerWorkout': totalWorkouts > 0 ? totalVolume / totalWorkouts : 0,
    };
  }

  // Get previous best (PR) for each exercise
  Map<String, double> getAllPreviousPRs() {
    final prs = <String, double>{};
    
    for (var workout in _completedWorkouts) {
      for (var log in workout.exerciseLogs) {
        final currentPR = prs[log.exerciseName] ?? 0;
        if (log.maxWeight > currentPR) {
          prs[log.exerciseName] = log.maxWeight;
        }
      }
    }
    
    return prs;
  }

  // Check for new PRs in a completed workout
  Map<String, Map<String, double>> checkForNewPRs(CompletedWorkout workout) {
    final newPRs = <String, Map<String, double>>{};
    
    // Get all previous PRs BEFORE this workout
    final previousPRs = <String, double>{};
    for (var pastWorkout in _completedWorkouts) {
      // Skip the current workout and any workout after it
      if (pastWorkout.id == workout.id || pastWorkout.date.isAfter(workout.date)) {
        continue;
      }
      
      for (var log in pastWorkout.exerciseLogs) {
        final currentPR = previousPRs[log.exerciseName] ?? 0;
        if (log.maxWeight > currentPR) {
          previousPRs[log.exerciseName] = log.maxWeight;
        }
      }
    }
    
    // Check each exercise in the current workout
    for (var log in workout.exerciseLogs) {
      if (log.sets.isEmpty) continue;
      
      final previousPR = previousPRs[log.exerciseName];
      final currentMax = log.maxWeight;
      
      // It's a PR only if there's a previous record AND current is higher
      // (ignore first time exercises)
      if (previousPR != null && currentMax > previousPR) {
        newPRs[log.exerciseName] = {
          'new': currentMax,
          'old': previousPR,
        };
      }
    }
    
    return newPRs;
  }
}
