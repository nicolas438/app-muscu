/// Réglages du minuteur de repos.
class RestSettings {
  /// Durée de repos proposée par défaut, en secondes.
  static const int fallbackSeconds = 90;

  /// Lancer automatiquement le minuteur après chaque série validée.
  final bool autoStart;

  /// Durée de repos par défaut, en secondes.
  final int defaultSeconds;

  /// Durées personnalisées par exercice (clé : nom de l'exercice en minuscules).
  final Map<String, int> secondsByExercise;

  const RestSettings({
    this.autoStart = true,
    this.defaultSeconds = fallbackSeconds,
    this.secondsByExercise = const {},
  });

  /// Durée de repos applicable à [exerciseName].
  int secondsFor(String exerciseName) =>
      secondsByExercise[exerciseName.toLowerCase()] ?? defaultSeconds;

  /// Copie avec la durée de repos de [exerciseName] remplacée par [seconds].
  RestSettings withExerciseSeconds(String exerciseName, int seconds) {
    return copyWith(
      secondsByExercise: {...secondsByExercise, exerciseName.toLowerCase(): seconds},
    );
  }

  RestSettings copyWith({
    bool? autoStart,
    int? defaultSeconds,
    Map<String, int>? secondsByExercise,
  }) {
    return RestSettings(
      autoStart: autoStart ?? this.autoStart,
      defaultSeconds: defaultSeconds ?? this.defaultSeconds,
      secondsByExercise: secondsByExercise ?? this.secondsByExercise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoStart': autoStart,
      'defaultSeconds': defaultSeconds,
      'secondsByExercise': secondsByExercise,
    };
  }

  factory RestSettings.fromJson(Map<String, dynamic> json) {
    final byExercise = (json['secondsByExercise'] as Map<String, dynamic>?) ?? {};
    return RestSettings(
      autoStart: json['autoStart'] as bool? ?? true,
      defaultSeconds: json['defaultSeconds'] as int? ?? fallbackSeconds,
      secondsByExercise: byExercise.map((key, value) => MapEntry(key, (value as num).toInt())),
    );
  }
}
