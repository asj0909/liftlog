/// 推移グラフの指標（要件定義書 F-06）。
enum ProgressMetric {
  maxWeight('最大重量'),
  estimatedOneRepMax('推定 1RM'),
  totalVolume('総ボリューム');

  const ProgressMetric(this.label);

  final String label;
}

/// 期間フィルタ。`query` は URL の `range` パラメータの値（基本設計書 6.2）。
enum ProgressRange {
  oneMonth('1m', '1か月', 1),
  threeMonths('3m', '3か月', 3),
  sixMonths('6m', '6か月', 6),
  oneYear('1y', '1年', 12),
  all('all', '全期間', null);

  const ProgressRange(this.query, this.label, this._months);

  final String query;
  final String label;
  final int? _months;

  static const defaultRange = ProgressRange.threeMonths;

  /// URL の値から変換する。不明な値・未指定は既定（3 か月）。
  static ProgressRange fromQuery(String? value) => values.firstWhere(
        (r) => r.query == value,
        orElse: () => defaultRange,
      );

  /// [today] を含む期間の開始日。全期間なら null。
  ///
  /// 月末の日付は移動先の月末に丸める（3/31 の 1 か月前は 2/28 または 2/29）。
  DateTime? startDate(DateTime today) {
    final months = _months;
    if (months == null) return null;
    final totalMonths = today.year * 12 + (today.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, today.day > lastDay ? lastDay : today.day);
  }
}

/// 実施日 1 日分の集計値（DB 関数 get_exercise_progress の 1 行）。
class ProgressPoint {
  const ProgressPoint({
    required this.performedOn,
    required this.maxWeight,
    required this.estimatedOneRepMax,
    required this.totalVolume,
  });

  final DateTime performedOn;
  final double maxWeight;
  final double estimatedOneRepMax;
  final double totalVolume;

  double valueOf(ProgressMetric metric) => switch (metric) {
        ProgressMetric.maxWeight => maxWeight,
        ProgressMetric.estimatedOneRepMax => estimatedOneRepMax,
        ProgressMetric.totalVolume => totalVolume,
      };

  @override
  bool operator ==(Object other) =>
      other is ProgressPoint &&
      other.performedOn == performedOn &&
      other.maxWeight == maxWeight &&
      other.estimatedOneRepMax == estimatedOneRepMax &&
      other.totalVolume == totalVolume;

  @override
  int get hashCode =>
      Object.hash(performedOn, maxWeight, estimatedOneRepMax, totalVolume);
}

/// グラフを描くのに必要な最小件数（基本設計書 6.4 S-06）
const minPointsForChart = 2;
