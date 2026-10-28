import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/training_metrics.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';

void main() {
  group('estimateOneRepMax（Epley 式）', () {
    test('重量 × (1 + 回数 / 30) で計算する', () {
      expect(
        TrainingMetrics.estimateOneRepMax(weightKg: 60, reps: 10),
        closeTo(80, 1e-9),
      );
      expect(
        TrainingMetrics.estimateOneRepMax(weightKg: 100, reps: 5),
        closeTo(116.6667, 1e-4),
      );
    });

    test('1 回のときは重量そのもの', () {
      expect(TrainingMetrics.estimateOneRepMax(weightKg: 120, reps: 1), 120);
    });

    test('重量 0（自重）や回数 0 以下は 0', () {
      expect(TrainingMetrics.estimateOneRepMax(weightKg: 0, reps: 10), 0);
      expect(TrainingMetrics.estimateOneRepMax(weightKg: 60, reps: 0), 0);
    });
  });

  group('セット集計', () {
    const sets = [
      WorkoutSet(weightKg: 60, reps: 10),
      WorkoutSet(weightKg: 70, reps: 6),
      WorkoutSet(weightKg: 50, reps: 15),
    ];

    test('maxWeight は最も重い重量', () {
      expect(TrainingMetrics.maxWeight(sets), 70);
    });

    test('bestEstimatedOneRepMax はセットごとの推定 1RM の最大値', () {
      // 60×10→80, 70×6→84, 50×15→75
      expect(TrainingMetrics.bestEstimatedOneRepMax(sets), closeTo(84, 1e-9));
    });

    test('totalVolume は 重量 × 回数 の合計', () {
      expect(TrainingMetrics.totalVolume(sets), 600 + 420 + 750);
    });

    test('空のときはすべて 0', () {
      expect(TrainingMetrics.maxWeight(const []), 0);
      expect(TrainingMetrics.bestEstimatedOneRepMax(const []), 0);
      expect(TrainingMetrics.totalVolume(const []), 0);
    });
  });
}
