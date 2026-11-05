import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session/current_user_id.dart';
import '../features/auth/application/auth_providers.dart';

/// 認証状態の変化を [currentUserIdProvider] に伝える。アプリの一番外側に置く。
///
/// ユーザーごとのデータを持つ Provider は currentUserIdProvider を watch しているので、
/// ユーザーが変わるとまとめて作り直される（QA M-02）。
class UserDataReset extends ConsumerWidget {
  const UserDataReset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(
      authStateProvider.select((state) => state.value?.id),
      (previous, next) => ref.read(currentUserIdProvider.notifier).set(next),
    );
    return child;
  }
}
