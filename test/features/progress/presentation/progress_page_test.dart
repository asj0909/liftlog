import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liftlog/core/date/today_provider.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/exercise/application/exercise_providers.dart';
import 'package:liftlog/features/progress/application/progress_providers.dart';
import 'package:liftlog/features/progress/domain/progress_point.dart';
import 'package:liftlog/features/progress/presentation/progress_chart.dart';
import 'package:liftlog/features/progress/presentation/progress_page.dart';

import '../../../helpers/fake_exercise_repository.dart';
import '../../../helpers/fake_progress_repository.dart';
import '../../../helpers/test_data.dart';

ProgressPoint _point(DateTime date, double weight) => ProgressPoint(
      performedOn: date,
      maxWeight: weight,
      estimatedOneRepMax: weight * 1.2,
      totalVolume: weight * 30,
    );

void main() {
  late FakeProgressRepository repo;
  late GoRouter router;

  setUp(() {
    repo = FakeProgressRepository()
      ..pointsByExercise = {
        bench.id: [
          _point(DateTime(2026, 10, 1), 60),
          _point(DateTime(2026, 10, 15), 62.5),
          _point(DateTime(2026, 10, 29), 65),
        ],
        latPulldown.id: [_point(DateTime(2026, 10, 20), 50)],
      };
  });

  String location() =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpPage(
    WidgetTester tester, {
    required String initialLocation,
    Size size = const Size(400, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/progress',
          builder: (context, state) => ProgressPage(
            exerciseId: state.uri.queryParameters['exercise'],
            range: state.uri.queryParameters['range'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        // Riverpod の自動リトライを止め、エラー表示を確認できるようにする
        retry: (retryCount, error) => null,
        overrides: [
          progressRepositoryProvider.overrideWithValue(repo),
          exerciseRepositoryProvider.overrideWithValue(
            FakeExerciseRepository(const [bench, latPulldown]),
          ),
          todayProvider.overrideWithValue(DateTime(2026, 11, 1)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('種目が未選択なら選択を促す', (tester) async {
    await pumpPage(tester, initialLocation: '/progress');

    expect(find.text('種目を選択してください'), findsOneWidget);
    expect(repo.fetchCount, 0);
  });

  testWidgets('種目を選ぶと URL に種目と期間が入る', (tester) async {
    await pumpPage(tester, initialLocation: '/progress');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ベンチプレス').last);
    await tester.pumpAndSettle();

    expect(location(), '/progress?exercise=e-bench&range=3m');
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('期間を切り替えると URL と取得期間が変わる', (tester) async {
    await pumpPage(tester, initialLocation: '/progress?exercise=e-bench');
    expect(repo.lastFrom, DateTime(2026, 8, 1));

    await tester.tap(find.text('1年'));
    await tester.pumpAndSettle();

    expect(location(), '/progress?exercise=e-bench&range=1y');
    expect(repo.lastFrom, DateTime(2025, 11, 1));
  });

  testWidgets('コンパクト時は指標を切り替えて 1 つずつ表示する', (tester) async {
    await pumpPage(tester, initialLocation: '/progress?exercise=e-bench');

    ProgressMetric shownMetric() =>
        tester.widget<ProgressChartCard>(find.byType(ProgressChartCard)).metric;

    expect(find.byType(LineChart), findsOneWidget);
    expect(shownMetric(), ProgressMetric.maxWeight);

    await tester.tap(find.text('推定 1RM'));
    await tester.pumpAndSettle();
    expect(shownMetric(), ProgressMetric.estimatedOneRepMax);

    await tester.tap(find.text('総ボリューム'));
    await tester.pumpAndSettle();
    expect(shownMetric(), ProgressMetric.totalVolume);
  });

  testWidgets('ミディアム時は指標の切り替えを出さず、グラフを縦に並べる', (tester) async {
    await pumpPage(
      tester,
      initialLocation: '/progress?exercise=e-bench',
      size: const Size(800, 1200),
    );

    expect(find.byType(SegmentedButton<ProgressMetric>), findsNothing);
    expect(find.byType(LineChart), findsNWidgets(3));
    expect(
      tester.getTopLeft(find.text('最大重量')).dy,
      lessThan(tester.getTopLeft(find.text('推定 1RM')).dy),
    );
  });

  testWidgets('エキスパンデッド時は 3 指標を 2 列で表示する', (tester) async {
    await pumpPage(
      tester,
      initialLocation: '/progress?exercise=e-bench',
      size: const Size(1200, 900),
    );

    expect(find.byType(SegmentedButton<ProgressMetric>), findsNothing);
    expect(find.byType(LineChart), findsNWidgets(3));
    // 1 行目に最大重量と推定 1RM が横に並ぶ
    expect(
      tester.getTopLeft(find.text('最大重量')).dy,
      tester.getTopLeft(find.text('推定 1RM')).dy,
    );
    expect(
      tester.getTopLeft(find.text('総ボリューム')).dy,
      greaterThan(tester.getTopLeft(find.text('最大重量')).dy),
    );
  });

  testWidgets('記録が 2 回未満なら案内を表示する', (tester) async {
    await pumpPage(tester, initialLocation: '/progress?exercise=e-lat');

    expect(find.text('記録が 2 回以上になるとグラフが表示されます'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('一覧にない種目 id が URL に来ても選択なしで表示する', (tester) async {
    await pumpPage(tester, initialLocation: '/progress?exercise=deleted');

    expect(tester.takeException(), isNull);
    expect(find.text('記録が 2 回以上になるとグラフが表示されます'), findsOneWidget);
  });

  testWidgets('読み込みに失敗したら再試行できる', (tester) async {
    repo.nextError = const NetworkException();
    await pumpPage(tester, initialLocation: '/progress?exercise=e-bench');

    expect(find.text('再試行'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
  });

  group('formatMetricValue', () {
    test('重量は小数を必要な分だけ出す', () {
      expect(formatMetricValue(ProgressMetric.maxWeight, 60), '60kg');
      expect(formatMetricValue(ProgressMetric.maxWeight, 62.5), '62.5kg');
      expect(
        formatMetricValue(ProgressMetric.estimatedOneRepMax, 93.33),
        '93.33kg',
      );
    });

    test('総ボリュームは 3 桁区切り', () {
      expect(formatMetricValue(ProgressMetric.totalVolume, 12500), '12,500kg');
      expect(formatMetricValue(ProgressMetric.totalVolume, 1237.5), '1,237.5kg');
    });
  });
}
