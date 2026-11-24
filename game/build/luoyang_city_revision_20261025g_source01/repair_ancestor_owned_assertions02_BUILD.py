"""Root requested residual: exact ancestor model old-value assertions only, driver unchanged."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(pin):
    raw=(GAME/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
pin=dict(path=S+'source_input_courtyard45_exact32_ROOT_REVIEW.json',sha256='dc94b2cb95be82df619722fcdcfc179b3edc669fe26c9fffeebd31552457d6a7')
raw=(GAME/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];old=json.loads(raw);new=copy.deepcopy(old)
pins={r['id']:r for r in new['pinned_inputs']};authority=load(pins[new['authority_input']])
assert len(authority['owned'])==10 and len(authority['source_sha256'])==170
changes=[];counts={}
for n in new['nodes']:
    if n['kind']!='docks_incremental_map':continue
    base=load(pins[n['ancestor_base_input']])['source_sha256']
    model={p:authority['owned'][p]['current_sha256'] if p in authority['owned'] else h for p,h in base.items()}
    for index,op in enumerate(n['ancestor_operations']):
        path=op['pointer'];assert len(path)==2 and path[0]=='source_sha256'
        p=path[1]
        if op['existed'] and model.get(p)!=op['old']:
            assert p in authority['owned'] and op['op']=='set' and model[p]==authority['owned'][p]['current_sha256']
            changes.append(dict(scene_id=n['scene_id'],node=n['id'],ancestor_operation_index=index,pointer=path,old=op['old'],new=model[p],cause='Model first promotes to newly approved owned currentSHA, so exact old assertion must be that value; no historical authorization changed.'))
            op['old']=model[p];counts[n['scene_id']]=counts.get(n['scene_id'],0)+1
        assert (p in model)==op['existed']
        if op['existed']:assert model[p]==op['old']
        if op['op']=='set':model[p]=op['new']
        elif op['op']=='remove':del model[p]
        else:raise AssertionError(op)
assert counts=={'ch4_s0_luoyang_gate':3,'ch4_s1_luoyang_yamen':4,'ch4_s2_canal_docks':6,'ch4_s3_luoyang_market':5}
assert len(changes)==18
new['output_root']=S+'outputs/root_market_courtyard45_exact32_stage02/'
for key in old:
    if key not in ['nodes','output_root']:assert old[key]==new[key]
restored=copy.deepcopy(new)
byid={r['id']:r for r in restored['nodes']}
for d in changes:byid[d['node']]['ancestor_operations'][d['ancestor_operation_index']]['old']=d['old']
restored['output_root']=old['output_root'];assert enc(restored)==raw
child=enc(new);dest=HERE/'source_input_courtyard45_exact32_residual02_ROOT_REVIEW.json'
with dest.open('xb') as out:out.write(child)
aa,bb=raw.decode().splitlines(keepends=True),child.decode().splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,v=raw,child
for d in reversed(patch):
    i,j=d['old_offset'],d['new_offset'];a,b=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a and v[j:j+len(b)]==b;f=f[:i]+b+f[i+len(a):];v=v[:j]+a+v[j+len(b):]
assert f==child and v==raw
report=dict(status='EXACT32_ANCESTOR_MODEL_18_OLD_VALUE_ASSERTIONS_RESIDUAL_NOT_EXECUTED',parent_input=pin,input=dict(path=S+dest.name,sha256=sha(child),bytes=len(child)),driver_unchanged=new['required_generator'],changes=changes,count_by_scene=counts,new_output_root=new['output_root'],whole_typed_serialized_inverse=True,offset_byte_patch=patch,whole_byte_forward_inverse=True,all32_candidates_and_current_parent_incremental_operations_and_source_groups_unchanged=True,owned10_proof170_depth16_all_gates_unchanged=True,first_failed_driver_input_and_output_namespace_preserved=True,Stage_imports=0,Stage_calls=0,engine_calls=0,canonical_writes=0)
out=HERE/'courtyard32_residual02_input_exact_inverse_NOT_EXECUTED.json';r=enc(report)
with out.open('xb') as stream:stream.write(r)
print(json.dumps(dict(input=report['input'],driver=report['driver_unchanged'],proof=dict(path=S+out.name,sha256=sha(r),bytes=len(r)),counts=counts)))
