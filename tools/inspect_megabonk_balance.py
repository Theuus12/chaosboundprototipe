import sys,pathlib,json,re,collections,struct
root=pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0,str(root/'tools/unity-inspect'))
import UnityPy
from UnityPy.helpers.TypeTreeGenerator import TypeTreeGenerator
from UnityPy.helpers.TypeTreeNode import TypeTreeNode
source=pathlib.Path(r'C:\Program Files (x86)\Steam\steamapps\common\Megabonk\Megabonk_Data')
report={'scripts':[], 'records':[], 'errors':collections.Counter()}
script_classes={}
for file in source.glob('*.assets'):
    for obj in UnityPy.load(str(file)).objects:
        if obj.type.name=='MonoScript':
            script_classes[obj.path_id]=obj.read_typetree().get('m_ClassName','')
generator=TypeTreeGenerator('6000.0.0f1')
for dll in ['mscorlib.dll','UnityEngine.CoreModule.dll','UnityEngine.dll','Unity.Localization.dll','Unity.Mathematics.dll','Assembly-CSharp.dll']:
    print('Loading schema',dll,flush=True)
    generator.load_dll((root/'tools/il2cpp-dumper/DummyDll'/dll).read_bytes())
for cls in ['WeaponData','TomeData','ItemData','UpgradeData']:
    full_name = 'Assets.Scripts.Inventory__Items__Pickups.Upgrades.UpgradeData' if cls == 'UpgradeData' else cls
    print('Generating', full_name, flush=True)
    nodes=json.loads(generator.get_nodes_as_json('Assembly-CSharp.dll',full_name))
    # Generated inherited managed-reference registry must be the final field.
    refs=[]; clean=[]; moving=False
    for node in nodes:
        if node['m_Level']==1:
            moving=node['m_Name']=='references'
        if node['m_Name']=='m_Enabled': node['m_MetaFlag']=16384
        (refs if moving else clean).append(node)
    nodes=clean+refs
    generator.cache[('Assembly-CSharp',cls)]=TypeTreeNode.from_list([TypeTreeNode(n['m_Level'],n['m_Type'],n['m_Name'],0,0,m_MetaFlag=n['m_MetaFlag']) for n in nodes])
    generator.cache[('Assembly-CSharp.dll',cls)]=generator.cache[('Assembly-CSharp',cls)]
for file in source.glob('*.assets'):
    print('Reading',file.name,flush=True)
    env=UnityPy.load(str(file))
    env.typetree_generator=generator
    for obj in env.objects:
        if obj.type.name=='MonoScript':
            t=obj.read_typetree(); report['scripts'].append(t)
        if obj.type.name!='MonoBehaviour': continue
        raw=obj.get_raw_data()
        if len(raw)<32: continue
        script_id=struct.unpack_from('<q',raw,20)[0]
        class_name=script_classes.get(script_id,'')
        if class_name not in ['WeaponData','TomeData','ItemData','UpgradeData','StatData']: continue
        n=struct.unpack_from('<i',raw,28)[0]
        if n<=0 or n>150: continue
        name=raw[32:32+n].decode('utf-8',errors='replace')
        try:
            t=obj.read_typetree()
            name=t.get('m_Name','')
            if any(k in t for k in ['eWeapon','eTome','eItem','statModifiers','upgradeData']) or re.search('stat|upgrade|damage',name,re.I):
                report['records'].append({'file':file.name,'id':obj.path_id,'class':class_name,'data':t,'raw_size':obj.byte_size})
        except Exception as ex: report['errors'][type(ex).__name__]+=1
metadata=(source/'il2cpp_data/Metadata/global-metadata.dat').read_bytes()
strings=re.findall(rb'[ -~]{4,}',metadata)
report['metadata_symbols']=sorted(set(s.decode() for s in strings if len(s)<120 and re.search(rb'damage|critical|weapon|tome|bounc|projectile|armor',s,re.I)))
(root/'docs/megabonk-balance-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Records',len(report['records']),'scripts',len(report['scripts']),'errors',report['errors'])
for r in report['records'][:15]: print(str(r)[:600])
print('Symbols',report['metadata_symbols'][:100])
