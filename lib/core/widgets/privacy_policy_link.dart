import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../links/external_links.dart';

/// プライバシーポリシーを開く（Google Play の要件：アプリ内にリンクを置く）。
/// 開けなかったときはスナックバーで URL を案内する。
Future<void> openPrivacyPolicy(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final url = ExternalLinks.privacyPolicy;
  final opened = await ref.read(openUrlProvider)(url);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('ページを開けませんでした。$url をブラウザで開いてください。')),
    );
  }
}

/// ログイン画面などに置く小さなリンク
class PrivacyPolicyLink extends ConsumerWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      key: const Key('privacy_policy_link'),
      onPressed: () => openPrivacyPolicy(context, ref),
      child: const Text('プライバシーポリシー'),
    );
  }
}
