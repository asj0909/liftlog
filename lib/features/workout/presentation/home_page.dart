import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/placeholder_body.dart';
import 'date_format.dart';

/// S-02 ホーム（履歴一覧）。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: const PlaceholderBody(
        screenId: 'S-02',
        detail: 'ワークアウト履歴の一覧をここに表示します',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          Uri(
            path: AppRoutes.newWorkout,
            queryParameters: {'date': formatYmd(DateTime.now())},
          ).toString(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('今日の記録'),
      ),
    );
  }
}
