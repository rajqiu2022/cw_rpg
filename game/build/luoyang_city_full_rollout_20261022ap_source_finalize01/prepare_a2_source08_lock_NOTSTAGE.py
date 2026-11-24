"""Lock NEW source input to actual two-leaf promotion and Root scopes. No stage."""
import copy
import hashlib
import json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
O=S+'a2_source_recipe08/'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):return G/p[6:]
def read(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
parentpath=S+'a2_source_recipe07/source_input_PENDING_PROMOTION.json'
parentsha='d87dddd72b05fc6fd025e3c9052ab0f1aa999aca916e789c15693aa84072b64a'
spec=json.loads(read(parentpath,parentsha));parent=copy.deepcopy(spec)
promotionpath=R+'integration15/two_mask_media_promotion_actual.json'
promotionsha='6deeda055ce403d79fb2f440e3c61f850fac962221c607945279dd7cc2b63a64'
promotion=json.loads(read(promotionpath,promotionsha))
assert promotion['status']=='ROOT_EXACT_TWO_A2_MASK_IMPORT_LEAVES_PROMOTED' and promotion['passed'] is True and promotion['target_count']==2
scope=next(r for r in spec['pinned_inputs'] if r['id']=='a2_root_scope')
scopevalue=json.loads(read(scope['path'],scope['sha256']))
assert scope['sha256']=='350d22e9d57a1622b6d08e0b3d18ab127ecbab9e740c2baa04f67ebb7dee4892'
assert scopevalue['request_sha256']=='b2e0ef8625e93198d48086030d0a1832bcc932d8c821a946a3490592adaca219' and scopevalue['target_count']==28
freshpath=R+'integration16/guard_before.json'
freshsha='0a714f5bd18db5d68a7ee8fd91a1e66ac1af666b76381f407bf6d6a0756c8a1d'
read(freshpath,freshsha)
spec['pinned_inputs'].append({'id':'a2_mask_promotion_actual','path':promotionpath,'sha256':promotionsha})
spec['pinned_inputs'].append({'id':'a2_Root16_fresh_before','path':freshpath,'sha256':freshsha})
spec['a2_contract']['mask_promotion_input']='a2_mask_promotion_actual'
spec['a2_contract']['mask_promotion_gate']={'input':'a2_mask_promotion_actual','pointer':[],'equals':promotion}
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
spec['root_fresh_deploy_baseline']={'path':freshpath,'sha256':freshsha,'separate_from_scope15_before4528':True,'not_a_deployment_authorization':True,'expected_final_path_count':2117}
tool=spec['required_generator'];read(tool['path'],tool['sha256'])
assert tool['sha256']=='6dd7ff3b39841461d1c6573bbd60230e8afce578dbfdc271c7604e71e0152920'
spec['root_lock_scope']['still_not_deployment_authorization']=True
proof={'status':'A2_FINAL_INPUT_ROOT_READ_REQUIRED_NOT_STAGE','parent_input':{'path':parentpath,'sha256':parentsha},'tool':tool,'changes':['fixed actual Root15 two-leaf promotion input/whole receipt gate','fixed independent Root16 fresh before reference, not deployment permission','status ROOT_LOCKED/blockers[] per Root instruction; original nodes/groups/targets unchanged'],'scope350D_requestB2E_28_old_targets_unchanged':True,'two_media_actual':{'path':promotionpath,'sha256':promotionsha},'symbolic_review':{'path':S+'a2_source_recipe07/symbolic_order_and_oldpointer_review_READY.json','sha256':'f0d80b7f58c2b1c43659df0e88abcddd1045b26f2bfeb3c8b43a5257888af566'},'no_stage_engine_collector_native_decode_or_canonical_writes':True}
outputs={O+'source_input_ROOT_LOCKED.json':js(spec),O+'input_lock_inheritance_READY.json':js(proof)}
assert not path(O).exists()
for p,b in outputs.items():
    assert not path(p).exists();path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'input':{'path':O+'source_input_ROOT_LOCKED.json','sha256':sha(js(spec))},'proof_sha256':sha(js(proof)),'tool':tool,'stage_runs':0}))
