class SessionExerciseRef {
  final String exerciseId; // Reference to GlobalExercise
  int order;

  SessionExerciseRef({
    required this.exerciseId,
    this.order = 0,
  });

  SessionExerciseRef copyWith({
    String? exerciseId,
    int? order,
  }) {
    return SessionExerciseRef(
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'order': order,
    };
  }

  factory SessionExerciseRef.fromJson(Map<String, dynamic> json) {
    return SessionExerciseRef(
      exerciseId: json['exerciseId'] as String,
      order: json['order'] as int? ?? 0,
    );
  }
}
