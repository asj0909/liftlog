import 'package:liftlog/core/error/app_exception.dart';
import 'package:liftlog/features/progress/domain/progress_point.dart';
import 'package:liftlog/features/progress/domain/progress_repository.dart';

class FakeProgressRepository implements ProgressRepository {
  /// 種目 id ごとの集計値（日付の古い順）
  Map<String, List<ProgressPoint>> pointsByExercise = {};

  /// 次の 1 回だけ投げるエラー
  AppException? nextError;

  int fetchCount = 0;

  /// 最後に渡された期間の開始日
  DateTime? lastFrom;

  @override
  Future<List<ProgressPoint>> fetchProgress({
    required String exerciseId,
    DateTime? from,
  }) async {
    fetchCount++;
    lastFrom = from;
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return [
      for (final p in pointsByExercise[exerciseId] ?? const <ProgressPoint>[])
        if (from == null || !p.performedOn.isBefore(from)) p,
    ];
  }
}
