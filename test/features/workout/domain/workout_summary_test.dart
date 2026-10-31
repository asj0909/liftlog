import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/workout_summary.dart';

void main() {
  group('historyOf', () {
    final oct29 = WorkoutSummary(
      id: 'w29',
      performedOn: DateTime(2026, 10, 29),
      exerciseNames: const ['ベンチプレス'],
    );
    final oct31 = WorkoutSummary(
      id: 'w31',
      performedOn: DateTime(2026, 10, 31),
      exerciseNames: const ['ラットプルダウン', 'ケーブルフライ'],
    );
    final nov1 = WorkoutSummary(
      id: 'w01',
      performedOn: DateTime(2026, 11, 1),
      exerciseNames: const ['ベンチプレス'],
    );

    test('実施日の新しい順に並べる', () {
      expect(historyOf([oct29, nov1, oct31]), [nov1, oct31, oct29]);
    });

    test('種目が 0 件のワークアウトは除く', () {
      final empty =
          WorkoutSummary(id: 'w30', performedOn: DateTime(2026, 10, 30));
      expect(historyOf([oct31, empty, oct29]), [oct31, oct29]);
    });

    test('同じ日の行は元の順序を保つ', () {
      final sameDay = WorkoutSummary(
        id: 'w31b',
        performedOn: DateTime(2026, 10, 31),
        exerciseNames: const ['スクワット'],
      );
      expect(historyOf([oct31, sameDay]), [oct31, sameDay]);
      expect(historyOf([sameDay, oct31]), [sameDay, oct31]);
    });

    test('空の一覧は空のまま', () {
      expect(historyOf(const []), isEmpty);
    });
  });
}
