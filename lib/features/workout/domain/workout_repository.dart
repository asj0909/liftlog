import '../../exercise/domain/exercise.dart';
import 'workout.dart';
import 'workout_set.dart';
import 'workout_summary.dart';

/// ワークアウト記録（F-03〜F-05）。失敗時は AppException を投げる。
abstract interface class WorkoutRepository {
  /// 指定日のワークアウトを返す。なければ作成する（同じ日に 2 つ作らない）。
  Future<String> findOrCreateByDate(DateTime date);

  Future<WorkoutDetail> fetchDetail(String workoutId);

  /// 自分のワークアウトの一覧（S-02）。種目が 0 件のものも含む。
  Future<List<WorkoutSummary>> fetchSummaries();

  Future<WorkoutEntry> addEntry({
    required String workoutId,
    required Exercise exercise,
    required int sortOrder,
  });

  /// 保存したセット（id 付き）を返す
  Future<WorkoutSet> addSet({
    required String entryId,
    required WorkoutSet workoutSet,
  });

  /// id が付いたセットの重量・回数を更新する
  Future<void> updateSet(WorkoutSet set);

  Future<void> deleteSet(String setId);

  /// [before] より前で、その種目を行った直近のセッション。なければ null。
  Future<PreviousRecord?> fetchPreviousRecord({
    required String exerciseId,
    required DateTime before,
  });
}
