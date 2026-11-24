"""Read-only final source/save guard; preserve the initial and intermediate receipts."""
from linxi_entry_repair_20261029q import *
base=json.loads((STAGE/'before.json').read_text('utf-8'))
allowed={str(ROOT/'game/data/maps/linxi_farmer_cottage_layout_v1.tres'),str(ROOT/'game/scripts/autoload/scene_router.gd')}
differences=[];protected=0
for old in base:
    now=fact(Path(old['path']))
    if now!=old:
        differences.append({'before':old,'after':now,'authorized':old['path'] in allowed})
    elif old['path'] not in allowed:protected+=1
closure=json.loads((STAGE/'closure.json').read_text('utf-8'))
source_rows=[]
for row in closure['targets']:
    p=ROOT/'game'/row['path'][6:]
    source_rows.append({'path':row['path'],'expected':row['after'],'actual':sha(p),'ok':sha(p)==row['after']})
data=[]
for row in json.loads((STAGE/'data-changes.json').read_text('utf-8')):
    p=ROOT/row['path']
    data.append({**row,'final_sha256':sha(p),'intermediate_receipt_retained':True})
external=[x for x in differences if not x['authorized']]
observed=json.loads((STAGE/'final-guard01-differences.json').read_text('utf-8'))
observed_now={x['after']['path']:x['after'] for x in observed}
for x in external:
    p=Path(x['after']['path'])
    assert p.name in ('save_0.json','save_0.json.bak')
    assert 'app_userdata' in p.parts
    # Changed 23:35/23:36, between own probe02 exit and verify03 launch.
    assert x['after']==observed_now[str(p)]
assert all(x['ok'] for x in source_rows)
for label in ['verify03','wall04']:
    result=json.loads((QA/(label+'.json')).read_text('utf-8'))
    assert result['finished'] and all(c['ok'] for c in result['checks'])
result={'ok':True,'initial_global_guard_passed':False,'external_save_changes_preserved':external,'external_save_current_fact_stable':True,'baseline_count':len(base),'protected_exact_count':protected,'authorized_differences':[x for x in differences if x['authorized']],'source_targets':source_rows,'data_final':data,'helper':fact(ROOT/'game/scripts/field/linxi_entry_contract_20261029q.gd'),'scope':'Linxi cottage doorway, invalid origin restoration and right-wall clearance only; no global room claim.'}
save(STAGE/'final-guard.json',result)
print(json.dumps({'protected_exact':protected,'authorized_differences':len(differences)-len(external),'external_save_changes_preserved':len(external),'sources':len(source_rows),'data_final':data},ensure_ascii=False))
