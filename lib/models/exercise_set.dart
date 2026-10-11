/// Une série : charge et répétitions.
///
/// Pour un exercice unilatéral (un côté à la fois), la charge est commune
/// aux deux côtés et les répétitions sont comptées séparément :
/// [reps] pour le côté gauche, [repsRight] pour le côté droit.
class ExerciseSet {
  final String id;
  double weight;

  /// Répétitions (côté gauche pour un exercice unilatéral).
  int reps;

  /// Répétitions du côté droit, ou `null` pour un exercice bilatéral.
  int? repsRight;

  int setNumber;
  bool isCompleted;
  String? notes;

  ExerciseSet({
    required this.id,
    required this.weight,
    required this.reps,
    required this.setNumber,
    this.repsRight,
    this.isCompleted = false,
    this.notes,
  });

  ExerciseSet copyWith({
    String? id,
    double? weight,
    int? reps,
    int? repsRight,
    int? setNumber,
    bool? isCompleted,
    String? notes,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      repsRight: repsRight ?? this.repsRight,
      setNumber: setNumber ?? this.setNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }

  /// Vrai si la série a été réalisée un côté à la fois.
  bool get isUnilateral => repsRight != null;

  /// Total des répétitions, les deux côtés cumulés pour un exercice unilatéral.
  int get totalReps => reps + (repsRight ?? 0);

  /// Répétitions retenues pour mesurer la force : celles du côté le plus
  /// faible pour un exercice unilatéral, afin de ne pas surestimer le 1RM.
  int get effectiveReps {
    final right = repsRight;
    if (right == null) return reps;
    return reps < right ? reps : right;
  }

  /// Volume de travail : charge × répétitions (des deux côtés).
  double get volume => weight * totalReps;

  /// Répétitions à afficher : « 10 », ou « 10 / 9 » (gauche / droite).
  String get repsLabel => isUnilateral ? '$reps / $repsRight' : '$reps';

  /// 1RM estimé (charge maximale théorique sur une répétition), formule d'Epley.
  ///
  /// Permet de comparer des séries de charges et de répétitions différentes :
  /// 80 kg × 10 (≈ 106,7 kg) est plus performant que 85 kg × 5 (≈ 99,2 kg).
  double get estimatedOneRepMax => estimateOneRepMax(weight, effectiveReps);

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
      if (repsRight != null) 'repsRight': repsRight,
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
      repsRight: json['repsRight'] as int?,
      setNumber: json['setNumber'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}
