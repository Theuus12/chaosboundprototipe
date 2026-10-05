# Chaosbound - beta 0.3.0

[Baixar beta para Windows 64 bits](https://github.com/Theuus12/chaosboundprototipe/releases/download/v0.3.0-beta/Chaosbound-Beta-0.3.0-Windows-x64.zip)

Extraia o ZIP e abra Chaosbound-Beta.exe. Nao precisa instalar Godot.

## Conteudo atual

- Floresta de 360 x 360, colinas maiores, campo de visao limitado e minimapa.
- Arco com salvas simultaneas, Espada, Aura e Adaga reversa; dois espacos iniciais para armas.
- Quinze totens com tres escolhas gratuitas de buffs, separados dos cristais.
- Escudo, pulos extras, regeneracao, roubo de vida e melhorias por raridade.
- XP de 10, 30 e 50 pontos; custo por nivel cresce a cada dez niveis.
- Grupos de seis monstros a cada dois segundos; teto de 50 no normal e 100 nas hordas.
- Goblins ate cinco minutos; depois esqueletos e liches. Orc soldado como elite comum.
- Altar interativo que invoca o Rei Ossuario, com 50000 HP, e libera olhos infernais ao derrota-lo.
- Banir, Passar e Atualizar com custos progressivos em moedas; ate tres banimentos por partida.
- Animacoes articuladas, malhas compartilhadas e navegacao sobre as colinas.

## Controles

WASD: andar; mouse: camera; Espaco: pular; E: interagir com totens e altar; Esc: inventario/pausa; Enter: reiniciar apos morrer.

## Desenvolvimento e exportacao

Godot 4.7.2, renderer Compatibility (OpenGL 3.3), Windows x86_64.
Abra project.godot. Modelos editaveis em assets/characters; geradores em tools.
Scripts de gameplay em scripts; testes executados com Godot --headless --path . --script tests/NOME.gd.

O preset Windows Beta usa tools/templates/windows_release_x86_64.exe e embute os dados no executavel.
Execute tools/prepare-beta.ps1 para exportar e empacotar. Downloads sao distribuidos nas Releases; ferramentas e builds locais ficam fora do historico.

## Validacao e limites

A beta possui arte original e balanceamento experimental, sem assinatura digital.
Testes de XP/drop, cristais, combate, adaga, animacao, hordas e boss cobrem o comportamento atual.
Alguns testes antigos ainda descrevem mecanicas anteriores. A analise do Megabonk esta documentada em docs e nao representa reproducao completa dos seus efeitos.
