class GlobalExercise {
  final String id;
  String name;
  String? notes;
  String? category; // e.g., "Pecs", "Dos", "Jambes", etc.

  /// Exercice réalisé un côté à la fois (curl haltère, fente, rowing à un bras…) :
  /// les répétitions sont saisies séparément pour la gauche et la droite.
  bool isUnilateral;

  DateTime createdAt;

  GlobalExercise({
    required this.id,
    required this.name,
    this.notes,
    this.category,
    this.isUnilateral = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GlobalExercise copyWith({
    String? id,
    String? name,
    String? notes,
    String? category,
    bool? isUnilateral,
    DateTime? createdAt,
  }) {
    return GlobalExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'category': category,
      'isUnilateral': isUnilateral,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GlobalExercise.fromJson(Map<String, dynamic> json) {
    return GlobalExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      isUnilateral: json['isUnilateral'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
