"""Read Root exact-two actual deployment guard; no new guard scan or runtime."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
P=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration13'
OUT=Path(__file__).with_name('yamen_classification_actual_guard_independent_review_READY.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_bytes())
assert sha(P/'final_guard.json')=='e5e524144f5340f5367808f5452f347b230f14484e655b1ed16dded531c389c4'
g=load(P/'final_guard.json');before=load(P/'guard_before.json');plan=load(P/'predeploy_plan_READY.json')
assert g['passed'] is True and g['checked']==2113 and g['exact_unchanged']==2111
assert g['unexpected_change_count']==g['save_change_count']==0 and g['unexpected_changes']==g['save_changes']==[]
assert g['authorized_change_count']==2 and g['save_count']==15
assert g['before_sha256']==sha(P/'guard_before.json')==plan['before_sha256']
assert plan['independent_review_sha256']=='ff4fd024f943789fdf1e2e7066cbe9b75b3922a38c7e1c4e867b2809b3223ee3'
a={x['path']:x for x in before['facts']};b={x['path']:x for x in g['facts']}
assert a.keys()==b.keys() and len(a)==2113
changed={x['path'] for x in plan['targets']}
assert changed==set(g['authorized_targets']) and len(changed)==2
assert {p for p in a if a[p]!=b[p]}==changed
for p in a:
    if p not in changed:assert a[p]==b[p]
for p in g['save_paths']:assert a[p]==b[p]
for row in plan['targets']:
    p=Path(row['path']);candidate=Path(row['candidate_path']);backup=Path(row['backup_path'])
    assert sha(p)==sha(candidate)==row['new_sha256'] and p.stat().st_size==row['new_bytes']
    assert sha(backup)==row['backup_sha256']==row['old_sha256']
    assert a[str(p)]['sha256']==row['old_sha256'] and b[str(p)]['sha256']==row['new_sha256']
assert not OUT.exists()
report={'status':'INDEPENDENT_ROOT_EXACT_TWO_ACTUAL_DEPLOYMENT_GUARD_REVIEW','guard_path':'res://'+(P/'final_guard.json').relative_to(ROOT).as_posix(),'guard_sha256':sha(P/'final_guard.json'),'authorized_changes':2,'guard_checked':2113,'other_full_fact_including_exactticks_unchanged':2111,'save_full_exactticks_facts_unchanged':15,'current_exact_two_target_SHA_bytes_and_original_backups':True,'B_C_adapter_OWNED_native_geometry_not_changed_by_this_epoch':True,'does_not_grant_runtime_or_loading_or_Field_pass':True,'new_guard_scan':False,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_sha256':sha(OUT),'guard_checked':2113,'exactsame':2111}))
