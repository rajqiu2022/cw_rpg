"""Static data/byte audit only. Does not import the producer or execute Stage."""
from pathlib import Path
import copy
import hashlib
import json

QA=Path(__file__).resolve().parent
GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration35'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):
    assert p.startswith('res://')
    return GAME/p[6:]
def same(a,b):
    return type(a)is type(b) and (a.keys()==b.keys() and all(same(a[k],b[k])for k in a) if isinstance(a,dict) else len(a)==len(b) and all(same(x,y)for x,y in zip(a,b)) if isinstance(a,list) else a==b)
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def at(v,keys):
    for k in keys:v=v[k]
    return v

dp=S/'stage_performance48_estate17_READY.py'
ip=S/'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json'
assert sha(dp)=='868c36954db0397c320a93eb04ab4f9ff95f3cf1e1d5c432ab1fa06de1d0c0c8'
assert sha(ip)=='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a'
d,s=dp.read_bytes(),rd(ip)
p47p=S/'performance47_estate17_source_recipe/driver_input_whole_inverse_READY.json'
p48p=S/'performance48_estate17_source_recipe/triple_guard_whole_inverse_READY.json'
assert sha(p47p)=='e22da4835617ae6eb00effdcde49f09245d50200fc36e17e214bd8600655c648'
assert sha(p48p)=='56cc807c5a0ff85e6b9926ea8ee92d1088cdd0fcb9862a5806e2bfa61f2ea267'
p47,p48=rd(p47p),rd(p48p)
old48,new48=(p48['one_hunk'][k].encode()for k in ['old','new'])
assert d.count(new48)==1
d47=d.replace(new48,old48,1)
assert hashlib.sha256(d47).hexdigest()==p48['parent_driver_sha256']
d42=res(p47['parent_driver']['path']).read_bytes()
assert hashlib.sha256(d42).hexdigest()==p47['parent_driver']['sha256']
forward=d42
for h in reversed(p47['driver_hunks']):
    a,b=h['old_start'],h['old_end']
    assert d42[a:b]==h['old'].encode()
    forward=forward[:a]+h['new'].encode()+forward[b:]
assert forward==d47
inverse=d47
for h in reversed(p47['driver_hunks']):
    a,b=h['new_start'],h['new_end']
    assert d47[a:b]==h['new'].encode()
    inverse=inverse[:a]+h['old'].encode()+inverse[b:]
assert inverse==d42
in47=copy.deepcopy(s)
in47['required_generator']={'path':'res://'+(S/'stage_performance47_estate17_READY.py').relative_to(GAME).as_posix(),'sha256':p48['parent_driver_sha256']}
assert hashlib.sha256(encode(in47)).hexdigest()==p48['input_parent_sha256']
in42=copy.deepcopy(in47)
for delta in reversed(p47['input_deltas']):
    keys=delta['pointer'];holder=at(in42,keys[:-1]);key=keys[-1]
    assert same(holder[key],delta['new'])
    holder[key]=copy.deepcopy(delta['old'])
parent_input=res(p47['parent_input']['path'])
assert sha(parent_input)==p47['parent_input']['sha256']
assert same(in42,rd(parent_input)) and encode(in42)==parent_input.read_bytes()
assert len(p47['input_deltas'])==73

# All45 are metadata/short code/report pins; no media or native decoding.
pins={x['id']:x for x in s['pinned_inputs']}
assert len(pins)==len(s['pinned_inputs'])==45
hashed_bytes=0
for pin in pins.values():
    p=res(pin['path']);assert p.stat().st_size<8*1024*1024
    assert sha(p)==pin['sha256'];hashed_bytes+=p.stat().st_size
root=rd(R/'preparation_scope_approval.json')
assert sha(R/'preparation_scope_approval.json')=='61696f03de75249a8ce133319106b258e3f78d6efbfae1db52095b7fd0605bf2'
assert same(root,s['B_only_contract']['expected_Root_document'])
assert root['Stage_execution_authorized']is False and root['deployment_authorized']is False and root['engine_authorized']is False
scope=res(pins['estate17_scope_request']['path']);sp=rd(scope)
assert sha(scope)=='a7d5fc152a5740a435d6f8314c825862127fffce1635d97bc7fbacf319695b6a'
backups=rd(R/'old_full_backups_READY.json')
assert sha(R/'old_full_backups_READY.json')=='17fb9dc23ec6236a5eaac7183a3e31983ce2c60d3eed0d49e96f19cec679ee1d'
assert backups['target_count']==17 and len(backups['targets'])==17
targets={x['target']:x['old_sha256']for x in sp['targets']}
assert list(targets)==s['root_target_allowlist'] and len(targets)==17
stage=rd(res(pins['estate17_parent_stage']['path']))
prior={x['target']:x['candidate_sha256']for x in stage['targets']}
assert all(prior.get(k)==v for k,v in targets.items())
for row in backups['targets']:
    target,backup=Path(row['path']),Path(row['backup_path'])
    k='res://'+target.relative_to(GAME).as_posix()
    assert sha(backup)==sha(target)==row['sha256']==targets[k]
    assert target.read_bytes()==backup.read_bytes() and backup.stat().st_size==row['bytes']
nodes={x['id']:x for x in s['nodes']}
actual_targets={x['target']:x['old_sha256']for x in s['nodes']if 'target'in x}
assert actual_targets==targets
assert sum(k.endswith('.gd')for k in targets)==6 and sum(k.endswith('.json')for k in targets)==11
assert s['pass_through_targets']==s['prospective_targets']==[]
assert pins[s['authority_input']]['sha256']=='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
assert {x['id']for x in s['nodes']if x['kind']=='estate17_frozen'}==set(p47['frozen_nodes'])
for ident,digest in p47['frozen_nodes'].items():
    n=nodes[ident];assert 'target'not in n and n['immutable_sha256']==pins[n['base_input']]['sha256']==digest
for n in s['nodes']:
    if n['kind']=='index':
        b=res(pins[n['base_input']]['path']).read_bytes()
        assert b.endswith(b'\n')and b'\r'not in b and not b.startswith(b'\xef\xbb\xbf')
    if n['kind']=='metadata':
        old=rd(res(pins[n['base_input']]['path']))
        for op in n.get('operations',[]):
            assert op['op']=='set' and op['existed']is True and same(at(old,op['pointer']),op['old'])
            assert op['pointer'][0]in ['registry_sha256','legacy_source_sha256','runtime_authority_sha256']
        if 'protected_pointers'in n:
            for p in n['protected_pointers']:at(old,p)

scalar=rd(res(pins['estate17_scalar_inverse']['path']))
candidate=res(pins['estate17_scalar_candidate']['path']).read_bytes()
parent=res(scalar['parent']['path']).read_bytes()
old,new=rd(res(scalar['parent']['path'])),json.loads(candidate)
registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
f529='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'
assert new['registry_path']==registry and new['registry_sha256']==new['source_sha256'][registry]==f529
new['registry_sha256']=old['registry_sha256']
assert same(old,new)and encode(new)==parent
assert same(nodes['estate_final']['operations'],[scalar['operation']])
assert len(s['source_groups'])==48 and len(s['required_gates'])==5
assert s['required_gates'][-1]['equals']==17
base=S/'stage_unified06_04_READY.py'
assert sha(base)=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
text=dp.read_text(encoding='utf-8')
for literal in ['ALL_PINNED_SOURCE_FIRST_FINAL_SAME','ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED','PATCH6_COPY11_EXACT_DISJOINT_UNION17','ONLY_FULL_TYPED_INVERSE_GENERATED_JSON','M._strict_lf_build_file_patch','FIXED_REGISTRY_PATH_SCALAR_DECLARED_SOURCE_TRIPLE_EQUALITY']:
    assert literal in text
assert not res(s['output_root']).exists()

out=QA/'estate48_scalar17_driver_input_independent_preStage_admission_READY.json'
assert not out.exists()
receipt={'status':'ESTATE48_EXACT17_METADATA_STAGE_STATIC_NO_BLOCKER_ROOT_ONLY_EXECUTION_DECISION',
 'driver':{'path':str(dp),'sha256':sha(dp)},'input':{'path':str(ip),'sha256':sha(ip)},
 'inverse':{'47_tool_hunks':len(p47['driver_hunks']),'47_input_deltas':73,'48_single_added_semantic_guard':True,'whole_tool_forward_reverse_to42':True,'whole_input_typed_serialized_inverse_to42':True},
 'checked':{'45small_pins_SHA_current_exact':True,'small_pinned_bytes':hashed_bytes,'Root35_preparation_schema_whole_typed_exact':True,'17_full_old_backups_scope_current_exact':True,'old_pins_from_5B455_candidate_values_not_old_values':True,'17_targets_6GD11JSON':True,'0runtime_passthrough_or_owned_edges':True,'6GD_original_LF_and_original_strict_transport':True,'Estate_only_one_scalar_exact2410':True,'registry_path_scalar_declared_source_fixedF529_three_equal':True,'48groups_and_five_gates_maintained':True,'13?metadata_note':'This scope has11 JSON outputs, not inherited13/14 output labels.','fourT_runtime_authority_and_native_protected_fields_inherited_no_changes':True,'unchanged8DE0_core':True,'FIRST_FINAL_and_buffered_NEW_only_output_checks_maintained':True},
 'unchanged':['executionBF043/85proofs/10owned','runtime B/C/DT/G/Fade/Field/Router/Family/Coordinator/Temple','registryF529bytes/12rows','Quarter/ENV/ExecIndex','nativeScene/layout/packet/mask/geometry'],
 'boundaries':['No Stage performed; generated candidate exactness/final counts remain future Root actual evidence.','No new engine or collector/G method;557 remains intended guard until catalogue naturally admits.','Original hall33/34 failures/crashes retained; no next-stage guarantee.','No all-cityART or performance/whole runtime pass.'],
 'operations':{'Stage':0,'engine':0,'collector':0,'media_or_native_decode':0,'big_media_hash':0,'canonical_write':0}}
out.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'no_blocker':True,'small_pin_bytes':hashed_bytes}))
