/// Temps de repos en cours entre deux séries.
///
/// Le minuteur est défini par son heure de fin et non par un compte à rebours :
/// il reste juste même si l'application passe en arrière-plan ou est fermée.
class ActiveRest {
  /// Heure à laquelle le repos se termine.
  final DateTime endsAt;

  /// Durée totale prévue, en secondes (pour la barre de progression).
  final int totalSeconds;

  /// Exercice dont la série vient d'être validée.
  final String exerciseName;

  const ActiveRest({
    required this.endsAt,
    required this.totalSeconds,
    required this.exerciseName,
  });

  /// Temps restant à [now] (jamais négatif).
  Duration remainingAt(DateTime now) {
    final remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Vrai tant que le repos n'est pas terminé.
  bool isRunningAt(DateTime now) => endsAt.isAfter(now);

  ActiveRest copyWith({DateTime? endsAt, int? totalSeconds}) {
    return ActiveRest(
      endsAt: endsAt ?? this.endsAt,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      exerciseName: exerciseName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endsAt': endsAt.toIso8601String(),
      'totalSeconds': totalSeconds,
      'exerciseName': exerciseName,
    };
  }

  factory ActiveRest.fromJson(Map<String, dynamic> json) {
    return ActiveRest(
      endsAt: DateTime.parse(json['endsAt'] as String),
      totalSeconds: json['totalSeconds'] as int,
      exerciseName: json['exerciseName'] as String,
    );
  }
}
