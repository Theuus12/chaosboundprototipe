# Tomos

Os buffs agora são livros/tomos. Os seis efeitos existentes continuam disponíveis, junto de 17 novos tomos em `scripts/tomes.gd`. As armas continuam separadas nos slots de itens. Cada nível oferece três opções distintas entre armas e tomos elegíveis. Após equipar quatro tomos, novos tipos deixam de aparecer; melhorias dos quatro equipados continuam acumulando. Raridades e sorte usam os intervalos existentes, e Ctrl + clique no Esc também funciona com os novos tomos.

## Regras de balanceamento

- HP: bônus aditivo sobre a vida máxima inicial; cura somente a vida adicionada.
- Regeneração: percentual da vida máxima por 5 segundos, com acumulação de frações.
- Escudo: capacidade em percentual da vida máxima; começa cheio ao melhorar. Após 5 segundos sem receber dano, recarrega em 2 segundos. Absorve dano depois da armadura.
- Evasão: bônus em pontos percentuais, limitado a 75%; um desvio aciona a proteção temporária contra contato.
- Armadura: dano multiplicado por `100 / (100 + armadura)`; dano mínimo de 1 antes do escudo.
- Espinhos: percentual do dano à vida, depois da armadura e do escudo, refletido no agressor. Não provoca reflexão recursiva.
- Dano global: soma ao bônus de dano próprio de cada arma.
- Precisão: chance crítica em pontos percentuais, limitada a 100%; dano crítico dobrado. Sorte não altera esta chance.
- Tamanho: soma à área da arma, com raio proporcional à raiz quadrada do multiplicador. Flechas aumentam visual e volume de colisão.
- Duração: aumenta a vida útil da flecha e a duração visual do corte. Não repete o dano instantâneo do corte; a aura permanece contínua.
- Recuo: concede impulso base de 4 m/s, multiplicado pelo bônus; desacelera gradualmente.
- Sangue: cura pelo dano efetivamente removido da vida do inimigo, incluindo críticos; não conta excesso de dano nem espinhos.
- Velocidade de projétil: aumenta a velocidade das flechas.
- Dourado e Prata: efeitos independentes, somados no valor das moedas amarelas. Valor base 1; frações são preservadas. Não alteram a chance de drop.
- Atração: aumenta o raio base de 2,2 metros para XP e moedas. O item ímã continua atraindo todo o XP do mapa.
- Caos: a cada escolha, sorteia um dos 16 novos atributos restantes e aplica o valor da raridade. Não ocupa outro slot. O histórico acumulado aparece no Esc.

A beta pública 0.1.0 não inclui estas alterações até uma nova exportação/publicação.
