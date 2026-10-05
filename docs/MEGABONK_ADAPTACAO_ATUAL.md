# Configuração aplicada às quatro armas e cristais

Os dados numéricos recuperados da instalação local estão centralizados em scripts/megabonk_balance.gd. Arco usa WeaponBow, Espada usa WeaponSword, Aura usa WeaponAura e Adaga usa WeaponWirelessDagger/BluetoothBladeUpgrades.

Dano configurado: Arco 9, Espada 11, Aura 6, Adaga 9. Melhorias acrescentam dano absoluto: respectivamente 1,75; 2; 1,4; 2. O cristal de dano usa incrementos multiplicativos de 8% no nível de raridade base. Dois incrementos produzem 16,64%. Arco oferece quantidade, velocidade de projétil, tamanho, chance crítica e dano crítico; Espada oferece tamanho, quantidade e empurrão; Aura oferece tamanho e dano; Adaga oferece quantidade, velocidade e ricochetes. Ricochetes da adaga usam seu mesmo dano efetivo.

Cristais usam os valores base de TomeData, com unidades explícitas na interface. Vida e escudo acrescentam 25 unidades; espinhos acrescentam 15 de dano. A regeneração usa 40 HP por minuto como interpretação do protótipo, ainda sem validação da unidade temporal original.

Esta é uma adaptação dos valores de configuração, e não uma reprodução comprovada de todo o dano final do Megabonk. Multiplicadores de raridade [1; 1,25; 1,5; 2; 3], escalonamento com nível do personagem, comportamento da regeneração, armadura, dano crítico adicional, área, efeitos elementais e efeitos especiais ainda precisam de comparação dinâmica/inspeção completa. A chance de drop do Cristal do Conhecimento, coleta, limites de níveis, boss e hordas continuam com as regras solicitadas para este jogo. O cristal do Caos mantém seu comportamento próprio.

Os limites de 50 níveis nas armas e 100 nos cristais permanecem. A escala interna de dano mudou: vidas dos inimigos não foram reduzidas automaticamente. Os documentos anteriores descrevem etapas históricas; este documento registra a configuração atual.
