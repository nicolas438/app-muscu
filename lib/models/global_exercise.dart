class GlobalExercise {
  final String id;
  String name;
  String? notes;
  String? category; // e.g., "Pecs", "Dos", "Jambes", etc.
  DateTime createdAt;

  GlobalExercise({
    required this.id,
    required this.name,
    this.notes,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GlobalExercise copyWith({
    String? id,
    String? name,
    String? notes,
    String? category,
    DateTime? createdAt,
  }) {
    return GlobalExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GlobalExercise.fromJson(Map<String, dynamic> json) {
    return GlobalExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
