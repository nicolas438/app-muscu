import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'workout_provider.dart';

enum ActiveWorkoutStatus {
  notStarted,
  inProgress,
  completed,
}

class ActiveWorkoutProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  CompletedWorkout? _currentWorkout;
  int _currentExerciseIndex = 0;
  ActiveWorkoutStatus _status = ActiveWorkoutStatus.notStarted;
  DateTime? _workoutStartTime;

  // Getters
  CompletedWorkout? get currentWorkout => _currentWorkout;
  int get currentExerciseIndex => _currentExerciseIndex;
  ActiveWorkoutStatus get status => _status;
  DateTime? get workoutStartTime => _workoutStartTime;

  bool get hasActiveWorkout => _status == ActiveWorkoutStatus.inProgress;

  ExerciseLog? get currentExerciseLog {
    if (_currentWorkout == null) return null;
    if (_currentExerciseIndex >= _currentWorkout!.exerciseLogs.length) return null;
    return _currentWorkout!.exerciseLogs[_currentExerciseIndex];
  }

  Duration get elapsedTime {
    if (_workoutStartTime == null) return Duration.zero;
    return DateTime.now().difference(_workoutStartTime!);
  }

  // Start a new workout
  void startWorkout(WorkoutSession session, WorkoutProvider workoutProvider) {
    final workoutId = _storage.generateId();
    final now = DateTime.now();

    // Get global exercises from refs
    final exerciseLogs = session.exerciseRefs.map((ref) {
      final globalExercise = workoutProvider.getGlobalExerciseById(ref.exerciseId);
      if (globalExercise == null) return null;
      
      // Create an Exercise from GlobalExercise
      final exercise = Exercise(
        id: globalExercise.id,
        name: globalExercise.name,
        order: ref.order,
      );
      return ExerciseLog.fromExercise(_storage.generateId(), exercise);
    }).whereType<ExerciseLog>().toList();

    _currentWorkout = CompletedWorkout(
      id: workoutId,
      sessionId: session.id,
      sessionName: session.name,
      date: now,
      startTime: now,
      exerciseLogs: exerciseLogs,
    );

    _currentExerciseIndex = 0;
    _status = ActiveWorkoutStatus.inProgress;
    _workoutStartTime = now;

    notifyListeners();
  }

  // Add a set to current exercise
  void addSet({
    required double weight,
    required int reps,
    String? notes,
  }) {
    if (_currentWorkout == null || currentExerciseLog == null) return;

    final setId = _storage.generateId();
    final setNumber = currentExerciseLog!.sets.length + 1;

    final newSet = ExerciseSet(
      id: setId,
      weight: weight,
      reps: reps,
      setNumber: setNumber,
      isCompleted: true,
      notes: notes,
    );

    currentExerciseLog!.sets.add(newSet);
    notifyListeners();
  }

  // Update a set
  void updateSet(int setIndex, {double? weight, int? reps, String? notes}) {
    if (currentExerciseLog == null) return;
    if (setIndex >= currentExerciseLog!.sets.length) return;

    final currentSet = currentExerciseLog!.sets[setIndex];
    currentExerciseLog!.sets[setIndex] = currentSet.copyWith(
      weight: weight,
      reps: reps,
      notes: notes,
    );

    notifyListeners();
  }

  // Delete a set
  void deleteSet(int setIndex) {
    if (currentExerciseLog == null) return;
    if (setIndex >= currentExerciseLog!.sets.length) return;

    currentExerciseLog!.sets.removeAt(setIndex);

    // Renumber remaining sets
    for (var i = 0; i < currentExerciseLog!.sets.length; i++) {
      currentExerciseLog!.sets[i] = currentExerciseLog!.sets[i].copyWith(
        setNumber: i + 1,
      );
    }

    notifyListeners();
  }

  // Add an off-session exercise (exercice hors séance)
  void addOffSessionExercise(String exerciseName) {
    if (_currentWorkout == null) return;

    final exerciseId = _storage.generateId();

    final offSessionLog = ExerciseLog(
      id: exerciseId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: [], // No sets initially - user will add them manually
      isOffSession: true,
    );

    _currentWorkout!.exerciseLogs.add(offSessionLog);
    notifyListeners();
  }

  // Navigate exercises
  void nextExercise() {
    if (_currentWorkout == null) return;
    if (_currentExerciseIndex < _currentWorkout!.exerciseLogs.length - 1) {
      _currentExerciseIndex++;
      notifyListeners();
    }
  }

  void previousExercise() {
    if (_currentExerciseIndex > 0) {
      _currentExerciseIndex--;
      notifyListeners();
    }
  }

  void goToExercise(int index) {
    if (_currentWorkout == null) return;
    if (index >= 0 && index < _currentWorkout!.exerciseLogs.length) {
      _currentExerciseIndex = index;
      notifyListeners();
    }
  }

  // Complete workout
  Future<CompletedWorkout?> completeWorkout({String? notes}) async {
    if (_currentWorkout == null) return null;

    _currentWorkout = _currentWorkout!.copyWith(
      endTime: DateTime.now(),
      notes: notes,
    );

    _status = ActiveWorkoutStatus.completed;

    // Save to storage
    await _storage.saveCompletedWorkout(_currentWorkout!);

    final completedWorkout = _currentWorkout;
    
    notifyListeners();
    
    return completedWorkout;
  }

  // Cancel workout
  void cancelWorkout() {
    _currentWorkout = null;
    _currentExerciseIndex = 0;
    _status = ActiveWorkoutStatus.notStarted;
    _workoutStartTime = null;
    notifyListeners();
  }

  // Reset after completing
  void reset() {
    _currentWorkout = null;
    _currentExerciseIndex = 0;
    _status = ActiveWorkoutStatus.notStarted;
    _workoutStartTime = null;
    notifyListeners();
  }
}
