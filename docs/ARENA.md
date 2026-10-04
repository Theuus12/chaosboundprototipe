# Estruturas e monstros

Os monstros usam um visual original de criatura de pedra: corpo roxo, chifres, olhos luminosos e membros animados. A geometria é gerada por `scripts/enemy_visual.gd`; não depende de modelos externos.

A arena tem cinco novas estruturas, além das plataformas anteriores. Todas as 14 estruturas altas têm uma rampa com 2,6 metros de largura e inclinação de aproximadamente 29 graus. O mapa de navegação inclui essas rampas e os topos, permitindo que os monstros persigam o jogador em altura sem teletransporte. A subida ocorre pelas rampas, não por escalada vertical de paredes.

`tests/structures.gd` verifica a chegada de um monstro ao topo de cada estrutura. `tests/enemy_chase.gd` verifica perseguição longa e mudança da posição do alvo.
