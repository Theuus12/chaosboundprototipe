"""Export readable numeric reference tables; never import source game assets."""
from pathlib import Path
import json, re, collections

root = Path(__file__).resolve().parent.parent
report = json.loads((root / 'docs/megabonk-balance-inspection.json').read_text(encoding='utf-8'))
dump = (root / 'tools/il2cpp-dumper/dump.cs').read_text(encoding='utf-8-sig')
def enum(name):
    body = re.search(r'public enum ' + name + r'\b[^\n]*\n\{(.*?)\n\}', dump, re.S).group(1)
    return {int(value): key for key, value in re.findall(r'public const \w+ (\w+) = (-?\d+);', body)}

stats, types = enum('EStat'), enum('EStatModifyType')
records = report['records']
lookup = {(r['file'], r['id']): r['data']['m_Name'] for r in records}
def modifiers(values):
    return '; '.join(f"{stats.get(v['stat'],v['stat'])}: {types[v['modifyType']]} {v['modification']:.4g}" for v in values)

assert not report['errors'], report['errors']
weapons = [r for r in records if r['class'] == 'WeaponData']
assert len({r['data']['eWeapon'] for r in weapons}) == len(weapons)
assert all(-1 <= r['data']['eWeapon'] <= 30 and 0 <= r['data']['damage'] < 1000 for r in weapons)
lines = ['# Referência numérica da instalação local do Megabonk', '',
         'Extraído em 2026-10-04. Valores de configuração, não dano final em combate. '
         'Itens com efeitos próprios precisam de análise de suas rotinas; raridade e limites não descrevem esses efeitos. '
         'Valores decimais de modificadores são unidades internas: 0.08 pode representar 8%, conforme o atributo.', '',
         '## Armas', '', '| Registro | Dano configurado | Projéteis | Ricochetes | Velocidade interna | Melhorias |',
         '|---|---:|---:|---:|---:|---|']
for r in weapons:
    d = r['data']; ref = d.get('upgradeData', {})
    upgrade = lookup.get((r['file'], ref.get('m_PathID')), '?')
    lines.append(f"| {d['m_Name']} | {d['damage']:.4g} | {d['projectiles']} | {d['projectileBounces']} | {d['projectileSpeed']:.4g} | {upgrade} |")
lines += ['', '## Tomos', '', '| Registro | Modificador base |', '|---|---|']
for r in records:
    if r['class'] == 'TomeData':
        lines.append(f"| {r['data']['m_Name']} | {modifiers([r['data']['statModifier']])} |")
lines += ['', '## Melhorias de armas', '', '| Registro | Modificadores base |', '|---|---|']
for r in records:
    if r['class'] == 'UpgradeData':
        lines.append(f"| {r['data']['m_Name']} | {modifiers(r['data']['upgradeModifiers'])} |")
lines += ['', '## Itens', '', 'Raridade é o enum interno. Limite 0 é armazenado como 0; não significa ausência do item.', '',
          '| Registro | ID | Raridade | Limite | Limite por partida | Habilitado | No conjunto de itens |', '|---|---:|---:|---:|---:|---:|---:|']
for r in records:
    if r['class'] == 'ItemData':
        d = r['data']
        lines.append(f"| {d['m_Name']} | {d['eItem']} | {d['rarity']} | {d['maxAmount']} | {d['maxAmountPerRun']} | {d['isEnabled']} | {d['inItemPool']} |")
(root / 'docs/MEGABONK_CATALOGO.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
print('Catalog exported:', dict(collections.Counter(r['class'] for r in records)))
