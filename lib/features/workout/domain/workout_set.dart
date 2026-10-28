/// 1 セットの記録（F-03）。
class WorkoutSet {
  const WorkoutSet({
    required this.weightKg,
    required this.reps,
    this.id,
    this.memo,
  });

  /// 未保存のセットは null
  final String? id;

  /// 自重種目は 0（加重分のみ記録する）
  final double weightKg;
  final int reps;
  final String? memo;

  /// このセットのボリューム（重量 × 回数）
  double get volume => weightKg * reps;

  WorkoutSet copyWith({String? id, double? weightKg, int? reps, String? memo}) =>
      WorkoutSet(
        id: id ?? this.id,
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
        memo: memo ?? this.memo,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkoutSet &&
      other.id == id &&
      other.weightKg == weightKg &&
      other.reps == reps &&
      other.memo == memo;

  @override
  int get hashCode => Object.hash(id, weightKg, reps, memo);
}
