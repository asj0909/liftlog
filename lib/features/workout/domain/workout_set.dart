/// 1 セットの記録（F-03）。
class WorkoutSet {
  const WorkoutSet({
    required this.weightKg,
    required this.reps,
    this.id,
    this.sortOrder = 0,
    this.memo,
  });

  /// 未保存のセットは null
  final String? id;

  /// 種目内での表示順
  final int sortOrder;

  /// 自重種目は 0（加重分のみ記録する）
  final double weightKg;
  final int reps;
  final String? memo;

  bool get isSaved => id != null;

  /// このセットのボリューム（重量 × 回数）
  double get volume => weightKg * reps;

  WorkoutSet copyWith({
    String? id,
    int? sortOrder,
    double? weightKg,
    int? reps,
    String? memo,
  }) =>
      WorkoutSet(
        id: id ?? this.id,
        sortOrder: sortOrder ?? this.sortOrder,
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
        memo: memo ?? this.memo,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkoutSet &&
      other.id == id &&
      other.sortOrder == sortOrder &&
      other.weightKg == weightKg &&
      other.reps == reps &&
      other.memo == memo;

  @override
  int get hashCode => Object.hash(id, sortOrder, weightKg, reps, memo);
}
