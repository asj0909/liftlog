import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_body.dart';

/// S-03 カレンダー。
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: const PlaceholderBody(
        screenId: 'S-03',
        detail: 'トレーニング実施日をカレンダーに表示します',
      ),
    );
  }
}
