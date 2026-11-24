"""One finite current29/plan/full-old-backup review; no2979 source sweep."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration12'
def sha(b):return hashlib.sha256(b).hexdigest()
stagebytes=(H/'outputs/root_finite09_two_domain_stage02/receipt.json').read_bytes()
assert sha(stagebytes)=='885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
stage=json.loads(stagebytes);assert stage['source_first']==stage['source_final']
planbytes=(R/'predeploy_plan_READY.json').read_bytes();plan=json.loads(planbytes)
authbytes=(R/'deployment_authorization.json').read_bytes();auth=json.loads(authbytes)
guardbytes=(R/'final_guard.json').read_bytes()
assert sha(guardbytes)=='af12b2f1c93dc1f55674ee9ec78849b5bf755a7eaf1e64a73664a504c0bf7216'
guard=json.loads(guardbytes);assert guard['authorization_sha256']==sha(authbytes)
assert guard['exact_unchanged']==2083 and guard['save_change_count']==0
assert plan['approved_by_root'] is True and plan['actual_stage_receipt_sha256']==sha(stagebytes)
assert plan['target_count']==auth['target_count']==29
assert plan['gd_apply_patch_count']==16 and plan['generated_json_mechanical_copy_count']==13
targets={r['target']:r for r in stage['targets']};rows=[]
assert set(targets)=={r['target'] for r in plan['targets']}
for r in plan['targets']:
 expected=targets[r['target']]
 assert r['old_sha256']==expected['old_sha256'] and r['new_sha256']==expected['candidate_sha256']
 current=(G/r['target'][6:]).read_bytes()
 candidate=(G/expected['candidate_path'][6:]).read_bytes()
 backup=Path(r['backup_path']).read_bytes()
 assert current==candidate and sha(current)==r['new_sha256'] and len(current)==r['new_bytes']
 assert sha(backup)==r['old_sha256']==r['backup_sha256']
 rows.append({'target':r['target'],'current_sha256':sha(current),'current_bytes':len(current),'complete_candidate_bytes_same':True,'full_old_backup_sha256':sha(backup),'full_old_backup_bytes':len(backup),'old_and_new_distinct':current!=backup})
out={'status':'DEPLOYED29_SOURCE_INHERITANCE_EXACT_NOT_FIELD_RUNTIME_ADMISSION',
 'actual_stage_receipt_sha256':sha(stagebytes),'root_plan_sha256':sha(planbytes),'root_deployment_authorization_sha256':sha(authbytes),'root_final_guard_sha256':sha(guardbytes),
 'current_target_and_candidate_full_bytes_checked':29,'full_old_backups_checked':29,
 'mechanisms_inherited_from_locked_Root_plan':{'GD_apply_patch':16,'generated_JSON_mechanical_copy':13},
 'prior2979_source_first_final_equality_inherited_not_rehashed':True,
 'guard_2112_29_authorized_2083_unchanged_and_15_save_exactticks_credit':'Root pinned AF12 guard; not repeated by this read-only review',
 'owner_source_maps_sha256':'1002af3bf3cd46ef0e1f4864d8313bfca0d82eea04349437b916e5df6f932188',
 'native_89216_and_code8FD3_executionC668_unchanged':True,
 'canonical_writes':0,'engine_calls':0,'collector_calls':0,'all2979_current_SHA_sweeps':0,
 'runtime_validation':'QA single default Yamen actual pending; prior unrelated groups stopped','targets':rows}
p=H/'finite09_stage02_independent_review/deployed29_source_inheritance_READY.json';assert not p.exists()
b=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode()
with p.open('xb') as f:f.write(b)
print(json.dumps({'path':S+'finite09_stage02_independent_review/'+p.name,'sha256':sha(b),'current29_exact':True,'full_old_backups29_exact':True,'all2979_rehash':False,'engine_calls':0,'canonical_writes':0}))
