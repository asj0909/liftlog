import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_body.dart';

/// S-07 種目管理。
class ExerciseManagePage extends StatelessWidget {
  const ExerciseManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('種目管理')),
      body: const PlaceholderBody(
        screenId: 'S-07',
        detail: 'カスタム種目の追加・編集・削除をここで行います',
      ),
    );
  }
}
