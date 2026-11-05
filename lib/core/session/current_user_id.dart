import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ログイン中のユーザー id（未ログインは null）。
///
/// ユーザーごとのデータを持つ Provider はこれを watch する。ユーザーが変わると
/// （ログアウト・別アカウントでのログイン）作り直され、再取得中は読み込み中の表示になるので、
/// 前のユーザーのデータが画面に残らない（QA M-02）。
/// 値は app/user_data_reset.dart の UserDataReset が認証状態に合わせて更新する。
/// 認証（Supabase）に直接依存させないのは、テストで差し替えずに使えるようにするため。
final currentUserIdProvider =
    NotifierProvider<CurrentUserId, String?>(CurrentUserId.new);

class CurrentUserId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
