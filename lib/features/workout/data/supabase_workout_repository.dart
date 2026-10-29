import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/date/date_format.dart';
import '../../../core/error/supabase_error.dart';
import '../../exercise/data/exercise_row.dart';
import '../../exercise/domain/exercise.dart';
import '../domain/workout.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_set.dart';

class SupabaseWorkoutRepository implements WorkoutRepository {
  SupabaseWorkoutRepository(this._client);

  final SupabaseClient _client;

  // user_id は DB 側の既定値 auth.uid() で入り、RLS で本人の行だけが対象になる

  @override
  Future<String> findOrCreateByDate(DateTime date) => guardSupabase(() async {
        final ymd = formatYmd(date);
        final existing = await _client
            .from('workouts')
            .select('id')
            .eq('performed_on', ymd)
            .order('created_at', ascending: true)
            .limit(1)
            .maybeSingle();
        if (existing != null) return existing['id'] as String;

        final created = await _client
            .from('workouts')
            .insert({'performed_on': ymd})
            .select('id')
            .single();
        return created['id'] as String;
      });

  @override
  Future<WorkoutDetail> fetchDetail(String workoutId) =>
      guardSupabase(() async {
        // 種目・セットを 1 回の問い合わせでまとめて取得する
        final row = await _client
            .from('workouts')
            .select(
              'id, performed_on, memo, '
              'workout_exercises(id, sort_order, '
              'exercise:exercises(id, user_id, name, category), '
              'sets(id, sort_order, weight_kg, reps, memo))',
            )
            .eq('id', workoutId)
            .single();
        return _detailFromRow(row);
      });

  @override
  Future<WorkoutEntry> addEntry({
    required String workoutId,
    required Exercise exercise,
    required int sortOrder,
  }) =>
      guardSupabase(() async {
        final row = await _client
            .from('workout_exercises')
            .insert({
              'workout_id': workoutId,
              'exercise_id': exercise.id,
              'sort_order': sortOrder,
            })
            .select('id')
            .single();
        return WorkoutEntry(
          id: row['id'] as String,
          exercise: exercise,
          sortOrder: sortOrder,
        );
      });

  @override
  Future<WorkoutSet> addSet({
    required String entryId,
    required WorkoutSet workoutSet,
  }) =>
      guardSupabase(() async {
        final row = await _client
            .from('sets')
            .insert({
              'workout_exercise_id': entryId,
              'sort_order': workoutSet.sortOrder,
              'weight_kg': workoutSet.weightKg,
              'reps': workoutSet.reps,
            })
            .select('id')
            .single();
        return workoutSet.copyWith(id: row['id'] as String);
      });

  @override
  Future<void> updateSet(WorkoutSet set) => guardSupabase(() async {
        final id = set.id;
        if (id == null) {
          throw ArgumentError('未保存のセットは更新できません');
        }
        await _client
            .from('sets')
            .update({'weight_kg': set.weightKg, 'reps': set.reps})
            .eq('id', id);
      });

  @override
  Future<void> deleteSet(String setId) => guardSupabase(() async {
        await _client.from('sets').delete().eq('id', setId);
      });

  @override
  Future<PreviousRecord?> fetchPreviousRecord({
    required String exerciseId,
    required DateTime before,
  }) =>
      guardSupabase(() async {
        final result = await _client.rpc(
          'get_previous_sets',
          params: {'p_exercise_id': exerciseId, 'p_before': formatYmd(before)},
        );
        final rows = (result as List<dynamic>).cast<Map<String, dynamic>>();
        if (rows.isEmpty) return null;
        return PreviousRecord(
          performedOn: _parseDate(rows.first['performed_on']),
          sets: rows.map(_setFromRow).toList(),
        );
      });

  // ---- 行 → ドメイン ----

  static WorkoutDetail _detailFromRow(Map<String, dynamic> row) {
    final entries = (row['workout_exercises'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_entryFromRow)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return WorkoutDetail(
      id: row['id'] as String,
      performedOn: _parseDate(row['performed_on']),
      memo: row['memo'] as String?,
      entries: entries,
    );
  }

  static WorkoutEntry _entryFromRow(Map<String, dynamic> row) {
    final sets = (row['sets'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_setFromRow)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return WorkoutEntry(
      id: row['id'] as String,
      exercise: exerciseFromRow(row['exercise'] as Map<String, dynamic>),
      sortOrder: row['sort_order'] as int,
      sets: sets,
    );
  }

  static WorkoutSet _setFromRow(Map<String, dynamic> row) => WorkoutSet(
        id: row['id'] as String?,
        sortOrder: row['sort_order'] as int,
        // numeric 型は JSON では整数・小数どちらでも来るので num で受ける
        weightKg: (row['weight_kg'] as num).toDouble(),
        reps: row['reps'] as int,
        memo: row['memo'] as String?,
      );

  static DateTime _parseDate(Object? value) =>
      parseYmd(value as String?) ??
      (throw FormatException('日付の形式が不正です: $value'));
}
