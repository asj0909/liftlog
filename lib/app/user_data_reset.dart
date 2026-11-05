import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/exercise/application/exercise_manage_controller.dart';
import '../features/exercise/application/exercise_providers.dart';
import '../features/progress/application/progress_providers.dart';
import '../features/workout/application/workout_providers.dart';

/// ログイン中のユーザーが変わったとき（ログアウト・別アカウントでのログイン）に、
/// 前のユーザーのデータを持ち続けているかもしれない Provider を作り直させる（QA M-02）。
///
/// autoDispose でない Provider（種目管理）や、画面が残っていて破棄されない Provider が対象。
/// 新しくユーザーごとのデータを持つ Provider を足したら、ここにも加える。
void invalidateUserData(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(exerciseManageControllerProvider);
  invalidate(exercisesProvider);
  invalidate(workoutHistoryProvider);
  invalidate(previousRecordProvider);
  invalidate(exerciseProgressProvider);
}

/// ユーザーが変わったら [invalidateUserData] を呼ぶ。アプリの一番外側に置く。
class UserDataReset extends ConsumerWidget {
  const UserDataReset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      authStateProvider.select((state) => state.value?.id),
      (previous, next) {
        if (previous != next) invalidateUserData(ref.invalidate);
      },
    );
    return child;
  }
}
