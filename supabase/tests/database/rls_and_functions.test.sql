-- RLS と DB 関数のテスト（基本設計書 8 章 DB テスト）
-- 実行: supabase test db
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(17);

-- ------------------------------------------------------------
-- 準備：ユーザー A / B
-- ------------------------------------------------------------
insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'a@example.com'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'b@example.com');

create temp table ids as
  select id as bench_id from public.exercises where name = 'ベンチプレス' and user_id is null;
grant select on ids to authenticated, anon;

-- ------------------------------------------------------------
-- ユーザー A として記録
-- ------------------------------------------------------------
set local role authenticated;
set local request.jwt.claim.sub = 'aaaaaaaa-0000-0000-0000-000000000001';

select is(
  (select count(*)::int from public.exercises where user_id is null), 14,
  'プリセット種目 14 件が参照できる'
);

insert into public.workouts (id, performed_on) values
  ('11111111-0000-0000-0000-000000000001', '2026-10-20'),
  ('11111111-0000-0000-0000-000000000002', '2026-10-27');
insert into public.workout_exercises (id, workout_id, exercise_id, sort_order) values
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', (select bench_id from ids), 0),
  ('22222222-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002', (select bench_id from ids), 0);
insert into public.sets (workout_exercise_id, sort_order, weight_kg, reps) values
  ('22222222-0000-0000-0000-000000000001', 0, 60, 10),
  ('22222222-0000-0000-0000-000000000001', 1, 60, 8),
  ('22222222-0000-0000-0000-000000000002', 0, 70, 6),
  ('22222222-0000-0000-0000-000000000002', 1, 50, 15);

select results_eq(
  $$ select performed_on, max_weight, est_1rm, total_volume
     from public.get_exercise_progress((select bench_id from ids)) $$,
  $$ values ('2026-10-20'::date, 60.00::numeric, 80.00::numeric, 1080.00::numeric),
            ('2026-10-27'::date, 70.00::numeric, 84.00::numeric, 1170.00::numeric) $$,
  '推移グラフ：日付ごとの最大重量・推定 1RM・総ボリューム'
);

select results_eq(
  $$ select performed_on from public.get_exercise_progress((select bench_id from ids), '2026-10-21') $$,
  $$ values ('2026-10-27'::date) $$,
  '推移グラフ：開始日で期間を絞り込める'
);

select results_eq(
  $$ select weight_kg, reps from public.get_previous_sets((select bench_id from ids), '2026-10-27') $$,
  $$ values (60.00::numeric, 10), (60.00::numeric, 8) $$,
  '前回記録：指定日より前の直近セッションのセットを順番どおり返す'
);

select is(
  public.estimate_one_rep_max(120, 1), 120::numeric,
  '推定 1RM：1 回なら重量そのもの（アプリ側と同じ定義）'
);

select throws_ok(
  $$ insert into public.sets (workout_exercise_id, sort_order, weight_kg, reps)
     values ('22222222-0000-0000-0000-000000000001', 9, -1, 5) $$,
  '23514', null,
  'CHECK：負の重量は登録できない'
);

select lives_ok(
  $$ insert into public.sets (workout_exercise_id, sort_order, weight_kg, reps)
     values ('22222222-0000-0000-0000-000000000001', 9, 0, 12) $$,
  'CHECK：自重種目の 0kg は登録できる'
);

select is_empty(
  $$ update public.exercises set name = 'x' where user_id is null returning id $$,
  'RLS：プリセット種目は変更できない'
);

select lives_ok(
  $$ insert into public.exercises (user_id, name, category) values (auth.uid(), 'ケーブルフライ', 'chest') $$,
  'カスタム種目を追加できる'
);

select throws_ok(
  $$ insert into public.exercises (user_id, name, category) values (auth.uid(), 'ケーブルフライ', 'chest') $$,
  '23505', null,
  'カスタム種目：同じユーザー内で同名は登録できない'
);

-- ------------------------------------------------------------
-- ユーザー B から A のデータにアクセスできないこと
-- ------------------------------------------------------------
set local request.jwt.claim.sub = 'bbbbbbbb-0000-0000-0000-000000000002';

select is(
  (select count(*)::int from public.workouts)
    + (select count(*)::int from public.workout_exercises)
    + (select count(*)::int from public.sets),
  0,
  'RLS：他ユーザーのワークアウト・種目・セットは見えない'
);

select is_empty(
  $$ select * from public.get_exercise_progress((select bench_id from ids)) $$,
  'RLS：集計関数でも他ユーザーの記録は集計されない'
);

select throws_ok(
  $$ insert into public.workout_exercises (workout_id, exercise_id, sort_order)
     values ('11111111-0000-0000-0000-000000000001', (select bench_id from ids), 5) $$,
  '42501', null,
  '所有者チェック：他ユーザーのワークアウトに種目を追加できない'
);

select throws_ok(
  $$ insert into public.workouts (user_id, performed_on)
     values ('aaaaaaaa-0000-0000-0000-000000000001', '2026-10-28') $$,
  '42501', null,
  'RLS：他ユーザーになりすまして登録できない'
);

select is_empty(
  $$ delete from public.workouts returning id $$,
  'RLS：他ユーザーのワークアウトは削除できない'
);

select lives_ok(
  $$ insert into public.exercises (user_id, name, category) values (auth.uid(), 'ケーブルフライ', 'chest') $$,
  'カスタム種目：別ユーザーなら同名でも登録できる'
);

-- ------------------------------------------------------------
-- 未ログイン（anon）
-- ------------------------------------------------------------
set local role anon;
set local request.jwt.claim.sub = '';

select throws_ok(
  $$ select * from public.get_exercise_progress((select bench_id from ids)) $$,
  '42501', null,
  '未ログインでは集計関数を実行できない'
);

select * from finish();
rollback;
