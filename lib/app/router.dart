import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/app_shell.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/exercise/presentation/exercise_manage_page.dart';
import '../features/progress/presentation/progress_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/workout/presentation/calendar_page.dart';
import '../features/workout/presentation/exercise_picker_page.dart';
import '../features/workout/presentation/home_page.dart';
import '../features/workout/presentation/new_workout_page.dart';
import '../features/workout/presentation/workout_page.dart';

/// ルートのパス定義（基本設計書 6.2）。
abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const calendar = '/calendar';
  static const progress = '/progress';
  static const settings = '/settings';
  static const exercises = '/settings/exercises';
  static const newWorkout = '/workouts/new';
  static String workout(String id) => '/workouts/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refresh = _StreamListenable(authRepository.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      isLoggedIn: authRepository.currentUser != null,
      location: state.uri,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => ProgressPage(
                  exerciseId: state.uri.queryParameters['exercise'],
                  range: state.uri.queryParameters['range'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'exercises',
                    builder: (context, state) => const ExerciseManagePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newWorkout,
        builder: (context, state) => NewWorkoutPage(
          date: state.uri.queryParameters['date'],
        ),
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (context, state) =>
            WorkoutPage(workoutId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'pick-exercise',
            builder: (context, state) => const ExercisePickerPage(),
          ),
        ],
      ),
    ],
  );
});

/// 認証ガード（基本設計書 6.2）。
///
/// 未ログインで保護されたパスに来た場合は `/login?from=元のパス` へ、
/// ログイン済みで `/login` に来た場合は元のパス（なければホーム）へ戻す。
/// 戻り値 null はリダイレクトしないことを表す。
@visibleForTesting
String? authRedirect({required bool isLoggedIn, required Uri location}) {
  final onLogin = location.path == AppRoutes.login;

  if (!isLoggedIn) {
    if (onLogin) return null;
    return Uri(
      path: AppRoutes.login,
      queryParameters: {'from': location.toString()},
    ).toString();
  }

  if (onLogin) {
    final from = location.queryParameters['from'];
    // 外部 URL へのオープンリダイレクトを防ぐため、アプリ内パスのみ許可する
    if (from != null && from.startsWith('/') && !from.startsWith('//')) {
      return from;
    }
    return AppRoutes.home;
  }
  return null;
}

/// Stream のイベントごとに go_router へ再評価を通知する。
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
