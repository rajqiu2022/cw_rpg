from pathlib import Path
import json,hashlib,struct
N=Path(__file__).resolve().parent;GAME=N.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
def physical(p):return GAME/p.removeprefix('res://')
parent_input=(N/'finish8_publication_input09_ROOT_READY.json').read_bytes()
a=json.loads(parent_input)
prior=physical(a['priors']['temple']['path']) if 'temple' in a.get('priors',{}) else None
# Use only the exact already-pinned independent source expectation, not publication observations.
prior_path='res://build/luoyang_city_finish_20261025i_system01/qa_role_new/temple_prior02_ROOT_READY/output_ROOT_READY/108880/prior.json'
pb=physical(prior_path).read_bytes();assert sha(pb)=='97ca9a5e77334432695e9f27795a2d274487ac2055d6ea48597ba9532cbf3770'
auth_path=NS+'author_temple_source_compiled03_NOTREADY.json'
ab=physical(auth_path).read_bytes();assert sha(ab)=='0a8ab1db61b0f8109b26c2b82921be17869278a4f02934b96c47230775e102a3'
expected=json.loads(pb)['prior']['expected_source_author'];actual=json.loads(ab)
coordinates={'foot_px','source_ground_anchor_px','size_px','ground_polygon_px','floor_regions_px'}
differences=[]
def walk(x,y,path=()):
    if set(path)&coordinates and isinstance(x,list) and isinstance(y,list) and len(x)==len(y)==2 and all(type(v) in (int,float) for v in x+y):
        assert struct.pack('<2f',*x)==struct.pack('<2f',*y),path
        return
    if type(x) in (int,float) and type(y) in (int,float):
        if float(x)!=float(y): differences.append(dict(path=list(path),expected=x,authored=y,expected_f32_bits=struct.pack('<f',x).hex(),authored_f32_bits=struct.pack('<f',y).hex()))
        return
    assert type(x)==type(y),path
    if isinstance(x,dict):
        assert x.keys()==y.keys(),path
        for k in x:walk(x[k],y[k],path+(k,))
    elif isinstance(x,list):
        assert len(x)==len(y),path
        for i,(u,v) in enumerate(zip(x,y)):walk(u,v,path+(str(i),))
    else:assert x==y,path
walk(expected,actual)
assert len(differences)==5
for i,d in enumerate(differences):
    assert d['path']==['interaction_relocations',str(i),'new_pos_uv','0']
    assert d['expected_f32_bits']==d['authored_f32_bits']
report=emit('temple_schema_new_pos_uv_only_READONLY.json',(json.dumps(dict(status='EXACT_INDEPENDENT_SOURCE_SCHEMA_DIFF_ONLY_JSON_UV_DECIMAL_SERIALIZATION',independent_prior=dict(path=prior_path,sha256=sha(pb)),source_author=dict(path=auth_path,sha256=sha(ab)),differences=differences,all_other_schema_and_noncoordinate_numbers_exact=True,geometry_changed=False,epsilon_used=False,Godot_JSON_number_semantics='JSON.parse_string parses both integer and decimal tokens as float; Python int/float token distinction is not a Godot runtime type difference.',engine_calls=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
actual_report_path=NS+'publication09/output_ROOT_READY/18720/result.json'
rb=physical(actual_report_path).read_bytes();assert sha(rb)=='446959513e454d486d716ea392922a4b14f00fd8e242ac78450b70ef6554d07a'
r=json.loads(rb);assert len(r['scenes'])==5 and r['source_first']==r['source_final']
a['ready']=False;a['root_run_authorized']=False;a['output_root']=NS+'publication10/output_NOTREADY'
a['inherited_scenes']=r['scenes'];a['sources'][actual_report_path]=sha(rb)
def pin(value):
    if isinstance(value,dict):
        if {'path','sha256'}<=value.keys() and value['path'].startswith('res://'):
            assert sha(physical(value['path']).read_bytes())==value['sha256']
            a['sources'][value['path']]=value['sha256']
        for v in value.values():pin(v)
    elif isinstance(value,list):
        for v in value:pin(v)
pin(r['scenes'])
a['inherited_publication_component']={'path':actual_report_path,'sha256':sha(rb),'whole_pass':False,'scope':'Root admitted first5 complete scene components; original Temple wholeFAIL preserved. No geometry/raster replay of first5.'}
ip=emit('finish8_publication_input10_NOTREADY.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
old=(N/'publish_finish8_components09_ROOT_READY.gd').read_bytes();t=old.decode('utf-8');hunks=[]
for o,n in [
 ('const READY: bool=true','const READY: bool=false'),
 ('const INPUT: String="'+NS+'finish8_publication_input09_ROOT_READY.json"\nconst INPUT_SHA: String="'+sha(parent_input)+'"','const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"'),
 ('["foot_px","source_ground_anchor_px","size_px","ground_polygon_px","floor_regions_px"]','["foot_px","source_ground_anchor_px","size_px","ground_polygon_px","floor_regions_px","new_pos_uv"]')]:
    assert t.count(o)==1;t=t.replace(o,n);hunks.append(dict(old=o,new=n))
back=t
for h in reversed(hunks):back=back.replace(h['new'],h['old'])
assert back.encode('utf-8')==old
key=emit('publish_finish8_components10_NOTREADY.gd',t.encode('utf-8'))
proof=emit('publication10_temple_UV_coordinate_schema_whole_inverse_BUILD.json',(json.dumps(dict(status='EXPLICIT_NEW_POS_UV_VECTOR2F32_COORDINATE_CONTAINER_ONLY',entry=key,input=ip,diagnostic=report,parent_sha256=sha(old),hunks=hunks,whole_byte_inverse=True,inherited_scene_count=5,remaining_scene_count=3,all_old_gates_preserved=True,actual_final25Packed_comparison_preserved=True,engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(dict(entry=key,input=ip,diagnostic=report,proof=proof)))
