from pathlib import Path
import colorsys
root=Path(__file__).resolve().parent.parent
names={0:'Ataque',1:'Projétil',2:'Conhecimento',3:'Desafio',4:'Movimento',5:'Destino',6:'Vigor',7:'Renascimento',8:'Escudo',9:'Desvio',13:'Defensor',14:'Espinho',15:'Dano',16:'Acerto Crítico',17:'Tamanho',18:'Tempo',19:'Impacto',20:'Sangue',21:'Projétil Veloz',22:'Ouro',23:'Metal Prateado',24:'Magnetismo',25:'Caos'}
symbols=['⚔','➶','✦','!','➤','✧','♥','+','⬟','↝','⬢','✹','✖','◎','↗','◷','➜','♦','»','$','◆','∩','?']
# All emblems use SVG geometry, avoiding dependence on fonts or emoji rendering.
paths=[
'M25 42L40 23M36 23H41V28M24 35L31 42',
'M24 40L40 24M32 24H40V32M24 34L30 40',
'M32 22L35 29L42 32L35 35L32 42L29 35L22 32L29 29Z',
'M32 22V34M32 40V41',
'M23 28H35L30 23M35 28L30 33M27 38H41',
'M23 32L32 23L41 32L32 41Z',
'M32 41L23 32Q18 22 27 24L32 28L37 24Q46 22 41 32Z',
'M32 23V41M23 32H41',
'M23 24H41V32Q40 39 32 43Q24 39 23 32Z',
'M22 37Q32 19 42 27M35 24L42 27L37 33',
'M24 40V29L32 23L40 29V40M28 31H36',
'M32 22L35 29L42 27L37 34L41 41L32 37L23 41L27 34L22 27L29 29Z',
'M24 25L40 41M40 25L24 41',
'M32 22V27M32 37V42M22 32H27M37 32H42',
'M23 29V23H29M35 23H41V29M23 35V41H29M35 41H41V35',
'M32 23V32L38 35',
'M22 32H41M34 25L41 32L34 39',
'M32 22Q20 35 26 40Q32 45 38 40Q44 35 32 22Z',
'M22 26L29 32L22 38M33 26L40 32L33 38',
'M38 25H28Q22 26 27 31L37 34Q43 39 35 40H25M32 22V43',
'M32 23L41 32L32 41L23 32Z',
'M24 24V35Q24 44 32 44Q40 44 40 35V24M24 29H28M36 29H40',
'M25 27Q25 20 35 23Q43 27 35 32L32 35M32 40V41']
out=root/'assets'/'ui'/'crystals'; out.mkdir(parents=True,exist_ok=True)
for index,kind in enumerate(names):
    rgb=colorsys.hsv_to_rgb(index/len(names),.68,.86)
    color='#'+''.join(f'{int(c*255):02x}' for c in rgb)
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 64 64">
<path d="M32 3L49 17L54 39L32 61L10 39L15 17Z" fill="{color}" stroke="#111f35" stroke-width="2"/>
<path d="M32 3L32 61L10 39L15 17Z" fill="#fff" opacity=".18"/>
<path d="M32 3L49 17L32 13L15 17Z" fill="#fff" opacity=".55"/>
<path d="M49 17L54 39L32 61L42 37Z" fill="#000" opacity=".22"/>
<path d="{paths[index]}" fill="none" stroke="#fff7dc" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="32" cy="32" r="5" fill="none" stroke="#fff7dc" stroke-width="2" opacity="{1 if kind in [16,18] else 0}"/>
</svg>'''
    (out/f'crystal_{kind}.svg').write_text(svg,encoding='utf-8')
p=root/'scripts'/'tomes.gd'; text=p.read_text(encoding='utf-8')
start=text.index('const NAMES ='); end=text.index('const DESCRIPTIONS')
text=text[:start]+'const NAMES = {\n'+',\n'.join(f'\t{k}: "Cristal do {v}"' for k,v in names.items())+'\n}\n'+text[end:]
p.write_text(text,encoding='utf-8')
for file in ['game_hud.gd','stats_menu.gd','upgrade_menu.gd']:
    p=root/'scripts'/file; text=p.read_text(encoding='utf-8')
    text=text.replace('TOMOS','CRISTAIS').replace('arma ou tomo','arma ou cristal').replace('Melhorar tomo equipado','Melhorar cristal equipado').replace('slot de tomo','slot de cristal')
    p.write_text(text,encoding='utf-8')
print('Created',len(names),'crystal icons and renamed buffs.')
