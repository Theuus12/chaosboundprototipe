# Articulações do arqueiro

O modelo Blender separa braço e antebraço e adiciona volumes nos cotovelos e joelhos para reduzir aberturas durante a flexão. O GLB mantém os nomes das peças.

`scripts/imported_archer_visual.gd` cria hierarquias ombro → cotovelo → antebraço/mão e quadril → joelho → canela/bota. Os movimentos continuam procedurais, com peças rígidas: esta etapa não inclui Skeleton3D com pesos de deformação nem clipes de animação no Blender.

Estados próprios: idle, run, jump, fall e land. `player.gd` fornece a velocidade vertical real após o movimento para distinguir subida e queda. Os joelhos flexionam na recuperação da passada, os cotovelos dobram durante a corrida e a aterrissagem comprime as pernas. A capa acompanha o movimento com atraso suave.

O comportamento é inspirado na organização de estados observada na instalação local do Megabonk. Nenhum clipe ou modelo desse jogo foi reutilizado. Os movimentos não são uma reprodução exata de suas animações.

Verificação: `tests/archer_animation_smoke.gd` confere ligação das peças, hierarquia das articulações, flexão de joelhos/cotovelos e transições entre corrida, subida, queda, aterrissagem e repouso. O teste headless do jogo verifica carregamento e execução; não substitui avaliação visual durante a partida.
