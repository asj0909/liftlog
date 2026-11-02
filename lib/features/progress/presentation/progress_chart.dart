import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/date/date_format.dart';
import '../../workout/presentation/set_format.dart';
import '../domain/progress_point.dart';

/// 指標の値の表示：最大重量・推定 1RM は「62.5kg」、総ボリュームは「1,250kg」
String formatMetricValue(ProgressMetric metric, double value) =>
    switch (metric) {
      ProgressMetric.maxWeight ||
      ProgressMetric.estimatedOneRepMax =>
        '${formatWeightKg(value)}kg',
      ProgressMetric.totalVolume => '${NumberFormat('#,##0.##').format(value)}kg',
    };

/// 1 指標分の折れ線グラフ（カード）。点をタップすると日付と値を表示する。
///
/// [points] は日付の古い順で 2 件以上ある前提（件数の判定は呼び出し側で行う）。
class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    super.key,
    required this.points,
    required this.metric,
    this.showTitle = true,
  });

  final List<ProgressPoint> points;
  final ProgressMetric metric;

  /// コンパクト時は指標をセグメントボタンで選ぶので、カード内の見出しは出さない
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(metric.label, style: theme.textTheme.titleMedium),
              ),
            Expanded(child: _buildChart(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final first = points.first.performedOn;
    // 横軸は最初の実施日からの日数（実施日の間隔が空いた分だけ線も離す）
    double xOf(DateTime date) =>
        _utcDate(date).difference(_utcDate(first)).inDays.toDouble();
    DateTime dateOf(double x) =>
        DateTime(first.year, first.month, first.day + x.round());

    final spots = [
      for (final p in points) FlSpot(xOf(p.performedOn), p.valueOf(metric)),
    ];
    final span = spots.last.x;
    final color = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.bodySmall;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: span,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(meta.formattedValue, style: labelStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              // 日付ラベルは両端を含めて 4 つ程度にする
              interval: span >= 3 ? span / 3 : 1,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(formatShortDate(dateOf(value)), style: labelStyle),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${formatShortDate(points[spot.spotIndex].performedOn)}\n'
                  '${formatMetricValue(metric, spot.y)}',
                  TextStyle(color: theme.colorScheme.onInverseSurface),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  /// 夏時間の切り替えで日数がずれないよう UTC の日付で差を取る
  static DateTime _utcDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
