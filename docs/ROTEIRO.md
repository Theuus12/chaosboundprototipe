# Roteiro de desenvolvimento

## 1. Movimento primeiro

Jogue alguns minutos na arena. Teste sair de bordas, saltar entre plataformas, mudar direção no ar e usar dash contra obstáculos. Ajuste um parâmetro de cada vez em `scripts/player.gd`.

Critério para avançar: mover, saltar e desviar deve ser divertido mesmo sem inimigos. Decida se o jogo terá salto duplo, dash aéreo ou corrida automática; a base atual tem salto simples, dash aéreo permitido e corrida com Shift.

## 2. Primeiro ciclo de combate

Transformar o jogador numa cena reutilizável. Adicionar um inimigo simples que persegue, vida, dano por contato, ataque automático com intervalo e reinício ao morrer. Começar com poucos inimigos e medir desempenho antes de aumentar a quantidade.

## 3. Progressão de uma partida

Adicionar experiência coletável, níveis, três escolhas de melhoria e um temporizador. Separar atributos base dos modificadores para evitar acumular bônus incorretamente.

## 4. Conteúdo e identidade

Criar personagem e cenário próprios, animações, efeitos e sons. Só depois adicionar variedade de armas, inimigos e mapas. Evitar copiar personagens, nomes, arte ou áudio do jogo de referência.

## 5. Preparar uma versão compartilhável

Menu, pausa, opções de mouse/volume, suporte a controle, exportação para Windows e testes em outra máquina. Export templates só são necessários na etapa de gerar o executável.
