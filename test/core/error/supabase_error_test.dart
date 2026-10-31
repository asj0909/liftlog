import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/core/error/supabase_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('postgresErrorCode', () {
    test('code に HTTP ステータス、message に JSON が入っている場合は JSON 側を使う', () {
      // 2026-10-29 に実際に返ってきた形（テーブル権限がなかったとき）
      const e = PostgrestException(
        message: '{"code":"42501","details":null,'
            '"hint":"Grant the required privileges to the current role with: '
            'GRANT SELECT ON public.workouts TO authenticated;",'
            '"message":"permission denied for table workouts"}',
        code: '403',
      );
      expect(postgresErrorCode(e), '42501');
    });

    test('通常の形ならそのまま code を使う', () {
      const e = PostgrestException(message: 'duplicate key', code: '23505');
      expect(postgresErrorCode(e), '23505');
    });

    test('message が JSON 風でも壊れていれば code を使う', () {
      const e = PostgrestException(message: '{broken', code: '403');
      expect(postgresErrorCode(e), '403');
    });
  });

  group('mapPostgrestException', () {
    test('権限エラー（42501 / 403）は ForbiddenException', () {
      expect(
        mapPostgrestException(
          const PostgrestException(
            message: '{"code":"42501","message":"permission denied"}',
            code: '403',
          ),
        ),
        isA<ForbiddenException>(),
      );
      expect(
        mapPostgrestException(
          const PostgrestException(message: 'forbidden', code: '403'),
        ),
        isA<ForbiddenException>(),
      );
    });

    test('JWT の期限切れは UnauthorizedException', () {
      expect(
        mapPostgrestException(
          const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
        ),
        isA<UnauthorizedException>(),
      );
    });

    test('CHECK 制約・一意制約違反は ValidationException', () {
      expect(
        mapPostgrestException(
          const PostgrestException(message: 'check', code: '23514'),
        ),
        isA<ValidationException>(),
      );
      expect(
        mapPostgrestException(
          const PostgrestException(message: 'dup', code: '23505'),
        ),
        isA<ValidationException>(),
      );
    });

    test('知らないコードは UnknownException', () {
      expect(
        mapPostgrestException(
          const PostgrestException(message: '?', code: 'XX000'),
        ),
        isA<UnknownException>(),
      );
    });
  });
}
