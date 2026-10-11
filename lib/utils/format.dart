/// Fonctions de mise en forme partagées par les écrans (format français).
library;

/// Charge sans unité, avec une décimale seulement si nécessaire :
/// `80` → « 80 », `82.5` → « 82,5 », `106.66` → « 106,7 ».
String formatWeight(double kg) {
  final rounded = (kg * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
  return rounded.toStringAsFixed(1).replaceAll('.', ',');
}

/// Charge avec son unité : « 82,5 kg ».
String formatKg(double kg) => '${formatWeight(kg)} kg';

/// Volume (charge × répétitions) lisible, en tonnes au-delà de 10 000 kg.
String formatVolume(double kg) {
  if (kg >= 10000) return '${formatWeight(kg / 1000)} t';
  return '${kg.round()} kg';
}

/// Durée de séance : « 52 min », « 1 h 05 ».
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h ${minutes.toString().padLeft(2, '0')}';
}

/// Chronomètre : « 05:32 », « 1:05:32 ».
String formatClock(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours == 0) return '$minutes:$seconds';
  return '$hours:$minutes:$seconds';
}

/// Accorde un nom avec un nombre : `plural(1, 'séance')` → « 1 séance »,
/// `plural(3, 'séance')` → « 3 séances ».
String plural(int count, String singular, [String? pluralForm]) {
  final word = count > 1 ? (pluralForm ?? '${singular}s') : singular;
  return '$count $word';
}

/// Met la première lettre en majuscule (les dates françaises de `intl`
/// sont en minuscules : « lundi 13 janvier »).
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
