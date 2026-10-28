import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_body.dart';

/// S-05 種目選択。
class ExercisePickerPage extends StatelessWidget {
  const ExercisePickerPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('種目を選択')),
      body: const PlaceholderBody(
        screenId: 'S-05',
        detail: 'カテゴリ別の種目一覧と検索をここに表示します',
      ),
    );
  }
}
