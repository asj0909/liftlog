import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/placeholder_body.dart';
import 'date_format.dart';

/// S-04 ワークアウト記録。
///
/// `/workouts/new?date=...`（新規）と `/workouts/{id}`（既存）の両方を扱う。
class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key, required String this.workoutId}) : date = null;

  const WorkoutPage.create({super.key, this.date}) : workoutId = null;

  final String? workoutId;

  /// 新規作成時の実施日（yyyy-MM-dd）。不正・未指定なら当日。
  final String? date;

  bool get isNew => workoutId == null;

  @override
  Widget build(BuildContext context) {
    final performedOn = parseYmd(date) ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '新しい記録（${formatYmd(performedOn)}）' : 'ワークアウト'),
      ),
      body: PlaceholderBody(
        screenId: 'S-04',
        detail: isNew
            ? 'ワークアウトを作成し、${AppRoutes.workout('{id}')} に置き換えます'
            : '種目とセットの入力をここに表示します',
      ),
      floatingActionButton: isNew
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('${AppRoutes.workout(workoutId!)}/pick-exercise'),
              icon: const Icon(Icons.add),
              label: const Text('種目を追加'),
            ),
    );
  }
}
