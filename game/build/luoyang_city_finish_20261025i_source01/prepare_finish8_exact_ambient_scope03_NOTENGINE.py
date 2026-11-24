from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
out=[]
for role in ['C','Estate']:
    p=json.loads((N/(role+'_finish8_consumer02_direct_formal_whole_inverse_BUILD.json')).read_text(encoding='utf-8'))
    old=(G/p['candidate']['path'].removeprefix('res://')).read_bytes();assert sha(old)==p['candidate']['sha256']
    raw=(G/p['target'].removeprefix('res://')).read_bytes();assert sha(raw)==p['parent_sha256']
    t=old.decode('utf-8');delta=[]
    def change(a,b):
        global t
        assert t.count(a)==1,(role,a,t.count(a));t=t.replace(a,b);delta.append(dict(old=a,new=b))
    if role=='C':
        change('\tif FINISH25I_ENABLED:\n\t\tvar terminal: Variant=_finish25i_runtime()\n\t\tif terminal==null: return {}\n\t\tvar terminal_paths:',
               '\tif FINISH25I_ENABLED and owns_id(id):\n\t\tvar terminal: Variant=_finish25i_runtime()\n\t\tif terminal==null: return {}\n\t\tvar terminal_paths:')
    else:
        change('static var _finish25i_handle: Variant=null',
               'const FINISH25I_AMBIENT: String="res://build/luoyang_city_finish_20261025i_system01/ambient18_runtime05_family_receipt_NOTREADY.gd"\nconst FINISH25I_AMBIENT_SHA: String="db339bcb7b5a734a24116f4d73bafb936d075bef445babe7d454d36394da984a"\nstatic var _finish25i_handle: Variant=null')
        change('\t\tpaths.merge(extra,true);paths[FINISH25I_ADAPTER]=true\n', '''		paths.merge(extra,true);paths[FINISH25I_ADAPTER]=true
		if FileAccess.get_sha256(FINISH25I_AMBIENT)!=FINISH25I_AMBIENT_SHA: return {}
		var ambient: Variant=load(FINISH25I_AMBIENT)
		if not ambient is GDScript or ambient.resource_path!=FINISH25I_AMBIENT: return {}
		var ambient_paths: Dictionary=ambient.source_paths_for(ID)
		if ambient_paths.is_empty(): return {}
		paths.merge(ambient_paths,true)
''')
    back=t
    for d in reversed(delta):back=back.replace(d['new'],d['old'])
    assert back.encode('utf-8')==old
    hunks=[]
    for h in p['hunks']:
        v=h['new']
        for d in delta:
            if d['old'] in v:v=v.replace(d['old'],d['new'])
        hunks.append(dict(old=h['old'],new=v))
    forward=raw.decode('utf-8')
    for h in hunks:
        assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'])
    assert forward==t
    back=t
    for h in reversed(hunks):back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==raw
    c=emit(role+'_finish8_exact_ambient_scope03_CANDIDATE.gd',t.encode('utf-8'))
    proof=emit(role+'_finish8_exact_ambient_scope03_direct_formal_inverse_BUILD.json',(json.dumps(dict(status='HARD_FALSE_EXACT_AMBIENT_SOURCE_PARTITION',target=p['target'],parent_sha256=sha(raw),candidate=c,hunks=hunks,whole_byte_inverse=True,layer_parent_candidate=p['candidate'],layer_delta=delta,layer_inverse=True,scope='C only actual four city IDs; Estate source_paths explicitly consumes only its fifth ambient source_paths_for(ID). No room or other field ambient expansion.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    out.append(dict(candidate=c,proof=proof))
print(json.dumps(out))
