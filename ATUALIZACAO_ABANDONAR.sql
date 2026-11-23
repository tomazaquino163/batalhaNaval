-- ATUALIZAÇÃO INCREMENTAL: executar apenas este arquivo no SQL Editor.
-- Não apague o banco nem execute DROP TABLE.
-- Quem abandona perde; a pessoa restante vence automaticamente.
-- Se não houver adversário, a sala é cancelada sem registrar vitória.
create or replace function public.bnc_abandon(c text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.bnc_rooms%rowtype;
  me uuid := auth.uid();
  rival uuid;
begin
  if me is null then
    raise exception 'Entre na partida antes de abandoná-la';
  end if;
  select * into r from public.bnc_rooms where code = upper(btrim(c)) for update;
  if not found or me not in (r.host, r.guest) then
    raise exception 'Você não participa desta partida';
  end if;
  if r.stage in ('finished','cancelled') then
    raise exception 'Esta partida já foi encerrada';
  end if;
  rival := case when me = r.host then r.guest else r.host end;
  update public.bnc_rooms
  set stage = case when rival is null then 'cancelled' else 'finished' end,
      winner = rival,
      pending = null,
      turn_uid = null,
      deadline = null,
      last_event = jsonb_build_object('id',gen_random_uuid(),
                     'type','abandon','by',me::text,
                     'winner',rival::text)
  where code = r.code;
end;
$$;

-- Permitir esta ação apenas a jogadores autenticados, inclusive login anônimo.
revoke all on function public.bnc_abandon(text) from public, anon;
grant execute on function public.bnc_abandon(text) to authenticated;
