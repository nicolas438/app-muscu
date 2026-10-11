import 'exercise.dart';
import 'exercise_set.dart';

class ExerciseLog {
  final String id;
  final String exerciseId;
  final String exerciseName;
  List<ExerciseSet> sets;
  String? notes;
  final bool isOffSession; // Exercice hors séance

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    List<ExerciseSet>? sets,
    this.notes,
    this.isOffSession = false,
  }) : sets = sets ?? [];

  factory ExerciseLog.fromExercise(String id, Exercise exercise) {
    return ExerciseLog(
      id: id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: [],
      notes: exercise.notes,
    );
  }

  double get totalVolume => sets.fold(0, (sum, set) => sum + set.volume);

  double get maxWeight => sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  ExerciseLog copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    List<ExerciseSet>? sets,
    String? notes,
    bool? isOffSession,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? List.from(this.sets),
      notes: notes ?? this.notes,
      isOffSession: isOffSession ?? this.isOffSession,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'isOffSession': isOffSession,
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      isOffSession: json['isOffSession'] as bool? ?? false,
    );
  }
}
