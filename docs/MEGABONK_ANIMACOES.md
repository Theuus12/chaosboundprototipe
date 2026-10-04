# Inspeção local das animações do Megabonk

Instalação examinada somente para leitura: `C:\Program Files (x86)\Steam\steamapps\common\Megabonk`.

## Evidências dos arquivos

- Estrutura Unity com `UnityPlayer.dll`, `GameAssembly.dll` e metadados IL2CPP. O código-fonte original não acompanha essa instalação.
- Foram lidos os arquivos `.assets` e `level0` a `level4`: 134 AnimationClip, 32 AnimatorController e 40 Animator. Esses totais incluem personagens, objetos e interface; não representam apenas animações do jogador.
- Há componentes SkinnedMeshRenderer, indicando uso de malhas deformáveis. Essa inspeção não reconstrói os esqueletos nem identifica o programa em que as animações foram produzidas.
- Nos 40 componentes Animator examinados, `m_ApplyRootMotion` está desativado. Isso indica que esses componentes não aplicam automaticamente o deslocamento do clipe ao objeto; a lógica exata de movimento exigiria inspecionar o código compilado.
- Existem conjuntos de clipes específicos para personagens: FoxRun, FoxJump4, FoxFalling; KnightRun, KnightJump, KnightFalling; BirdoRun, BirdoJump e BirdoFall, entre outros.
- FoxRun dura aproximadamente 0,889 s, com amostragem de 45 Hz; FoxJump4 dura 0,917 s, com amostragem de 60 Hz. Amostragem do clipe não é FPS de renderização.

## Exemplo: AnimatorFox2

Parâmetros booleanos: `jumping`, `grounded`, `moving`, `grinding`.

Estados: Idle, Walking, Jump, Falling, FoxGrind. O nome Walking é o nome do estado, não prova que o movimento visual seja uma caminhada.

O controlador possui transições de movimento para parado, entrada no salto a partir de qualquer estado, salto para queda e retorno da queda para parado ou movimento. Foram encontradas durações de transição de 0 s, aproximadamente 0,020 s e 0,150 s entre estados. Logo, não é correto atribuir a fluidez apenas a transições longas: os próprios clipes e suas poses também precisam ser considerados.

## Aplicação ao nosso protótipo

Nosso arqueiro atualmente usa rotações procedurais de peças rígidas e uma única pose aérea. Para aproximar o comportamento observado, os próximos passos são criar articulações de cotovelos e joelhos, produzir clipes próprios, separar decolagem/subida/queda/aterrissagem e combinar estados com transições breves. O balanço da capa pode continuar sendo um movimento adicional independente.

Não foi determinado nesta análise como o Megabonk simula capas, quais ferramentas de autoria usa ou quais ajustes o código faz por frame. Nenhum modelo, textura ou clipe do Megabonk foi integrado ao protótipo.

Dados estruturais e inventário: `megabonk-animation-inspection.json`. Script de inspeção: `../tools/inspect_megabonk.py`.
