/// 履歴一覧（S-02）の 1 行分。セットの中身は持たない。
class WorkoutSummary {
  const WorkoutSummary({
    required this.id,
    required this.performedOn,
    this.exerciseNames = const [],
  });

  final String id;

  /// 実施日（時刻なし）
  final DateTime performedOn;

  /// 表示順に並んだ種目名
  final List<String> exerciseNames;

  @override
  bool operator ==(Object other) =>
      other is WorkoutSummary &&
      other.id == id &&
      other.performedOn == performedOn &&
      _listEquals(other.exerciseNames, exerciseNames);

  @override
  int get hashCode =>
      Object.hash(id, performedOn, Object.hashAll(exerciseNames));

  @override
  String toString() => 'WorkoutSummary($id, $performedOn, $exerciseNames)';
}

/// 履歴一覧に出す行：種目が 0 件のワークアウト（「今日の記録」を開いただけの日）を除き、
/// 実施日の新しい順に並べる。同じ日の行は元の順序を保つ。
List<WorkoutSummary> historyOf(List<WorkoutSummary> summaries) {
  final indexed = [
    for (final (i, s) in summaries.indexed)
      if (s.exerciseNames.isNotEmpty) (i, s),
  ]..sort((a, b) {
      final byDate = b.$2.performedOn.compareTo(a.$2.performedOn);
      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
  return [for (final (_, s) in indexed) s];
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
