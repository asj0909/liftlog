/// ログインフォームの入力チェック。純粋な Dart なので単体テストしやすい。
abstract final class CredentialsValidator {
  static const minPasswordLength = 8;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// エラーメッセージを返す。問題なければ null。
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'メールアドレスを入力してください';
    if (!_emailPattern.hasMatch(v)) return 'メールアドレスの形式が正しくありません';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'パスワードを入力してください';
    if (v.length < minPasswordLength) {
      return 'パスワードは$minPasswordLength文字以上で入力してください';
    }
    return null;
  }
}
