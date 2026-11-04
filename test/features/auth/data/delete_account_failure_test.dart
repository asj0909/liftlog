import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/auth/data/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  bool definite(String? code, {String message = 'error'}) =>
      SupabaseAuthRepository.isDefiniteFailure(
        PostgrestException(message: message, code: code),
      );

  group('アカウント削除の失敗が確定しているか', () {
    test('PostgreSQL のエラーコードは確定（削除されていない）', () {
      expect(definite('42501'), isTrue);
      expect(definite('P0001'), isTrue);
    });

    test('PostgREST のコードと HTTP 4xx は確定', () {
      expect(definite('PGRST301'), isTrue);
      expect(definite('401'), isTrue);
      expect(definite('404'), isTrue);
    });

    test('message の JSON にある PostgreSQL のコードを優先する', () {
      expect(definite('403', message: '{"code":"42501"}'), isTrue);
    });

    test('5xx・コードなし（成功応答の本文解析の失敗など）は結果不明', () {
      expect(definite('502'), isFalse);
      expect(definite('500'), isFalse);
      expect(definite(null), isFalse);
      expect(definite('200'), isFalse);
      // PostgREST 内部の予期しないエラー（HTTP 500）
      expect(definite('PGRSTX00'), isFalse);
    });
  });
}
