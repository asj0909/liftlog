-- ============================================================
-- F-04 前回記録：セットが 1 件もない種目エントリは「前回」とみなさない
--
-- 種目を追加しただけでセットを記録しなかった日があると、その日が直近のセッションになり、
-- 前回記録が 0 件（表示なし）になっていた（QA M-03）。
-- ============================================================
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
      and exists (select 1 from public.sets s where s.workout_exercise_id = we.id)
    order by w.performed_on desc, we.created_at desc
    limit 1
  )
  select ls.performed_on, s.sort_order, s.weight_kg, s.reps
  from last_session ls
  join public.sets s on s.workout_exercise_id = ls.id
  order by s.sort_order;
$$;

-- create or replace では権限が保たれるが、念のため明示する
revoke execute on function public.get_previous_sets(uuid, date) from public, anon;
grant execute on function public.get_previous_sets(uuid, date) to authenticated;
