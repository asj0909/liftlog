import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/core/date/date_format.dart';

void main() {
  test('formatYmd はゼロ埋めした yyyy-MM-dd', () {
    expect(formatYmd(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('parseYmd は正しい日付を変換する', () {
    expect(parseYmd('2026-10-28'), DateTime(2026, 10, 28));
  });

  test('parseYmd は不正な形式・存在しない日付・null で null', () {
    expect(parseYmd(null), isNull);
    expect(parseYmd('2026/10/28'), isNull);
    expect(parseYmd('2026-02-30'), isNull);
    expect(parseYmd('2026-13-01'), isNull);
  });

  test('dateOnly は時刻を切り捨てる', () {
    expect(dateOnly(DateTime(2026, 10, 29, 23, 59)), DateTime(2026, 10, 29));
  });

  test('formatJpDate は「10月29日（木）」の形', () {
    expect(formatJpDate(DateTime(2026, 10, 29)), '10月29日（木）');
    expect(formatJpDate(DateTime(2026, 11, 1)), '11月1日（日）');
  });

  test('formatShortDate は「10/29」の形', () {
    expect(formatShortDate(DateTime(2026, 10, 29)), '10/29');
  });
}
