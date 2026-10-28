import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/application/auth_providers.dart';

/// S-08 設定。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authStateProvider).value?.email;

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
        ],
      ),
    );
  }
}
