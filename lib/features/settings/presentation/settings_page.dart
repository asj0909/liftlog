import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../../auth/application/auth_providers.dart';

/// S-08 設定。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authStateProvider).value?.email;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('アカウント'),
            subtitle: Text(email ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('種目管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.exercises),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            // ログアウト後のログイン画面への遷移は認証ガードが行う
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
          ListTile(
            leading: Icon(Icons.person_remove_outlined, color: errorColor),
            title: Text('アカウントを削除', style: TextStyle(color: errorColor)),
            onTap: () => _deleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  /// アカウント削除（Google Play のアカウント削除要件）。確認してから削除する。
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Text(
          'ワークアウトの記録・カスタム種目を含む、このアカウントのデータがすべて削除されます。'
          '削除したデータは元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await runWithErrorSnackBar(context, () async {
      await ref.read(authRepositoryProvider).deleteAccount();
      // ログイン画面への遷移は認証ガードが行う。スナックバーは画面をまたいで表示される
      messenger.showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
    });
  }
}
