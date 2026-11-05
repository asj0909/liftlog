import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../exercise/domain/exercise.dart';
import '../../progress/application/progress_providers.dart';
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
/// 保存に成功したら履歴一覧と推移グラフを invalidate し、戻ったときに最新の内容を出す。
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
    _invalidateReadModels();
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
      _invalidateReadModels();
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

  /// セットごとの、サーバーに保存できている最後の値（失敗したときの戻し先）
  final _confirmedSets = <String, WorkoutSet>{};

  /// セットごとの、まだ送っていない最新の値
  final _pendingSets = <String, WorkoutSet>{};

  /// 保存を送信中のセット id
  final _savingSetIds = <String>{};

  /// 重量・回数を変更する。
  ///
  /// ± を続けて押しても画面はすぐに変わる。保存はセットごとに 1 件ずつ順番に送り、
  /// 送信中に変わった分は送信完了後に最新の値だけをまとめて送る（QA M-01、既知の課題 Q-03）。
  /// これで応答の順番が入れ替わって古い値が残ることがない。
  /// 保存に失敗したら、最後に保存できた値に戻して AppException を投げる（送っていない変更は捨てる）。
  /// 送信中に呼ばれた変更は、その場ではすぐに完了し、結果は最初の呼び出しが返す。
  Future<void> updateSet(String entryId, WorkoutSet updated) async {
    final id = updated.id;
    if (id == null) return; // 保存前のセットは変更させない

    final error = SetInputValidator.weight(updated.weightKg) ??
        SetInputValidator.reps(updated.reps);
    if (error != null) throw ValidationException(error);

    _confirmedSets.putIfAbsent(
      id,
      () => _current.entry(entryId).sets.firstWhere((s) => s.id == id),
    );
    _replaceSet(entryId, updated);
    _pendingSets[id] = updated;
    if (!_savingSetIds.add(id)) return; // 送信中：完了後に最新の値を送る

    try {
      while (true) {
        final next = _pendingSets.remove(id);
        if (next == null) break;
        await _repository.updateSet(next);
        _confirmedSets[id] = next;
      }
      if (ref.mounted) _invalidateReadModels();
    } on AppException {
      _pendingSets.remove(id);
      final restore = _confirmedSets[id];
      if (ref.mounted && restore != null) _replaceSet(entryId, restore);
      rethrow;
    } finally {
      _savingSetIds.remove(id);
      _confirmedSets.remove(id);
    }
  }

  /// セットを削除する
  Future<void> deleteSet(String entryId, String setId) async {
    final before = _current.entry(entryId).sets;
    _updateSets(entryId, (sets) => [for (final s in sets) if (s.id != setId) s]);
    try {
      await _repository.deleteSet(setId);
      if (ref.mounted) _invalidateReadModels();
    } on AppException {
      if (ref.mounted) _updateSets(entryId, (_) => before);
      rethrow;
    }
  }

  /// 記録から作られる表示（履歴一覧・推移グラフ）を読み直させる（基本設計書 7.2）
  void _invalidateReadModels() {
    ref
      ..invalidate(workoutHistoryProvider)
      ..invalidate(exerciseProgressProvider);
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
