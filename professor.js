(() => {
'use strict';
const $=id=>document.getElementById(id);
const config=window.BNC_CONFIG||{};
let client, dashboardTimer=null, records=[];
const escapeText=(s)=>String(s??'');
function errorMessage(error){return error?.message||String(error)}
function setText(id,text){$(id).textContent=escapeText(text)}
function showDashboard(yes){$('loginPanel').hidden=yes;$('dashboard').hidden=!yes}
function fmtDate(iso){if(!iso)return '—';return new Date(iso).toLocaleString('pt-BR',{dateStyle:'short',timeStyle:'short'})}
async function call(name,args={}){const {data,error}=await client.rpc('bnc_'+name,args);if(error)throw error;return data}
function cell(tr,txt){const td=document.createElement('td');td.textContent=escapeText(txt);tr.append(td)}
function stageLabel(s){return ({waiting:'Aguardando rival',placement:'Posicionamento',rps:'Joquempô',battle:'Em batalha',finished:'Finalizada',cancelled:'Cancelada'})[s]||s}
function renderRooms(){const body=$('roomRows');body.replaceChildren();const filter=$('filter').value;const filtered=records.filter(r=>filter==='all'||(filter==='active'?['waiting','placement','rps','battle'].includes(r.stage):['finished','cancelled'].includes(r.stage)));if(!filtered.length){const tr=document.createElement('tr');const td=document.createElement('td');td.colSpan=6;td.textContent='Nenhuma partida neste filtro.';tr.append(td);body.append(tr);return}for(const room of filtered){const tr=document.createElement('tr');cell(tr,room.code);cell(tr,room.host_name+' × '+(room.guest_name||'Aguardando'));cell(tr,room.host_score+' × '+room.guest_score);cell(tr,stageLabel(room.stage));cell(tr,room.winner_name||'—');cell(tr,fmtDate(room.created_at));body.append(tr)}}
async function loadDashboard(){if($('dashboard').hidden)return;try{const [overview,ranking]=await Promise.all([call('teacher_overview'),call('leaderboard')]);setText('activeRooms',overview.active_rooms);setText('activePlayers',overview.active_players);setText('finishedRooms',overview.finished_rooms);setText('rankSince','Classificação desde '+fmtDate(overview.rank_started_at));records=overview.rooms||[];renderRooms();const body=$('rankRows');body.replaceChildren();if(!ranking?.length){const tr=document.createElement('tr');const td=document.createElement('td');td.colSpan=5;td.textContent='Nenhuma pontuação registrada neste período.';tr.append(td);body.append(tr)}else ranking.forEach((r,i)=>{const tr=document.createElement('tr');[i+1,r.name,r.points,r.wins,r.games].forEach(x=>cell(tr,x));body.append(tr)});setText('synced','✓ Atualizado às '+new Date().toLocaleTimeString('pt-BR'));}catch(e){setText('synced','⚠ '+errorMessage(e));if(/Acesso restrito/.test(errorMessage(e)))await logout()}}
async function logout(){clearInterval(dashboardTimer);dashboardTimer=null;try{await client.auth.signOut()}catch{}showDashboard(false);setText('loginError','');$('password').value=''}
async function login(event){event.preventDefault();$('loginButton').disabled=true;setText('loginError','');try{const {error}=await client.auth.signInWithPassword({email:$('email').value.trim(),password:$('password').value});if(error)throw error;const allowed=await call('is_teacher');if(!allowed){await client.auth.signOut();throw new Error('Essa conta não está cadastrada como professor no banco.')}showDashboard(true);await loadDashboard();clearInterval(dashboardTimer);dashboardTimer=setInterval(loadDashboard,8000)}catch(e){setText('loginError',errorMessage(e))}finally{$('loginButton').disabled=false}}
async function clearRanking(){if(!window.confirm('Deseja iniciar um novo ranking? O histórico das partidas será preservado.'))return;const answer=window.prompt('Para confirmar, digite LIMPAR:');if(answer!=='LIMPAR')return;const b=$('clearRank');b.disabled=true;try{await call('teacher_clear_ranking');await loadDashboard();window.alert('✅ Ranking reiniciado! As partidas antigas continuam guardadas.')}catch(e){window.alert('Não foi possível limpar: '+errorMessage(e))}finally{b.disabled=false}}
try{if(!window.supabase?.createClient)throw new Error('Falha ao carregar o Supabase');if(!config.SUPABASE_URL||!config.SUPABASE_ANON_KEY)throw new Error('Preencha o config.js');
// Sem sessão persistente: a conta do professor não interfere no login anônimo do jogo.
client=window.supabase.createClient(config.SUPABASE_URL,config.SUPABASE_ANON_KEY,{auth:{persistSession:false,autoRefreshToken:true,detectSessionInUrl:false}});
$('loginForm').addEventListener('submit',login);$('logout').addEventListener('click',logout);$('refresh').addEventListener('click',loadDashboard);$('filter').addEventListener('change',renderRooms);$('clearRank').addEventListener('click',clearRanking);
}catch(e){setText('loginError',errorMessage(e))}
})();
