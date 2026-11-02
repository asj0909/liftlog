import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/progress/data/supabase_progress_repository.dart';
import 'package:liftlog/features/progress/domain/progress_point.dart';

void main() {
  test('get_exercise_progress の行を変換する（numeric は整数・小数どちらも受ける）', () {
    final point = progressPointFromRow({
      'performed_on': '2026-10-29',
      'max_weight': 80,
      'est_1rm': 93.33,
      'total_volume': 2400.0,
    });

    expect(
      point,
      ProgressPoint(
        performedOn: DateTime(2026, 10, 29),
        maxWeight: 80,
        estimatedOneRepMax: 93.33,
        totalVolume: 2400,
      ),
    );
  });

  test('日付の形式が不正なら FormatException', () {
    expect(
      () => progressPointFromRow({
        'performed_on': '2026/10/29',
        'max_weight': 80,
        'est_1rm': 80,
        'total_volume': 800,
      }),
      throwsFormatException,
    );
  });
}
