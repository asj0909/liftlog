import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/supabase_error.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'exercise_row.dart';

class SupabaseExerciseRepository implements ExerciseRepository {
  SupabaseExerciseRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Exercise>> fetchAll() => guardSupabase(() async {
        // RLS により、プリセット（user_id が null）と自分の種目だけが返る
        final rows = await _client
            .from('exercises')
            .select('id, user_id, name, category')
            .order('name', ascending: true);
        return rows.map(exerciseFromRow).toList();
      });
}
