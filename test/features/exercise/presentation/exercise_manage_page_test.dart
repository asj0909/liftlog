import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/exercise/application/exercise_providers.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/exercise/presentation/exercise_manage_page.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';

import '../../../helpers/fake_exercise_repository.dart';
import '../../../helpers/fake_workout_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  late FakeExerciseRepository repo;

  setUp(() {
    repo = FakeExerciseRepository(const [bench, latPulldown, cableFly]);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod の自動リトライを止め、エラー表示を確認できるようにする
        retry: (retryCount, error) => null,
        overrides: [
          exerciseRepositoryProvider.overrideWithValue(repo),
          workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
        ],
        child: const MaterialApp(home: ExerciseManagePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.tap(find.text('種目を追加').last);
    await tester.pumpAndSettle();
  }

  testWidgets('カスタム種目をカテゴリごとに出し、プリセットは折りたたんで出す', (tester) async {
    await pumpPage(tester);

    expect(find.text('胸'), findsOneWidget);
    expect(find.text('ケーブルフライ'), findsOneWidget);
    expect(find.text('プリセット種目（2）'), findsOneWidget);
    // プリセットは展開するまで見えない
    expect(find.text('ベンチプレス'), findsNothing);

    await tester.tap(find.text('プリセット種目（2）'));
    await tester.pumpAndSettle();

    expect(find.text('ベンチプレス'), findsOneWidget);
    expect(find.text('ラットプルダウン'), findsOneWidget);
  });

  testWidgets('カスタム種目がなければ案内を出す', (tester) async {
    repo = FakeExerciseRepository(const [bench]);
    await pumpPage(tester);

    expect(
      find.text('カスタム種目はまだありません。右下の「種目を追加」から登録できます。'),
      findsOneWidget,
    );
  });

  testWidgets('種目を追加できる', (tester) async {
    await pumpPage(tester);
    await openAddDialog(tester);

    await tester.enterText(find.byKey(const Key('exercise_name')), ' ペックデック ');
    await tester.tap(find.byKey(const Key('exercise_category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('腕').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final added = repo.exercises.last;
    expect(added.name, 'ペックデック');
    expect(added.category, ExerciseCategory.arms);
    expect(find.text('ペックデック'), findsOneWidget);
    expect(find.text('腕'), findsOneWidget);
  });

  testWidgets('名前が空・重複なら保存せずにエラーを出す', (tester) async {
    await pumpPage(tester);
    await openAddDialog(tester);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('種目名を入力してください'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('exercise_name')), 'ベンチプレス');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('同じ名前のプリセット種目があります'), findsOneWidget);

    expect(repo.exercises, hasLength(3));
  });

  testWidgets('タップで名前を編集できる', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('ケーブルフライ'));
    await tester.pumpAndSettle();
    expect(find.text('種目を編集'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exercise_name')),
      'ケーブルクロスオーバー',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.exercises.last.name, 'ケーブルクロスオーバー');
    expect(find.text('ケーブルクロスオーバー'), findsOneWidget);
  });

  testWidgets('記録で使われている種目は、記録も消えることを確認してから削除する', (tester) async {
    repo.usage[cableFly.id] = 3;
    await pumpPage(tester);

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();

    expect(find.text('「ケーブルフライ」を削除しますか？'), findsOneWidget);
    expect(find.textContaining('3 件の記録で使われています'), findsOneWidget);

    // キャンセルなら消さない
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(repo.deletedIds, isEmpty);

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, [cableFly.id]);
    expect(find.text('ケーブルフライ'), findsNothing);
  });

  testWidgets('使われていない種目も確認してから削除する', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();

    expect(find.text('この種目は記録で使われていません。'), findsOneWidget);
  });

  testWidgets('保存に失敗したらスナックバーでエラーを出す', (tester) async {
    await pumpPage(tester);
    repo.nextError = const NetworkException();

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();

    expect(find.textContaining('通信に失敗しました'), findsOneWidget);
    expect(find.text('ケーブルフライ'), findsOneWidget);
  });
}
