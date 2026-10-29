import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liftlog/features/exercise/application/exercise_providers.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/workout/presentation/exercise_picker_page.dart';

import '../../../helpers/fake_exercise_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  test('filterExercises は名前の部分一致で絞り込む', () {
    const all = [bench, latPulldown, cableFly];
    expect(filterExercises(all, ''), all);
    expect(filterExercises(all, 'ラット'), [latPulldown]);
    expect(filterExercises(all, 'スクワット'), isEmpty);
  });

  testWidgets('カテゴリ別に表示し、検索して選んだ種目を呼び出し元に返す', (tester) async {
    Exercise? picked;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await context.push<Exercise>('/pick');
              },
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/pick',
          builder: (context, state) => const ExercisePickerPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseRepositoryProvider.overrideWithValue(
            FakeExerciseRepository(const [bench, latPulldown, cableFly]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 部位カテゴリの見出し
    expect(find.text('胸'), findsOneWidget);
    expect(find.text('背中'), findsOneWidget);
    expect(find.text('ベンチプレス'), findsOneWidget);

    // 検索で絞り込む
    await tester.enterText(find.byKey(const Key('exercise_search')), 'ラット');
    await tester.pump();
    expect(find.text('ベンチプレス'), findsNothing);
    expect(find.text('胸'), findsNothing);

    await tester.tap(find.text('ラットプルダウン'));
    await tester.pumpAndSettle();
    expect(picked, latPulldown);
  });
}
