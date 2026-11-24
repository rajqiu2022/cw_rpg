"""Exact necessary canonical scope proposal, inherited actual stage snapshots."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s):
 b=(G/p[6:]).read_bytes();assert sha(b)==s;return b
stagepin={'path':S+'outputs/root_unified06_numeric_stage03/receipt.json','sha256':'9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'}
stage=json.loads(read(**{'p':stagepin['path'],'s':stagepin['sha256']}))
hand=json.loads(read(S+'finite_adapter_production08/handoff_PRODUCTION_PROPOSAL.json','8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c'))
targets={r['target']:{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'basis_actual_receipt':stagepin} for r in stage['targets']}
del targets['res://scripts/autoload/scene_router.gd']
for r in hand['consumers']:
 old=read(r['target'],r['old_sha256'])
 # All newly functional source parents have historical immutable copies in
 # 06/07 proofs or System ground snapshot; copy exact source bytes as build
 # backup only, not a canonical write or inferred expected hash.
 snap=S+'finite_adapter_production08_scope/parents/'+r['domain']+'.gd'
 dest=G/snap[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True)
 with dest.open('xb') as f:f.write(old)
 targets[r['target']]={'target':r['target'],'old_sha256':r['old_sha256'],'old_snapshot':snap,'candidate':r['candidate'],'whole_byte_inverse_proof':True}
for p,d in [('res://data/maps/luoyang_full_city_20261022ap/execution_successor.json',hand['execution_proposal']),('res://data/luoyang_culture_integration_20261019x/runtime_contract.json',hand['contract'])]:targets[p]['candidate']=d
assert len(targets)==28
for r in targets.values():assert sha(read(r['target'],r['old_sha256']))==sha(read(r['old_snapshot'],r['old_sha256']))
out={'status':'REQUEST_ROOT_EXACT28_SCOPE_NOT_STAGE_OR_DEPLOY_PERMISSION','target_count':28,'targets':list(targets.values()),'current_actual_stage':stagepin,'unchanged_router_excluded':True,'unchanged_registry_ENV_author_ENVindex_not_targets':True,'native_media_not_targets':True,'new_runtime_manifests_and_adapter_binding_build_only':True,'candidate_production_flags_not_deployment_permission':True}
dest=H/'finite_adapter_production08_scope/scope_request_READY.json';assert not dest.exists()
b=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb') as f:f.write(b)
print(json.dumps({'path':S+'finite_adapter_production08_scope/scope_request_READY.json','sha256':sha(b),'targets':len(targets)}))
