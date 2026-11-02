import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date/date_format.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../data/supabase_progress_repository.dart';
import '../domain/progress_point.dart';
import '../domain/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => SupabaseProgressRepository(ref.watch(supabaseClientProvider)),
);

/// 期間の起点となる「今日」。テストで固定できるように Provider にしている。
final todayProvider = Provider<DateTime>((ref) => dateOnly(DateTime.now()));

/// 推移の検索キー：どの種目の、どの期間か
typedef ProgressKey = ({String exerciseId, ProgressRange range});

/// S-06 推移グラフのデータ。記録を変更したら WorkoutController が invalidate する。
final exerciseProgressProvider =
    FutureProvider.autoDispose.family<List<ProgressPoint>, ProgressKey>(
  (ref, key) => ref.watch(progressRepositoryProvider).fetchProgress(
        exerciseId: key.exerciseId,
        from: key.range.startDate(ref.watch(todayProvider)),
      ),
);
