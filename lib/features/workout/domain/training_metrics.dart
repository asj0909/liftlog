import 'workout_set.dart';

/// 推移グラフ（F-06）の指標計算。
///
/// DB 関数 `get_exercise_progress` と同じ定義にしておき、
/// 記録画面での即時表示とテストに使う（基本設計書 5.4）。
abstract final class TrainingMetrics {
  /// Epley 式による推定 1RM：重量 × (1 + 回数 / 30)
  static double estimateOneRepMax({
    required double weightKg,
    required int reps,
  }) {
    if (weightKg <= 0 || reps <= 0) return 0;
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  /// セットの中で最も重い重量。空なら 0。
  static double maxWeight(Iterable<WorkoutSet> sets) =>
      sets.fold<double>(0, (max, s) => s.weightKg > max ? s.weightKg : max);

  /// セットごとの推定 1RM の最大値。空なら 0。
  static double bestEstimatedOneRepMax(Iterable<WorkoutSet> sets) => sets.fold<double>(
        0,
        (best, s) {
          final e1rm = estimateOneRepMax(weightKg: s.weightKg, reps: s.reps);
          return e1rm > best ? e1rm : best;
        },
      );

  /// 総ボリューム（重量 × 回数 の合計）。
  static double totalVolume(Iterable<WorkoutSet> sets) =>
      sets.fold<double>(0, (sum, s) => sum + s.volume);
}
