import 'exercise_set.dart';

/// Nature du record battu.
enum PersonalRecordKind {
  /// Charge la plus lourde jamais soulevée sur l'exercice.
  heaviestWeight,

  /// Meilleur 1RM estimé : plus de répétitions à charge égale, par exemple.
  estimatedOneRepMax,
}

/// Record personnel établi lors d'une séance.
class PersonalRecord {
  final String exerciseName;
  final PersonalRecordKind kind;

  /// Ancienne meilleure valeur (charge ou 1RM estimé selon [kind]), en kg.
  final double previousValue;

  /// Nouvelle meilleure valeur (charge ou 1RM estimé selon [kind]), en kg.
  final double newValue;

  /// Série ayant permis d'établir le record.
  final ExerciseSet recordSet;

  const PersonalRecord({
    required this.exerciseName,
    required this.kind,
    required this.previousValue,
    required this.newValue,
    required this.recordSet,
  });

  /// Progression par rapport à l'ancien record, en kg.
  double get improvement => newValue - previousValue;
}
