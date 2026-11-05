import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// アプリから開く外部ページ（GitHub Pages の site/ で公開）。
abstract final class ExternalLinks {
  static final privacyPolicy =
      Uri.parse('https://asj0909.github.io/liftlog/privacy.html');
  static final deleteAccount =
      Uri.parse('https://asj0909.github.io/liftlog/delete-account.html');
}

/// URL をブラウザで開く。開けなかったら false。テストではフェイクに差し替える。
typedef OpenUrl = Future<bool> Function(Uri url);

final openUrlProvider = Provider<OpenUrl>((ref) => _openInBrowser);

Future<bool> _openInBrowser(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Exception {
    // ブラウザがない・プラットフォームの例外など。呼び出し側で URL を案内する
    return false;
  }
}
