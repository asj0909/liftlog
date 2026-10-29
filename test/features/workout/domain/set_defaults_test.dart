import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/set_defaults.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';

void main() {
  const previous = [
    WorkoutSet(weightKg: 50, reps: 12),
    WorkoutSet(weightKg: 55, reps: 8),
  ];

  test('今回のセットがあれば、直前（最後）のセットをコピーする', () {
    final next = SetDefaults.next(
      current: const [
        WorkoutSet(id: 'a', weightKg: 60, reps: 10),
        WorkoutSet(id: 'b', weightKg: 65, reps: 6),
      ],
      previous: previous,
    );
    expect(next.weightKg, 65);
    expect(next.reps, 6);
    expect(next.id, isNull, reason: '新しいセットなので id は持たない');
  });

  test('今回のセットがなければ、前回記録の 1 セット目を使う', () {
    final next = SetDefaults.next(current: const [], previous: previous);
    expect(next.weightKg, 50);
    expect(next.reps, 12);
  });

  test('どちらもなければ既定値（0kg × 10 回）', () {
    final next = SetDefaults.next(current: const [], previous: const []);
    expect(next.weightKg, SetDefaults.initialWeightKg);
    expect(next.reps, SetDefaults.initialReps);
  });
}
