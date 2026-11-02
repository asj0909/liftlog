import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'date_format.dart';

/// 今日の日付（時刻なし）。テストで日付を固定できるように Provider にしている。
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));
