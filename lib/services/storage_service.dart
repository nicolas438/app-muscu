import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class StorageService {
  static const String _globalExercisesBox = 'global_exercises';
  static const String _sessionsBox = 'workout_sessions';
  static const String _completedWorkoutsBox = 'completed_workouts';
  static const String _scheduleBox = 'weekly_schedule';
  static const String _streakBox = 'user_streak';
  static const String _activeWorkoutBox = 'active_workout';

  late Box<Map> _globalExercisesBoxInstance;
  late Box<Map> _sessionsBoxInstance;
  late Box<Map> _completedWorkoutsBoxInstance;
  late Box<Map> _scheduleBoxInstance;
  late Box<Map> _streakBoxInstance;
  late Box<Map> _activeWorkoutBoxInstance;

  final _uuid = const Uuid();

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    _globalExercisesBoxInstance = await Hive.openBox<Map>(_globalExercisesBox);
    _sessionsBoxInstance = await Hive.openBox<Map>(_sessionsBox);
    _completedWorkoutsBoxInstance = await Hive.openBox<Map>(_completedWorkoutsBox);
    _scheduleBoxInstance = await Hive.openBox<Map>(_scheduleBox);
    _streakBoxInstance = await Hive.openBox<Map>(_streakBox);
    _activeWorkoutBoxInstance = await Hive.openBox<Map>(_activeWorkoutBox);
  }

  String generateId() => _uuid.v4();

  // Helper to recursively convert Map<dynamic, dynamic> to Map<String, dynamic>
  Map<String, dynamic> _convertMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _convertList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic> _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  // =====================
  // GLOBAL EXERCISES
  // =====================

  Future<List<GlobalExercise>> getAllGlobalExercises() async {
    final exercises = <GlobalExercise>[];
    for (var key in _globalExercisesBoxInstance.keys) {
      final data = _globalExercisesBoxInstance.get(key);
      if (data != null) {
        exercises.add(GlobalExercise.fromJson(_convertMap(data)));
      }
    }
    exercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return exercises;
  }

  Future<GlobalExercise?> getGlobalExercise(String id) async {
    final data = _globalExercisesBoxInstance.get(id);
    if (data != null) {
      return GlobalExercise.fromJson(_convertMap(data));
    }
    return null;
  }

  Future<void> saveGlobalExercise(GlobalExercise exercise) async {
    await _globalExercisesBoxInstance.put(exercise.id, exercise.toJson());
  }

  Future<void> saveAllGlobalExercises(List<GlobalExercise> exercises) async {
    await _globalExercisesBoxInstance.clear();
    for (var exercise in exercises) {
      await _globalExercisesBoxInstance.put(exercise.id, exercise.toJson());
    }
  }

  Future<void> deleteGlobalExercise(String id) async {
    await _globalExercisesBoxInstance.delete(id);
  }

  // =====================
  // WORKOUT SESSIONS
  // =====================

  Future<List<WorkoutSession>> getAllSessions() async {
    final sessions = <WorkoutSession>[];
    for (var key in _sessionsBoxInstance.keys) {
      final data = _sessionsBoxInstance.get(key);
      if (data != null) {
        sessions.add(WorkoutSession.fromJson(_convertMap(data)));
      }
    }
    return sessions;
  }

  Future<WorkoutSession?> getSession(String id) async {
    final data = _sessionsBoxInstance.get(id);
    if (data != null) {
      return WorkoutSession.fromJson(_convertMap(data));
    }
    return null;
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _sessionsBoxInstance.put(session.id, session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBoxInstance.delete(id);
  }

  // =====================
  // COMPLETED WORKOUTS
  // =====================

  Future<List<CompletedWorkout>> getAllCompletedWorkouts() async {
    final workouts = <CompletedWorkout>[];
    for (var key in _completedWorkoutsBoxInstance.keys) {
      final data = _completedWorkoutsBoxInstance.get(key);
      if (data != null) {
        workouts.add(CompletedWorkout.fromJson(_convertMap(data)));
      }
    }
    workouts.sort((a, b) => b.date.compareTo(a.date));
    return workouts;
  }

  Future<List<CompletedWorkout>> getCompletedWorkoutsForMonth(int year, int month) async {
    final all = await getAllCompletedWorkouts();
    return all.where((w) => w.date.year == year && w.date.month == month).toList();
  }

  Future<List<CompletedWorkout>> getCompletedWorkoutsForExercise(String exerciseId) async {
    final all = await getAllCompletedWorkouts();
    return all.where((w) => w.exerciseLogs.any((l) => l.exerciseId == exerciseId)).toList();
  }

  Future<CompletedWorkout?> getCompletedWorkout(String id) async {
    final data = _completedWorkoutsBoxInstance.get(id);
    if (data != null) {
      return CompletedWorkout.fromJson(_convertMap(data));
    }
    return null;
  }

  Future<void> saveCompletedWorkout(CompletedWorkout workout) async {
    await _completedWorkoutsBoxInstance.put(workout.id, workout.toJson());
  }

  Future<void> deleteCompletedWorkout(String id) async {
    await _completedWorkoutsBoxInstance.delete(id);
  }

  // =====================
  // WEEKLY SCHEDULE
  // =====================

  Future<WeeklySchedule> getWeeklySchedule() async {
    final data = _scheduleBoxInstance.get('schedule');
    if (data != null) {
      return WeeklySchedule.fromJson(_convertMap(data));
    }
    return WeeklySchedule();
  }

  Future<void> saveWeeklySchedule(WeeklySchedule schedule) async {
    await _scheduleBoxInstance.put('schedule', schedule.toJson());
  }

  // =====================
  // ANALYTICS HELPERS
  // =====================

  Future<Map<String, List<ExerciseLog>>> getExerciseLogsGroupedByName() async {
    final all = await getAllCompletedWorkouts();
    final grouped = <String, List<ExerciseLog>>{};

    for (var workout in all) {
      for (var log in workout.exerciseLogs) {
        if (!grouped.containsKey(log.exerciseName)) {
          grouped[log.exerciseName] = [];
        }
        grouped[log.exerciseName]!.add(log);
      }
    }

    return grouped;
  }

  Future<List<Map<String, dynamic>>> getExerciseProgressionData(
    String exerciseName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final all = await getAllCompletedWorkouts();
    final data = <Map<String, dynamic>>[];

    for (var workout in all) {
      if (startDate != null && workout.date.isBefore(startDate)) continue;
      if (endDate != null && workout.date.isAfter(endDate)) continue;

      for (var log in workout.exerciseLogs) {
        if (log.exerciseName == exerciseName && log.sets.isNotEmpty) {
          data.add({
            'date': workout.date,
            'maxWeight': log.maxWeight,
            'totalVolume': log.totalVolume,
            'totalReps': log.totalReps,
            'sets': log.sets.length,
          });
        }
      }
    }

    data.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return data;
  }

  // =====================
  // USER STREAK
  // =====================

  Future<UserStreak> getUserStreak() async {
    final data = _streakBoxInstance.get('streak');
    if (data == null) return UserStreak();
    try {
      return UserStreak.fromJson(_convertMap(data));
    } catch (e) {
      return UserStreak();
    }
  }

  Future<void> saveUserStreak(UserStreak streak) async {
    await _streakBoxInstance.put('streak', streak.toJson());
  }

  // =====================
  // SÉANCE EN COURS
  // =====================

  /// Clé unique sous laquelle la séance en cours est conservée.
  static const String _activeWorkoutKey = 'current';

  /// Sauvegarde l'état de la séance en cours (séries saisies et exercice affiché).
  ///
  /// Appelée après chaque modification afin qu'aucune donnée ne soit perdue
  /// si le système ferme l'application pendant l'entraînement.
  Future<void> saveActiveWorkout(CompletedWorkout workout, int currentExerciseIndex) async {
    await _activeWorkoutBoxInstance.put(_activeWorkoutKey, {
      'workout': workout.toJson(),
      'currentExerciseIndex': currentExerciseIndex,
    });
  }

  /// Restaure la séance en cours, ou renvoie `null` s'il n'y en a pas.
  ///
  /// Une donnée illisible (format obsolète, écriture interrompue) est supprimée
  /// plutôt que de bloquer le démarrage de l'application.
  ({CompletedWorkout workout, int currentExerciseIndex})? getActiveWorkout() {
    final data = _activeWorkoutBoxInstance.get(_activeWorkoutKey);
    if (data == null) return null;

    try {
      final map = _convertMap(data);
      return (
        workout: CompletedWorkout.fromJson(map['workout'] as Map<String, dynamic>),
        currentExerciseIndex: map['currentExerciseIndex'] as int? ?? 0,
      );
    } catch (_) {
      _activeWorkoutBoxInstance.delete(_activeWorkoutKey);
      return null;
    }
  }

  /// Supprime la séance en cours une fois celle-ci terminée ou abandonnée.
  Future<void> clearActiveWorkout() async {
    await _activeWorkoutBoxInstance.delete(_activeWorkoutKey);
  }
}
