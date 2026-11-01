import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../../exercise/application/exercise_providers.dart';
import '../../exercise/domain/exercise.dart';
import '../application/progress_providers.dart';
import '../domain/progress_point.dart';
import 'progress_chart.dart';

/// S-06 推移グラフ（F-06）。
///
/// 種目と期間は URL のクエリで受け取り、変更したら URL を書き換える
/// （Web で共有・ブックマークできるようにするため。基本設計書 6.2）。
/// コンパクト時は指標をセグメントボタンで切り替えて 1 つずつ表示し、
/// それより広い画面では 3 指標を並べて表示する（基本設計書 6.3）。
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key, this.exerciseId, this.range});

  final String? exerciseId;

  /// 1m / 3m / 6m / 1y / all。未指定・不明な値は 3m。
  final String? range;

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  ProgressMetric _metric = ProgressMetric.maxWeight;

  ProgressRange get _range => ProgressRange.fromQuery(widget.range);

  void _go({required String? exerciseId, required ProgressRange range}) {
    context.go(
      Uri(
        path: AppRoutes.progress,
        queryParameters: {
          if (exerciseId != null) 'exercise': exerciseId,
          'range': range.query,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.fromWidth(MediaQuery.sizeOf(context).width);
    final compact = size == WindowSize.compact;
    final exerciseId = widget.exerciseId;

    return Scaffold(
      appBar: AppBar(title: const Text('推移')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExerciseSelector(
              selectedId: exerciseId,
              onSelected: (id) => _go(exerciseId: id, range: _range),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<ProgressRange>(
                showSelectedIcon: false,
                segments: [
                  for (final r in ProgressRange.values)
                    ButtonSegment(value: r, label: Text(r.label)),
                ],
                selected: {_range},
                onSelectionChanged: (selected) =>
                    _go(exerciseId: exerciseId, range: selected.single),
              ),
            ),
            if (compact) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ProgressMetric>(
                  showSelectedIcon: false,
                  segments: [
                    for (final m in ProgressMetric.values)
                      ButtonSegment(value: m, label: Text(m.label)),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (selected) =>
                      setState(() => _metric = selected.single),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: exerciseId == null
                  ? const Center(child: Text('種目を選択してください'))
                  : _ProgressBody(
                      progressKey: (exerciseId: exerciseId, range: _range),
                      size: size,
                      metric: _metric,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 種目の選択。プリセットとカスタム種目をまとめて出す。
class _ExerciseSelector extends ConsumerWidget {
  const _ExerciseSelector({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    return exercises.when(
      data: (list) => _dropdown(list),
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Row(
        children: [
          const Expanded(child: Text('種目を読み込めませんでした')),
          TextButton(
            onPressed: () => ref.invalidate(exercisesProvider),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<Exercise> list) {
    // 削除された種目などで一覧にない id が URL に来ても落ちないようにする
    final value = list.any((e) => e.id == selectedId) ? selectedId : null;
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '種目',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final e in list)
          DropdownMenuItem(value: e.id, child: Text(e.name)),
      ],
      onChanged: (id) {
        if (id != null) onSelected(id);
      },
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({
    required this.progressKey,
    required this.size,
    required this.metric,
  });

  final ProgressKey progressKey;
  final WindowSize size;
  final ProgressMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(exerciseProgressProvider(progressKey));
    return progress.when(
      data: (points) {
        if (points.length < minPointsForChart) {
          return const Center(
            child: Text(
              '記録が 2 回以上になるとグラフが表示されます',
              textAlign: TextAlign.center,
            ),
          );
        }
        return switch (size) {
          WindowSize.compact => ProgressChartCard(
              points: points,
              metric: metric,
              showTitle: false,
            ),
          WindowSize.medium => _ChartGrid(points: points, columns: 1),
          WindowSize.expanded => _ChartGrid(points: points, columns: 2),
        };
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetryBody(
        error: error,
        onRetry: () => ref.invalidate(exerciseProgressProvider(progressKey)),
      ),
    );
  }
}

/// 3 指標を [columns] 列で並べる（ミディアムは 1 列、エキスパンデッドは 2 列）
class _ChartGrid extends StatelessWidget {
  const _ChartGrid({required this.points, required this.columns});

  final List<ProgressPoint> points;
  final int columns;

  static const _chartHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    const metrics = ProgressMetric.values;
    final rows = <List<ProgressMetric>>[
      for (var i = 0; i < metrics.length; i += columns)
        metrics.sublist(i, (i + columns).clamp(0, metrics.length)),
    ];
    return ListView(
      children: [
        for (final row in rows)
          SizedBox(
            height: _chartHeight,
            child: Row(
              children: [
                for (var i = 0; i < columns; i++)
                  Expanded(
                    child: i < row.length
                        ? ProgressChartCard(points: points, metric: row[i])
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
