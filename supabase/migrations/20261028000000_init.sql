-- LiftLog 初期スキーマ（基本設計書 5 章）

-- ============================================================
-- 共通：updated_at 自動更新トリガー
-- ============================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- exercises（種目）。user_id が null のものはプリセット
-- ============================================================
create table public.exercises (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 50),
  category    text not null check (
                category in ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'other')
              ),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 同一ユーザー内で同名の種目を禁止（NULL 同士も重複とみなす = プリセット名の重複も禁止）
create unique index exercises_user_name_key
  on public.exercises (coalesce(user_id, '00000000-0000-0000-0000-000000000000'::uuid), name);

-- ============================================================
-- workouts（ワークアウト）
-- ============================================================
create table public.workouts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  performed_on  date not null,
  memo          text check (memo is null or char_length(memo) <= 500),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index workouts_user_performed_on_idx
  on public.workouts (user_id, performed_on desc);

-- ============================================================
-- workout_exercises（ワークアウト種目）
-- user_id は RLS 判定用に非正規化（基本設計書 5.2 設計判断）
-- ============================================================
create table public.workout_exercises (
  id           uuid primary key default gen_random_uuid(),
  workout_id   uuid not null references public.workouts (id) on delete cascade,
  exercise_id  uuid not null references public.exercises (id) on delete cascade,
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sort_order   integer not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index workout_exercises_workout_idx
  on public.workout_exercises (workout_id, sort_order);
create index workout_exercises_exercise_idx
  on public.workout_exercises (exercise_id);

-- ============================================================
-- sets（セット）
-- ============================================================
create table public.sets (
  id                   uuid primary key default gen_random_uuid(),
  workout_exercise_id  uuid not null references public.workout_exercises (id) on delete cascade,
  user_id              uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sort_order           integer not null,
  weight_kg            numeric(6, 2) not null check (weight_kg >= 0),
  reps                 integer not null check (reps between 1 and 999),
  memo                 text check (memo is null or char_length(memo) <= 200),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index sets_workout_exercise_idx
  on public.sets (workout_exercise_id, sort_order);

-- ============================================================
-- updated_at トリガー
-- ============================================================
create trigger exercises_set_updated_at before update on public.exercises
  for each row execute function public.set_updated_at();
create trigger workouts_set_updated_at before update on public.workouts
  for each row execute function public.set_updated_at();
create trigger workout_exercises_set_updated_at before update on public.workout_exercises
  for each row execute function public.set_updated_at();
create trigger sets_set_updated_at before update on public.sets
  for each row execute function public.set_updated_at();

-- ============================================================
-- 親子の所有者整合性チェック
-- RLS だけでは「他人の workout に自分の workout_exercise を付ける」ことを防げないため、
-- 親行の user_id と一致することを挿入・更新時に確認する。
-- ============================================================
create or replace function public.check_workout_exercise_owner()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.workouts w
    where w.id = new.workout_id and w.user_id = new.user_id
  ) then
    raise exception 'workout does not belong to user' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.exercises e
    where e.id = new.exercise_id and (e.user_id is null or e.user_id = new.user_id)
  ) then
    raise exception 'exercise does not belong to user' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger workout_exercises_check_owner
  before insert or update on public.workout_exercises
  for each row execute function public.check_workout_exercise_owner();

create or replace function public.check_set_owner()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1 from public.workout_exercises we
    where we.id = new.workout_exercise_id and we.user_id = new.user_id
  ) then
    raise exception 'workout_exercise does not belong to user' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger sets_check_owner
  before insert or update on public.sets
  for each row execute function public.check_set_owner();

-- ============================================================
-- テーブル権限
-- 「新しいテーブルを自動で API に公開」設定に依存しないよう明示的に付与する。
-- 未ログイン（anon）には一切付与しない。行単位の制御は下の RLS で行う。
-- ============================================================
revoke all on public.exercises, public.workouts, public.workout_exercises, public.sets
  from anon;
grant select, insert, update, delete
  on public.exercises, public.workouts, public.workout_exercises, public.sets
  to authenticated;

-- ============================================================
-- RLS（基本設計書 5.3）
-- ============================================================
alter table public.exercises         enable row level security;
alter table public.workouts          enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.sets              enable row level security;

-- exercises：プリセットは全員が参照可。変更は自分の種目のみ
create policy exercises_select on public.exercises
  for select to authenticated
  using (user_id is null or user_id = (select auth.uid()));
create policy exercises_insert on public.exercises
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy exercises_update on public.exercises
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy exercises_delete on public.exercises
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- 自分の行のみ全操作可
create policy workouts_owner on public.workouts
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy workout_exercises_owner on public.workout_exercises
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy sets_owner on public.sets
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ============================================================
-- DB 関数（基本設計書 5.4）。SECURITY INVOKER なので RLS がそのまま効く
-- ============================================================

-- 推定 1RM（Epley 式）。アプリ側 TrainingMetrics.estimateOneRepMax と同じ定義
create or replace function public.estimate_one_rep_max(p_weight_kg numeric, p_reps integer)
returns numeric
language sql
immutable
as $$
  select case
    when p_weight_kg <= 0 or p_reps <= 0 then 0
    when p_reps = 1 then p_weight_kg
    else p_weight_kg * (1 + p_reps / 30.0)
  end;
$$;

-- F-06 推移グラフ：実施日ごとの最大重量・推定 1RM・総ボリューム
create or replace function public.get_exercise_progress(
  p_exercise_id uuid,
  p_from date default null
)
returns table (
  performed_on date,
  max_weight numeric,
  est_1rm numeric,
  total_volume numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    w.performed_on,
    max(s.weight_kg)                                         as max_weight,
    round(max(public.estimate_one_rep_max(s.weight_kg, s.reps)), 2) as est_1rm,
    sum(s.weight_kg * s.reps)                                as total_volume
  from public.sets s
  join public.workout_exercises we on we.id = s.workout_exercise_id
  join public.workouts w           on w.id = we.workout_id
  where we.exercise_id = p_exercise_id
    and (p_from is null or w.performed_on >= p_from)
  group by w.performed_on
  order by w.performed_on;
$$;

-- F-04 前回記録：指定日より前で、その種目を行った直近のセッションのセット一覧
create or replace function public.get_previous_sets(
  p_exercise_id uuid,
  p_before date
)
returns table (
  performed_on date,
  sort_order integer,
  weight_kg numeric,
  reps integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  with last_session as (
    select we.id, w.performed_on
    from public.workout_exercises we
    join public.workouts w on w.id = we.workout_id
    where we.exercise_id = p_exercise_id
      and w.performed_on < p_before
    order by w.performed_on desc, we.created_at desc
    limit 1
  )
  select ls.performed_on, s.sort_order, s.weight_kg, s.reps
  from last_session ls
  join public.sets s on s.workout_exercise_id = ls.id
  order by s.sort_order;
$$;

-- anon（未ログイン）には関数も実行させない
revoke execute on function public.get_exercise_progress(uuid, date) from public, anon;
revoke execute on function public.get_previous_sets(uuid, date) from public, anon;
grant execute on function public.get_exercise_progress(uuid, date) to authenticated;
grant execute on function public.get_previous_sets(uuid, date) to authenticated;
