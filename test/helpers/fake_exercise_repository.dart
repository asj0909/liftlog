import 'dart:async';

import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/exercise/domain/exercise_repository.dart';

/// テスト用の ExerciseRepository。メモリ上で動き、呼び出しを記録する。
class FakeExerciseRepository implements ExerciseRepository {
  FakeExerciseRepository(List<Exercise> exercises)
      : exercises = [...exercises];

  /// 現在の種目（プリセット＋カスタム）
  final List<Exercise> exercises;

  /// 種目 id ごとの使用件数（countUsage で返す）
  final usage = <String, int>{};

  /// 次の書き込み系の呼び出しで投げる例外
  AppException? nextError;

  /// 設定すると、書き込み系の呼び出しがこれの完了まで待つ（保存中の状態を確認する用）
  Completer<void>? gate;

  /// 設定すると、fetchAll がこれの完了まで待つ（読み込み中の表示を確認する用）
  Completer<void>? fetchGate;

  var fetchAllCount = 0;
  final deletedIds = <String>[];

  var _sequence = 0;

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
  Future<List<Exercise>> fetchAll() async {
    fetchAllCount++;
    final fetchGate = this.fetchGate;
    if (fetchGate != null) await fetchGate.future;
    return [...exercises];
  }

  @override
  Future<Exercise> create({
    required String name,
    required ExerciseCategory category,
  }) async {
    await _beforeWrite();
    final created = Exercise(
      id: 'custom-${++_sequence}',
      name: name,
      category: category,
      userId: 'user-1',
    );
    exercises.add(created);
    return created;
  }

  @override
  Future<void> update(Exercise exercise) async {
    await _beforeWrite();
    final i = exercises.indexWhere((e) => e.id == exercise.id);
    exercises[i] = exercise;
  }

  @override
  Future<void> delete(String exerciseId) async {
    await _beforeWrite();
    deletedIds.add(exerciseId);
    exercises.removeWhere((e) => e.id == exerciseId);
  }

  @override
  Future<int> countUsage(String exerciseId) async => usage[exerciseId] ?? 0;
}
