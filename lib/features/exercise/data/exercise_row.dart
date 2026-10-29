import '../domain/exercise.dart';

/// exercises テーブルの 1 行 → Exercise
Exercise exerciseFromRow(Map<String, dynamic> row) => Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      category: ExerciseCategory.fromDb(row['category'] as String),
      userId: row['user_id'] as String?,
    );
