import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Supabase 呼び出しを包み、例外を AppException に変換する（基本設計書 7.3）。
///
/// Exception（通信失敗など）は変換するが、Error（型の不一致などのバグ）は
/// 握りつぶさずそのまま投げる。
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on PostgrestException catch (e) {
    debugPrint('[Supabase] code=${e.code} message=${e.message} '
        'details=${e.details} hint=${e.hint}');
    throw mapPostgrestException(e);
  } on AuthException catch (e) {
    throw UnauthorizedException(cause: e);
  } on Exception catch (e) {
    throw NetworkException(cause: e);
  }
}

/// PostgreSQL / PostgREST のエラーコードで振り分ける。
AppException mapPostgrestException(PostgrestException e) {
  switch (postgresErrorCode(e)) {
    case '23514': // CHECK 制約違反（負の重量など）
    case '22003': // 数値の範囲外
      return ValidationException('入力値が正しくありません', cause: e);
    case '23505': // 一意制約違反
      return ValidationException('同じ名前がすでに登録されています', cause: e);
    case '42501': // 権限なし（テーブル権限・RLS・所有者チェック）
    case '403':
      return ForbiddenException(cause: e);
    case 'PGRST301': // JWT の期限切れ・不正
    case 'PGRST303':
    case '401':
      return UnauthorizedException(cause: e);
    default:
      return UnknownException(cause: e);
  }
}

/// エラーの本当のコードを取り出す。
///
/// 応答によっては code に HTTP ステータス（"403" など）が入り、
/// PostgreSQL のコード（"42501" など）は message の JSON の中にある。
/// その場合は JSON 側のコードを優先する。
@visibleForTesting
String? postgresErrorCode(PostgrestException e) {
  final message = e.message.trim();
  if (message.startsWith('{')) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } on FormatException {
      // JSON でなければ code をそのまま使う
    }
  }
  return e.code;
}
