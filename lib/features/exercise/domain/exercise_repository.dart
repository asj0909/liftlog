import 'exercise.dart';

/// 種目（F-02）。失敗時は AppException を投げる。
abstract interface class ExerciseRepository {
  /// プリセット種目と自分のカスタム種目
  Future<List<Exercise>> fetchAll();

  /// カスタム種目を追加し、保存した種目（id 付き）を返す
  Future<Exercise> create({
    required String name,
    required ExerciseCategory category,
  });

  /// カスタム種目の名前・カテゴリを変更する
  Future<void> update(Exercise exercise);

  /// カスタム種目を削除する。その種目の記録（ワークアウト種目・セット）も DB 側で削除される。
  Future<void> delete(String exerciseId);

  /// その種目が使われている記録（ワークアウト種目）の件数。削除の確認に使う。
  Future<int> countUsage(String exerciseId);
}
