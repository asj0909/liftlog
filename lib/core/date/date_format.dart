// 日付の変換（URL・DB 用の yyyy-MM-dd と画面表示用）。
// intl の日本語ロケール初期化に依存しないよう自前で実装している。

/// URL・DB 用の日付文字列（yyyy-MM-dd）。
String formatYmd(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}

/// yyyy-MM-dd を日付に変換する。形式が不正なら null。
DateTime? parseYmd(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  // 2026-02-30 のような存在しない日付を弾く
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// 時刻を切り捨てた日付。
DateTime dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

/// 画面表示用：10月29日（木）
String formatJpDate(DateTime date) =>
    '${date.month}月${date.day}日（${_weekdays[date.weekday - 1]}）';

/// 画面表示用（短い形）：10/29
String formatShortDate(DateTime date) => '${date.month}/${date.day}';
