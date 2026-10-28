import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/auth/domain/credentials_validator.dart';

void main() {
  group('email', () {
    test('正しい形式なら null（前後の空白は無視）', () {
      expect(CredentialsValidator.email('user@example.com'), isNull);
      expect(CredentialsValidator.email('  user@example.com  '), isNull);
    });

    test('空・形式不正はエラー', () {
      expect(CredentialsValidator.email(null), 'メールアドレスを入力してください');
      expect(CredentialsValidator.email(''), 'メールアドレスを入力してください');
      expect(CredentialsValidator.email('user@'), 'メールアドレスの形式が正しくありません');
      expect(CredentialsValidator.email('user example.com'), 'メールアドレスの形式が正しくありません');
    });
  });

  group('password', () {
    test('8 文字以上なら null', () {
      expect(CredentialsValidator.password('12345678'), isNull);
    });

    test('空・8 文字未満はエラー', () {
      expect(CredentialsValidator.password(''), 'パスワードを入力してください');
      expect(CredentialsValidator.password('1234567'), 'パスワードは8文字以上で入力してください');
    });
  });
}
