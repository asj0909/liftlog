import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../data/supabase_workout_repository.dart';
import '../domain/workout.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_summary.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => SupabaseWorkoutRepository(ref.watch(supabaseClientProvider)),
);

/// 前回記録の検索キー：どの種目の、どの日より前か
typedef PreviousRecordKey = ({String exerciseId, DateTime before});

/// F-04 前回記録
final previousRecordProvider =
    FutureProvider.autoDispose.family<PreviousRecord?, PreviousRecordKey>(
  (ref, key) => ref
      .watch(workoutRepositoryProvider)
      .fetchPreviousRecord(exerciseId: key.exerciseId, before: key.before),
);

/// S-02 履歴一覧。記録を変更したら WorkoutController が invalidate する。
final workoutHistoryProvider = FutureProvider.autoDispose<List<WorkoutSummary>>(
  (ref) async =>
      historyOf(await ref.watch(workoutRepositoryProvider).fetchSummaries()),
);
