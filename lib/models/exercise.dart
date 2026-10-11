class Exercise {
  final String id;
  String name;
  String? notes;
  int order;

  Exercise({
    required this.id,
    required this.name,
    this.notes,
    this.order = 0,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? notes,
    int? order,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'order': order,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }
}
