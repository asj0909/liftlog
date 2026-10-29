import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/workout.dart';
import 'package:liftlog/features/workout/domain/workout_set.dart';
import 'package:liftlog/features/workout/presentation/set_format.dart';
import 'package:liftlog/features/workout/presentation/workout_page.dart';

void main() {
  test('formatWeightKg は不要な小数点以下を出さない', () {
    expect(formatWeightKg(60), '60');
    expect(formatWeightKg(0), '0');
    expect(formatWeightKg(62.5), '62.5');
    expect(formatWeightKg(1.25), '1.25');
  });

  test('formatSet は「60kg×10」の形', () {
    expect(formatSet(const WorkoutSet(weightKg: 62.5, reps: 8)), '62.5kg×8');
  });

  group('previousLabel（前回記録の 1 行表示）', () {
    test('記録があれば日付とセットを並べる', () {
      final record = PreviousRecord(
        performedOn: DateTime(2026, 10, 20),
        sets: const [
          WorkoutSet(weightKg: 60, reps: 10),
          WorkoutSet(weightKg: 60, reps: 8),
        ],
      );
      expect(
        previousLabel(AsyncData(record)),
        '前回（10/20）：60kg×10、60kg×8',
      );
    });

    test('記録がない・読み込み中・失敗', () {
      expect(previousLabel(const AsyncData(null)), '前回の記録はありません');
      expect(previousLabel(const AsyncLoading()), '前回の記録を読み込み中…');
      expect(
        previousLabel(AsyncError(Exception('x'), StackTrace.empty)),
        '前回の記録を取得できませんでした',
      );
    });
  });
}
