# ⚓ Batalha Naval do Conhecimento

**Análise e Projeto de Sistemas — Professor Tomaz Machado de Aquino**

Jogo educacional online para **dois jogadores em aparelhos diferentes**, hospedado no GitHub Pages, com banco de dados no Supabase. Visual responsivo, efeitos de explosões, 20 conceitos, 40 questões, joquempô, sala por código, cronômetro de 2min30 e ranking.

## Instalação (uma vez)

1. Crie um projeto gratuito em https://supabase.com e abra **SQL Editor > New query**. Copie o conteúdo inteiro de `database.sql`, execute e verifique que não houve erro. **Execute uma única vez**: o arquivo contém a carga das questões e rodá-lo novamente pode duplicá-las.
2. Em **Authentication > Providers**, habilite **Anonymous Sign-Ins**. Isso identifica os dois navegadores sem pedir e-mail ou senha. Não é apenas o papel SQL `anon`.
3. No Supabase, abra **Project Settings > API** (ou **Connect**) e copie a **Project URL** e a chave pública **publishable / anon**. Abra `config.js`, substitua os dois textos `COLE_AQUI_...` e salve. **Nunca use `service_role` ou `secret key` no site.**
4. Crie um repositório público no GitHub, por exemplo `batalha-naval-conhecimento`, e envie `index.html`, `style.css`, `app.js`, `config.js`, `database.sql` e `README.md`.
5. Vá em **Settings > Pages > Build and deployment > Deploy from a branch**, escolha `main` e a pasta `/ (root)` e salve. A URL será semelhante a `https://SEU-USUARIO.github.io/batalha-naval-conhecimento/`.
6. Abra essa URL em **dois navegadores diferentes** (ou duas janelas anônimas independentes). Jogador 1 cria uma sala, jogador 2 entra com o código de seis caracteres.

> Para abrir localmente, use um servidor HTTP simples (por exemplo, a extensão Live Server do VS Code) em vez de abrir `file://`.

## Regras

- 18×18 células. Cada comandante escolhe **7 palavras** entre 20 e posiciona horizontal/verticalmente (letras contínuas, sem cruzamentos). Você pode clicar numa palavra já posicionada para retirá-la.
- Depois que o segundo jogador entrar, o cronômetro começa: **150 segundos**. Se terminar, o servidor organiza automaticamente os navios de quem não finalizou.
- Ambos escolhem **pedra, papel ou tesoura**; empate gera uma nova rodada. O vencedor dispara primeiro.
- Tiros são alternados. **Acerto: +10 pontos** por letra; erro: 0. A tela adversária esconde os navios não atingidos.
- Ao atingir todas as letras de uma palavra, surge uma pergunta aleatória de múltipla escolha **somente para o atacante**. Acertou: navio afunda e **+100 pontos**. Errou: navio afunda sem bônus. Depois, passa a vez.
- Vence quem afundar os **sete** navios adversários. O ranking soma pontos e vitórias de partidas finalizadas, agrupando por nome digitado.

## Arquitetura e segurança

- O **GitHub Pages** apenas hospeda HTML/CSS/JS. Para compartilhar salas, manter turnos e validar respostas usa-se **Supabase PostgreSQL**. O navegador consulta o estado em intervalos de ~1,7 s.
- O banco mantém as posições dos navios do oponente e os gabaritos **privados**; o navegador acessa apenas funções `bnc_*` que verificam autenticação, identidade e estado da partida.
- As tabelas têm **RLS ativada sem políticas de leitura/escrita direta**; os movimentos passam por funções SQL `SECURITY DEFINER` que validam turno, coordenadas, posicionamento e acertos. Use projeto Supabase exclusivo ou revise o SQL antes de executar numa base já em produção.
- Ranking é público para qualquer usuário autenticado anonimamente; oriente os alunos a usar **apelidos** em vez de nomes completos. Há limite lógico de 2 jogadores por sala. O jogo não fornece sistema de moderação ou proteção contra criação automatizada massiva de salas. Para uso escolar em grande escala, acrescente rate limiting, limpeza de salas antigas e política de retenção.

## Personalização

- `app.js`: constante `WORDS` contém as 20 palavras.
- `database.sql`: função `bnc_words()` precisa ter **exatamente as mesmas palavras**. Todas as palavras devem ter no máximo 18 letras sem espaços/acentos.
- `database.sql`: tabela `bnc_questions` contém as perguntas, as quatro opções e o índice correto (0=A, 1=B, 2=C, 3=D). Para mudar perguntas após a instalação, edite diretamente a tabela no Supabase ou crie uma migração.
- `style.css`: cores, tipografia, efeitos da água e explosões. `index.html`: títulos e créditos.

## Limitações da primeira versão

- Não possui chat, múltiplos espectadores, antitrapaça avançado, convites por QR code nem limite de tempo para **responder** à questão.
- Se os dois alunos usarem o mesmo perfil de navegador e a mesma sessão Supabase, serão tratados como a mesma pessoa. Teste em dispositivos/perfis diferentes.
- O ranking agrupa por **nome exibido**, então apelidos iguais compartilham pontuação. Em uma versão com contas definitivas, substitua por IDs de usuário.
- Efeitos sonoros são sintetizados pelo navegador via Web Audio (sem MP3 externo), portanto alguns navegadores só reproduzem som depois do primeiro clique.
