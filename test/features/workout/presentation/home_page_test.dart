import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';
import 'package:liftlog/features/workout/domain/workout_summary.dart';
import 'package:liftlog/features/workout/presentation/home_page.dart';

import '../../../helpers/fake_workout_repository.dart';

void main() {
  late FakeWorkoutRepository repo;
  late GoRouter router;

  setUp(() {
    repo = FakeWorkoutRepository()
      ..summaries = [
        WorkoutSummary(
          id: 'w29',
          performedOn: DateTime(2026, 10, 29),
          exerciseNames: const ['ベンチプレス'],
        ),
        WorkoutSummary(id: 'w30', performedOn: DateTime(2026, 10, 30)),
        WorkoutSummary(
          id: 'w31',
          performedOn: DateTime(2026, 10, 31),
          exerciseNames: const ['ラットプルダウン', 'ケーブルフライ'],
        ),
      ];
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) =>
              Scaffold(body: Text('workout ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod の自動リトライを止め、エラー表示を確認できるようにする
        retry: (retryCount, error) => null,
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('新しい順に日付と種目名を表示し、種目のない日は出さない', (tester) async {
    await pumpPage(tester);

    final oct31 = find.text('10月31日（土）');
    final oct29 = find.text('10月29日（木）');
    expect(oct31, findsOneWidget);
    expect(oct29, findsOneWidget);
    expect(find.text('10月30日（金）'), findsNothing);
    expect(find.text('ラットプルダウン、ケーブルフライ'), findsOneWidget);
    expect(find.text('ベンチプレス'), findsOneWidget);
    expect(
      tester.getTopLeft(oct31).dy,
      lessThan(tester.getTopLeft(oct29).dy),
    );
  });

  testWidgets('記録が 0 件なら「まだ記録がありません」と表示する', (tester) async {
    repo.summaries = [
      WorkoutSummary(id: 'w30', performedOn: DateTime(2026, 10, 30)),
    ];
    await pumpPage(tester);

    expect(find.text('まだ記録がありません'), findsOneWidget);
  });

  testWidgets('読み込みに失敗したら再試行できる', (tester) async {
    repo.nextSummariesError = const NetworkException();
    await pumpPage(tester);

    expect(find.text('再試行'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(find.text('10月31日（土）'), findsOneWidget);
  });

  testWidgets('行をタップすると /workouts/{id} を開く', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('10月31日（土）'));
    await tester.pumpAndSettle();

    expect(find.text('workout w31'), findsOneWidget);
  });

  testWidgets('一覧が invalidate されると読み直す', (tester) async {
    await pumpPage(tester);
    expect(repo.fetchSummariesCount, 1);

    repo.summaries = [
      ...repo.summaries,
      WorkoutSummary(
        id: 'w01',
        performedOn: DateTime(2026, 11, 1),
        exerciseNames: const ['スクワット'],
      ),
    ];
    ProviderScope.containerOf(tester.element(find.byType(HomePage)))
        .invalidate(workoutHistoryProvider);
    await tester.pumpAndSettle();

    expect(repo.fetchSummariesCount, 2);
    expect(find.text('11月1日（日）'), findsOneWidget);
  });
}
