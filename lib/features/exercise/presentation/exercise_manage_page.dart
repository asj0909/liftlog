import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_snack_bar.dart';
import '../application/exercise_manage_controller.dart';
import '../domain/exercise.dart';
import '../domain/exercise_name_validator.dart';

/// S-07 種目管理（F-02）。
///
/// カスタム種目を部位カテゴリごとに表示し、追加・編集・削除する。プリセット種目は参照のみ。
/// 削除する種目が記録で使われているときは、記録も消えることを確認してから削除する。
class ExerciseManagePage extends ConsumerWidget {
  const ExerciseManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseManageControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('種目管理')),
      body: exercises.when(
        data: (all) => _ExerciseManageList(exercises: all),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryBody(
          error: error,
          onRetry: () => ref.invalidate(exerciseManageControllerProvider),
        ),
      ),
      floatingActionButton: exercises.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref, exercises.requireValue),
              icon: const Icon(Icons.add),
              label: const Text('種目を追加'),
            )
          : null,
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<Exercise> existing,
  ) async {
    final input = await showDialog<_ExerciseInput>(
      context: context,
      builder: (context) => _ExerciseFormDialog(existing: existing),
    );
    if (input == null || !context.mounted) return;
    await runWithErrorSnackBar(
      context,
      () => ref
          .read(exerciseManageControllerProvider.notifier)
          .add(name: input.name, category: input.category),
    );
  }
}

class _ExerciseManageList extends ConsumerWidget {
  const _ExerciseManageList({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final custom = [for (final e in exercises) if (!e.isPreset) e];
    final presets = [for (final e in exercises) if (e.isPreset) e];

    final children = <Widget>[];
    if (custom.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text('カスタム種目はまだありません。右下の「種目を追加」から登録できます。'),
        ),
      );
    }
    // 部位カテゴリの定義順に見出しを付けて並べる（S-05 と同じ）
    for (final category in ExerciseCategory.values) {
      final inCategory = [for (final e in custom) if (e.category == category) e];
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
              onTap: () => _edit(context, ref, e),
              trailing: IconButton(
                tooltip: '削除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, e),
              ),
            ),
        ]);
    }
    children.add(
      ExpansionTile(
        title: Text('プリセット種目（${presets.length}）'),
        subtitle: const Text('プリセットは編集・削除できません'),
        children: [
          for (final e in presets)
            ListTile(
              dense: true,
              title: Text(e.name),
              trailing: Text(e.category.label),
            ),
        ],
      ),
    );

    return ListView(
      // FAB と最後の行が重ならないように下に余白を取る
      padding: const EdgeInsets.only(bottom: 88),
      children: children,
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Exercise target) async {
    final input = await showDialog<_ExerciseInput>(
      context: context,
      builder: (context) =>
          _ExerciseFormDialog(existing: exercises, editing: target),
    );
    if (input == null || !context.mounted) return;
    if (input.name == target.name && input.category == target.category) return;
    await runWithErrorSnackBar(
      context,
      () => ref
          .read(exerciseManageControllerProvider.notifier)
          .edit(target.copyWith(name: input.name, category: input.category)),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Exercise target,
  ) async {
    final controller = ref.read(exerciseManageControllerProvider.notifier);
    await runWithErrorSnackBar(context, () async {
      // 記録で使われているかを先に調べ、確認文を変える（要件定義書 F-02）
      final usage = await controller.usageCount(target.id);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('「${target.name}」を削除しますか？'),
          content: Text(
            usage == 0
                ? 'この種目は記録で使われていません。'
                : 'この種目は $usage 件の記録で使われています。'
                    '削除すると、その記録（セット）もすべて削除され、元に戻せません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await controller.remove(target.id);
    });
  }
}

/// 追加・編集ダイアログの入力結果
typedef _ExerciseInput = ({String name, ExerciseCategory category});

/// 種目の追加・編集ダイアログ。[editing] があれば編集、なければ追加。
class _ExerciseFormDialog extends StatefulWidget {
  const _ExerciseFormDialog({required this.existing, this.editing});

  final List<Exercise> existing;
  final Exercise? editing;

  @override
  State<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<_ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.name);
  late ExerciseCategory _category =
      widget.editing?.category ?? ExerciseCategory.chest;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<_ExerciseInput>((
      name: ExerciseNameValidator.normalize(_name.text),
      category: _category,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return AlertDialog(
      title: Text(isEdit ? '種目を編集' : '種目を追加'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('exercise_name'),
              controller: _name,
              autofocus: true,
              maxLength: ExerciseNameValidator.maxLength,
              decoration: const InputDecoration(labelText: '種目名'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => ExerciseNameValidator.validate(
                value,
                existing: widget.existing,
                editingId: widget.editing?.id,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExerciseCategory>(
              key: const Key('exercise_category'),
              initialValue: _category,
              decoration: const InputDecoration(labelText: '部位'),
              items: [
                for (final c in ExerciseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) {
                if (c != null) setState(() => _category = c);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
