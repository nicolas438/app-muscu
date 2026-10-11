import 'package:appnuno/models/models.dart';
import 'package:appnuno/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseSet _set(double weight, int reps) =>
    ExerciseSet(id: '$weight-$reps', weight: weight, reps: reps, setNumber: 1);

void main() {
  group('1RM estimé (Epley)', () {
    test('une répétition vaut exactement la charge', () {
      expect(ExerciseSet.estimateOneRepMax(100, 1), 100);
    });

    test('plus de répétitions à charge égale donne un meilleur 1RM', () {
      expect(
        ExerciseSet.estimateOneRepMax(80, 10),
        greaterThan(ExerciseSet.estimateOneRepMax(80, 8)),
      );
    });

    test('80 kg × 10 vaut environ 106,7 kg', () {
      expect(ExerciseSet.estimateOneRepMax(80, 10), closeTo(106.67, 0.01));
    });

    test('valeurs nulles ou négatives donnent 0', () {
      expect(ExerciseSet.estimateOneRepMax(0, 10), 0);
      expect(ExerciseSet.estimateOneRepMax(80, 0), 0);
    });
  });

  group('Meilleure série', () {
    test('retient la série au meilleur 1RM, pas la plus lourde ni la dernière', () {
      final log = ExerciseLog(
        id: 'log',
        exerciseId: 'bench',
        exerciseName: 'Développé couché',
        sets: [_set(85, 3), _set(80, 10), _set(60, 12)],
      );
      expect(log.bestSet!.weight, 80);
      expect(log.bestSet!.reps, 10);
    });

    test('aucune série : pas de meilleure série', () {
      final log = ExerciseLog(id: 'log', exerciseId: 'x', exerciseName: 'X');
      expect(log.bestSet, isNull);
      expect(log.bestEstimatedOneRepMax, 0);
    });
  });

  group('Semaines ISO 8601', () {
    test('le 1er janvier 2026 (jeudi) est en semaine 1 de 2026', () {
      final date = DateTime(2026, 1, 1);
      expect(UserStreak.getWeekNumber(date), 1);
      expect(UserStreak.getWeekYear(date), 2026);
    });

    test('le 1er janvier 2027 (vendredi) est en semaine 53 de 2026', () {
      final date = DateTime(2027, 1, 1);
      expect(UserStreak.getWeekNumber(date), 53);
      expect(UserStreak.getWeekYear(date), 2026);
    });

    test('le 30 décembre 2024 (lundi) est en semaine 1 de 2025', () {
      final date = DateTime(2024, 12, 30);
      expect(UserStreak.getWeekNumber(date), 1);
      expect(UserStreak.getWeekYear(date), 2025);
    });

    test('le lundi de la semaine est bien calculé', () {
      expect(UserStreak.getStartOfWeek(DateTime(2026, 10, 11)), DateTime(2026, 10, 5));
      expect(UserStreak.getStartOfWeek(DateTime(2026, 10, 5, 18)), DateTime(2026, 10, 5));
    });

    test('écart en semaines, y compris au passage de l\'année', () {
      expect(UserStreak.weeksBetween(DateTime(2026, 10, 5), DateTime(2026, 10, 11)), 0);
      expect(UserStreak.weeksBetween(DateTime(2026, 10, 4), DateTime(2026, 10, 5)), 1);
      expect(UserStreak.weeksBetween(DateTime(2026, 12, 28), DateTime(2027, 1, 4)), 1);
      expect(UserStreak.weeksBetween(DateTime(2026, 12, 21), DateTime(2027, 1, 4)), 2);
    });

    test('le changement d\'heure ne fausse pas l\'écart', () {
      // Passage à l'heure d'hiver le dimanche 25 octobre 2026.
      expect(UserStreak.weeksBetween(DateTime(2026, 10, 19), DateTime(2026, 10, 26)), 1);
    });
  });

  group('Mise en forme', () {
    test('charges', () {
      expect(formatWeight(80), '80');
      expect(formatWeight(82.5), '82,5');
      expect(formatWeight(106.666), '106,7');
      expect(formatKg(62.5), '62,5 kg');
    });

    test('accords', () {
      expect(plural(1, 'séance'), '1 séance');
      expect(plural(3, 'séance'), '3 séances');
    });

    test('durées', () {
      expect(formatDuration(const Duration(minutes: 52)), '52 min');
      expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1 h 05');
      expect(formatClock(const Duration(minutes: 5, seconds: 32)), '05:32');
    });
  });
}
