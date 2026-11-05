import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/app/user_data_reset.dart';
import 'package:liftlog/features/auth/application/auth_providers.dart';
import 'package:liftlog/features/exercise/application/exercise_manage_controller.dart';
import 'package:liftlog/features/exercise/application/exercise_providers.dart';
import 'package:liftlog/features/exercise/domain/exercise.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_exercise_repository.dart';
import '../helpers/test_data.dart';

void main() {
  const userACustom = Exercise(
    id: 'a-1',
    name: 'A のカスタム種目',
    category: ExerciseCategory.chest,
    userId: 'user-a',
  );
  const userBCustom = Exercise(
    id: 'b-1',
    name: 'B のカスタム種目',
    category: ExerciseCategory.back,
    userId: 'user-b',
  );

  testWidgets('別のアカウントでログインし直すと、前のユーザーの種目を出さない', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    // サーバーは RLS でログイン中のユーザーの種目だけを返す。その振る舞いをまねる
    final exercises = FakeExerciseRepository(const [bench, userACustom]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          exerciseRepositoryProvider.overrideWithValue(exercises),
        ],
        child: MaterialApp(
          home: UserDataReset(
            child: Consumer(
              builder: (context, ref, _) {
                final names = ref
                        .watch(exerciseManageControllerProvider)
                        .value
                        ?.map((e) => e.name)
                        .join(',') ??
                    '';
                return Text(names);
              },
            ),
          ),
        ),
      ),
    );

    await auth.signIn(email: 'a@example.com', password: 'password123');
    await tester.pumpAndSettle();
    expect(find.text('ベンチプレス,A のカスタム種目'), findsOneWidget);

    await auth.signOut();
    exercises.exercises
      ..clear()
      ..addAll(const [bench, userBCustom]);
    await auth.signIn(email: 'b@example.com', password: 'password123');
    await tester.pumpAndSettle();

    expect(find.textContaining('A のカスタム種目'), findsNothing);
    expect(find.text('ベンチプレス,B のカスタム種目'), findsOneWidget);
  });
}
