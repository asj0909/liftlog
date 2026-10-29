import 'package:liftlog/features/exercise/domain/exercise.dart';

/// テストで使う種目
const bench = Exercise(
  id: 'e-bench',
  name: 'ベンチプレス',
  category: ExerciseCategory.chest,
);
const latPulldown = Exercise(
  id: 'e-lat',
  name: 'ラットプルダウン',
  category: ExerciseCategory.back,
);
const cableFly = Exercise(
  id: 'e-fly',
  name: 'ケーブルフライ',
  category: ExerciseCategory.chest,
  userId: 'user-1',
);
