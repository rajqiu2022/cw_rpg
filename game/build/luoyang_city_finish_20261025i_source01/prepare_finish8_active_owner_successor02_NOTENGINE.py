from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
outputs=[]
for role,proofname,newname in [
 ('C','C_finish8_ambient01_direct_formal_whole_inverse_BUILD.json','C_finish8_ambient02_CANDIDATE.gd'),
 ('Quarter','Quarter_finish8_original_owner01_whole_inverse_BUILD.json','Quarter_finish8_original_owner02_CANDIDATE.gd'),
 ('Estate','Estate_finish8_original_owner01_whole_inverse_BUILD.json','Estate_finish8_original_owner02_CANDIDATE.gd')]:
    pb=(N/proofname).read_bytes();p=json.loads(pb)
    parent=(G/p['target'].removeprefix('res://')).read_bytes();assert sha(parent)==p['parent_sha256']
    old=(G/p['candidate']['path'].removeprefix('res://')).read_bytes();assert sha(old)==p['candidate']['sha256']
    t=old.decode('utf-8');delta=[]
    def change(a,b):
        global t
        assert t.count(a)==1,(role,a,t.count(a));t=t.replace(a,b);delta.append(dict(old=a,new=b))
    if role=='C':
        change('original_owner_receipts02_source_arrays_NOTREADY.gd','original_owner_receipts03_family_weak_snapshot_NOTREADY.gd')
        change('a427abf67f581e6970135cc4c1fe88393c1db99e9a9cf00b69eaf1dd5f30380a','9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')
    else:
        change('static var _finish25i_original_owners: Dictionary={}','static var _finish25i_original_owners: Dictionary={}\nstatic var _finish25i_active_scenes: Dictionary={}')
        change('\treturn runtime.ensure(scene,receipt.original_native_navigation,receipt.original_parent_blockers,receipt)',
               '\tif not runtime.ensure(scene,receipt.original_native_navigation,receipt.original_parent_blockers,receipt): return false\n\t_finish25i_active_scenes[scene.scene_id]=weakref(scene)\n\treturn true')
        a='''	for row: Dictionary in _finish25i_original_owners.values():
		var scene: SceneScript=row.scene.get_ref()
		if scene!=null and scene.scene_id==id and row.layout.get_ref()==scene.map_layout and runtime.safe_body(scene,foot): return true
	return false'''
        b='''	var active: WeakRef=_finish25i_active_scenes.get(id) as WeakRef
	var scene: SceneScript=active.get_ref() as SceneScript if active!=null else null
	if scene==null or scene.scene_id!=id or scene.map_layout==null: return false
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	return not row.is_empty() and row.scene.get_ref()==scene and row.layout.get_ref()==scene.map_layout and runtime.safe_body(scene,foot)'''
        change(a,b)
    back=t
    for h in reversed(delta):back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==old
    direct=[]
    for h in p['hunks']:
        value=h['new']
        for d in delta:
            if d['old'] in value:value=value.replace(d['old'],d['new'])
        direct.append(dict(old=h['old'],new=value))
    forward=parent.decode('utf-8')
    for h in direct:
        assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'])
    assert forward==t
    inverse=t
    for h in reversed(direct):inverse=inverse.replace(h['new'],h['old'])
    assert inverse.encode('utf-8')==parent
    c=emit(newname,t.encode('utf-8'))
    proof=emit(role+'_finish8_consumer02_direct_formal_whole_inverse_BUILD.json',(json.dumps(dict(status='HARD_FALSE_CONSUMER_FINAL_FUNCTIONAL_REVIEW',target=p['target'],parent_sha256=sha(parent),candidate=c,hunks=direct,whole_byte_inverse=True,layer_parent_candidate=p['candidate'],layer_delta=delta,layer_inverse=True,original_semantics_preserved=True,owner_note='Family id-only safe queries select only the most recently original-matches/ensure-bound exact WeakScene for that id, not OR across parked/new instances. No token rebind; per-Scene snapshots remain original.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    outputs.append(dict(candidate=c,proof=proof))
print(json.dumps(outputs))
