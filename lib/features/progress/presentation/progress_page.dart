import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_body.dart';

/// S-06 推移グラフ。種目と期間は URL のクエリで受け取る（Web で共有可能にするため）。
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, this.exerciseId, this.range});

  final String? exerciseId;

  /// 1m / 3m / 6m / 1y / all
  final String? range;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('推移')),
      body: PlaceholderBody(
        screenId: 'S-06',
        detail: '種目: ${exerciseId ?? '未選択'} / 期間: ${range ?? '3m'}',
      ),
    );
  }
}
