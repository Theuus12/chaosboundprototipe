# Arena Rush — protótipo 3D

## Drops e experiencia

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
