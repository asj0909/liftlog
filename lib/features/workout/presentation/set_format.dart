import '../domain/workout_set.dart';

/// 重量の表示：60.0 → "60"、62.5 → "62.5"、1.25 → "1.25"
String formatWeightKg(double weightKg) {
  if (weightKg == weightKg.roundToDouble()) return weightKg.toInt().toString();
  return weightKg
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// セット 1 つの表示：60kg×10
String formatSet(WorkoutSet set) => '${formatWeightKg(set.weightKg)}kg×${set.reps}';
