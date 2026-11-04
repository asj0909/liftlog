import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/supabase_error.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.onAuthStateChange.map((state) => _toAppUser(state.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> signUp({required String email, required String password}) =>
      _guard(() => _auth.signUp(email: email, password: password));

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _guard(() => _auth.resetPasswordForEmail(email));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<void> deleteAccount() => _guard(_deleteAccount);

  Future<void> _deleteAccount() async {
    try {
      // DB 関数が auth.users から本人を削除し、記録は CASCADE で消える
      await _client.rpc<void>('delete_my_account');
    } on AuthException {
      // 送信前のトークン更新の失敗：削除の要求は送られていない。ログインしたまま _guard で変換する
      rethrow;
    } on PostgrestException catch (e) {
      if (isDefiniteFailure(e)) {
        // サーバーが失敗を返した＝削除されていない。ログインしたままにする
        rethrow;
      }
      // 成功応答の本文が読めない・ゲートウェイのエラーなど：削除されたかどうか分からない
      await _signOutLocally();
      throw _uncertainDeletion(e);
    } on Exception catch (e) {
      // 応答を受け取れなかった：削除されたかどうか分からない。
      // 削除済みならこのセッションはもう使えないので、端末のセッションは破棄しておく
      await _signOutLocally();
      throw _uncertainDeletion(e);
    }
    // サーバー側のユーザーはもういないので、端末のセッションだけを破棄する
    await _signOutLocally();
  }

  static UncertainResultException _uncertainDeletion(Object cause) =>
      UncertainResultException(
        '通信が途切れたため、アカウントを削除できたか確認できませんでした。'
        'ログインできる場合は、もう一度削除してください。',
        cause: cause,
      );

  /// サーバーが「処理しなかった」と判断できる失敗か。
  ///
  /// PostgreSQL のエラーコード（42501 など 5 桁）・PostgREST のコード（PGRST...）・
  /// HTTP 4xx は、DB 関数が実行されなかった（またはロールバックされた）ことを表す。
  /// それ以外（5xx・コードなし・成功応答の本文解析の失敗など）は結果が分からない。
  @visibleForTesting
  static bool isDefiniteFailure(PostgrestException e) {
    final code = postgresErrorCode(e) ?? '';
    if (RegExp(r'^[0-9A-Z]{5}$').hasMatch(code)) return true;
    // PGRSTX00 は PostgREST 内部の予期しないエラー（HTTP 500）なので結果不明に含める
    if (code.startsWith('PGRST')) return code != 'PGRSTX00';
    final status = int.tryParse(code);
    return status != null && status >= 400 && status < 500;
  }

  /// 端末のセッションを破棄する。
  ///
  /// SignOutScope.local でもサーバーへのトークン失効の通知が失敗すると例外になるが、
  /// 端末のセッションは先に消えている。アカウント削除の結果とは関係ないので、ログに残すだけにする。
  Future<void> _signOutLocally() async {
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } on Exception catch (e) {
      debugPrint('[Auth] ローカルのログアウトで例外（無視する）：$e');
    }
  }

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email);

  /// Supabase の例外を AppException に変換する（基本設計書 7.3）。
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthRetryableFetchException catch (e) {
      // 通信失敗も AuthException の一種として投げられるため先に判定する
      throw NetworkException(cause: e);
    } on AuthException catch (e) {
      throw UnauthorizedException(message: _authMessage(e), cause: e);
    } on PostgrestException catch (e) {
      // DB 関数（アカウント削除）の失敗
      throw mapPostgrestException(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException(cause: e);
    }
  }

  static String _authMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'メールアドレスまたはパスワードが違います';
    }
    if (message.contains('already registered')) {
      return 'このメールアドレスは既に登録されています';
    }
    if (message.contains('email not confirmed')) {
      return 'メールアドレスの確認が完了していません。届いたメールを確認してください';
    }
    return '認証に失敗しました（${e.message}）';
  }
}
