/// ログイン中のユーザー。Supabase の User 型を上位レイヤーに漏らさないための値。
class AppUser {
  const AppUser({required this.id, required this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
