import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/supabase_error.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'exercise_row.dart';

class SupabaseExerciseRepository implements ExerciseRepository {
  SupabaseExerciseRepository(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, user_id, name, category';

  @override
  Future<List<Exercise>> fetchAll() => guardSupabase(() async {
        // RLS により、プリセット（user_id が null）と自分の種目だけが返る
        final rows = await _client
            .from('exercises')
            .select(_columns)
            .order('name', ascending: true);
        return rows.map(exerciseFromRow).toList();
      });

  @override
  Future<Exercise> create({
    required String name,
    required ExerciseCategory category,
  }) =>
      guardSupabase(() async {
        // exercises.user_id には既定値がない（NULL はプリセットを表す）ので明示する。
        // 他人の id を入れても RLS（user_id = auth.uid()）で拒否される
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw const UnauthorizedException();
        final row = await _client
            .from('exercises')
            .insert({
              'user_id': userId,
              'name': name,
              'category': category.dbValue,
            })
            .select(_columns)
            .single();
        return exerciseFromRow(row);
      });

  @override
  Future<void> update(Exercise exercise) => guardSupabase(() async {
        // プリセットは RLS で更新対象にならない
        await _client
            .from('exercises')
            .update({
              'name': exercise.name,
              'category': exercise.category.dbValue,
            })
            .eq('id', exercise.id);
      });

  @override
  Future<void> delete(String exerciseId) => guardSupabase(() async {
        // workout_exercises・sets は ON DELETE CASCADE で一緒に消える
        await _client.from('exercises').delete().eq('id', exerciseId);
      });

  @override
  Future<int> countUsage(String exerciseId) => guardSupabase(() async {
        final response = await _client
            .from('workout_exercises')
            .select('id')
            .eq('exercise_id', exerciseId)
            .count(CountOption.exact);
        return response.count;
      });
}
