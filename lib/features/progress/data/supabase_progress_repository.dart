import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/date/date_format.dart';
import '../../../core/error/supabase_error.dart';
import '../domain/progress_point.dart';
import '../domain/progress_repository.dart';

class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProgressPoint>> fetchProgress({
    required String exerciseId,
    DateTime? from,
  }) =>
      guardSupabase(() async {
        // 集計は DB 側で行う（基本設計書 5 章）。RLS で本人の記録だけが対象になる
        final result = await _client.rpc(
          'get_exercise_progress',
          params: {
            'p_exercise_id': exerciseId,
            'p_from': from == null ? null : formatYmd(from),
          },
        );
        return (result as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(progressPointFromRow)
            .toList();
      });
}

/// get_exercise_progress の 1 行をドメインに変換する。
ProgressPoint progressPointFromRow(Map<String, dynamic> row) {
  final performedOn = row['performed_on'] as String?;
  return ProgressPoint(
    performedOn: parseYmd(performedOn) ??
        (throw FormatException('日付の形式が不正です: $performedOn')),
    // numeric 型は JSON では整数・小数どちらでも来るので num で受ける
    maxWeight: (row['max_weight'] as num).toDouble(),
    estimatedOneRepMax: (row['est_1rm'] as num).toDouble(),
    totalVolume: (row['total_volume'] as num).toDouble(),
  );
}
