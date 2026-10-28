import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/auth/application/auth_providers.dart';
import 'package:liftlog/features/auth/presentation/login_page.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository());
  tearDown(() => repo.dispose());

  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_password')), password);
  }

  testWidgets('未入力でログインすると入力エラーを表示し、認証は呼ばない', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(find.text('パスワードを入力してください'), findsOneWidget);
    expect(repo.signInCalls, isEmpty);
  });

  testWidgets('正しい入力でログインすると認証を呼ぶ（前後の空白は除去）', (tester) async {
    await pumpLoginPage(tester);
    await enterCredentials(
      tester,
      email: ' user@example.com ',
      password: 'password123',
    );

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(repo.signInCalls, hasLength(1));
    expect(repo.signInCalls.single.email, 'user@example.com');
    expect(repo.currentUser?.email, 'user@example.com');
  });

  testWidgets('認証に失敗したらエラーメッセージを表示する', (tester) async {
    repo.nextError = const UnauthorizedException(
      message: 'メールアドレスまたはパスワードが違います',
    );
    await pumpLoginPage(tester);
    await enterCredentials(
      tester,
      email: 'user@example.com',
      password: 'wrongpass',
    );

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump(); // 認証処理
    await tester.pump(); // スナックバー表示

    expect(find.text('メールアドレスまたはパスワードが違います'), findsOneWidget);
    expect(repo.currentUser, isNull);
  });
}
