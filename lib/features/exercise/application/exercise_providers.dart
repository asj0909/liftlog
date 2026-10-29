import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../data/supabase_exercise_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => SupabaseExerciseRepository(ref.watch(supabaseClientProvider)),
);

/// 種目一覧（S-05 種目選択で使う）
final exercisesProvider = FutureProvider.autoDispose<List<Exercise>>(
  (ref) => ref.watch(exerciseRepositoryProvider).fetchAll(),
);
