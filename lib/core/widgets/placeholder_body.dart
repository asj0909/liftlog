import 'package:flutter/material.dart';

/// 未実装画面の仮表示。実装が進んだら置き換える。
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key, required this.screenId, this.detail});

  /// 基本設計書の画面 ID（例：S-02）
  final String screenId;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 48),
            const SizedBox(height: 12),
            Text('$screenId（未実装）', style: textTheme.titleMedium),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
