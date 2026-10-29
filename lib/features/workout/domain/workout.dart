import '../../exercise/domain/exercise.dart';
import 'workout_set.dart';

/// ワークアウト内の 1 種目とそのセット（workout_exercises 1 行 + sets）。
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.exercise,
    required this.sortOrder,
    this.sets = const [],
  });

  final String id;
  final Exercise exercise;
  final int sortOrder;

  /// 表示順に並んだセット
  final List<WorkoutSet> sets;

  /// 次に追加するセットの表示順（削除で欠番があっても重複しない）
  int get nextSetSortOrder => sets.isEmpty
      ? 0
      : sets.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  WorkoutEntry copyWith({List<WorkoutSet>? sets}) => WorkoutEntry(
        id: id,
        exercise: exercise,
        sortOrder: sortOrder,
        sets: sets ?? this.sets,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkoutEntry &&
      other.id == id &&
      other.exercise == exercise &&
      other.sortOrder == sortOrder &&
      _listEquals(other.sets, sets);

  @override
  int get hashCode => Object.hash(id, exercise, sortOrder, Object.hashAll(sets));
}

/// 1 回分のワークアウト（S-04 で扱う単位）。
class WorkoutDetail {
  const WorkoutDetail({
    required this.id,
    required this.performedOn,
    this.memo,
    this.entries = const [],
  });

  final String id;

  /// 実施日（時刻なし）
  final DateTime performedOn;
  final String? memo;

  /// 表示順に並んだ種目
  final List<WorkoutEntry> entries;

  int get nextEntrySortOrder => entries.isEmpty
      ? 0
      : entries.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  WorkoutEntry entry(String entryId) =>
      entries.firstWhere((e) => e.id == entryId);

  WorkoutDetail copyWith({List<WorkoutEntry>? entries}) => WorkoutDetail(
        id: id,
        performedOn: performedOn,
        memo: memo,
        entries: entries ?? this.entries,
      );

  /// 同じ id の種目を差し替える
  WorkoutDetail replaceEntry(WorkoutEntry entry) => copyWith(
        entries: [for (final e in entries) e.id == entry.id ? entry : e],
      );

  /// 種目を末尾に追加する
  WorkoutDetail addEntry(WorkoutEntry entry) =>
      copyWith(entries: [...entries, entry]);

  @override
  bool operator ==(Object other) =>
      other is WorkoutDetail &&
      other.id == id &&
      other.performedOn == performedOn &&
      other.memo == memo &&
      _listEquals(other.entries, entries);

  @override
  int get hashCode =>
      Object.hash(id, performedOn, memo, Object.hashAll(entries));
}

/// 前回のセッションの記録（F-04）。
class PreviousRecord {
  const PreviousRecord({required this.performedOn, required this.sets});

  final DateTime performedOn;
  final List<WorkoutSet> sets;

  @override
  bool operator ==(Object other) =>
      other is PreviousRecord &&
      other.performedOn == performedOn &&
      _listEquals(other.sets, sets);

  @override
  int get hashCode => Object.hash(performedOn, Object.hashAll(sets));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
