import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_snack_bar.dart';
import '../../exercise/application/exercise_providers.dart';
import '../../exercise/domain/exercise.dart';

/// S-05 種目選択。選んだ種目を `context.pop(exercise)` で呼び出し元に返す。
class ExercisePickerPage extends ConsumerStatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  ConsumerState<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends ConsumerState<ExercisePickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('種目を選択')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('exercise_search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '種目名で検索',
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: exercises.when(
              data: (all) => _ExerciseList(
                exercises: filterExercises(all, _query),
                onSelected: (exercise) => context.pop(exercise),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorRetryBody(
                error: error,
                onRetry: () => ref.invalidate(exercisesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 名前に検索語を含む種目（大文字・小文字は区別しない）
@visibleForTesting
List<Exercise> filterExercises(List<Exercise> all, String query) {
  if (query.isEmpty) return all;
  final q = query.toLowerCase();
  return [for (final e in all) if (e.name.toLowerCase().contains(q)) e];
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.exercises, required this.onSelected});

  final List<Exercise> exercises;
  final ValueChanged<Exercise> onSelected;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Center(child: Text('該当する種目がありません'));
    }

    // 部位カテゴリの定義順に見出しを付けて並べる
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (final category in ExerciseCategory.values) {
      final inCategory = [for (final e in exercises) if (e.category == category) e];
      if (inCategory.isEmpty) continue;
      children
        ..add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(category.label, style: textTheme.labelLarge),
          ),
        )
        ..addAll([
          for (final e in inCategory)
            ListTile(
              title: Text(e.name),
              trailing: e.isPreset ? null : const Icon(Icons.person_outline),
              onTap: () => onSelected(e),
            ),
        ]);
    }
    return ListView(children: children);
  }
}
