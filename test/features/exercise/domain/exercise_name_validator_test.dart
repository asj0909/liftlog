import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/features/exercise/domain/exercise_name_validator.dart';

import '../../../helpers/test_data.dart';

void main() {
  const existing = [bench, cableFly];

  String? validate(String? value, {String? editingId}) =>
      ExerciseNameValidator.validate(
        value,
        existing: existing,
        editingId: editingId,
      );

  test('空・空白だけはエラー', () {
    expect(validate(null), '種目名を入力してください');
    expect(validate('   '), '種目名を入力してください');
  });

  test('50 文字までは OK、51 文字はエラー（前後の空白は数えない）', () {
    expect(validate(' ${'あ' * 50} '), isNull);
    expect(validate('あ' * 51), '種目名は50文字以内で入力してください');
  });

  test('プリセットと同じ名前はエラー', () {
    expect(validate('ベンチプレス'), '同じ名前のプリセット種目があります');
  });

  test('自分の種目と同じ名前はエラー（前後の空白は無視して比べる）', () {
    expect(validate(' ケーブルフライ '), '同じ名前の種目がすでに登録されています');
  });

  test('編集中の種目自身とは重複扱いしない', () {
    expect(validate('ケーブルフライ', editingId: cableFly.id), isNull);
  });

  test('新しい名前は OK', () {
    expect(validate('ペックデック'), isNull);
  });

  test('normalize は前後の空白を除く', () {
    expect(ExerciseNameValidator.normalize('  ペックデック '), 'ペックデック');
    expect(ExerciseNameValidator.normalize(null), '');
  });
}
