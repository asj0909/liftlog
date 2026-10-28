import 'dart:async';

import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/auth/domain/app_user.dart';
import 'package:liftlog/features/auth/domain/auth_repository.dart';

/// テスト用の AuthRepository。Supabase に接続せずに認証の挙動を再現する。
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  /// 次の呼び出しで投げる例外（設定するとその操作は失敗する）
  AppException? nextError;

  final signInCalls = <({String email, String password})>[];

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  void _setUser(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add((email: email, password: password));
    _throwIfNeeded();
    _setUser(AppUser(id: 'user-1', email: email));
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    _throwIfNeeded();
    _setUser(AppUser(id: 'user-1', email: email));
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _throwIfNeeded();
  }

  @override
  Future<void> signOut() async {
    _throwIfNeeded();
    _setUser(null);
  }

  Future<void> dispose() => _controller.close();
}
