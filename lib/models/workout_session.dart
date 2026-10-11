import 'exercise.dart';
import 'session_exercise_ref.dart';

class WorkoutSession {
  final String id;
  String name;
  List<SessionExerciseRef> exerciseRefs; // References to global exercises
  String? notes;
  String? color;

  WorkoutSession({
    required this.id,
    required this.name,
    List<SessionExerciseRef>? exerciseRefs,
    this.notes,
    this.color,
  }) : exerciseRefs = exerciseRefs ?? [];

  // Legacy support: keep exercises property for backwards compatibility
  @Deprecated('Use exerciseRefs instead')
  List<Exercise> get exercises => [];

  WorkoutSession copyWith({
    String? id,
    String? name,
    List<SessionExerciseRef>? exerciseRefs,
    String? notes,
    String? color,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      exerciseRefs: exerciseRefs ?? List.from(this.exerciseRefs),
      notes: notes ?? this.notes,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exerciseRefs': exerciseRefs.map((e) => e.toJson()).toList(),
      'notes': notes,
      'color': color,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    // Migration: support old format with exercises
    if (json['exercises'] != null && json['exerciseRefs'] == null) {
      final exercises = (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Convert old exercises to refs (we'll need to create global exercises for these)
      final exerciseRefs = exercises.asMap().entries.map((entry) {
        return SessionExerciseRef(
          exerciseId: entry.value.id,
          order: entry.key,
        );
      }).toList();

      return WorkoutSession(
        id: json['id'] as String,
        name: json['name'] as String,
        exerciseRefs: exerciseRefs,
        notes: json['notes'] as String?,
        color: json['color'] as String?,
      );
    }

    return WorkoutSession(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseRefs: (json['exerciseRefs'] as List<dynamic>?)
              ?.map((e) => SessionExerciseRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      color: json['color'] as String?,
    );
  }
}
