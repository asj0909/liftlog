import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/progress/domain/progress_point.dart';

void main() {
  group('ProgressRange.fromQuery', () {
    test('URL の値から変換する', () {
      expect(ProgressRange.fromQuery('1m'), ProgressRange.oneMonth);
      expect(ProgressRange.fromQuery('3m'), ProgressRange.threeMonths);
      expect(ProgressRange.fromQuery('6m'), ProgressRange.sixMonths);
      expect(ProgressRange.fromQuery('1y'), ProgressRange.oneYear);
      expect(ProgressRange.fromQuery('all'), ProgressRange.all);
    });

    test('未指定・不明な値は 3 か月', () {
      expect(ProgressRange.fromQuery(null), ProgressRange.threeMonths);
      expect(ProgressRange.fromQuery('2w'), ProgressRange.threeMonths);
    });
  });

  group('ProgressRange.startDate', () {
    test('指定の月数だけさかのぼる', () {
      final today = DateTime(2026, 11, 1);
      expect(ProgressRange.oneMonth.startDate(today), DateTime(2026, 10, 1));
      expect(ProgressRange.threeMonths.startDate(today), DateTime(2026, 8, 1));
      expect(ProgressRange.sixMonths.startDate(today), DateTime(2026, 5, 1));
      expect(ProgressRange.oneYear.startDate(today), DateTime(2025, 11, 1));
    });

    test('年をまたぐ', () {
      expect(
        ProgressRange.threeMonths.startDate(DateTime(2026, 2, 15)),
        DateTime(2025, 11, 15),
      );
    });

    test('移動先の月にその日がなければ月末にする', () {
      expect(
        ProgressRange.oneMonth.startDate(DateTime(2026, 3, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        ProgressRange.oneMonth.startDate(DateTime(2028, 3, 31)),
        DateTime(2028, 2, 29),
      );
      expect(
        ProgressRange.oneYear.startDate(DateTime(2028, 2, 29)),
        DateTime(2027, 2, 28),
      );
    });

    test('全期間は null', () {
      expect(ProgressRange.all.startDate(DateTime(2026, 11, 1)), isNull);
    });
  });

  test('valueOf は指標に対応する値を返す', () {
    final point = ProgressPoint(
      performedOn: DateTime(2026, 10, 29),
      maxWeight: 80,
      estimatedOneRepMax: 93.33,
      totalVolume: 2400,
    );
    expect(point.valueOf(ProgressMetric.maxWeight), 80);
    expect(point.valueOf(ProgressMetric.estimatedOneRepMax), 93.33);
    expect(point.valueOf(ProgressMetric.totalVolume), 2400);
  });
}
