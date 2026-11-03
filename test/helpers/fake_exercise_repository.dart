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

  var fetchAllCount = 0;
  final deletedIds = <String>[];

  var _sequence = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  Future<List<Exercise>> fetchAll() async {
    fetchAllCount++;
    return [...exercises];
  }

  @override
  Future<Exercise> create({
    required String name,
    required ExerciseCategory category,
  }) async {
    _throwIfNeeded();
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
    _throwIfNeeded();
    final i = exercises.indexWhere((e) => e.id == exercise.id);
    exercises[i] = exercise;
  }

  @override
  Future<void> delete(String exerciseId) async {
    _throwIfNeeded();
    deletedIds.add(exerciseId);
    exercises.removeWhere((e) => e.id == exerciseId);
  }

  @override
  Future<int> countUsage(String exerciseId) async => usage[exerciseId] ?? 0;
}
