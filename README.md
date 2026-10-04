# Chaosbound - beta 0.2.0

[Baixar beta para Windows 64 bits](https://github.com/Theuus12/chaosboundprototipe/releases/download/v0.2.0-beta/Chaosbound-Beta-0.2.0-Windows-x64.zip)

Extraia o ZIP e abra Chaosbound-Beta.exe. Nao precisa instalar Godot.

## Conteudo atual

- Menu inicial com Jogar, Opcoes e Sair.
- Floresta com grama, tres tipos de arvores e arbustos.
- Arqueiro, goblins e chefe orc modelados no Blender, com animacoes articuladas.
- Arco, Espada que mira no inimigo mais proximo, Aura e Adaga reversa com ricochetes.
- Cristais com icones, melhorias por raridade, Banir, Passar e Atualizar.
- Orbs comuns com 10 XP e maiores com 20 XP. Drop base de 30%; Cristal do Conhecimento aumenta drop e chance de orb maior.
- Hordas durante 30 segundos em 8:00, 6:00, 4:00 e 1:00 restantes; limite de 24 inimigos.
- Chefe de 100000 de vida e cinco vezes a altura do jogador em 7:00 restantes.
- Monstros com nove malhas por modelo e instanciacao distribuida entre frames.

## Controles

WASD: andar; mouse: camera; Espaco: pular; Esc: inventario/pausa; Enter: reiniciar apos morrer.

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
