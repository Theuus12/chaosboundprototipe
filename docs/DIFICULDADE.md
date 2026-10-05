# Progressao de dificuldade adaptada

Inspecao local de CombatScaling: inicializador RVA 0x4700F0; HP 0x46F6B0, dano 0x46F320, velocidade 0x46FAB0. Constantes por minuto: velocidade 0.025, vida 0.10, dano/resistencia a empurrao 0.028. Os ramos da horda final usam bases 4 para vida e 2 para dano, com tempo dividido por 60. Evidencias em megabonk-difficulty-native.txt.

Aplicacao ao nosso mapa unico: crescimento continuo desde o inicio, recalculado a cada cinco segundos para monstros vivos e no spawn. Vida preserva a fracao restante. Aos 10 minutos: 2x vida, 1.28x dano e 1.25x velocidade sem cristal de desafio. Apos zero, termos adicionais crescem como 4^minutos extras - 1 para vida e 2^minutos extras - 1 para dano; expoente limitado a 10 para evitar overflow. Velocidade permanece limitada a velocidade base do player. Resistencia a empurrao cresce por minuto.

Populacao inicial 12, mais um por minuto ate 18; hordas continuam limitadas a 24. Bosses mantem as vidas fixas pedidas. A combinacao com o cristal de desafio e a populacao sao adaptacoes proprias; o Megabonk possui fatores de fase e outros modificadores que nao existem aqui. Nao representa reproducao integral da formula original.
