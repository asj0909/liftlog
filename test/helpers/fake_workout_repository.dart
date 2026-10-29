import 'dart:async';

import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/workout/domain/workout.dart';
import 'package:liftlog/features/workout/domain/workout_repository.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';

/// テスト用の WorkoutRepository。メモリ上で動き、呼び出しを記録する。
class FakeWorkoutRepository implements WorkoutRepository {
  /// fetchDetail で返す内容（id → 詳細）
  final details = <String, WorkoutDetail>{};

  /// fetchPreviousRecord で返す内容
  PreviousRecord? previousRecord;

  /// 次の書き込み系の呼び出しで投げる例外
  AppException? nextError;

  /// 設定すると、書き込み系の呼び出しがこれの完了まで待つ（保存中の状態を確認する用）
  Completer<void>? gate;

  final addedSets = <WorkoutSet>[];
  final updatedSets = <WorkoutSet>[];
  final deletedSetIds = <String>[];

  var _sequence = 0;
  String _newId(String prefix) => '$prefix-${++_sequence}';

  Future<void> _beforeWrite() async {
    final gate = this.gate;
    if (gate != null) await gate.future;
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<String> findOrCreateByDate(DateTime date) async {
    await _beforeWrite();
    for (final detail in details.values) {
      if (detail.performedOn == date) return detail.id;
    }
    final id = _newId('w');
    details[id] = WorkoutDetail(id: id, performedOn: date);
    return id;
  }

  @override
  Future<WorkoutDetail> fetchDetail(String workoutId) async {
    final detail = details[workoutId];
    if (detail == null) throw const UnknownException();
    return detail;
  }

  @override
  Future<WorkoutEntry> addEntry({
    required String workoutId,
    required Exercise exercise,
    required int sortOrder,
  }) async {
    await _beforeWrite();
    return WorkoutEntry(
      id: _newId('we'),
      exercise: exercise,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<WorkoutSet> addSet({
    required String entryId,
    required WorkoutSet workoutSet,
  }) async {
    await _beforeWrite();
    final saved = workoutSet.copyWith(id: _newId('s'));
    addedSets.add(saved);
    return saved;
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    await _beforeWrite();
    updatedSets.add(set);
  }

  @override
  Future<void> deleteSet(String setId) async {
    await _beforeWrite();
    deletedSetIds.add(setId);
  }

  @override
  Future<PreviousRecord?> fetchPreviousRecord({
    required String exerciseId,
    required DateTime before,
  }) async =>
      previousRecord;
}
