import 'progress_point.dart';

/// 推移グラフ（F-06）。失敗時は AppException を投げる。
abstract interface class ProgressRepository {
  /// 種目の実施日ごとの集計値を日付の古い順に返す。[from] が null なら全期間。
  Future<List<ProgressPoint>> fetchProgress({
    required String exerciseId,
    DateTime? from,
  });
}
