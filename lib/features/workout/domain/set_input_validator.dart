/// セット入力のチェック。DB の CHECK 制約（基本設計書 5.2）と範囲を合わせる。
abstract final class SetInputValidator {
  static const maxWeightKg = 9999.99;
  static const minReps = 1;
  static const maxReps = 999;

  /// 重量の刻み幅（基本設計書 Q-02：MVP は 2.5kg 固定）
  static const weightStepKg = 2.5;

  static String? weight(double? value) {
    if (value == null) return '重量を入力してください';
    if (value < 0) return '重量は0以上で入力してください';
    if (value > maxWeightKg) return '重量が大きすぎます';
    // numeric(6,2) に収まるか（小数第2位まで）
    final hundredths = value * 100;
    if ((hundredths - hundredths.roundToDouble()).abs() > 1e-6) {
      return '重量は小数第2位までで入力してください';
    }
    return null;
  }

  static String? reps(int? value) {
    if (value == null) return '回数を入力してください';
    if (value < minReps || value > maxReps) {
      return '回数は$minReps〜$maxRepsで入力してください';
    }
    return null;
  }
}
