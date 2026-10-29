import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';
import 'package:liftlog/features/workout/domain/workout.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';
import 'package:liftlog/features/workout/presentation/workout_page.dart';

import '../../../helpers/fake_workout_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  late FakeWorkoutRepository repo;

  setUp(() {
    repo = FakeWorkoutRepository()
      ..details['w1'] = WorkoutDetail(
        id: 'w1',
        performedOn: DateTime(2026, 10, 29),
        entries: const [
          WorkoutEntry(
            id: 'we1',
            exercise: bench,
            sortOrder: 0,
            sets: [WorkoutSet(id: 's1', sortOrder: 0, weightKg: 60, reps: 10)],
          ),
        ],
      );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: WorkoutPage(workoutId: 'w1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('日付・種目・前回記録・セットを表示する', (tester) async {
    await pumpPage(tester);

    expect(find.text('10月29日（木）'), findsOneWidget);
    expect(find.text('ベンチプレス'), findsOneWidget);
    expect(find.text('前回の記録はありません'), findsOneWidget);
    expect(find.text('60kg'), findsOneWidget);
    expect(find.text('10回'), findsOneWidget);
  });

  testWidgets('「セットを追加」1 タップで直前のセットと同じ内容が増える', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('add_set_we1')));
    await tester.pumpAndSettle();

    expect(find.text('60kg'), findsNWidgets(2));
    expect(find.text('10回'), findsNWidgets(2));
    expect(repo.addedSets, hasLength(1));
  });

  testWidgets('＋ をタップすると 2.5kg 増えて保存される', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('重量を増やす'));
    await tester.pumpAndSettle();

    expect(find.text('62.5kg'), findsOneWidget);
    expect(repo.updatedSets.single.weightKg, 62.5);
  });

  testWidgets('前回記録があれば表示する', (tester) async {
    repo.previousRecord = PreviousRecord(
      performedOn: DateTime(2026, 10, 22),
      sets: const [WorkoutSet(weightKg: 57.5, reps: 10)],
    );
    await pumpPage(tester);

    expect(find.text('前回（10/22）：57.5kg×10'), findsOneWidget);
  });
}
