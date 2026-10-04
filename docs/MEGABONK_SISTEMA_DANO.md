# Análise e adaptação do sistema de combate

Inspeção somente de leitura da instalação local em 2026-10-04. O catálogo completo dos registros recuperados está em MEGABONK_CATALOGO.md; os campos originais estão em megabonk-balance-inspection.json.

## Evidências

- Recuperados 30 WeaponData, 26 TomeData, 87 ItemData e 29 UpgradeData, sem erros de leitura. Incluem registros habilitados e desabilitados; não equivalem necessariamente ao conteúdo disponível na partida.
- EStatModifyType separa Addition, Multiplication e Flat. TomeDamage usa Multiplication; melhorias de dano das armas usam Flat. Assim, o bônus global e a melhoria da arma pertencem a camadas diferentes.
- BluetoothBladeUpgrades oferece dano, projéteis, ricochetes e velocidade de projétil. WeaponWirelessDagger possui dano interno 9 e um ricochete. Esses valores não substituem o pedido de dano inicial 100 e ricochete 30 para nossa adaga.
- Player.CalculateBaseDamage (RVA 0x4B4DD0) soma o nível do personagem a um valor estático. Ainda falta identificar e validar todos os fatores posteriores para reproduzir o dano final dessa instalação.
- DamageUtility.GetCritDamageMultiplier (RVA 0x4702D0) separa a parte inteira da chance da parte fracionária. A fração sorteia um nível adicional; nível 1 tem multiplicador 2. O ramo de níveis maiores foi reconstruído como 1 + nível + (nível / 2)^2 a partir das instruções e da chamada matemática nativa. Trata-se de reconstrução por análise estática, ainda sem comparação com execuções do Megabonk.
- Os dados básicos dos itens fornecem identidade, raridade e limites. Seus efeitos especiais ficam nas classes de comportamento; não podem ser deduzidos apenas da tabela ItemData.

## Aplicado ao protótipo

Arco, Espada, Aura e Adaga passam a usar a mesma rotina de dano. Mantivemos a melhoria percentual já usada no protótipo, em vez de trocar silenciosamente para os incrementos absolutos do Megabonk:

`dano = base × (1 + melhoria da arma / 100) × (1 + cristal global / 100)`

Exemplo: base 100, melhoria da arma 50%, cristal de dano 50% → 225. Sem melhorias, a adaga continua com 100 no primeiro alvo e 30 nos seguintes. Seu bônus de dano afeta os dois.

Críticos deixam de ser limitados a 100%. 150% garante nível 1 (2×), com 50% de chance de nível 2 (4×). 200% garante 4×; 300% garante 6,25×. Dano exibido e roubo de vida continuam usando a vida efetivamente removida do inimigo.

Quantidade e velocidade de projéteis, ricochetes, frequência, área e duração continuam usando os atributos existentes. As preferências anteriores para coleta, área e dano foram preservadas.

## O que ainda falta para reprodução completa

Não foram replicados os 87 efeitos especiais, personagens, evoluções, sinergias, efeitos elementais, coeficientes de ativação de efeitos e toda a progressão do jogo original. O catálogo documenta os dados recuperados; não representa uma validação de cada comportamento. A próxima implementação desses efeitos exige conferir suas rotinas e escolher equivalentes adequados às armas e inimigos do protótipo.

## Validação

tests/combat_stats.gd verifica camadas de dano e limites das probabilidades de crítico. tests/reverse_dagger.gd verifica dano inicial/ricochete, quantidade e velocidade de projéteis e alvos distintos. tests/tomes.gd verifica a integração dos cristais existentes.
