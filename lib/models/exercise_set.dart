class ExerciseSet {
  final String id;
  double weight;
  int reps;
  int setNumber;
  bool isCompleted;
  String? notes;

  ExerciseSet({
    required this.id,
    required this.weight,
    required this.reps,
    required this.setNumber,
    this.isCompleted = false,
    this.notes,
  });

  ExerciseSet copyWith({
    String? id,
    double? weight,
    int? reps,
    int? setNumber,
    bool? isCompleted,
    String? notes,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      setNumber: setNumber ?? this.setNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  double get volume => weight * reps;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'reps': reps,
      'setNumber': setNumber,
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      setNumber: json['setNumber'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}
