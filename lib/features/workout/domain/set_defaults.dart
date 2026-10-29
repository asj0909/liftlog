import 'workout_set.dart';

/// 「セットを追加」したときの初期値（基本設計書 6.4：直前セットのコピー）。
abstract final class SetDefaults {
  /// 今回も前回も記録がないときの初期値
  static const initialWeightKg = 0.0;
  static const initialReps = 10;

  /// 優先順位：今回の直前のセット → 前回記録の 1 セット目 → 既定値
  static WorkoutSet next({
    required List<WorkoutSet> current,
    required List<WorkoutSet> previous,
  }) {
    if (current.isNotEmpty) {
      final last = current.last;
      return WorkoutSet(weightKg: last.weightKg, reps: last.reps);
    }
    if (previous.isNotEmpty) {
      final first = previous.first;
      return WorkoutSet(weightKg: first.weightKg, reps: first.reps);
    }
    return const WorkoutSet(weightKg: initialWeightKg, reps: initialReps);
  }
}
