-- Execute inteiro em Supabase > SQL Editor. Ative Authentication > Anonymous Sign-Ins.
-- Projetado para uma instalação nova. Tabelas privadas; somente RPCs expostas.
create table if not exists public.bnc_rooms (
 code text primary key, host uuid not null, guest uuid, host_name text not null,
 guest_name text, stage text not null default 'waiting', deadline timestamptz,
 host_ready boolean not null default false, guest_ready boolean not null default false,
 host_rps text, guest_rps text, turn_uid uuid,
 host_score int not null default 0, guest_score int not null default 0,
 pending jsonb, last_event jsonb, winner uuid, created_at timestamptz default now(),
 constraint bnc_code_format check (code ~ '^[A-Z0-9]{6}$')
);
create table if not exists public.bnc_ships (
 room_code text not null references public.bnc_rooms(code) on delete cascade,
 owner uuid not null, word text not null, x int not null, y int not null,
 dir text not null check(dir in ('H','V')), hits jsonb not null default '[]'::jsonb,
 sunk boolean not null default false, primary key(room_code,owner,word)
);
create table if not exists public.bnc_shots (
 room_code text not null references public.bnc_rooms(code) on delete cascade,
 shooter uuid not null, target uuid not null, x int not null, y int not null,
 hit boolean not null, word text, letter text, created_at timestamptz not null default now(),
 primary key(room_code,shooter,x,y)
);
create table if not exists public.bnc_questions (
 id int generated always as identity primary key, question text not null,
 options jsonb not null, correct int not null check(correct between 0 and 3)
);
-- Bloquear acesso direto às tabelas. SECURITY DEFINER valida cada operação.
alter table public.bnc_rooms enable row level security;
alter table public.bnc_ships enable row level security;
alter table public.bnc_shots enable row level security;
alter table public.bnc_questions enable row level security;
revoke all on public.bnc_rooms,public.bnc_ships,public.bnc_shots,public.bnc_questions from anon,authenticated;

insert into public.bnc_questions(question,options,correct) values
('O que é um requisito funcional?','["Uma função que o sistema deve executar","A cor da interface","A velocidade do processador","Uma linguagem de programação"]',0),
('Qual diagrama UML representa atores e funcionalidades?','["Diagrama de classes","Diagrama de casos de uso","Diagrama de objetos","Diagrama de implantação"]',1),
('Qual a finalidade da prototipação?','["Substituir todos os testes","Eliminar os requisitos","Validar ideias e interfaces antes da implementação","Criptografar o banco de dados"]',2),
('Na orientação a objetos, o que é uma classe?','["Uma instância concreta","Um modelo para criar objetos","Um arquivo de texto","Um banco de dados"]',1),
('O que significa UML?','["Universal Machine Logic","Unified Modeling Language","User Management List","Unified Memory Layer"]',1),
('Qual é um exemplo de requisito não funcional?','["Cadastrar cliente","Emitir nota fiscal","Recuperar senha","Responder em até 2 segundos"]',3),
('O que é encapsulamento?','["Ocultar detalhes internos e controlar acesso aos dados","Copiar arquivos","Excluir objetos","Fazer backup automático"]',0),
('O que o modelo incremental propõe?','["Entregar tudo apenas no final","Construir o sistema em entregas sucessivas","Ignorar testes","Não coletar requisitos"]',1),
('Em casos de uso, o ator representa:','["Somente um funcionário","Um usuário ou sistema externo que interage","Uma tabela SQL","Uma classe abstrata"]',1),
('O que é herança em orientação a objetos?','["Reutilizar atributos e comportamentos de outra classe","Apagar métodos","Criar chaves primárias","Ordenar requisitos"]',0),
('O que um diagrama de classes apresenta?','["Somente telas do sistema","Classes, atributos, métodos e relacionamentos","Apenas cronogramas","A topologia de rede"]',1),
('O que é polimorfismo?','["Uma única classe para todo sistema","Diferentes implementações para uma mesma operação","Converter dados em binário","Repetir variáveis"]',1),
('Qual técnica ajuda a levantar requisitos?','["Entrevista com usuários","Formatar o computador","Compactar arquivos","Trocar o monitor"]',0),
('O que são critérios de aceitação?','["Condições verificáveis para considerar uma funcionalidade aceita","Senhas do usuário","Etapas da compilação","A quantidade de telas"]',0),
('O que representa uma associação no diagrama de classes?','["Uma relação entre classes","Um defeito de compilação","Uma conexão Wi-Fi","A exclusão de um objeto"]',0),
('O que é composição em UML?','["Relação todo-parte com forte dependência de ciclo de vida","Uma planilha de custos","Uma consulta SQL","Um requisito não funcional"]',0),
('O objetivo principal dos testes de software é:','["Provar que não há defeitos","Identificar falhas e verificar o comportamento","Evitar documentação","Substituir o cliente"]',1),
('Qual etapa busca entender necessidades dos interessados?','["Levantamento de requisitos","Implantação","Manutenção corretiva","Hospedagem"]',0),
('Um wireframe é:','["Uma estrutura simplificada de uma interface","Um código compilado","Um diagrama de rede","Uma chave estrangeira"]',0),
('O que é uma história de usuário?','["Descrição breve de necessidade sob a perspectiva do usuário","Uma biografia do programador","Um erro de execução","Um comando de banco"]',0),
('Qual princípio busca reduzir a dependência entre módulos?','["Alto acoplamento","Baixo acoplamento","Duplicação de código","Ausência de interfaces"]',1),
('O que é coesão em um módulo?','["Grau em que seus elementos atendem a um propósito comum","Tamanho da tela","Quantidade de computadores","Tempo de instalação"]',0),
('Um diagrama de sequência destaca:','["A ordem temporal das mensagens entre participantes","Somente as cores da tela","Tabela de preços","O hardware disponível"]',0),
('O que é backlog do produto?','["Lista priorizada de trabalhos e necessidades do produto","Relatório de erros do sistema operacional","Diagrama físico de rede","Backup diário"]',0),
('Qual é o propósito da rastreabilidade de requisitos?','["Relacionar requisitos às origens, implementações e testes","Criar animações","Aumentar a memória RAM","Mudar a linguagem"]',0),
('Quem normalmente valida se requisitos atendem às necessidades?','["Partes interessadas e usuários representantes","Somente o compilador","A placa-mãe","O antivírus"]',0),
('O diagrama de atividades é utilizado para:','["Representar fluxos de atividades e decisões","Desenhar tabelas físicas exclusivamente","Mostrar somente atributos","Criptografar documentos"]',0),
('Qual é o objetivo da manutenção corretiva?','["Adicionar um novo recurso","Corrigir defeitos identificados","Alterar a identidade visual","Comprar servidores"]',1),
('O que é um MVP?','["Produto mínimo viável para validar hipóteses","Modelo visual permanente","Matriz de variáveis primárias","Método de versão paralela"]',0),
('Em uma relação 1:N, uma ocorrência de A pode estar ligada a:','["Nenhuma ocorrência de B sempre","Várias ocorrências de B","Exatamente uma ocorrência de B sempre","Somente uma classe abstrata"]',1),
('O que faz um diagrama de estados?','["Mostra estados de um objeto e suas transições","Lista senhas do sistema","Mede velocidade de rede","Exibe apenas o banco de dados"]',0),
('Uma interface em POO geralmente define:','["Um contrato de operações","Um monitor físico","Um arquivo ZIP","Uma senha do sistema"]',0),
('Qual documento pode formalizar requisitos do sistema?','["Especificação de Requisitos de Software","Manual da impressora","Tabela periódica","Mapa topográfico"]',0),
('Em Scrum, uma sprint é:','["Uma iteração com duração definida","Um servidor de banco","Uma classe filha","Uma exceção"]',0),
('O que é refatoração?','["Melhorar a estrutura interna sem alterar o comportamento externo esperado","Desinstalar o programa","Aumentar o escopo sem planejamento","Apagar os testes"]',0),
('Qual é uma vantagem de protótipos de baixa fidelidade?','["Permitem explorar soluções rapidamente e com baixo custo","Já contêm toda a lógica final","Substituem entrevistas","Impedem mudanças"]',0),
('O que representa a cardinalidade de um relacionamento?','["Quantas ocorrências podem se relacionar","O nome das classes","A cor do sistema","O sistema operacional"]',0),
('Uma pré-condição em um caso de uso é:','["Condição que precisa valer antes da execução","Resultado final esperado","Erro de sintaxe","Descrição do hardware"]',0),
('Qual prática envolve validar funcionalidades com usuários?','["Teste de aceitação","Desfragmentação","Compilação cruzada","Minificação CSS"]',0),
('O que é diagrama de componentes?','["Representação de componentes e dependências do sistema","Relação de funcionários","Lista de arquivos temporários","Gráfico de temperaturas"]',0)
on conflict do nothing;

create or replace function public.bnc_words() returns text[] language sql immutable as $$
 select array['CASO DE USO','PROTOTIPACAO','ORIENTADO A OBJETOS','REQUISITOS','INCREMENTAL','DIAGRAMA DE CLASSES','UML','SCRUM','HERANCA','ENCAPSULAMENTO','POLIMORFISMO','BACKLOG','MODELAGEM','ARQUITETURA','TESTES','ATOR','CLASSE','INTERFACE','CASO DE TESTE','SEQUENCIA'];
$$;
create or replace function public.bnc_normalize(t text) returns text language sql immutable as $$
 select regexp_replace(translate(upper(t),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC'),'[^A-Z]','','g');
$$;
-- Validar que as sete palavras cabem e não se cruzam.
create or replace function public.bnc_validate_layout(layout jsonb) returns boolean language plpgsql as $$
declare elem jsonb; w text; posx int; posy int; d text; i int; gx int; gy int; occupied text[] := '{}'; chosen text[] := '{}';
begin
 if jsonb_typeof(layout) <> 'array' or jsonb_array_length(layout) <> 7 then return false; end if;
 for elem in select value from jsonb_array_elements(layout) loop
  if (elem->>'x') !~ '^[0-9]{1,2}$' or (elem->>'y') !~ '^[0-9]{1,2}$' then return false; end if;
  w:=elem->>'word'; posx:=(elem->>'x')::int; posy:=(elem->>'y')::int; d:=elem->>'dir';
  if not (w=any(public.bnc_words())) or w=any(chosen) or d not in ('H','V') then return false; end if;
  chosen:=array_append(chosen,w);
  for i in 0..length(public.bnc_normalize(w))-1 loop
   gx:=posx+case when d='H' then i else 0 end;
   gy:=posy+case when d='V' then i else 0 end;
   if gx not between 0 and 17 or gy not between 0 and 17 then return false; end if;
   if (gx||':'||gy)=any(occupied) then return false; end if;
   occupied:=array_append(occupied,gx||':'||gy);
  end loop;
 end loop;
 return true;
exception when others then return false;
end; $$;

create or replace function public.bnc_autolayout() returns jsonb language plpgsql volatile as $$
declare ws text[] := public.bnc_words(); chosen text[] := '{}'; j int; i int; outj jsonb := '[]'::jsonb; temp text;
begin
 for i in 0..6 loop
  loop j:=1+floor(random()*array_length(ws,1))::int; temp:=ws[j]; exit when not temp=any(chosen); end loop;
  chosen:=array_append(chosen,temp);
  outj:=outj||jsonb_build_array(jsonb_build_object('word',temp,'x',0,'y',i*2,'dir','H'));
 end loop;
 return outj;
end; $$;

create or replace function public.bnc_create(n text) returns text language plpgsql security definer set search_path=public as $$
declare c text; k int:=0;
begin
 if auth.uid() is null then raise exception 'Entre anonimamente primeiro'; end if;
 if length(btrim(n)) not between 2 and 24 then raise exception 'Nome precisa ter 2 a 24 caracteres'; end if;
 loop
  c:=upper(substr(md5(gen_random_uuid()::text),1,6));
  begin insert into public.bnc_rooms(code,host,host_name) values(c,auth.uid(),btrim(n)); exit;
  exception when unique_violation then k:=k+1; if k>5 then raise; end if; end;
 end loop;
 return c;
end; $$;
create or replace function public.bnc_join(c text,n text) returns text language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype;
begin
 if auth.uid() is null then raise exception 'Entre anonimamente primeiro'; end if;
 if length(btrim(n)) not between 2 and 24 then raise exception 'Nome precisa ter 2 a 24 caracteres'; end if;
 select * into r from public.bnc_rooms where code=upper(btrim(c)) for update;
 if not found then raise exception 'Código não encontrado'; end if;
 if r.host=auth.uid() or r.guest=auth.uid() then return r.code; end if;
 if r.guest is not null then raise exception 'Esta sala já tem dois jogadores'; end if;
 update public.bnc_rooms set guest=auth.uid(),guest_name=btrim(n),stage='placement',deadline=now()+interval '150 seconds' where code=r.code;
 return r.code;
end; $$;

-- Cronômetro: após 150 s, o servidor posiciona automaticamente para quem não finalizou.
create or replace function public.bnc_tick(c text) returns void language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; who uuid; arr jsonb; item jsonb;
begin
 select * into r from public.bnc_rooms where code=c for update;
 if not found or r.stage<>'placement' or now()<r.deadline then return; end if;
 if not r.host_ready then
  who:=r.host; arr:=public.bnc_autolayout();
  for item in select value from jsonb_array_elements(arr) loop
   insert into public.bnc_ships(room_code,owner,word,x,y,dir) values(c,who,item->>'word',(item->>'x')::int,(item->>'y')::int,item->>'dir');
  end loop;
 end if;
 if not r.guest_ready then
  who:=r.guest; arr:=public.bnc_autolayout();
  for item in select value from jsonb_array_elements(arr) loop
   insert into public.bnc_ships(room_code,owner,word,x,y,dir) values(c,who,item->>'word',(item->>'x')::int,(item->>'y')::int,item->>'dir');
  end loop;
 end if;
 update public.bnc_rooms set host_ready=true,guest_ready=true,stage='rps' where code=c;
end; $$;

create or replace function public.bnc_place(c text,layout jsonb) returns void language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; item jsonb; me uuid:=auth.uid();
begin
 select * into r from public.bnc_rooms where code=c for update;
 if not found or me is null or me not in (r.host,r.guest) or r.stage<>'placement' then raise exception 'Posicionamento não disponível'; end if;
 if (me=r.host and r.host_ready) or (me=r.guest and r.guest_ready) then raise exception 'Você já confirmou sua frota'; end if;
 if not public.bnc_validate_layout(layout) then raise exception 'Posicione sete palavras válidas, sem sobreposição'; end if;
 for item in select value from jsonb_array_elements(layout) loop
  insert into public.bnc_ships(room_code,owner,word,x,y,dir) values(c,me,item->>'word',(item->>'x')::int,(item->>'y')::int,item->>'dir');
 end loop;
 if me=r.host then update public.bnc_rooms set host_ready=true where code=c;
 else update public.bnc_rooms set guest_ready=true where code=c; end if;
 if (me=r.host and r.guest_ready) or (me=r.guest and r.host_ready) then update public.bnc_rooms set stage='rps' where code=c; end if;
end; $$;

create or replace function public.bnc_rps(c text,choice text) returns void language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; a text; b text; who uuid;
begin
 select * into r from public.bnc_rooms where code=c for update;
 if not found or r.stage<>'rps' or auth.uid() not in (r.host,r.guest) then raise exception 'Joquempô indisponível'; end if;
 if choice not in ('rock','paper','scissors') then raise exception 'Jogada inválida'; end if;
 if auth.uid()=r.host then
  if r.host_rps is not null then raise exception 'Você já escolheu'; end if;
  a:=choice; b:=r.guest_rps;
  update public.bnc_rooms set host_rps=choice where code=c;
 else
  if r.guest_rps is not null then raise exception 'Você já escolheu'; end if;
  a:=r.host_rps; b:=choice;
  update public.bnc_rooms set guest_rps=choice where code=c;
 end if;
 if a is not null and b is not null then
  if a=b then
   update public.bnc_rooms set host_rps=null,guest_rps=null,last_event=jsonb_build_object('id',gen_random_uuid(),'type','tie') where code=c;
  else
   who:=case when (a='rock' and b='scissors') or (a='paper' and b='rock') or (a='scissors' and b='paper') then r.host else r.guest end;
   update public.bnc_rooms set stage='battle',turn_uid=who,last_event=jsonb_build_object('id',gen_random_uuid(),'type','rps','first',who::text) where code=c;
  end if;
 end if;
end; $$;

create or replace function public.bnc_fire(c text,px int,py int) returns void language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; enemy uuid; s record; ch text; idx int; h jsonb; allhit boolean; qid int;
begin
 select * into r from public.bnc_rooms where code=c for update;
 if not found or r.stage<>'battle' or r.pending is not null or r.turn_uid is distinct from auth.uid() then raise exception 'Não é sua vez'; end if;
 if px not between 0 and 17 or py not between 0 and 17 then raise exception 'Coordenada inválida'; end if;
 enemy:=case when r.host=auth.uid() then r.guest else r.host end;
 if enemy is null then raise exception 'Aguardando adversário'; end if;
 if exists(select 1 from public.bnc_shots where room_code=c and shooter=auth.uid() and x=px and y=py) then raise exception 'Você já disparou nesta posição'; end if;
 ch:=null; idx:=null;
 for s in select * from public.bnc_ships where room_code=c and owner=enemy loop
  if s.dir='H' and py=s.y and px between s.x and s.x+length(public.bnc_normalize(s.word))-1 then ch:=s.word; idx:=px-s.x; exit; end if;
  if s.dir='V' and px=s.x and py between s.y and s.y+length(public.bnc_normalize(s.word))-1 then ch:=s.word; idx:=py-s.y; exit; end if;
 end loop;
 insert into public.bnc_shots(room_code,shooter,target,x,y,hit,word,letter) values(c,auth.uid(),enemy,px,py,ch is not null,ch,case when ch is not null then substr(public.bnc_normalize(ch),idx+1,1) else null end);
 if ch is not null then
  select hits into h from public.bnc_ships where room_code=c and owner=enemy and word=ch;
  h:=h||to_jsonb(idx);
  update public.bnc_ships set hits=h where room_code=c and owner=enemy and word=ch;
  if auth.uid()=r.host then update public.bnc_rooms set host_score=host_score+10 where code=c;
  else update public.bnc_rooms set guest_score=guest_score+10 where code=c; end if;
  allhit:=jsonb_array_length(h)=length(public.bnc_normalize(ch));
  if allhit then
   select id into qid from public.bnc_questions order by random() limit 1;
   update public.bnc_rooms set pending=jsonb_build_object('shooter',auth.uid()::text,'target',enemy::text,'word',ch,'qid',qid) where code=c;
  end if;
 end if;
 update public.bnc_rooms set
  turn_uid=case when ch is not null and allhit then turn_uid else enemy end,
  last_event=jsonb_build_object('id',gen_random_uuid(),'type','shot','x',px,'y',py,'hit',ch is not null,'shooter',auth.uid()::text,'target',enemy::text)
 where code=c;
end; $$;

create or replace function public.bnc_answer(c text,choice int) returns boolean language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; correct_answer int; good boolean; enemy uuid; remaining int;
begin
 select * into r from public.bnc_rooms where code=c for update;
 if not found or r.stage<>'battle' or r.pending is null or r.pending->>'shooter' is distinct from auth.uid()::text then raise exception 'Nenhuma pergunta sua está pendente'; end if;
 if choice not between 0 and 3 then raise exception 'Alternativa inválida'; end if;
 select correct into correct_answer from public.bnc_questions where id=(r.pending->>'qid')::int;
 good:=choice=correct_answer; enemy:=(r.pending->>'target')::uuid;
 update public.bnc_ships set sunk=true where room_code=c and owner=enemy and word=r.pending->>'word';
 if good then
  if auth.uid()=r.host then update public.bnc_rooms set host_score=host_score+100 where code=c;
  else update public.bnc_rooms set guest_score=guest_score+100 where code=c; end if;
 end if;
 select count(*) into remaining from public.bnc_ships where room_code=c and owner=enemy and not sunk;
 update public.bnc_rooms set pending=null,turn_uid=enemy,
  stage=case when remaining=0 then 'finished' else 'battle' end,
  winner=case when remaining=0 then auth.uid() else null end,
  last_event=jsonb_build_object('id',gen_random_uuid(),'type','sunk','word',r.pending->>'word','correct',good,'shooter',auth.uid()::text,'target',enemy::text)
 where code=c;
 return good;
end; $$;

create or replace function public.bnc_state(c text) returns jsonb language plpgsql security definer set search_path=public as $$
declare r public.bnc_rooms%rowtype; me uuid:=auth.uid(); other uuid; own jsonb; shots_out jsonb; ownshots jsonb; pq jsonb:=null; p record;
begin
 select * into r from public.bnc_rooms where code=upper(btrim(c));
 if not found or me is null or me not in (r.host,r.guest) then raise exception 'Partida não encontrada para este jogador'; end if;
 if r.stage='placement' and now()>=r.deadline then
  perform public.bnc_tick(r.code);
  select * into r from public.bnc_rooms where code=r.code;
 end if;
 other:=case when me=r.host then r.guest else r.host end;
 select coalesce(jsonb_agg(jsonb_build_object('word',word,'x',x,'y',y,'dir',dir,'hits',hits,'sunk',sunk)),'[]'::jsonb) into own from public.bnc_ships where room_code=r.code and owner=me;
 select coalesce(jsonb_agg(jsonb_build_object('x',x,'y',y,'hit',hit,'word',case when hit then word else null end,'letter',letter)),'[]'::jsonb) into shots_out from public.bnc_shots where room_code=r.code and shooter=me;
 select coalesce(jsonb_agg(jsonb_build_object('x',x,'y',y,'hit',hit)),'[]'::jsonb) into ownshots from public.bnc_shots where room_code=r.code and target=me;
 if r.pending is not null and r.pending->>'shooter'=me::text then
  select id,question,options into p from public.bnc_questions where id=(r.pending->>'qid')::int;
  pq:=jsonb_build_object('id',p.id,'question',p.question,'options',p.options);
 end if;
 return jsonb_build_object(
 'code',r.code,'stage',r.stage,'deadline',r.deadline,'host',r.host,'guest',r.guest,
 'host_name',r.host_name,'guest_name',r.guest_name,'host_score',r.host_score,'guest_score',r.guest_score,
 'host_ready',r.host_ready,'guest_ready',r.guest_ready,'my_rps',case when me=r.host then r.host_rps else r.guest_rps end,
 'turn_uid',r.turn_uid,'winner',r.winner,'pending',pq,'question_waiting',r.pending is not null,
 'my_ships',own,'my_shots',shots_out,'incoming_shots',ownshots,'last_event',r.last_event);
end; $$;

create or replace function public.bnc_leaderboard() returns jsonb language sql security definer set search_path=public as $$
 with scored as (
 select host_name as name,host_score as score,(winner=host) as won from public.bnc_rooms where stage='finished'
 union all
 select guest_name as name,guest_score as score,(winner=guest) as won from public.bnc_rooms where stage='finished' and guest is not null
 ), grouped as (
 select name,sum(score)::int as points,count(*)::int as games,count(*) filter(where won)::int as wins from scored group by name order by points desc,wins desc limit 15
 ) select coalesce(jsonb_agg(jsonb_build_object('name',name,'points',points,'games',games,'wins',wins)),'[]'::jsonb) from grouped;
$$;

-- Apenas funções RPC podem ser invocadas pelo usuário autenticado anonimamente.
revoke execute on function public.bnc_words(),public.bnc_normalize(text),public.bnc_validate_layout(jsonb),public.bnc_autolayout(),public.bnc_tick(text) from public,anon,authenticated;
revoke execute on function public.bnc_create(text),public.bnc_join(text,text),public.bnc_place(text,jsonb),public.bnc_rps(text,text),public.bnc_fire(text,int,int),public.bnc_answer(text,int),public.bnc_state(text),public.bnc_leaderboard() from public,anon;
grant execute on function public.bnc_create(text),public.bnc_join(text,text),public.bnc_place(text,jsonb),public.bnc_rps(text,text),public.bnc_fire(text,int,int),public.bnc_answer(text,int),public.bnc_state(text),public.bnc_leaderboard() to authenticated;
