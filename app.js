/* Batalha Naval do Conhecimento — Interface 100% estática + RPCs Supabase. */
(() => {
'use strict';
const WORDS=['CASO DE USO','PROTOTIPACAO','ORIENTADO A OBJETOS','REQUISITOS','INCREMENTAL','DIAGRAMA DE CLASSES','UML','SCRUM','HERANCA','ENCAPSULAMENTO','POLIMORFISMO','BACKLOG','MODELAGEM','ARQUITETURA','TESTES','ATOR','CLASSE','INTERFACE','CASO DE TESTE','SEQUENCIA'];
const N=18, $=id=>document.getElementById(id), norm=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase().replace(/[^A-Z]/g,'');
const cfg=window.BNC_CONFIG||{}; let db=null, uid=null, code='', snapshot=null, entryMode='create', placements=[], selected=WORDS[0], orient='H', busy=false, eventSeen=null, lastStage='', sounds=true, poll=null, toastTimer=null, lastRpsId=null, modalFor=null, questionDelay=null, revealedNotice=null;
function show(id,yes=true){$(id).classList.toggle('hide',!yes)}
function toast(msg){$('toast').textContent=msg;show('toast');clearTimeout(toastTimer);toastTimer=setTimeout(()=>show('toast',false),3200)}
function errText(e){return (e?.message||String(e)).replace(/^Error:\s*/,'')}
function audio(big=false){if(!sounds)return;try{const ctx=new(window.AudioContext||window.webkitAudioContext)();const t=ctx.currentTime;const osc=ctx.createOscillator(),gain=ctx.createGain();osc.type=big?'sawtooth':'triangle';osc.frequency.setValueAtTime(big?125:240,t);osc.frequency.exponentialRampToValueAtTime(big?35:60,t+.32);gain.gain.setValueAtTime(.0001,t);gain.gain.exponentialRampToValueAtTime(big?.24:.12,t+.016);gain.gain.exponentialRampToValueAtTime(.0001,t+.4);osc.connect(gain).connect(ctx.destination);osc.start(t);osc.stop(t+.41);setTimeout(()=>ctx.close().catch(()=>{}),700)}catch{}}
function fx(x,y,big=false){const layer=$('fxLayer');const bomb=document.createElement('div');bomb.className='blast'+(big?' bigblast':'');bomb.textContent=big?'💥':'🔥';bomb.style.left=x+'px';bomb.style.top=y+'px';layer.append(bomb);setTimeout(()=>bomb.remove(),big?1450:800);audio(big)}
function torpedo(cell,big=false){if(!cell)return;const r=cell.getBoundingClientRect();const x=r.left+r.width/2,y=r.top+r.height/2;const el=document.createElement('div');el.className='torpedo';el.textContent='🚀';el.style.left=x+'px';el.style.top=y+'px';$('fxLayer').append(el);setTimeout(()=>{el.remove();cell.classList.add('impact');fx(x,y,big);setTimeout(()=>cell.classList.remove('impact'),550)},560)}
function makeBoard(id,handler){const b=$(id);if(b.children.length===N*N)return;b.innerHTML='';for(let y=0;y<N;y++)for(let x=0;x<N;x++){const el=document.createElement('button');el.type='button';el.className='cell';el.dataset.x=x;el.dataset.y=y;el.title=`Coluna ${x+1}, linha ${y+1}`;el.setAttribute('aria-label',el.title);el.addEventListener('click',()=>handler(x,y));b.append(el)}}
function cell(id,x,y){return $(id).children[y*N+x]}
function occupiedOf(layout){const used=new Map();for(const ship of layout){const w=norm(ship.word);for(let i=0;i<w.length;i++){const x=ship.x+(ship.dir==='H'?i:0),y=ship.y+(ship.dir==='V'?i:0);used.set(`${x},${y}`,{ship,letter:w[i],index:i})}}return used}
function valid(word,x,y,dir,arr=placements){const len=norm(word).length, used=occupiedOf(arr);for(let i=0;i<len;i++){const xx=x+(dir==='H'?i:0),yy=y+(dir==='V'?i:0);if(xx>=N||yy>=N||xx<0||yy<0||used.has(`${xx},${yy}`))return false}return true}
function setupCell(x,y){if(!selected)return toast('Selecione uma palavra da lista.');if(placements.some(p=>p.word===selected))return toast('Essa palavra já está posicionada. Remova-a para mudar.');if(placements.length>=7)return toast('Você já posicionou as sete palavras.');if(!valid(selected,x,y,orient))return toast('Posição inválida: o navio não cabe ou encosta em outra letra.');placements.push({word:selected,x,y,dir:orient});selected=WORDS.find(w=>!placements.some(p=>p.word===w))||null;renderSetup()}
function renderSetup(){const area=$('wordList');area.innerHTML='';for(const word of WORDS){const btn=document.createElement('button');const placed=placements.some(p=>p.word===word);btn.className='word'+(placed?' placed':'')+(selected===word?' active':'');const name=document.createElement('span');name.textContent=word;const count=document.createElement('small');count.textContent=placed?'✓':norm(word).length;btn.append(name,count);btn.title=placed?'Clique para retirar do tabuleiro':'Clique para selecionar';btn.onclick=()=>{if(placed){placements=placements.filter(p=>p.word!==word);selected=word}else selected=word;renderSetup()};area.append(btn)}$('selectedCount').textContent=placements.length+'/7';$('ready').disabled=placements.length!==7;const map=occupiedOf(placements);for(let y=0;y<N;y++)for(let x=0;x<N;x++){const c=cell('setupBoard',x,y),v=map.get(`${x},${y}`);c.className='cell'+(v?' ship':'');c.textContent=v?v.letter:''}}
function autoPlace(){placements=[];const pool=[...WORDS].sort(()=>Math.random()-.5);for(let i=0;i<7;i++)placements.push({word:pool[i],x:0,y:i*2,dir:'H'});selected=null;renderSetup()}
function updateClock(){if(!snapshot||snapshot.stage!=='placement')return;const ms=Math.max(0,new Date(snapshot.deadline).getTime()-Date.now());const sec=Math.ceil(ms/1000);$('countdown').textContent=`${String(Math.floor(sec/60)).padStart(2,'0')}:${String(sec%60).padStart(2,'0')}`;if(sec<=20)$('countdown').style.color='#ff8d8d';else $('countdown').style.color='#7fffe5'}
async function connect(){if(!cfg.SUPABASE_URL?.startsWith('https://')||!cfg.SUPABASE_ANON_KEY||cfg.SUPABASE_ANON_KEY.startsWith('COLE_')){throw new Error('Configure o arquivo config.js com a URL e a chave pública do Supabase. Veja o README.')}if(!window.supabase?.createClient)throw new Error('Não foi possível carregar a biblioteca Supabase. Verifique sua conexão.');db=window.supabase.createClient(cfg.SUPABASE_URL,cfg.SUPABASE_ANON_KEY);let {data:{session},error}=await db.auth.getSession();if(error)throw error;if(!session){const res=await db.auth.signInAnonymously();if(res.error)throw new Error('Ative Anonymous Sign-Ins em Supabase → Authentication → Providers. Detalhes: '+res.error.message);session=res.data.session}uid=session.user.id;return true}
async function rpc(name,params){if(!db)await connect();const {data,error}=await db.rpc('bnc_'+name,params);if(error)throw error;return data}
async function start(mode){entryMode=mode;show('home',false);show('entry');$('entryTitle').textContent=mode==='create'?'⚓ Criar uma nova partida':'🔑 Entrar numa partida existente';$('entryHint').textContent=mode==='create'?'Compartilhe o código gerado com o seu adversário.':'Digite o código recebido do outro comandante.';show('codeGroup',mode==='join');$('entryError').textContent='';$('playerName').focus()}
async function submitEntry(){if(busy)return;const name=$('playerName').value.trim();if(name.length<2){$('entryError').textContent='Informe um nome de pelo menos 2 letras.';return}busy=true;$('entrySubmit').disabled=true;$('entryError').textContent='';try{const c=entryMode==='create'?await rpc('create',{n:name}):await rpc('join',{c:$('roomCode').value.trim().toUpperCase(),n:name});code=c;localStorage.setItem('bnc_last_room',code);show('entry',false);show('home',false);show('game');await refresh(true);clearInterval(poll);poll=setInterval(refresh,1700)}catch(e){$('entryError').textContent=errText(e)}finally{busy=false;$('entrySubmit').disabled=false}}
async function refresh(force=false){if(!code||(busy&&!force))return;try{const s=await rpc('state',{c:code});snapshot=s;renderState(s)}catch(e){console.warn('Erro ao sincronizar:',e);$('connection').textContent='◉ Reconectando...'}}
function renderState(s){$('connection').textContent='◉ Conectado';$('codeView').textContent=s.code;const host=uid===s.host, myName=host?s.host_name:s.guest_name,rival=host?s.guest_name:s.host_name;const myScore=host?s.host_score:s.guest_score,rivalScore=host?s.guest_score:s.host_score;$('meLabel').textContent=myName||'Você';$('rivalLabel').textContent=rival||'Aguardando';$('myScore').textContent=myScore;$('rivalScore').textContent=rivalScore;$('matchStatus').textContent=({waiting:'Aguardando o segundo comandante... Compartilhe o código!',placement:'Organizando frotas: prepare suas sete palavras.',rps:'Joquempô: quem ganha começa!',battle:'Batalha em andamento! Boa sorte, comandante.',finished:'A batalha chegou ao fim!'})[s.stage]||'';
show('abandon',s.stage!=='finished'&&s.stage!=='cancelled');if(s.stage!==lastStage){show('placement',false);show('rps',false);show('battle',false);show('finished',false);lastStage=s.stage}
if(s.stage==='waiting'){$('matchStatus').textContent='Aguardando o segundo comandante... Compartilhe o código!'}
if(s.stage==='placement'){const ready=uid===s.host?s.host_ready:s.guest_ready;show('placement',!ready);if(ready)$('matchStatus').textContent='Sua frota está pronta! Aguardando o colega ou o cronômetro.';if(!ready){makeBoard('setupBoard',setupCell);renderSetup();updateClock()}}
if(s.stage==='rps'){show('rps');const opts=document.querySelectorAll('[data-rps]');opts.forEach(b=>b.disabled=!!s.my_rps);$('rpsMessage').textContent=s.my_rps?'Sua escolha foi registrada. Aguardando o adversário...':'Escolha pedra, papel ou tesoura!'}
if(s.stage==='battle'){show('battle');makeBoard('enemyBoard',(x,y)=>fire(x,y));makeBoard('ownBoard',()=>{});renderBattle(s)}
if(s.stage==='finished'||s.stage==='cancelled'){show('revealBanner',false);show('finished');show('battle',false);const won=s.winner===uid, quit=s.last_event?.type==='abandon';if(s.stage==='cancelled'){$('finishTitle').textContent='⚓ Sala cancelada';$('finishMessage').textContent='A partida foi encerrada antes da entrada de outro comandante.'}else{$('finishTitle').textContent=quit?(won?'🏆 VITÓRIA POR DESISTÊNCIA!':'🐔 VOCÊ ABANDONOU O BARCO!'):(won?'🏆 VITÓRIA, COMANDANTE!':'⚓ FIM DE BATALHA!');$('finishMessage').textContent=`${quit?(won?'Seu adversário abandonou o barco. Vitória concedida a você!':'Você abandonou o barco. A vitória foi concedida ao adversário.'):(won?'Você afundou toda a frota rival!':'O oponente conquistou seu oceano.')} Placar: ${myName} ${myScore} × ${rival||'—'} ${rivalScore}.`}ranking()}
if(s.last_event?.id!==eventSeen){if(eventSeen!==null)handleEvent(s.last_event);eventSeen=s.last_event?.id||null}
if(s.pending&&s.stage==='battle'&&modalFor!==s.pending.id){
  modalFor=s.pending.id;
  clearTimeout(questionDelay);
  // Mostra o navio em chamas antes de abrir a pergunta ao atacante.
  questionDelay=setTimeout(()=>{if(snapshot?.pending?.id===s.pending.id&&snapshot?.stage==='battle')renderQuestion(s.pending)},1900);
}else if(!s.pending){clearTimeout(questionDelay);modalFor=null;show('questionModal',false)}
}
function shipCells(boardId,ship){
 const letters=norm(ship.word),nodes=[];
 for(let i=0;i<letters.length;i++){
  const x=ship.x+(ship.dir==='H'?i:0),y=ship.y+(ship.dir==='V'?i:0);
  const node=cell(boardId,x,y);if(node)nodes.push({node,letter:letters[i]});
 }
 return nodes;
}
function burnShip(boardId,ship){
 for(const {node,letter} of shipCells(boardId,ship)){
  node.textContent=letter;
  node.classList.add('ship-burning');
  node.setAttribute('aria-label',`Navio revelado: ${ship.word}, pegando fogo`);
 }
}
function showRevealedShip(word){
 if(revealedNotice===word)return;
 revealedNotice=word;
 $('revealName').textContent=word;
 show('revealBanner');
 $('revealBanner').classList.remove('reveal-pop');
 void $('revealBanner').offsetWidth;
 $('revealBanner').classList.add('reveal-pop');
 audio(true);
}
function renderBattle(s){
 const mine=occupiedOf(s.my_ships);
 const fired=new Map(s.my_shots.map(a=>[`${a.x},${a.y}`,a]));
 const incoming=new Map(s.incoming_shots.map(a=>[`${a.x},${a.y}`,a]));
 const sunkWords=new Set(s.my_ships.filter(sh=>sh.sunk).map(sh=>sh.word));
 const revealed=s.revealed_enemy_ships||[];
 const myTurn=s.turn_uid===uid&&!s.question_waiting;
 $('turnBadge').textContent=s.question_waiting?(s.pending?'🧠 Responda à pergunta!':'🧠 O oponente está respondendo...'):myTurn?'🎯 SUA VEZ DE ATIRAR':'⌛ Vez do adversário';
 for(let y=0;y<N;y++)for(let x=0;x<N;x++){
  const a=cell('enemyBoard',x,y),b=cell('ownBoard',x,y),shot=fired.get(`${x},${y}`),received=incoming.get(`${x},${y}`),own=mine.get(`${x},${y}`);
  a.className='cell'+(shot?(shot.hit?' hit':' miss'):'');
  a.textContent=shot?.hit?shot.letter||'✓':'';
  a.disabled=!!shot||!myTurn;
  b.className='cell'+(own?' ship':'')+(received?(received.hit?' hit':' miss'):'')+(own&&sunkWords.has(own.ship.word)?' sunk':'');
  b.textContent=own?own.letter:'';b.disabled=true;
 }
 // O estado recebido do servidor nunca contém a posição de palavras incompletas.
 for(const sh of revealed){if(!sh.sunk)burnShip('enemyBoard',sh);else for(const {node,letter} of shipCells('enemyBoard',sh)){node.textContent=letter;node.classList.add('revealed-sunk')}}
 for(const sh of s.my_ships){
  if(!sh.sunk && sh.hits?.length===norm(sh.word).length)burnShip('ownBoard',sh);
 }
 const active=revealed.find(sh=>!sh.sunk)||s.my_ships.find(sh=>!sh.sunk&&sh.hits?.length===norm(sh.word).length);
 if(active){showRevealedShip(active.word)}else{
  revealedNotice=null;show('revealBanner',false);
 }
 $('battleLog').textContent=active?`🔥 NAVIO DESCOBERTO: ${active.word}! ${s.pending?'Responda à questão para ganhar 100 pontos.':'Aguardando a resposta...'}`:myTurn?'🎯 Sua vez! Escolha uma coordenada do oceano inimigo.':s.question_waiting?'🧠 Um desafio está em andamento...':'⏳ Aguarde seu próximo turno.';
}
async function fire(x,y){if(busy||!snapshot||snapshot.stage!=='battle'||snapshot.turn_uid!==uid)return;busy=true;try{await rpc('fire',{c:code,px:x,py:y});await refresh(true)}catch(e){toast(errText(e))}finally{busy=false}}
function handleEvent(ev){if(!ev)return;if(ev.type==='tie'){toast('🤝 Empate no joquempô! Escolham novamente.');return}if(ev.type==='rps'){toast(ev.first===uid?'✊ Você venceu o joquempô! Comece a batalha!':'✋ Seu colega venceu o joquempô.');return}if(ev.type==='shot'){const onEnemy=ev.shooter===uid;const cellEl=cell(onEnemy?'enemyBoard':'ownBoard',ev.x,ev.y);if(cellEl)torpedo(cellEl);toast(ev.hit?(onEnemy?'💥 Você acertou uma letra! +10 pontos':'🔥 Sua frota foi atingida!'):(onEnemy?'🌊 Água! Seu torpedo errou.':'🌊 O adversário errou o tiro.'));return}if(ev.type==='sunk'){
 audio(true);
 const board=$(ev.shooter===uid?'enemyBoard':'ownBoard');
 const area=board.getBoundingClientRect();
 if(area.width&&area.height)fx(area.left+area.width/2,area.top+area.height/2,true);
 show('revealBanner',false);
 toast(ev.correct?`🚢 ${ev.word} afundou! +100 pontos!`:`🚢 ${ev.word} afundou, sem bônus de 100 pontos.`)
}}
function renderQuestion(q){show('questionModal');$('questionText').textContent=q.question;const area=$('answers');area.innerHTML='';q.options.forEach((answer,i)=>{const b=document.createElement('button');b.className='answer';b.textContent=String.fromCharCode(65+i)+') '+answer;b.onclick=()=>answerQuestion(i);area.append(b)})}
async function answerQuestion(choice){if(busy)return;busy=true;document.querySelectorAll('.answer').forEach(b=>b.disabled=true);try{const good=await rpc('answer',{c:code,choice});show('questionModal',false);modalFor=null;clearTimeout(questionDelay);questionDelay=null;toast(good?'✅ Resposta correta! +100 pontos!':'❌ Resposta incorreta: navio afundado, sem bônus.');await refresh(true)}catch(e){toast(errText(e));document.querySelectorAll('.answer').forEach(b=>b.disabled=false)}finally{busy=false}}
async function ranking(){try{const rows=await rpc('leaderboard',{});const area=$('rankList');area.innerHTML='';if(!rows?.length){area.textContent='Nenhuma batalha concluída ainda.';return}rows.forEach((p,i)=>{const d=document.createElement('div');d.className='rankitem';const label=document.createElement('span');label.textContent=`${i===0?'🥇':i===1?'🥈':i===2?'🥉':`${i+1}.`} ${p.name} (${p.wins} vitória${p.wins===1?'':'s'})`;const score=document.createElement('strong');score.textContent=p.points+' pts';d.append(label,score);area.append(d)})}catch(e){console.warn(e)}}
async function restore(){const previous=localStorage.getItem('bnc_last_room');if(!previous)return;try{await connect();const s=await rpc('state',{c:previous});if(s.stage==='finished'||s.stage==='cancelled'){ranking();return}code=previous;snapshot=s;show('home',false);show('game');renderState(s);poll=setInterval(refresh,1700);toast('Partida recuperada!')}catch{localStorage.removeItem('bnc_last_room')}}
async function abandonMatch(){if(busy||!code||!snapshot||['finished','cancelled'].includes(snapshot.stage))return;if(!window.confirm('🐔 Tem certeza que vai abandonar o barco?\n\nO adversário será declarado vencedor e a partida será encerrada!'))return;busy=true;$('abandon').disabled=true;try{await rpc('abandon',{c:code});show('questionModal',false);modalFor=null;clearTimeout(questionDelay);questionDelay=null;await refresh(true);toast('🚢 Partida encerrada.')}catch(e){toast('Não foi possível abandonar: '+errText(e))}finally{busy=false;$('abandon').disabled=false}}
$('abandon').onclick=abandonMatch;
$('create').onclick=()=>start('create');$('join').onclick=()=>start('join');$('back').onclick=()=>{show('entry',false);show('home')};$('entrySubmit').onclick=submitEntry;$('roomCode').oninput=e=>e.target.value=e.target.value.toUpperCase().replace(/[^A-Z0-9]/g,'');$('copy').onclick=async()=>{try{await navigator.clipboard.writeText(code);toast('📋 Código copiado: '+code)}catch{toast('Compartilhe o código: '+code)}};$('sound').onclick=()=>{sounds=!sounds;$('sound').textContent=sounds?'🔊':'🔇'};$('rotate').onclick=()=>{orient=orient==='H'?'V':'H';$('rotate').textContent=orient==='H'?'↻ Horizontal':'↻ Vertical'};$('auto').onclick=autoPlace;$('clear').onclick=()=>{placements=[];selected=WORDS[0];renderSetup()};$('ready').onclick=async()=>{if(busy||placements.length!==7)return;busy=true;try{await rpc('place',{c:code,layout:placements});toast('✅ Frota posicionada!');await refresh(true)}catch(e){toast(errText(e))}finally{busy=false}};document.querySelectorAll('[data-rps]').forEach(b=>b.onclick=async()=>{if(busy)return;busy=true;try{await rpc('rps',{c:code,choice:b.dataset.rps});await refresh(true)}catch(e){toast(errText(e))}finally{busy=false}});$('playAgain').onclick=()=>{localStorage.removeItem('bnc_last_room');location.reload()};$('refreshRank').onclick=ranking;setInterval(updateClock,500);restore().finally(()=>ranking());
})();
