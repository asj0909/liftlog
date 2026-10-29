import 'package:flutter/material.dart';

import '../error/app_exception.dart';

/// 開発中（debug ビルド）だけ、元の例外の内容を返す。リリースでは null。
String? debugDetailOf(Object error) {
  if (!kDebugMode) return null;
  final cause = error is AppException ? error.cause : error;
  return cause?.toString();
}

/// エラー文言の下に、debug ビルドでだけ原因を小さく表示する
class ErrorDetailText extends StatelessWidget {
  const ErrorDetailText(this.error, {super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final detail = debugDetailOf(error);
    if (detail == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SelectableText(
        detail,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// 処理を実行し、AppException ならスナックバーでメッセージを出す（基本設計書 7.3）。
///
/// await の前に ScaffoldMessenger を取っておくので、画面が閉じても安全。
Future<void> runWithErrorSnackBar(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } on AppException catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// 画面に出す文言。AppException 以外は汎用メッセージにする。
String errorMessageOf(Object error) =>
    error is AppException ? error.message : '読み込みに失敗しました';

/// 読み込み失敗時の表示（再試行ボタン付き）
class ErrorRetryBody extends StatelessWidget {
  const ErrorRetryBody({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessageOf(error), textAlign: TextAlign.center),
            ErrorDetailText(error),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}
