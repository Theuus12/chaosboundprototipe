# Santuários, salvas e progressão

O arco dispara sua quantidade inteira de flechas no mesmo frame. As origens ficam
distribuídas num círculo ao redor do jogador e todas miram o inimigo mais próximo.
Sem inimigos, as flechas seguem a direção do personagem.

As chances de XP e os tamanhos das orbes foram mantidos: pequena = 10, média = 30,
grande = 50. O custo de nível é `100 * (floor((nível - 1) / 10) + 1)`.
Assim, os níveis 1–10 custam 100; 11–20, 200; 21–30, 300; e assim por diante.
XP excedente é conservada, mesmo ao atravessar uma faixa.

O primeiro grupo de seis aparece após dois segundos. Tanto no combate normal
quanto nas hordas, um grupo de até seis aparece a cada dois segundos,
independentemente de mortes. Os tetos são 50 no normal e 100 nas hordas,
incluindo bosses. O último grupo é reduzido ao espaço disponível.
Ao entrar um boss com o teto ocupado, um monstro comum distante é removido
sem gerar loot. Ao fim da horda, os monstros comuns mais distantes que excedem
o teto normal são removidos; bosses são preservados e a fila de spawns é limpa.
A dificuldade não altera o intervalo de dois segundos nem esses tetos.

O jogador começa com dois espaços para armas: o arco ocupa o primeiro e o
segundo fica livre. HUD, inventário e ofertas respeitam essa capacidade.

Os 15 santuários continuam divididos nas cinco raridades. E abre uma escolha
gratuita e pausa o combate: escolha um dos três buffs elegíveis, ou volte com Esc.
Uma escolha consome o santuário; cancelar não consome nem sorteia novas ofertas.
Os buffs dos totens são permanentes na partida e ficam em uma camada própria
do personagem, sem ocupar slots nem níveis de cristal. Os cristais continuam
separados, com quatro slots e 100 níveis, obtidos no menu de subida de nível.
Os bônus das duas camadas se combinam apenas no cálculo dos atributos.

Escudo aparece numa barra azul acima da vida e absorve o dano primeiro.
Ele mantém a recarga existente após cinco segundos sem dano.
O novo buff Pulo extra concede mais um salto no ar por aquisição; os saltos
recarregam ao pousar. Altura do pulo permanece como buff separado.
A pose no ar inclina o tronco levemente para a frente.

Banir, Passar e Atualizar compartilham um contador de custo por partida:
5 → 25 → 125 → 225 → 325 → 425 → 525, permanecendo em 525.
O preço avança somente após uma ação concluída. Entrar ou cancelar o modo de
banimento não cobra moedas. São permitidos até três banimentos por partida.
Escolher uma melhoria normal continua gratuito.

Os 15 buffs comuns seguem os valores pedidos. Dano varia de 10% a 12%; os outros
valores são fixos. Regeneração concede 20 HP por minuto. Power-up aumenta a XP
recolhida pelo ímã, o power-up existente. Salto aumenta a altura, ajustando a
velocidade pela raiz quadrada do multiplicador. Dano contra elites também se
aplica a bosses; liches e olhos infernais contam como elites.

As demais raridades usam os multiplicadores existentes: verde 1,25; azul 1,5;
roxo 2; dourado 3. Projéteis permanecem inteiros. Essas escalas poderão ser
substituídas quando houver listas específicas dessas raridades.

## Desempenho

Os modelos de goblins e esqueletos compartilham peças via MultiMesh. Animações
distantes atualizam menos vezes e as barras usam uma única superfície com
billboard no shader. O alvo e a posição do NavigationAgent são sincronizados
mesmo na perseguição direta. NavigationAgent usa desvio RVO com oito
vizinhos em vez de contatos físicos entre todos os pares de monstros.

Teste renderizado após corrigir o desvio que deixava monstros parados, em
Godot 4.7.2, OpenGL, RTX 3060, arena de 360 × 360:
100 inimigos mistos incluindo um boss, perseguindo o jogador e recebendo salvas
de cinco flechas, medidos durante 360 frames após aquecimento:

- Média: 59,9 FPS / 16,68 ms por frame.
- Mediana: 16,63 ms; percentil 95: 17,94 ms.
- Física no percentil 95: 8,43 ms.

A medição anterior com 200 incluía agentes parados por um erro na sincronização
do alvo e não deve ser usada como evidência do desempenho de perseguição.

É uma amostra curta e controlada, não uma garantia para runs longas, outros PCs
ou quantidades muito altas de projéteis e loot. O benchmark pode ser repetido
com `--script res://tests/horde_benchmark.gd -- --mixed --100`; o relatório fica em
`builds/horde-benchmark-100.txt`.

## Altar do Rei Ossuário

Um altar de pedra em três degraus, com pilares, runas e musgo, fica no setor
nordeste do mapa. O minimapa mostra um losango dourado dentro do alcance local.
Aproxime-se e pressione E para invocar uma única vez por partida o Rei Ossuário.
Ele possui 50.000 HP fixos e 10,9 m de altura, igual ao orc vermelho. Não aparece
mais automaticamente pelo relógio. Sua morte libera os Olhos Infernais; o próximo
spawn é um olho, seguido de um a cada sete novos monstros.

Goblins verdes deixam de nascer aos cinco minutos decorridos (05:00 no contador
regressivo de dez minutos). A partir daí, os spawns comuns são esqueletos e liches,
mais olhos quando desbloqueados. Inimigos já vivos continuam até serem derrotados.
O orc soldado não é mais boss: aparece como elite comum, ocasionalmente, entre
três e cinco minutos. Os bosses comandante e orc vermelho mantêm seus eventos
nos cinco e oito minutos decorridos. A invocação pelo altar também respeita o
teto total de inimigos.

As quatro colinas têm raio de 18 m e altura de 6 m. O terreno físico e a malha
de navegação usam o mesmo relevo. Inimigos aderem às descidas e seguem rotas
com inclinação de até 45 graus; spawns também aceitam terreno elevado caminhável.
Cada grupo de seis é criado em dois frames para distribuir o trabalho de criação.
