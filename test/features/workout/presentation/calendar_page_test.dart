import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liftlog/core/date/today_provider.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';
import 'package:liftlog/features/workout/domain/workout_summary.dart';
import 'package:liftlog/features/workout/presentation/calendar_page.dart';

import '../../../helpers/fake_workout_repository.dart';

void main() {
  // 今日は 2026-11-20（金）に固定する
  final today = DateTime(2026, 11, 20);

  late FakeWorkoutRepository repo;
  late GoRouter router;

  setUp(() {
    repo = FakeWorkoutRepository()
      ..summaries = [
        WorkoutSummary(
          id: 'w03',
          performedOn: DateTime(2026, 11, 3),
          exerciseNames: const ['ベンチプレス'],
        ),
        WorkoutSummary(
          id: 'w10',
          performedOn: DateTime(2026, 11, 10),
          exerciseNames: const ['スクワット', 'レッグプレス'],
        ),
        // 「今日の記録」を開いただけの日（種目なし）は実施日として扱わない
        WorkoutSummary(id: 'w12', performedOn: DateTime(2026, 11, 12)),
      ];
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(400, 900),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    router = GoRouter(
      initialLocation: '/calendar',
      routes: [
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/workouts/new',
          builder: (context, state) =>
              Scaffold(body: Text('new ${state.uri.queryParameters['date']}')),
        ),
        GoRoute(
          path: '/workouts/:id',
          builder: (context, state) =>
              Scaffold(body: Text('workout ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        // Riverpod の自動リトライを止め、エラー表示を確認できるようにする
        retry: (retryCount, error) => null,
        overrides: [
          workoutRepositoryProvider.overrideWithValue(repo),
          todayProvider.overrideWithValue(today),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('今月を日本語の見出しで表示し、実施日にだけ印を付ける', (tester) async {
    await pumpPage(tester);

    expect(find.text('2026年11月'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-marker-2026-11-03')), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-marker-2026-11-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-marker-2026-11-12')), findsNothing);
  });

  testWidgets('最初は今日を選択し、記録がなければ作成ボタンでその日の記録を開く', (tester) async {
    await pumpPage(tester);

    expect(find.text('11月20日（金）'), findsOneWidget);
    expect(find.text('この日の記録はありません'), findsOneWidget);

    await tester.tap(find.text('この日の記録を作成'));
    await tester.pumpAndSettle();

    expect(find.text('new 2026-11-20'), findsOneWidget);
  });

  testWidgets('実施日を選ぶとその日の種目を表示し、タップで記録画面を開く', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(find.text('11月10日（火）'), findsOneWidget);
    expect(find.text('スクワット、レッグプレス'), findsOneWidget);
    expect(find.text('この日の記録はありません'), findsNothing);

    await tester.tap(find.text('スクワット、レッグプレス'));
    await tester.pumpAndSettle();

    expect(find.text('workout w10'), findsOneWidget);
  });

  testWidgets('未来の日は選べない', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();

    expect(find.text('11月20日（金）'), findsOneWidget);
  });

  testWidgets('前の月に移動できる', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('2026年10月'), findsOneWidget);
  });

  testWidgets('広い画面ではカレンダーの右にその日の記録を並べる', (tester) async {
    await pumpPage(tester, size: const Size(1200, 900));

    final calendarRight = tester.getTopRight(find.text('2026年11月')).dx;
    final panelLeft = tester.getTopLeft(find.text('11月20日（金）')).dx;
    expect(panelLeft, greaterThan(calendarRight));
  });

  testWidgets('読み込みに失敗したら再試行できる', (tester) async {
    repo.nextSummariesError = const NetworkException();
    await pumpPage(tester);

    expect(find.text('再試行'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(find.text('2026年11月'), findsOneWidget);
  });
}
