import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/date/date_format.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../application/workout_providers.dart';

/// `/workouts/new?date=yyyy-MM-dd`
///
/// その日のワークアウトを取得（なければ作成）し、記録画面 `/workouts/{id}` に置き換える。
class NewWorkoutPage extends ConsumerStatefulWidget {
  const NewWorkoutPage({super.key, this.date});

  /// 実施日（yyyy-MM-dd）。不正・未指定なら当日。
  final String? date;

  @override
  ConsumerState<NewWorkoutPage> createState() => _NewWorkoutPageState();
}

class _NewWorkoutPageState extends ConsumerState<NewWorkoutPage> {
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  void _retry() {
    setState(() => _error = null);
    _open();
  }

  Future<void> _open() async {
    final date = parseYmd(widget.date) ?? dateOnly(DateTime.now());
    try {
      final id =
          await ref.read(workoutRepositoryProvider).findOrCreateByDate(date);
      if (!mounted) return;
      context.replace(AppRoutes.workout(id));
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.message, textAlign: TextAlign.center),
                  ErrorDetailText(error),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _retry, child: const Text('再試行')),
                ],
              ),
      ),
    );
  }
}
