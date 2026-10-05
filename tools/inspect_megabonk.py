import sys, pathlib, json, collections
sys.path.insert(0,str(pathlib.Path(__file__).parent/'unity-inspect'))
import UnityPy
root=pathlib.Path(r'C:\Program Files (x86)\Steam\steamapps\common\Megabonk\Megabonk_Data')
out=pathlib.Path(__file__).parent.parent/'docs'/'megabonk-animation-inspection.json'
report={'files':[], 'animations':[], 'controllers':[], 'animators':[], 'errors':[]}
for path in list(root.glob('*.assets'))+list(root.glob('level[0-9]')):
    print('Scanning',path.name,flush=True)
    try:
        env=UnityPy.load(str(path)); counts=collections.Counter()
        for obj in env.objects:
            kind=obj.type.name; counts[kind]+=1
            if kind not in ('AnimationClip','AnimatorController','Animator','Avatar','Animation','SkinnedMeshRenderer'): continue
            try:
                tree=obj.read_typetree()
                if kind=='AnimationClip':
                    settings=tree.get('m_AnimationClipSettings',{})
                    report['animations'].append({'file':path.name,'id':obj.path_id,'name':tree.get('m_Name'),'sample_rate':tree.get('m_SampleRate'),'legacy':tree.get('m_Legacy'),'settings':settings,'muscle_clip':tree.get('m_MuscleClip',{}).get('m_StopTime'),'curve_counts':{k:len(v) for k,v in tree.items() if isinstance(v,list) and ('Curve' in k or 'Event' in k)}})
                elif kind=='AnimatorController':
                    report['controllers'].append({'file':path.name,'id':obj.path_id,'data':tree})
                elif kind in ('Animator','Animation'):
                    report['animators'].append({'file':path.name,'id':obj.path_id,'kind':kind,'data':tree})
            except Exception as exc: report['errors'].append({'file':path.name,'kind':kind,'error':str(exc)[:150]})
        report['files'].append({'file':path.name,'types':dict(counts)})
    except Exception as exc: report['errors'].append({'file':path.name,'error':str(exc)[:200]})
out.write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Clips',len(report['animations']),'controllers',len(report['controllers']),'animators',len(report['animators']))
for a in report['animations']: print(a['name'],a['sample_rate'],a['muscle_clip'],a['settings'].get('m_LoopTime'))
