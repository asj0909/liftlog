import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/app/router.dart';

void main() {
  group('未ログイン', () {
    test('保護されたパスはログイン画面へ。元のパスを from に保持する', () {
      final result = authRedirect(
        isLoggedIn: false,
        location: Uri.parse('/progress?exercise=abc&range=3m'),
      );
      final uri = Uri.parse(result!);
      expect(uri.path, '/login');
      expect(uri.queryParameters['from'], '/progress?exercise=abc&range=3m');
    });

    test('ログイン画面ならリダイレクトしない', () {
      expect(
        authRedirect(isLoggedIn: false, location: Uri.parse('/login')),
        isNull,
      );
    });
  });

  group('ログイン済み', () {
    test('ログイン画面に来たら from のパスへ戻す', () {
      expect(
        authRedirect(
          isLoggedIn: true,
          location: Uri.parse('/login?from=%2Fcalendar'),
        ),
        '/calendar',
      );
    });

    test('from がなければホームへ', () {
      expect(
        authRedirect(isLoggedIn: true, location: Uri.parse('/login')),
        '/',
      );
    });

    test('外部 URL の from は無視してホームへ（オープンリダイレクト対策）', () {
      expect(
        authRedirect(
          isLoggedIn: true,
          location: Uri.parse('/login?from=%2F%2Fevil.example.com'),
        ),
        '/',
      );
      expect(
        authRedirect(
          isLoggedIn: true,
          location: Uri.parse('/login?from=https%3A%2F%2Fevil.example.com'),
        ),
        '/',
      );
    });

    test('通常の画面ではリダイレクトしない', () {
      expect(
        authRedirect(isLoggedIn: true, location: Uri.parse('/settings')),
        isNull,
      );
    });
  });
}
