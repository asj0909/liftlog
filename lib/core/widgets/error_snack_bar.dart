import 'package:flutter/material.dart';

import '../error/app_exception.dart';

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
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}
