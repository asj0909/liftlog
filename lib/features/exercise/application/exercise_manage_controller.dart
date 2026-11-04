import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/application/progress_providers.dart';
import '../../workout/application/workout_providers.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'exercise_providers.dart';

/// S-07 種目管理画面の状態：プリセット＋自分の種目の一覧。
///
/// autoDispose にしない：保存中に画面を閉じても、保存後の再読み込み（invalidate）が
/// 必ず実行されるようにするため（連続して保存したときも含む）。保持するのは種目一覧だけなので小さい。
final exerciseManageControllerProvider =
    AsyncNotifierProvider<ExerciseManageController, List<Exercise>>(
  ExerciseManageController.new,
);

/// カスタム種目の追加・編集・削除（F-02）。
///
/// 一覧は種目選択（S-05）と同じ exercisesProvider から作る。保存に成功したら
/// exercisesProvider を invalidate して読み直す（この画面と S-05 の両方に反映される）。
/// 失敗したときは AppException をそのまま投げ、一覧は変えない。
class ExerciseManageController extends AsyncNotifier<List<Exercise>> {
  ExerciseRepository get _repository => ref.read(exerciseRepositoryProvider);

  @override
  Future<List<Exercise>> build() => ref.watch(exercisesProvider.future);

  Future<void> add({
    required String name,
    required ExerciseCategory category,
  }) async {
    await _write(() => _repository.create(name: name, category: category));
  }

  /// 名前・カテゴリを変更する。種目名は履歴一覧にも出るので、履歴と推移グラフも読み直す。
  Future<void> edit(Exercise exercise) async {
    await _write(() => _repository.update(exercise), recordsChanged: true);
  }

  /// 削除する。その種目の記録も DB 側で消えるので、履歴と推移グラフも読み直す。
  Future<void> remove(String exerciseId) async {
    await _write(() => _repository.delete(exerciseId), recordsChanged: true);
  }

  /// 削除の確認に使う：その種目が使われている記録の件数
  Future<int> usageCount(String exerciseId) =>
      _repository.countUsage(exerciseId);

  Future<void> _write(
    Future<void> Function() action, {
    bool recordsChanged = false,
  }) async {
    await action();
    _reload(recordsChanged: recordsChanged);
  }

  void _reload({bool recordsChanged = false}) {
    if (!ref.mounted) return;
    ref.invalidate(exercisesProvider);
    if (recordsChanged) {
      ref
        ..invalidate(workoutHistoryProvider)
        ..invalidate(exerciseProgressProvider);
    }
  }
}
