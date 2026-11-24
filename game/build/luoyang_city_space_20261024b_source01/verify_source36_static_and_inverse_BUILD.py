"""Finite static proof only. Does not import a compiler or evaluate source hashes."""
from pathlib import Path
import json
import hashlib
import difflib
import base64

GAME=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
H='res://build/luoyang_hall_portal_fix_20261024a_source01/'

def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):
    b=(GAME/p[6:]).read_bytes();assert b'tokens truncated' not in b;return b
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def at(v,keys):
    for k in keys:v=v[k]
    return v
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def write(name,b):
    p=HERE/name
    with p.open('xb') as stream:stream.write(b)
    return dict(path='res://'+p.relative_to(GAME).as_posix(),sha256=sha(b),bytes=len(b))

parent_input=H+'actor_parent_successor02/source_input_ROOT_READY.json'
input_path=S+'source_input36_ROOT_READY.json'
parent_driver=H+'actor_parent_successor02/stage_RGB22_ROOT_READY.py'
driver_path=S+'stage_market_dialogue36_NOTREADY.py'
new=json.loads(read(input_path));old=json.loads(read(parent_input))
pins={r['id']:r for r in new['pinned_inputs']}
assert new['required_generator']==dict(path=driver_path,sha256=sha(read(driver_path)))
assert len(new['root_target_allowlist'])==36 and len(new['pass_through_targets'])==14
assert len(set(new['root_target_allowlist']))==36
known=set();groups={g['id']:g for g in new['source_groups']};operation_count=0;visited_groups=set()
def refs(value):
    if isinstance(value,dict):
        if '$sha' in value:assert value['$sha'] in known,('EARLY_NODE',value)
        if '$pin' in value:assert value['$pin'] in pins,('UNKNOWN_PIN',value)
        for v in value.values():refs(v)
    elif isinstance(value,list):
        for v in value:refs(v)
def group(k,stack):
    assert k not in stack,('GROUP_CYCLE',k)
    g=groups[k];visited_groups.add(k);refs(g)
    if g['kind']=='input_dictionary':assert g['input'] in pins
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for child in g['groups']:group(child,stack+[k])
for n in new['nodes']:
    assert n['id'] not in known
    if n['kind'] not in ['index','space_execution','space_code','space_frozen','map']:
        p=pins[n['base_input']];base=json.loads(read(p['path']))
        for op in n.get('operations',[]):
            holder=at(base,op['pointer'][:-1]);key=op['pointer'][-1]
            assert (key in holder)==op['existed'],('OLD_EXISTENCE',n['id'],op['pointer'])
            assert not op['existed'] or same(holder[key],op['old']),('OLD_VALUE',n['id'],op['pointer'])
            operation_count+=1
    refs(n.get('operations',[]));refs(n.get('replacements',[]))
    uses=n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[g for f in n.get('source_fields',[]) for g in f.get('groups',[])]
    for k in uses:group(k,[])
    known.add(n['id'])
assert len(known)==30
def patch_pair(before_path,after_path):
    a,b=read(before_path),read(after_path)
    changes=[]
    matcher=difflib.SequenceMatcher(None,a,b,autojunk=False)
    for tag,i,j,k,l in matcher.get_opcodes():
        if tag!='equal':changes.append(dict(old_offset=i,new_offset=k,old_length=j-i,new_length=l-k,
            old_base64=base64.b64encode(a[i:j]).decode('ascii'),new_base64=base64.b64encode(b[k:l]).decode('ascii')))
    forward=bytearray(a);inverse=bytearray(b)
    for c in reversed(changes):
        oldbytes=base64.b64decode(c['old_base64']);newbytes=base64.b64decode(c['new_base64'])
        assert forward[c['old_offset']:c['old_offset']+c['old_length']]==oldbytes
        assert inverse[c['new_offset']:c['new_offset']+c['new_length']]==newbytes
        forward[c['old_offset']:c['old_offset']+c['old_length']]=newbytes
        inverse[c['new_offset']:c['new_offset']+c['new_length']]=oldbytes
    assert bytes(forward)==b and bytes(inverse)==a
    return dict(parent=dict(path=before_path,sha256=sha(a),bytes=len(a)),candidate=dict(path=after_path,sha256=sha(b),bytes=len(b)),
                ordered_offset_segments=changes,whole_byte_forward_inverse=True)
patches=write('source36_driver_input_complete_offset_inverse.json',encode(dict(driver=patch_pair(parent_driver,driver_path),input=patch_pair(parent_input,input_path))))
result=dict(status='SOURCE36_FINITE_STATIC_STRUCTURE_AND_COMPLETE_BYTE_INVERSE_NOT_STAGE',ready=False,
    driver=dict(path=driver_path,sha256=sha(read(driver_path))),input=dict(path=input_path,sha256=sha(read(input_path))),
    complete_offset_inverse=patches,target_count=36,patch_GD=21,copy_JSON=15,node_count=len(known),source_groups=len(groups),pinned_inputs=len(pins),
    old_metadata_pointer_count=operation_count,all_old_existence_types_values_exact=True,all_node_refs_topological=True,all_reachable_group_refs_acyclic=True,
    original8DE0_core_unchanged=True,source_collector_calls=0,compiler_imports=0,Stage_calls=0,engine_calls=0,canonical_writes=0,
    limited_exceptions=['Exact Market immutable header from binding003EC, full old parent inverse','Estate five exact F219 ordinary keys, original policy and full typed/UTF8 inverse'],
    inherited=['Root64 ordinary classification','all109 previous proof leaves and ten member identity','four independent original AO map baselines','five native gates','source-FIRST/FINAL','Estate registry three equality'],
    actual_runtime_or_whole_street_ART_credit=False)
out=write('source36_static_and_wholeinverse_NOT_STAGE.json',encode(result))
print(json.dumps(dict(review=out,offset_inverse=patches,old_pointer_count=operation_count)))
