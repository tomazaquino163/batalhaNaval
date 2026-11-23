-- EXECUTE SOMENTE ESTA ATUALIZACAO NO SQL EDITOR DO SUPABASE.
-- Nao apaga dados nem modifica o sistema de abandono de partida.
-- Impede vazamento do nome da palavra antes de todos os acertos.

create or replace function public.bnc_state(c text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; me uuid:=auth.uid(); other uuid; own jsonb; shots_out jsonb; ownshots jsonb; pq jsonb:=null; p record; revealed jsonb;
begin
 select * into r from public.bnc_rooms where code=upper(btrim(c));
 if not found or me is null or me not in (r.host,r.guest) then raise exception 'Partida não encontrada para este jogador'; end if;
 if r.stage='placement' and now()>=r.deadline then
  perform public.bnc_tick(r.code);
  select * into r from public.bnc_rooms where code=r.code;
 end if;
 other:=case when me=r.host then r.guest else r.host end;
 select coalesce(jsonb_agg(jsonb_build_object('word',word,'x',x,'y',y,'dir',dir,'hits',hits,'sunk',sunk)),'[]'::jsonb) into own from public.bnc_ships where room_code=r.code and owner=me;
 select coalesce(jsonb_agg(jsonb_build_object('x',x,'y',y,'hit',hit,'letter',letter)),'[]'::jsonb) into shots_out from public.bnc_shots where room_code=r.code and shooter=me;
 select coalesce(jsonb_agg(jsonb_build_object('x',x,'y',y,'hit',hit)),'[]'::jsonb) into ownshots from public.bnc_shots where room_code=r.code and target=me;
 -- Apenas palavras completamente atingidas podem ser vistas pelo atacante.
 select coalesce(jsonb_agg(jsonb_build_object('word',word,'x',x,'y',y,'dir',dir,'sunk',sunk)),'[]'::jsonb)
 into revealed from public.bnc_ships
 where room_code=r.code and owner=other
 and jsonb_array_length(hits)=length(public.bnc_normalize(word));
 if r.pending is not null and r.pending->>'shooter'=me::text then
  select id,question,options into p from public.bnc_questions where id=(r.pending->>'qid')::int;
  pq:=jsonb_build_object('id',p.id,'question',p.question,'options',p.options);
 end if;
 return jsonb_build_object(
 'code',r.code,'stage',r.stage,'deadline',r.deadline,'host',r.host,'guest',r.guest,
 'host_name',r.host_name,'guest_name',r.guest_name,'host_score',r.host_score,'guest_score',r.guest_score,
 'host_ready',r.host_ready,'guest_ready',r.guest_ready,'my_rps',case when me=r.host then r.host_rps else r.guest_rps end,
 'turn_uid',r.turn_uid,'winner',r.winner,'pending',pq,'question_waiting',r.pending is not null,
 'my_ships',own,'my_shots',shots_out,'incoming_shots',ownshots,
 'revealed_enemy_ships',revealed,'last_event',r.last_event);
end; $$;


-- Restringir RPC aos jogadores autenticados (inclusive login anonimo).
revoke all on function public.bnc_state(text) from public, anon;
grant execute on function public.bnc_state(text) to authenticated;
