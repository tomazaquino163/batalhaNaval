-- BATALHA NAVAL DO CONHECIMENTO — PAINEL DO PROFESSOR
-- Execute UMA VEZ no SQL Editor do Supabase.
-- A classificação é zerada por data de corte; o histórico das partidas permanece.

create table if not exists public.bnc_teacher_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.bnc_rank_control (
  id integer primary key check (id = 1),
  started_at timestamptz not null default '2000-01-01 00:00:00+00'
);
insert into public.bnc_rank_control(id, started_at) values (1,'2000-01-01 00:00:00+00')
on conflict (id) do nothing;

alter table public.bnc_teacher_admins enable row level security;
alter table public.bnc_rank_control enable row level security;
revoke all on public.bnc_teacher_admins,public.bnc_rank_control from anon,authenticated;

-- Confirma autorização no servidor: não confia em parâmetros enviados pelo navegador.
create or replace function public.bnc_is_teacher() returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and exists(
    select 1 from public.bnc_teacher_admins a where a.user_id=auth.uid()
  );
$$;

-- Atualiza a função pública de ranking para respeitar o último reinício.
create or replace function public.bnc_leaderboard() returns jsonb
language sql stable security definer set search_path = public as $$
 with scored as (
   select host_name as name,host_score as score,(winner=host) as won
   from public.bnc_rooms
   where stage='finished' and created_at >= (select started_at from public.bnc_rank_control where id=1)
   union all
   select guest_name as name,guest_score as score,(winner=guest) as won
   from public.bnc_rooms
   where stage='finished' and guest is not null and created_at >= (select started_at from public.bnc_rank_control where id=1)
 ), grouped as (
   select name,sum(score)::int as points,count(*)::int as games,
          count(*) filter (where won)::int as wins
   from scored group by name order by points desc,wins desc limit 15
 ) select coalesce(jsonb_agg(jsonb_build_object(
    'name',name,'points',points,'games',games,'wins',wins)), '[]'::jsonb)
 from grouped;
$$;

-- Retorna somente dados de supervisão, nunca coordenadas dos navios ou gabaritos.
create or replace function public.bnc_teacher_overview() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare result jsonb;
begin
 if not public.bnc_is_teacher() then raise exception 'Acesso restrito ao professor'; end if;
 select jsonb_build_object(
   'rank_started_at',(select started_at from public.bnc_rank_control where id=1),
   'active_rooms',(select count(*) from public.bnc_rooms where stage in ('waiting','placement','rps','battle')),
   'active_players',(select coalesce(sum(1 + case when guest is not null then 1 else 0 end),0)
       from public.bnc_rooms where stage in ('waiting','placement','rps','battle')),
   'finished_rooms',(select count(*) from public.bnc_rooms where stage='finished'),
   'rooms',coalesce((
      select jsonb_agg(jsonb_build_object(
        'code',t.code,'host_name',t.host_name,'guest_name',t.guest_name,
        'host_score',t.host_score,'guest_score',t.guest_score,
        'stage',t.stage,'winner_name',case when t.winner=t.host then t.host_name
                                    when t.winner=t.guest then t.guest_name else null end,
        'created_at',t.created_at) order by t.created_at desc)
      from (select * from public.bnc_rooms order by created_at desc limit 100) t
   ),'[]'::jsonb)
 ) into result;
 return result;
end;
$$;

-- Reset lógico (não elimina partida, pontuação armazenada ou usuários).
create or replace function public.bnc_teacher_clear_ranking() returns timestamptz
language plpgsql volatile security definer set search_path = public as $$
declare t timestamptz;
begin
 if not public.bnc_is_teacher() then raise exception 'Acesso restrito ao professor'; end if;
 t := clock_timestamp();
 update public.bnc_rank_control set started_at=t where id=1;
 return t;
end;
$$;

revoke all on function public.bnc_is_teacher(), public.bnc_teacher_overview(),
  public.bnc_teacher_clear_ranking() from public,anon,authenticated;
grant execute on function public.bnc_is_teacher(),public.bnc_teacher_overview(),
  public.bnc_teacher_clear_ranking() to authenticated;
revoke all on function public.bnc_leaderboard() from public,anon;
grant execute on function public.bnc_leaderboard() to authenticated;

-- PASSO FINAL, APÓS CRIAR A CONTA DE PROFESSOR EM AUTHENTICATION > USERS:
-- 1) Copie o UUID da conta (não é a chave de API do projeto).
-- 2) Execute separadamente, substituindo pelo UUID verdadeiro:
-- insert into public.bnc_teacher_admins(user_id) values ('UUID_DA_CONTA_DO_PROFESSOR');
