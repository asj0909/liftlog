import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
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

  static AppUser? _toAppUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email);

  /// Supabase の例外を AppException に変換する（基本設計書 7.3）。
  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on AuthRetryableFetchException catch (e) {
      // 通信失敗も AuthException の一種として投げられるため先に判定する
      throw NetworkException(cause: e);
    } on AuthException catch (e) {
      throw UnauthorizedException(message: _authMessage(e), cause: e);
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
