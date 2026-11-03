import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/router.dart';
import '../../../core/date/date_format.dart';
import '../../../core/date/today_provider.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/widgets/error_snack_bar.dart';
import '../application/workout_providers.dart';
import '../domain/workout_summary.dart';

/// S-03 カレンダー（F-05）。
///
/// 実施日に印を付け、日付を選ぶと下（広い画面では右）にその日の記録を表示する。
/// 記録があればタップで S-04 を開き、なければその日の記録を作成できる。
/// 一覧は S-02 と同じ workoutHistoryProvider を使うので、記録の変更は自動で反映される。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  /// 表示中の月の基準日
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay = ref.read(todayProvider);
  }

  void _select(DateTime selected, DateTime focused) {
    setState(() {
      // table_calendar は UTC の日付を渡すので、時刻なしのローカル日付にそろえる
      _selectedDay = _localDate(selected);
      _focusedDay = _localDate(focused);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(workoutHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: history.when(
        data: (summaries) => _buildBody(context, workoutsByDate(summaries)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryBody(
          error: error,
          onRetry: () => ref.invalidate(workoutHistoryProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<DateTime, List<WorkoutSummary>> byDate,
  ) {
    final calendar = _WorkoutCalendar(
      today: ref.watch(todayProvider),
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      byDate: byDate,
      onDaySelected: _select,
      onPageChanged: (focused) => _focusedDay = _localDate(focused),
    );
    final dayPanel = _DayPanel(
      day: _selectedDay,
      workouts: byDate[_selectedDay] ?? const [],
    );

    final size = WindowSize.fromWidth(MediaQuery.sizeOf(context).width);
    if (size == WindowSize.compact) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [calendar, const Divider(height: 1), dayPanel],
      );
    }
    // 広い画面はカレンダーとその日の記録を左右に並べる
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SingleChildScrollView(child: calendar)),
        const VerticalDivider(width: 1),
        Expanded(child: SingleChildScrollView(child: dayPanel)),
      ],
    );
  }

  static DateTime _localDate(DateTime d) => DateTime(d.year, d.month, d.day);
}

const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

/// カレンダーで戻れる最も古い日：10 年前の 1 月 1 日と、最も古い記録の日のうち早いほう。
///
/// 記録のない過去の日にも記録を作れるように、記録がなくても 10 年前までは戻れるようにする。
DateTime _firstDayOf(Iterable<DateTime> recordedDays, DateTime today) {
  var first = DateTime(today.year - 10);
  for (final day in recordedDays) {
    if (day.isBefore(first)) first = day;
  }
  return first;
}

class _WorkoutCalendar extends StatelessWidget {
  const _WorkoutCalendar({
    required this.today,
    required this.focusedDay,
    required this.selectedDay,
    required this.byDate,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime today;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<WorkoutSummary>> byDate;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TableCalendar<WorkoutSummary>(
      // 未来の日は選べない（lastDay より後は自動で無効になる）
      firstDay: _firstDayOf(byDate.keys, today),
      lastDay: today,
      currentDay: today,
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: (day) =>
          byDate[DateTime(day.year, day.month, day.day)] ?? const [],
      availableCalendarFormats: const {CalendarFormat.month: '月'},
      availableGestures: AvailableGestures.horizontalSwipe,
      // locale を指定すると intl の日本語データの初期化が必要になるため、表示文字列は自前で作る
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, _) => '${date.year}年${date.month}月',
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        dowTextFormatter: (date, _) => _weekdayLabels[date.weekday - 1],
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: colors.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: colors.onPrimaryContainer),
        selectedDecoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: colors.onPrimary),
      ),
      calendarBuilders: CalendarBuilders(
        // 実施日には件数によらず点を 1 つだけ付ける
        markerBuilder: (context, day, events) => events.isEmpty
            ? null
            : Positioned(
                bottom: 6,
                child: Container(
                  key: ValueKey('workout-marker-${formatYmd(day)}'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
      ),
    );
  }
}

/// 選んだ日の記録。記録があれば一覧（タップで S-04）、なければ作成ボタン。
class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.workouts});

  final DateTime day;
  final List<WorkoutSummary> workouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(formatJpDate(day), style: theme.textTheme.titleMedium),
        ),
        if (workouts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('この日の記録はありません'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.push(
                    Uri(
                      path: AppRoutes.newWorkout,
                      queryParameters: {'date': formatYmd(day)},
                    ).toString(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('この日の記録を作成'),
                ),
              ],
            ),
          )
        else
          for (final w in workouts)
            ListTile(
              title: Text(
                w.exerciseNames.join('、'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.workout(w.id)),
            ),
      ],
    );
  }
}
