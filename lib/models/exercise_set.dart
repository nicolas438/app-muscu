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

  /// 1RM estimé (charge maximale théorique sur une répétition), formule d'Epley.
  ///
  /// Permet de comparer des séries de charges et de répétitions différentes :
  /// 80 kg × 10 (≈ 106,7 kg) est plus performant que 85 kg × 5 (≈ 99,2 kg).
  double get estimatedOneRepMax => estimateOneRepMax(weight, reps);

  /// Formule d'Epley : charge × (1 + reps / 30). Une série d'une seule
  /// répétition vaut exactement sa charge.
  static double estimateOneRepMax(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

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
