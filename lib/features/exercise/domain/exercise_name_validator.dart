import 'exercise.dart';

/// カスタム種目の名前の入力チェック（F-02）。純粋な Dart なので単体テストしやすい。
abstract final class ExerciseNameValidator {
  /// exercises.name の CHECK 制約（1〜50 文字）と同じ
  static const maxLength = 50;

  /// エラーメッセージを返す。問題なければ null。
  ///
  /// [existing] は今ある種目（プリセット＋自分の種目）。編集中の種目は [editingId] で除外する。
  /// DB はプリセットと同名のカスタム種目を許すが、種目選択で見分けがつかなくなるので画面側で禁止する。
  static String? validate(
    String? value, {
    required List<Exercise> existing,
    String? editingId,
  }) {
    final name = normalize(value);
    if (name.isEmpty) return '種目名を入力してください';
    if (name.length > maxLength) return '種目名は$maxLength文字以内で入力してください';
    for (final e in existing) {
      if (e.id != editingId && e.name == name) {
        return e.isPreset
            ? '同じ名前のプリセット種目があります'
            : '同じ名前の種目がすでに登録されています';
      }
    }
    return null;
  }

  /// 保存する形：前後の空白を除く
  static String normalize(String? value) => value?.trim() ?? '';
}
