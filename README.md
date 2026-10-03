# Arena Rush — protótipo 3D

## Baixar a beta para Windows

[Baixar beta 0.1.0 (Windows 64 bits)](https://github.com/Theuus12/chaosboundprototipe/releases/download/v0.1.0-beta/Chaosbound-Beta-0.1.0-Windows-x64.zip).

Extraia o ZIP e abra `Chaosbound-Beta.exe`. Nao e necessario instalar a Godot. A beta usa arte provisoria e balanceamento experimental. Controles e requisitos estao no `LEIA-ME.txt` incluido. O executavel ainda nao possui assinatura digital.

O preset `export_presets.cfg` exporta para Windows x86_64 com os dados embutidos no EXE. Para reproduzir, use a Godot 4.7.2 e coloque o template oficial `windows_release_x86_64.exe` em `tools/templates/`. Execute `Godot --headless --path . --export-release "Windows Beta" builds/beta/Chaosbound-Beta.exe`. Crie antes a pasta de destino. Binarios ficam em `builds/`, fora do historico Git; downloads sao distribuidos nas Releases.

## Interface e controles atuais

Sobrevivencia atual: contador de 10 minutos no topo, depois tempo extra. Aos 15 minutos de partida, vida e dano dos monstros ficam em 2x; aos 20, 4x; aos 25, 8x. Monstros comecam a metade da velocidade base do jogador (4,5 m/s), e dificuldade/tempo aumentam ate o limite da velocidade base do jogador (9 m/s), sem incluir buff de movimento. Monstros atuais e futuros recebem a escala. Esc mostra todos os atributos nos slots das armas; Ctrl + clique aumenta todos os atributos locais em +1 e o nivel em um. `APRESENTACAO_LINKEDIN.txt` traz contexto para gerar uma apresentacao curta do projeto.

Sequencias atuais: flechas e cortes adicionais saem em sequencia com intervalo de ate 0,15 s (reduzido quando necessario pela velocidade de ataque). Flechas atualizam origem/alvo a cada disparo e priorizam monstros diferentes. Arma nova recebe um atributo aleatorio pela raridade; melhorias posteriores sorteiam dois. Todos os atributos existem desde o inicio e aparecem nos status/detalhes do item no Esc, mesmo com bonus zero. Corte agora possui quantidade de cortes, velocidade, dano e area; arco possui velocidade, quantidade e dano; aura possui area, velocidade e dano. Passe o mouse no item para ver todos os bonus locais. `tests/weapon_sequence.gd` verifica sequencia e primeira escolha.

Slots de itens: Arco ocupa sempre o primeiro; Corte e Aura ocupam o proximo slot livre ao desbloquear, e melhorias repetidas nao ocupam outro slot. Ima usado ocupa um slot de registro e atualiza a contagem no mesmo slot. Aura agora sorteia dois entre area, velocidade de ataque e dano. Acerta imediatamente um inimigo novo ao entrar no alcance; acertos seguintes respeitam intervalo por inimigo de 1 / (1 + bonus de velocidade/100) segundos, somando velocidade local da aura e buff global. Esc mostra o intervalo.

Armas atuais: comeca somente com arco (100 dano). Corte frontal (100 dano) e aura circular (50 dano por segundo, raio base 2,5 m) sao desbloqueados nas cartas de nivel junto com buffs. Todas as armas continuam elegiveis mesmo com quatro buffs equipados. Cada carta aplica dois atributos distintos da arma conforme raridade: arco [projeteis, velocidade de ataque, dano], corte [area, velocidade de ataque, dano], aura [area, dano]. Bonus locais acumulam separados dos buffs; velocidade/projeteis globais continuam somando com os locais. Area aumenta a superficie circular/conica, calculando raio pela raiz do multiplicador. Esc mostra armas e status. Ima agora cai exclusivamente com 1% por morte de monstro; nao aparece mais no inicio nem periodicamente.

Sorte: sexto buff, acumulativo, com os mesmos intervalos percentuais por raridade. Pesos de raridade = peso base * (1 + sorte/100)^indice (branco indice 0, dourado 4), normalizados para somar 100%. Essa e uma formula propria inspirada na proposta; nao replica uma formula verificada de Megabonk. Esc mostra sorte e chance de dourado. Ima vermelho coletavel: um perto do inicio, novos a cada 25 s (maximo tres no mapa). Ao tocar, atrai todos os fragmentos azuis existentes; nao afeta amarelos nem XP que cair depois. Item usado imediatamente; slot mostra total de imas coletados na partida. Teste `tests/luck_magnet.gd` verifica sorte e coleta global.

Segundo ataque: corte automatico a cada 2 segundos, 100 de dano em um cone frontal de 90 graus e alcance de 3 m. Atinge todos os monstros dentro da area e respeita obstaculos. Segue a direcao visual do personagem e recebe o bonus acumulado de velocidade de ataque. Flechas continuam ativas. Os nomes dos buffs no menu Esc ficam brancos; ofertas e slots do HUD mantem as cores de raridade. Teste `tests/slash_attack.gd` verifica area, direcao e cor.

Combate e dificuldade atuais: cada flecha causa 100 de dano fixo, monstros comecam com 100 HP. Cada ponto percentual acumulado de dificuldade adiciona 1 HP sobre essa base. +10% = 110 HP (dois acertos) e quatro monstros por grupo; +20% = 120 HP e sete por grupo. Tamanho do grupo = 1 + piso(dificuldade * 3 / 10). Limite ativo e frequencia continuam escalando; grupos respeitam o limite ativo e locais livres para spawn. Esc mostra dano da arma e quantidade por grupo. `tests/difficulty_combat.gd` valida spawn em grupo e dano real das flechas.

Raridades: branco (45%), verde (28%), azul (16%), roxo (8%), dourado (3%). Intervalos percentuais respectivos: 1–3, 2–4, 4–6, 5–8, 8–13. Quantidade de Projetil: 0,3–0,6; 0,5–1,0; 0,8–1,3; 1,0–1,7; 1,5–2,5. Cada oferta sorteia sua raridade independentemente. Slots mostram contagem de aplicacoes e maior raridade obtida. No menu Esc, Ctrl + clique esquerdo em buff equipado aplica +1 ponto percentual (ou +1 unidade de projetil) e incrementa a contagem em um. O buff de sorte ainda nao foi adicionado; pesos e intervalos ficam separados em `scripts/buff_rarity.gd` para essa etapa.

WASD para andar, Espaco para pular, mouse para camera e Esc para abrir/fechar inventario e status com pausa. Corrida e dash foram removidos. HUD simplificado: XP no topo com nivel em um circulo, contador de kills e duas fileiras pequenas com quatro itens e quatro buffs sempre visiveis. Vida permanece na barra sobre o personagem e nos status. Velocidade de movimento e o quinto buff, sorteado com 1 a 10% e acumulado sobre a velocidade base; com quatro slots ocupados, somente os quatro buffs equipados entram no sorteio. Kills contam somente monstros mortos por dano e reiniciam com a partida.

## Drops e experiencia

TAB tambem mostra o inventario: quatro slots de itens (vazios ate adicionarmos itens) e quatro slots fixos de buffs. A primeira escolha de cada tipo ocupa o proximo slot; repeticoes aumentam o valor no mesmo slot. Ao preencher quatro buffs distintos, o sorteio de nivel fica restrito aos equipados. Inventario e melhorias reiniciam com a partida. Hoje ha quatro tipos disponiveis; o filtro ja exclui futuros tipos quando os slots estiverem cheios.

Dificuldade e a quarta melhoria: a cada nivel sao sorteadas tres opcoes distintas entre as quatro. Dificuldade sorteia 1 a 10% e acumula pontos percentuais. O multiplicador 1 + bonus/100 aumenta velocidade e vida (arredondada para cima) dos monstros atuais e futuros, aumenta o limite de monstros e a frequencia de spawn. O painel TAB mostra os totais. As flechas mantem a regra de matar com um acerto.

A cada nivel, a partida pausa e apresenta tres melhorias, cada uma com um sorteio independente de 1 a 10%. Escolha uma para continuar. Velocidade de ataque acumula bonus de frequencia: intervalo = 2 / (1 + bonus/100). Quantidade de Projetil sorteia valores de 0,3 a 1,8 e acumula unidades: cada unidade inteira garante uma flecha adicional, com fracao guardada (0,5 + 0,5 = uma adicional; 1,8 + 0,3 = duas adicionais e 0,1 guardado). TAB abre/fecha os status acumulados e pausa a partida; nao fecha a escolha obrigatoria de melhoria. Flechas simultaneas miram em inimigos distintos por ordem de proximidade; as excedentes saem em leque. Aumento de XP soma pontos percentuais de chance de um azul adicional por morte, em sorteio independente dos drops base, limitado a 100%. Cada azul continua valendo 20 XP. Melhorias duram a partida e reiniciam ao morrer. `tests/upgrades.gd` verifica escolha, pausa, bonus e niveis simultaneos.

Cada monstro morto sorteia um resultado: 60% somente uma esfera azul, 30% uma azul e uma amarela, 10% nenhum drop. Esferas ficam no local da morte e sao atraidas quando o jogador chega a menos de 2,2 m. Cada azul concede 20/100 XP em todos os niveis; cinco azuis sobem um nivel e reiniciam a barra. Amarelas aumentam o contador de bonus, sem conceder XP ou alterar atributos por enquanto. Enter apos morrer reinicia tambem nivel, XP e bonus. `tests/loot_xp.gd` valida as faixas do sorteio e a coleta.

Base original inspirada na proposta de movimentação de Megabonk. O primeiro objetivo é acertar a sensação de controlar o personagem antes de construir combate e progressão.

## Ferramentas

- **Godot 4 estável, edição Standard (GDScript)**: engine e editor. Não precisa da edição .NET, Unity ou Visual Studio.
- **Blender**, mais tarde: personagens, cenários e animações. Agora usamos formas simples para testar.
- **Git**, recomendado quando começar a alterar o projeto: histórico e recuperação das mudanças.

Download da engine: https://godotengine.org/download/windows/

## Abrir e jogar

Godot portátil já está disponível em `tools/godot`. Clique duas vezes em `jogar.bat` para iniciar diretamente.

1. Baixe e extraia a versão Standard da Godot para Windows.
2. Abra a Godot, clique em **Importar** e escolha `project.godot` nesta pasta.
3. Abra o projeto e pressione **F6** com `scenes/arena.tscn` aberta, ou **F5** para executar o projeto.
4. Use WASD para mover, mouse para girar a câmera, Espaço para saltar, Shift para correr e Q para dash.
5. R volta ao início. Esc libera o mouse; clique na janela para capturá-lo novamente.

## O que já está preparado

- Movimento em terceira pessoa relativo à direção da câmera.
- Aceleração, frenagem e controle no ar.
- Salto com tolerância curta após sair da plataforma e buffer de entrada.
- Corrida e dash com recarga.
- Câmera com SpringArm3D para aproximar ao encontrar obstáculos.
- Arena com degraus e plataformas; retorno automático após cair.
- HUD com controles, velocidade e recarga do dash.
- Inimigos com 30 de vida surgem a cada 1,8 s, entre 8 e 13 m do jogador (limite de 25).
- Perseguicao usando mapa de navegacao para contornar obstaculos no solo.
- Inimigos correm a 6 m/s, atualizam o alvo continuamente e sobem degraus baixos de ate 0,3 m. Teste `tests/enemy_chase.gd` verifica chegada ao jogador de diferentes posicoes e retomada da perseguicao quando ele muda de lugar.
- Jogador com 100 de vida, barras no HUD e sobre os personagens. Contato causa 10 de dano com 0,75 s de protecao global entre golpes.
- Ao morrer, a partida para. Enter reinicia com vida cheia e limpa os inimigos.

Inimigos terrestres seguem o ponto navegavel mais proximo do jogador; nao saltam para plataformas altas. Parametros de spawn ficam em `scripts/arena.gd`, vida do jogador em `scripts/player.gd` e atributos dos inimigos em `scripts/enemy.gd`.

O arqueiro dispara automaticamente uma flecha a cada 2 segundos, mirando no inimigo mais proximo. Sem inimigos, dispara na direcao em que o personagem esta virado. As flechas seguem em linha reta, param nos obstaculos e matam o primeiro monstro atingido; nao atravessam varios monstros. O disparo nao adiciona animacoes ao jogador. Ajuste `attack_interval` em `scripts/player.gd` e velocidade/duracao em `scripts/arrow.gd`.

## Onde mexer

- `scripts/player.gd`: parâmetros de velocidade, salto, gravidade, dash e câmera no início do arquivo.
- `scripts/arena.gd`: criação da arena, iluminação, HUD e teclas.
- `scripts/archer_visual.gd`: arqueiro geometrico original com capuz, arco, aljava e animacoes procedurais.
- `scripts/arrow.gd`: visual, deslocamento e colisao das flechas.
- `scenes/player.tscn`: jogador reutilizavel; selecione o no Player para ajustar parametros no Inspector.
- `scenes/arena.tscn`: cena inicial.
- `assets/`: reserve para modelos, materiais, sons e texturas próprios.
- `docs/ROTEIRO.md`: próximas etapas e critérios para avançar.

A arena e o visual do personagem são gerados por código ao executar. Ajuste os valores `@export` em `player.gd` ou abra `scenes/player.tscn` e use o Inspector. O modelo do arqueiro usa formas geometricas; pode ser substituido por um modelo GLB com esqueleto e animacoes depois.

## Estado de validação

Projeto importado e executado em modo headless na Godot 4.7.2. Teste `tests/combat_smoke.gd` verifica spawn, aproximacao, vida dos inimigos, contato, protecao entre golpes e morte. `tests/arrow_attack.gd` verifica intervalo de disparo, morte com uma flecha, limite de um alvo por flecha e interrupcao dos disparos ao morrer. Ainda nao ha modelos finais ou audio. O arqueiro usado continua sendo o modelo geometrico local; o arquivo do Sketchfab ainda nao foi adicionado.
