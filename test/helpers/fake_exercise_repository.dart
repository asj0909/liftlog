import 'package:liftlog/features/exercise/domain/exercise.dart';
import 'package:liftlog/features/exercise/domain/exercise_repository.dart';

class FakeExerciseRepository implements ExerciseRepository {
  FakeExerciseRepository(this.exercises);

  final List<Exercise> exercises;

  @override
  Future<List<Exercise>> fetchAll() async => exercises;
}
