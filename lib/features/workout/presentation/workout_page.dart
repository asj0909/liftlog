import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/date/date_format.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../../exercise/domain/exercise.dart';
import '../application/workout_controller.dart';
import '../application/workout_providers.dart';
import '../domain/set_input_validator.dart';
import '../domain/workout.dart';
import '../domain/workout_set.dart';
import 'set_format.dart';

/// S-04 ワークアウト記録（`/workouts/{id}`）。
class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key, required this.workoutId});

  final String workoutId;

  Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await context.push<Exercise>(
      '${AppRoutes.workout(workoutId)}/pick-exercise',
    );
    if (exercise == null || !context.mounted) return;
    await runWithErrorSnackBar(
      context,
      () => ref
          .read(workoutControllerProvider(workoutId).notifier)
          .addExercise(exercise),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(workoutControllerProvider(workoutId));
    final loaded = detail.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded == null ? '記録' : formatJpDate(loaded.performedOn)),
      ),
      body: detail.when(
        data: (value) => value.entries.isEmpty
            ? const Center(child: Text('「種目を追加」から記録を始めましょう'))
            : ListView(
                // 下端の FAB と重ならないように余白を取る
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  for (final entry in value.entries)
                    _EntryCard(
                      workoutId: workoutId,
                      performedOn: value.performedOn,
                      entry: entry,
                    ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryBody(
          error: error,
          onRetry: () => ref.invalidate(workoutControllerProvider(workoutId)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_exercise'),
        onPressed: loaded == null ? null : () => _pickExercise(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('種目を追加'),
      ),
    );
  }
}

/// 種目 1 つ分のカード：前回記録、セット一覧、セット追加ボタン
class _EntryCard extends ConsumerWidget {
  const _EntryCard({
    required this.workoutId,
    required this.performedOn,
    required this.entry,
  });

  final String workoutId;
  final DateTime performedOn;
  final WorkoutEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previous = ref.watch(
      previousRecordProvider((exerciseId: entry.exercise.id, before: performedOn)),
    );
    final controller = ref.read(workoutControllerProvider(workoutId).notifier);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.exercise.name, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              previousLabel(previous),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final (index, workoutSet) in entry.sets.indexed)
              SetRow(
                key: ValueKey(workoutSet.id ?? 'draft-${workoutSet.sortOrder}'),
                number: index + 1,
                workoutSet: workoutSet,
                onChanged: (updated) => runWithErrorSnackBar(
                  context,
                  () => controller.updateSet(entry.id, updated),
                ),
                onDelete: () => runWithErrorSnackBar(
                  context,
                  () => controller.deleteSet(entry.id, workoutSet.id!),
                ),
              ),
            TextButton.icon(
              key: Key('add_set_${entry.id}'),
              onPressed: () => runWithErrorSnackBar(
                context,
                () => controller.addSet(
                  entry.id,
                  previous: previous.value?.sets ?? const [],
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('セットを追加'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 前回記録の 1 行表示（F-04）
@visibleForTesting
String previousLabel(AsyncValue<PreviousRecord?> previous) => switch (previous) {
      AsyncData(value: final record?) =>
        '前回（${formatShortDate(record.performedOn)}）：'
            '${record.sets.map(formatSet).join('、')}',
      AsyncData() => '前回の記録はありません',
      AsyncError() => '前回の記録を取得できませんでした',
      _ => '前回の記録を読み込み中…',
    };

/// セット 1 行：番号、重量（−/値/＋）、回数（−/値/＋）、削除
///
/// −/＋ は 1 タップごとに保存する（基本設計書 6.4：保存ボタンなし）。
/// 値をタップすると数値を直接入力できる。
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.number,
    required this.workoutSet,
    required this.onChanged,
    required this.onDelete,
  });

  final int number;
  final WorkoutSet workoutSet;
  final ValueChanged<WorkoutSet> onChanged;
  final VoidCallback onDelete;

  static const _step = SetInputValidator.weightStepKg;

  @override
  Widget build(BuildContext context) {
    // 保存が終わるまでは操作させない（id がないと更新できないため）
    final enabled = workoutSet.isSaved;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text('$number', style: textTheme.labelLarge),
        ),
        _StepButton(
          icon: Icons.remove,
          tooltip: '重量を減らす',
          onPressed: enabled && workoutSet.weightKg > 0
              ? () => onChanged(
                    workoutSet.copyWith(
                      weightKg: workoutSet.weightKg > _step ? workoutSet.weightKg - _step : 0.0,
                    ),
                  )
              : null,
        ),
        Expanded(
          child: _ValueButton(
            label: '${formatWeightKg(workoutSet.weightKg)}kg',
            onPressed: enabled
                ? () async {
                    final value = await _inputNumber(
                      context,
                      title: '重量（kg）',
                      initial: formatWeightKg(workoutSet.weightKg),
                      decimal: true,
                    );
                    if (value != null) onChanged(workoutSet.copyWith(weightKg: value));
                  }
                : null,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: '重量を増やす',
          onPressed: enabled
              ? () => onChanged(workoutSet.copyWith(weightKg: workoutSet.weightKg + _step))
              : null,
        ),
        const Text('×'),
        _StepButton(
          icon: Icons.remove,
          tooltip: '回数を減らす',
          onPressed: enabled && workoutSet.reps > SetInputValidator.minReps
              ? () => onChanged(workoutSet.copyWith(reps: workoutSet.reps - 1))
              : null,
        ),
        Expanded(
          child: _ValueButton(
            label: '${workoutSet.reps}回',
            onPressed: enabled
                ? () async {
                    final value = await _inputNumber(
                      context,
                      title: '回数',
                      initial: '${workoutSet.reps}',
                      decimal: false,
                    );
                    if (value != null) onChanged(workoutSet.copyWith(reps: value.toInt()));
                  }
                : null,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: '回数を増やす',
          onPressed: enabled && workoutSet.reps < SetInputValidator.maxReps
              ? () => onChanged(workoutSet.copyWith(reps: workoutSet.reps + 1))
              : null,
        ),
        SizedBox(
          width: 36,
          child: enabled
              ? IconButton(
                  tooltip: 'セットを削除',
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                )
              : const Center(
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 40),
      onPressed: onPressed,
    );
  }
}

class _ValueButton extends StatelessWidget {
  const _ValueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: const Size(0, 40),
      ),
      onPressed: onPressed,
      // 狭い画面では文字を縮めて 1 行に収める
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}

/// 数値を直接入力するダイアログを開く。キャンセルなら null。
Future<double?> _inputNumber(
  BuildContext context, {
  required String title,
  required String initial,
  required bool decimal,
}) =>
    showDialog<double>(
      context: context,
      builder: (_) => _NumberInputDialog(
        title: title,
        initial: initial,
        decimal: decimal,
      ),
    );

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.initial,
    required this.decimal,
  });

  final String title;
  final String initial;

  /// true：重量（小数可）、false：回数（整数）
  final bool decimal;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  // ダイアログの State が持つので、閉じるアニメーション後に安全に破棄される
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    final String? error;
    if (value == null) {
      error = '数値を入力してください';
    } else if (widget.decimal) {
      error = SetInputValidator.weight(value);
    } else {
      error = value == value.roundToDouble()
          ? SetInputValidator.reps(value.toInt())
          : '回数は整数で入力してください';
    }

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('number_input'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
