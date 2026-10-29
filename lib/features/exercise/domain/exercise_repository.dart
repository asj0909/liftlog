import 'exercise.dart';

/// 種目（F-02）。失敗時は AppException を投げる。
abstract interface class ExerciseRepository {
  /// プリセット種目と自分のカスタム種目
  Future<List<Exercise>> fetchAll();
}
