import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/workout/domain/set_input_validator.dart';

void main() {
  group('weight', () {
    test('0 以上で小数第 2 位までなら OK（0 は自重種目）', () {
      expect(SetInputValidator.weight(0), isNull);
      expect(SetInputValidator.weight(62.5), isNull);
      expect(SetInputValidator.weight(1.25), isNull);
    });

    test('未入力・負の値・上限超え・小数第 3 位以下は NG', () {
      expect(SetInputValidator.weight(null), isNotNull);
      expect(SetInputValidator.weight(-2.5), isNotNull);
      expect(SetInputValidator.weight(10000), isNotNull);
      expect(SetInputValidator.weight(1.125), isNotNull);
    });
  });

  group('reps', () {
    test('1〜999 なら OK', () {
      expect(SetInputValidator.reps(1), isNull);
      expect(SetInputValidator.reps(999), isNull);
    });

    test('未入力・0・1000 以上は NG', () {
      expect(SetInputValidator.reps(null), isNotNull);
      expect(SetInputValidator.reps(0), isNotNull);
      expect(SetInputValidator.reps(1000), isNotNull);
    });
  });
}
