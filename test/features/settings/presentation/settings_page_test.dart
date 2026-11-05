import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/core/links/external_links.dart';
import 'package:liftlog/features/auth/application/auth_providers.dart';
import 'package:liftlog/features/auth/domain/app_user.dart';
import 'package:liftlog/features/settings/presentation/settings_page.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late List<Uri> openedUrls;
  late bool openSucceeds;

  setUp(() {
    openedUrls = [];
    openSucceeds = true;
    repo = FakeAuthRepository(
      initialUser: const AppUser(id: 'user-1', email: 'user@example.com'),
    );
  });
  tearDown(() => repo.dispose());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          openUrlProvider.overrideWithValue((url) async {
            openedUrls.add(url);
            return openSucceeds;
          }),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.text('アカウントを削除'));
    await tester.pumpAndSettle();
  }

  testWidgets('確認ダイアログで「削除する」を押すとアカウントを削除する', (tester) async {
    await pumpPage(tester);
    await openDeleteDialog(tester);

    expect(find.text('アカウントを削除しますか？'), findsOneWidget);
    expect(find.textContaining('元に戻せません'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repo.deleteAccountCount, 1);
    expect(repo.currentUser, isNull);
    expect(find.text('アカウントを削除しました'), findsOneWidget);
  });

  testWidgets('キャンセルなら削除しない', (tester) async {
    await pumpPage(tester);
    await openDeleteDialog(tester);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(repo.deleteAccountCount, 0);
    expect(repo.currentUser, isNotNull);
  });

  testWidgets('削除に失敗したらエラーを表示し、ログインしたまま', (tester) async {
    repo.nextError = const NetworkException();
    await pumpPage(tester);
    await openDeleteDialog(tester);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repo.deleteAccountCount, 0);
    expect(repo.currentUser, isNotNull);
    expect(find.textContaining('通信に失敗しました'), findsOneWidget);
  });

  testWidgets('「プライバシーポリシー」でポリシーのページを開く', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(openedUrls, [ExternalLinks.privacyPolicy]);
  });

  testWidgets('ページを開けなかったら URL を案内する', (tester) async {
    openSucceeds = false;
    await pumpPage(tester);

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ページを開けませんでした'), findsOneWidget);
  });
}
