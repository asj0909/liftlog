-- ============================================================
-- アカウント削除（Google Play の「アプリ内アカウント削除」要件）
--
-- ログイン中のユーザー自身を auth.users から削除する。
-- exercises / workouts / workout_exercises / sets は auth.users への
-- ON DELETE CASCADE で一緒に削除される。
--
-- auth.users は authenticated ロールから削除できないため、この関数だけは
-- SECURITY DEFINER とする（基本設計書 5 章の例外）。対象は auth.uid() に固定し、
-- 引数を受け取らないので他人のアカウントは消せない。
-- ============================================================
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  delete from auth.users where id = v_uid;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
