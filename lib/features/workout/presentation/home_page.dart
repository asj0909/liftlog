import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/date/date_format.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../application/workout_providers.dart';
import '../domain/workout_summary.dart';

/// S-02 ホーム（履歴一覧）。
///
/// 記録画面で変更があると WorkoutController が workoutHistoryProvider を
/// invalidate するので、戻ったときには再読み込みされている。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: history.when(
        data: (summaries) => summaries.isEmpty
            ? const Center(child: Text('まだ記録がありません'))
            : ListView.separated(
                // FAB と最後の行が重ならないように下に余白を取る
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: summaries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _HistoryTile(summary: summaries[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryBody(
          error: error,
          onRetry: () => ref.invalidate(workoutHistoryProvider),
        ),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(formatJpDate(summary.performedOn)),
      subtitle: Text(
        summary.exerciseNames.join('、'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.workout(summary.id)),
    );
  }
}
