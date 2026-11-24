from lanxi_revision_20261030l import *
baseline=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[];save_count=0
allowed={str((GAME/p).resolve()).lower() for p in [OLD,'build/three_towns_world_20261029j_system01/native_sources.json','build/three_towns_world_20261029j_system01/town_registry.gd']}
for before in baseline:
 p=Path(before['path']);now=snapshot(p)
 if 'app_userdata' in str(p):save_count+=1
 if now!=before:changes.append({'before':before,'after':now,'authorized':str(p.resolve()).lower() in allowed})
report={'protected_count':len(baseline),'save_count':save_count,'changes':changes,'unexpected_changes':[r for r in changes if not r['authorized']]}
save(STAGE/'final-guard-pre-doc.json',report)
print('guard',len(baseline),'saves',save_count,'changed',len(changes),'unexpected',len(report['unexpected_changes']))
for r in changes:print(r['before']['path'],r['authorized'])
for n in ['candidate02','candidate04','layout07','residual08','formal09','restore10']:
 j=json.loads((QA/(n+'.json')).read_text('utf-8'));c=j if isinstance(j,list) else j['checks'];print(n,len(c),'failed',sum(not x['ok'] for x in c))
