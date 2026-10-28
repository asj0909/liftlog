import 'app_user.dart';

/// 認証（F-01）。実装は data レイヤー、テストではフェイクに差し替える。
abstract interface class AuthRepository {
  /// 現在ログイン中のユーザー。未ログインなら null。
  AppUser? get currentUser;

  /// ログイン状態が変化するたびに通知する。
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String email, required String password});

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();
}
