/// 部位カテゴリ。`dbValue` は exercises.category の CHECK 制約と一致させる。
enum ExerciseCategory {
  chest('chest', '胸'),
  back('back', '背中'),
  legs('legs', '脚'),
  shoulders('shoulders', '肩'),
  arms('arms', '腕'),
  core('core', '体幹'),
  other('other', 'その他');

  const ExerciseCategory(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ExerciseCategory fromDb(String value) => values.firstWhere(
        (c) => c.dbValue == value,
        orElse: () => ExerciseCategory.other,
      );
}

/// 種目（F-02）。userId が null のものはプリセット。
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.userId,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final String? userId;

  bool get isPreset => userId == null;

  @override
  bool operator ==(Object other) =>
      other is Exercise &&
      other.id == id &&
      other.name == name &&
      other.category == category &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(id, name, category, userId);
}
