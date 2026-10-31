import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/workout/application/workout_controller.dart';
import 'package:liftlog/features/workout/application/workout_providers.dart';
import 'package:liftlog/features/workout/domain/workout.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';

import '../../../helpers/fake_workout_repository.dart';
import '../../../helpers/test_data.dart';

void main() {
  const workoutId = 'w1';
  const firstSet = WorkoutSet(id: 's1', sortOrder: 0, weightKg: 60, reps: 10);

  late FakeWorkoutRepository repo;
  late ProviderContainer container;

  setUp(() async {
    repo = FakeWorkoutRepository()
      ..details[workoutId] = WorkoutDetail(
        id: workoutId,
        performedOn: DateTime(2026, 10, 29),
        entries: const [
          WorkoutEntry(id: 'we1', exercise: bench, sortOrder: 0, sets: [firstSet]),
        ],
      );
    container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // autoDispose のため、テスト中は購読して状態を保持する
    container.listen(workoutControllerProvider(workoutId), (previous, next) {});
    await container.read(workoutControllerProvider(workoutId).future);
  });

  WorkoutController controller() =>
      container.read(workoutControllerProvider(workoutId).notifier);

  List<WorkoutSet> setsOf(String entryId) => container
      .read(workoutControllerProvider(workoutId))
      .requireValue
      .entry(entryId)
      .sets;

  test('build でワークアウトの詳細を読み込む', () {
    expect(setsOf('we1'), [firstSet]);
  });

  group('addSet', () {
    test('直前のセットの重量・回数をコピーして保存する', () async {
      await controller().addSet('we1');

      final sets = setsOf('we1');
      expect(sets, hasLength(2));
      expect(sets.last.weightKg, 60);
      expect(sets.last.reps, 10);
      expect(sets.last.sortOrder, 1);
      expect(sets.last.isSaved, isTrue);
      expect(repo.addedSets.single.sortOrder, 1);
    });

    test('今回のセットがなければ前回記録の 1 セット目を初期値にする', () async {
      await controller().addExercise(latPulldown);
      final entry = container
          .read(workoutControllerProvider(workoutId))
          .requireValue
          .entries
          .last;
      expect(entry.exercise, latPulldown);
      expect(entry.sortOrder, 1);

      await controller().addSet(
        entry.id,
        previous: const [WorkoutSet(weightKg: 40, reps: 12)],
      );

      final added = setsOf(entry.id).single;
      expect(added.weightKg, 40);
      expect(added.reps, 12);
    });

    test('保存中は未保存のセットとして表示し、保存後に id が付く', () async {
      final gate = Completer<void>();
      repo.gate = gate;

      final saving = controller().addSet('we1');
      expect(setsOf('we1').last.isSaved, isFalse);

      gate.complete();
      await saving;
      expect(setsOf('we1').last.isSaved, isTrue);
    });

    test('保存に失敗したら追加を取り消して例外を投げる', () async {
      repo.nextError = const NetworkException();

      await expectLater(
        controller().addSet('we1'),
        throwsA(isA<NetworkException>()),
      );
      expect(setsOf('we1'), [firstSet]);
    });
  });

  group('updateSet', () {
    test('重量を変更して保存する', () async {
      await controller().updateSet('we1', firstSet.copyWith(weightKg: 62.5));

      expect(setsOf('we1').single.weightKg, 62.5);
      expect(repo.updatedSets.single.weightKg, 62.5);
    });

    test('不正な値は保存せず ValidationException', () async {
      await expectLater(
        controller().updateSet('we1', firstSet.copyWith(reps: 0)),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.updatedSets, isEmpty);
      expect(setsOf('we1'), [firstSet]);
    });

    test('保存に失敗したら元の値に戻す', () async {
      repo.nextError = const NetworkException();

      await expectLater(
        controller().updateSet('we1', firstSet.copyWith(weightKg: 100)),
        throwsA(isA<NetworkException>()),
      );
      expect(setsOf('we1'), [firstSet]);
    });
  });

  group('deleteSet', () {
    test('セットを削除する', () async {
      await controller().deleteSet('we1', 's1');

      expect(setsOf('we1'), isEmpty);
      expect(repo.deletedSetIds, ['s1']);
    });

    test('削除に失敗したら元に戻す', () async {
      repo.nextError = const NetworkException();

      await expectLater(
        controller().deleteSet('we1', 's1'),
        throwsA(isA<NetworkException>()),
      );
      expect(setsOf('we1'), [firstSet]);
    });
  });

  group('履歴一覧の再読み込み', () {
    setUp(() async {
      container.listen(workoutHistoryProvider, (previous, next) {});
      await container.read(workoutHistoryProvider.future);
    });

    Future<void> settleHistory() =>
        container.read(workoutHistoryProvider.future);

    test('種目・セットの保存に成功するたびに読み直す', () async {
      expect(repo.fetchSummariesCount, 1);

      await controller().addExercise(latPulldown);
      await settleHistory();
      expect(repo.fetchSummariesCount, 2);

      await controller().addSet('we1');
      await settleHistory();
      expect(repo.fetchSummariesCount, 3);

      await controller().updateSet('we1', firstSet.copyWith(reps: 8));
      await settleHistory();
      expect(repo.fetchSummariesCount, 4);

      await controller().deleteSet('we1', 's1');
      await settleHistory();
      expect(repo.fetchSummariesCount, 5);
    });

    test('保存に失敗したときは読み直さない', () async {
      repo.nextError = const NetworkException();

      await expectLater(
        controller().addSet('we1'),
        throwsA(isA<NetworkException>()),
      );
      await settleHistory();
      expect(repo.fetchSummariesCount, 1);
    });
  });
}
