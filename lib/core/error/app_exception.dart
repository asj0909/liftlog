/// アプリ共通の例外（基本設計書 7.3）。
///
/// data レイヤーで外部ライブラリの例外をこの型に変換し、
/// 上位レイヤーは Supabase などの型に依存しない。
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// 画面に表示してよいメッセージ
  final String message;

  /// 元の例外（ログ用）
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException({super.cause})
      : super('通信に失敗しました。通信環境を確認して再試行してください。');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({String? message, super.cause})
      : super(message ?? 'ログインの有効期限が切れました。再度ログインしてください。');
}

/// ログインはしているが、その操作の権限がない（テーブル権限・RLS・所有者チェック）
class ForbiddenException extends AppException {
  const ForbiddenException({super.cause})
      : super('この操作を行う権限がありません。');
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

class UnknownException extends AppException {
  const UnknownException({super.cause})
      : super('予期しないエラーが発生しました。');
}
