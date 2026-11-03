import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/exercise/application/exercise_manage_controller.dart';
import 'package:liftlog/features/exercise/application/exercise_providers.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';

import '../../../helpers/fake_exercise_repository.dart';
import '../../../helpers/fake_workout_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  late FakeExerciseRepository repo;
  late FakeWorkoutRepository workoutRepo;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<List<Exercise>>> manageSubscription;

  setUp(() async {
    repo = FakeExerciseRepository(const [bench, cableFly]);
    workoutRepo = FakeWorkoutRepository();
    container = ProviderContainer(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(repo),
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
      ],
    );
    addTearDown(container.dispose);

    // autoDispose のため、テスト中は購読して状態を保持する
    manageSubscription = container.listen(
      exerciseManageControllerProvider,
      (previous, next) {},
    );
    container.listen(workoutHistoryProvider, (previous, next) {});
    await container.read(exerciseManageControllerProvider.future);
    await container.read(workoutHistoryProvider.future);
  });

  ExerciseManageController controller() =>
      container.read(exerciseManageControllerProvider.notifier);

  Future<List<Exercise>> current() =>
      container.read(exerciseManageControllerProvider.future);

  test('追加すると一覧を読み直す（種目選択の一覧にも反映される）', () async {
    await controller().add(name: 'ペックデック', category: ExerciseCategory.chest);

    expect((await current()).map((e) => e.name), contains('ペックデック'));
    expect(
      (await container.read(exercisesProvider.future)).map((e) => e.name),
      contains('ペックデック'),
    );
  });

  test('編集すると一覧と履歴を読み直す', () async {
    await controller().edit(cableFly.copyWith(name: 'ケーブルクロスオーバー'));
    await container.read(workoutHistoryProvider.future);

    expect(
      (await current()).map((e) => e.name),
      containsAll(['ベンチプレス', 'ケーブルクロスオーバー']),
    );
    expect(workoutRepo.fetchSummariesCount, 2);
  });

  test('削除すると一覧と履歴を読み直す', () async {
    await controller().remove(cableFly.id);
    await container.read(workoutHistoryProvider.future);

    expect(repo.deletedIds, [cableFly.id]);
    expect(await current(), [bench]);
    expect(workoutRepo.fetchSummariesCount, 2);
  });

  test('保存に失敗したら例外を投げ、一覧は読み直さない', () async {
    final before = repo.fetchAllCount;
    repo.nextError = const NetworkException();

    await expectLater(
      controller().add(name: 'ペックデック', category: ExerciseCategory.chest),
      throwsA(isA<NetworkException>()),
    );
    expect(repo.fetchAllCount, before);
    expect(await current(), [bench, cableFly]);
  });

  test('usageCount は使用件数を返す', () async {
    repo.usage[cableFly.id] = 3;
    expect(await controller().usageCount(cableFly.id), 3);
    expect(await controller().usageCount('unused'), 0);
  });

  test('保存中に画面を閉じても、保存後に種目一覧と履歴を読み直す', () async {
    // 種目選択（S-05）など、ほかの画面が種目一覧を購読している状態
    container.listen(exercisesProvider, (previous, next) {});
    final fetchBefore = repo.fetchAllCount;
    final gate = repo.gate = Completer<void>();

    final removing = controller().remove(cableFly.id);
    // 保存中に種目管理画面を閉じる（購読がなくなる）
    manageSubscription.close();
    await Future<void>.delayed(Duration.zero);

    gate.complete();
    await removing;
    await container.read(exercisesProvider.future);
    await container.read(workoutHistoryProvider.future);

    expect(repo.fetchAllCount, greaterThan(fetchBefore));
    expect(
      (await container.read(exercisesProvider.future)).map((e) => e.id),
      isNot(contains(cableFly.id)),
    );
    expect(workoutRepo.fetchSummariesCount, 2);
  });
}
