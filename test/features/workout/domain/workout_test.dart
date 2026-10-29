import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/workout.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('WorkoutEntry.nextSetSortOrder', () {
    test('セットがなければ 0', () {
      const entry = WorkoutEntry(id: 'we1', exercise: bench, sortOrder: 0);
      expect(entry.nextSetSortOrder, 0);
    });

    test('削除で欠番があっても最大値 + 1（重複しない）', () {
      const entry = WorkoutEntry(
        id: 'we1',
        exercise: bench,
        sortOrder: 0,
        sets: [
          WorkoutSet(sortOrder: 1, weightKg: 60, reps: 10),
          WorkoutSet(sortOrder: 2, weightKg: 60, reps: 8),
        ],
      );
      expect(entry.nextSetSortOrder, 3);
    });
  });

  test('内容が同じ WorkoutDetail は等しい（Riverpod の更新判定に使われる）', () {
    WorkoutDetail build() => WorkoutDetail(
          id: 'w1',
          performedOn: DateTime(2026, 10, 29),
          entries: const [
            WorkoutEntry(
              id: 'we1',
              exercise: bench,
              sortOrder: 0,
              sets: [WorkoutSet(id: 's1', weightKg: 60, reps: 10)],
            ),
          ],
        );
    expect(build(), build());
    expect(
      build().replaceEntry(
        const WorkoutEntry(id: 'we1', exercise: bench, sortOrder: 0),
      ),
      isNot(build()),
    );
  });
}
