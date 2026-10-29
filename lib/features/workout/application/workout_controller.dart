import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../exercise/domain/exercise.dart';
import '../domain/set_defaults.dart';
import '../domain/set_input_validator.dart';
import '../domain/workout.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_set.dart';
import 'workout_providers.dart';

/// S-04 ワークアウト記録画面の状態。引数はワークアウトの id。
final workoutControllerProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutController, WorkoutDetail, String>(WorkoutController.new);

/// ワークアウト 1 件分の表示と編集。
///
/// セットの追加・変更・削除は楽観的更新（基本設計書 7.2）：
/// 先に画面へ反映し、保存に失敗したら元に戻して AppException を投げる。
class WorkoutController extends AsyncNotifier<WorkoutDetail> {
  WorkoutController(this.workoutId);

  final String workoutId;

  WorkoutRepository get _repository => ref.read(workoutRepositoryProvider);

  /// 現在の表示内容（読み込み完了後にだけ操作される前提）
  WorkoutDetail get _current => state.requireValue;

  @override
  Future<WorkoutDetail> build() =>
      ref.watch(workoutRepositoryProvider).fetchDetail(workoutId);

  /// 種目を追加する（S-05 で選んだ種目）
  Future<void> addExercise(Exercise exercise) async {
    final entry = await _repository.addEntry(
      workoutId: workoutId,
      exercise: exercise,
      sortOrder: _current.nextEntrySortOrder,
    );
    if (!ref.mounted) return;
    state = AsyncData(_current.addEntry(entry));
  }

  /// セットを 1 つ追加する。初期値は直前のセット、なければ前回記録から。
  Future<void> addSet(
    String entryId, {
    List<WorkoutSet> previous = const [],
  }) async {
    final entry = _current.entry(entryId);
    final draft = SetDefaults.next(current: entry.sets, previous: previous)
        .copyWith(sortOrder: entry.nextSetSortOrder);

    _updateSets(entryId, (sets) => [...sets, draft]);
    try {
      final saved = await _repository.addSet(
        entryId: entryId,
        workoutSet: draft,
      );
      if (!ref.mounted) return;
      _updateSets(
        entryId,
        (sets) => [for (final s in sets) identical(s, draft) ? saved : s],
      );
    } on AppException {
      if (ref.mounted) {
        _updateSets(
          entryId,
          (sets) => [for (final s in sets) if (!identical(s, draft)) s],
        );
      }
      rethrow;
    }
  }

  /// 重量・回数を変更する
  Future<void> updateSet(String entryId, WorkoutSet updated) async {
    final id = updated.id;
    if (id == null) return; // 保存前のセットは変更させない

    final error = SetInputValidator.weight(updated.weightKg) ??
        SetInputValidator.reps(updated.reps);
    if (error != null) throw ValidationException(error);

    final old = _current.entry(entryId).sets.firstWhere((s) => s.id == id);
    _replaceSet(entryId, updated);
    try {
      await _repository.updateSet(updated);
    } on AppException {
      if (ref.mounted) _replaceSet(entryId, old);
      rethrow;
    }
  }

  /// セットを削除する
  Future<void> deleteSet(String entryId, String setId) async {
    final before = _current.entry(entryId).sets;
    _updateSets(entryId, (sets) => [for (final s in sets) if (s.id != setId) s]);
    try {
      await _repository.deleteSet(setId);
    } on AppException {
      if (ref.mounted) _updateSets(entryId, (_) => before);
      rethrow;
    }
  }

  void _replaceSet(String entryId, WorkoutSet set) => _updateSets(
        entryId,
        (sets) => [for (final s in sets) s.id == set.id ? set : s],
      );

  void _updateSets(
    String entryId,
    List<WorkoutSet> Function(List<WorkoutSet> sets) change,
  ) {
    final detail = _current;
    final entry = detail.entry(entryId);
    state = AsyncData(
      detail.replaceEntry(entry.copyWith(sets: change(entry.sets))),
    );
  }
}
