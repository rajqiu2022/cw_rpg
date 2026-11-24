"""NEW exact successors for real Root scope schema + frozen Docks22 pin.

Only preparation/AST validation; never import/instantiate or run Stage.
"""
import ast
import copy
import difflib
import hashlib
import json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'a2_source_recipe06/'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return G/p[6:]
def read(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
scopepath='res://build/luoyang_city_full_rollout_20261022ap_root01/integration15/root_scope28_plus_two_media_READY.json'
scopesha='350d22e9d57a1622b6d08e0b3d18ab127ecbab9e740c2baa04f67ebb7dee4892'
scope=json.loads(read(scopepath,scopesha))
assert scope['approved_by_root'] is True and scope['request_sha256']=='b2e0ef8625e93198d48086030d0a1832bcc932d8c821a946a3490592adaca219'
toolold=read(S+'stage_a2_source05_READY.py','2110f66613dfe3f7879ba7745d41dca434816fa888a59b367d595af4e591f0f9')
text=toolold.decode();changes=[]
def sub(old,new,label):
    global text
    assert text.count(old)==1,(label,text.count(old))
    text=text.replace(old,new,1);changes.append({'label':label,'old':old,'new':new})
sub("scope.get('scope_sha256')==REQUEST", "scope.get('request_sha256')==REQUEST and self.inputs[c['scope_input']]['sha256']=='"+scopesha+"'", 'fixed350D_actual_request_sha256_schema')
anchor="        for row in request['targets']:\n            need(self.read(row['target'],row['old_sha256'])==self.read(row['old_snapshot'],row['old_sha256']),'ROOT_SCOPE_FROZEN_OLD_BYTES')\n"
extra=anchor+'''        for row in scope['targets']:
            backup=Path(row['backup_path']).resolve()
            need(backup.is_relative_to(M.ROOT) and row['backup_sha256']==row['old_sha256'],'ROOT_EXACT28_BACKUP_DOMAIN_AND_SHA')
            backup_resource='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(backup_resource,row['backup_sha256'])==self.read(row['target'],row['old_sha256']),'ALL28_COMPLETE_ROOT_OLD_BYTE_BACKUPS')
        lineage=self.read_json_input(c['docks22_lineage_input'])['source_sha256']
        family='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
        expected=copy.deepcopy(lineage)
        family_row=next(r for r in self.hand['consumers'] if r['target']==family)
        need(len(expected)==22 and expected.get(family)==family_row['old_sha256'],'EXACT_FROZEN22_FAMILY_PREDECESSOR')
        expected[family]=family_row['candidate']['sha256']
        group=self.groups['unified_docks22']
        need(group['kind']=='explicit' and same(self.value(group['leaves']),expected),'ONLY_FAMILY_SUCCESSOR_IN_FROZEN22_OTHERS_IDENTICAL')
'''
sub(anchor,extra,'all28_actual_full_byte_backups_and_frozen22_exact_Family_successor')
ast.parse(text)
back=text
for row in reversed(changes):
    assert back.count(row['new'])==1
    back=back.replace(row['new'],row['old'],1)
assert back.encode()==toolold
spec=json.loads(read(S+'a2_source_recipe05/source_input_PENDING_ROOT.json','c399f0d8ab8172bc216dbbd33232aeeef4c3f1ae389883d4c4ed038d1179fc9e'))
parent=copy.deepcopy(spec)
pins={r['id']:r for r in spec['pinned_inputs']}
lineage_pin=pins['docks22_lineage']
lineage=json.loads(read(lineage_pin['path'],lineage_pin['sha256']))['source_sha256']
family='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
assert len(lineage)==22 and lineage[family]=='cc97a68a178936ccb6bf54c1c8a65292adaeb7e5f6ae5a314c343810d07210f1'
family_new=next(r['sha256'] for r in spec['prospective_targets'] if r['target']==family)
replacement=copy.deepcopy(lineage);replacement[family]=family_new
group=next(g for g in spec['source_groups'] if g['id']=='unified_docks22')
group.clear();group.update({'id':'unified_docks22','kind':'explicit','leaves':replacement})
spec['a2_contract']['docks22_lineage_input']='docks22_lineage'
pins['a2_root_scope']={'id':'a2_root_scope','path':scopepath,'sha256':scopesha}
spec['pinned_inputs']=list(pins.values())
spec['a2_contract']['scope_input']='a2_root_scope'
spec['root_lock_scope']={'path':scopepath,'sha256':scopesha,'before_sha256':scope['before_sha256'],'exact_target_count':28,'canonical_deployment_still_requires_fresh_plan_authorization':True}
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='a2_root_scope',pointer=['approved_by_root'],equals=True)
spec['blockers']=['Root exact two mask leaf promotion actual','Root full stager/input read and external SHA lock']
spec['required_generator']={'path':S+'stage_a2_source06_READY.py','sha256':sha(text.encode())}
proof={'status':'A2_SOURCE_PREPARATION06_NOT_STAGE','parent05_input_sha256':'c399f0d8ab8172bc216dbbd33232aeeef4c3f1ae389883d4c4ed038d1179fc9e','parent05_tool_preserved_unexecuted':True,'tool_whole_byte_inverse_to05':True,'tool_changes':changes,'scope':{'path':scopepath,'sha256':scopesha},'docks22_lineage':lineage_pin,'docks22_changed_only_Family':{'path':family,'old_sha256':lineage[family],'new_sha256':family_new},'all_other21_declared_leaves_unchanged':True,'root_exact28_scope_request_unchanged':True,'no_stage_engine_collector_decode_or_canonical_writes':True}
outputs={S+'stage_a2_source06_READY.py':text.encode(),O+'source_input_PENDING_PROMOTION.json':js(spec),O+'exact06_tool_and_lineage_successor_proof_READY.json':js(proof),O+'stage06_vs05.diff':''.join(difflib.unified_diff(toolold.decode().splitlines(True),text.splitlines(True),fromfile='frozen_stage05_unexecuted',tofile='stage06',n=4)).encode()}
assert not path(O).exists()
for p,b in outputs.items():
    assert not path(p).exists();path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'tool':{'path':S+'stage_a2_source06_READY.py','sha256':sha(text.encode())},'input':{'path':O+'source_input_PENDING_PROMOTION.json','sha256':sha(js(spec))},'proof_sha256':sha(js(proof)),'stage_calls':0}))
