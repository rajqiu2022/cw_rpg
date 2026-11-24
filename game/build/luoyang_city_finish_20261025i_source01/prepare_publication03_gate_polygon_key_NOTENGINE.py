from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
old=(N/'finish8_source_views01_NOTREADY.gd').read_bytes();assert sha(old)=='fb6a7dac70a23fe45a6d521e708325bba43592ad3b5be7ff810ffab727f73f21'
t=old.decode();hunks=[]
def change(o,n):
    global t
    assert t.count(o)==1;t=t.replace(o,n);hunks.append(dict(old=o,new=n))
change('p(old.get("interaction_polygon_px",[]))','p(old.get("city_v3_interaction_polygon_px",[]))')
change('changed.interaction_polygon_px=p(move.new_interaction_polygon_world_f32)','changed.city_v3_interaction_polygon_px=p(move.new_interaction_polygon_world_f32)')
diagnostic='''
static func diagnose(id: String,parent_scene: SceneScript,inputs: Dictionary,helpers: Dictionary) -> Dictionary:
	var result: Dictionary={"scene_present":parent_scene!=null}
	if parent_scene==null or parent_scene.map_layout==null: return result
	var native: Array=parent_scene.map_layout.visual_objects
	result["scene_id"]=String(parent_scene.scene_id);result["layout_path"]=parent_scene.map_layout.resource_path
	if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]:
		var seed: Dictionary=inputs.parent_seed[id]
		result["native_count"]=native.size();result["seed_count"]=seed.native_visual_rows.size()
		result["native_typed_equal"]=var_to_bytes(native)==var_to_bytes(seed.native_visual_rows)
		result["native_var_sha"]=helpers.axis.digest(native);result["seed_var_sha"]=helpers.axis.digest(seed.native_visual_rows)
		result["axis_source_derive_ok"]=helpers.axis.derive(id,inputs.axis_author,inputs.axis_library,inputs.parent_seed).get("ok")==true
		result["interactions"]=[]
		var spec: Dictionary=scene_spec(inputs.axis_author,id)
		for move: Dictionary in spec.get("same_interaction_migrations",[]):
			var prior: Dictionary=find(parent_scene.map_layout.interactions,String(move.id))
			result.interactions.append({"id":move.id,"present":not prior.is_empty(),"keys":prior.keys(),"position":prior.get("pos"),"expected_position":v(move.old_stand_world_px)/SIZE,"old_polygon_type":typeof(prior.get("city_v3_interaction_polygon_px")),"polygon_exact":var_to_bytes(p(prior.get("city_v3_interaction_polygon_px",[])))==var_to_bytes(p(move.old_interaction_polygon_world_px))})
	return result
'''
t+=diagnostic
back=t.removesuffix(diagnostic)
for h in reversed(hunks):back=back.replace(h['new'],h['old'])
assert back.encode()==old
view=emit('finish8_source_views02_gate_polygon_key_NOTREADY.gd',t.encode())
raw=(N/'finish8_publication_input02_ROOT_READY.json').read_bytes();assert sha(raw)=='ee1674b2465051540d6137e21c5fee8418dfc8891a073d2af80af0b54079fab6'
a=json.loads(raw);a['ready']=False;a['root_run_authorized']=False;a['output_root']=NS+'publication03/output_NOTREADY'
a['sources'].pop(a['source_views']);a['source_views']=view['path'];a['sources'][view['path']]=view['sha256']
ip=emit('finish8_publication_input03_NOTREADY.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
oldkey=(N/'publish_finish8_components02_ROOT_READY.gd').read_bytes();keytext=oldkey.decode();keyhunks=[]
def kchange(o,n):
    global keytext
    assert keytext.count(o)==1;keytext=keytext.replace(o,n);keyhunks.append(dict(old=o,new=n))
kchange('const READY: bool=true','const READY: bool=false')
kchange('const INPUT: String="'+NS+'finish8_publication_input02_ROOT_READY.json"\nconst INPUT_SHA: String="'+sha(raw)+'"','const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"')
kchange('if not check(view.get("ok")==true,"SOURCE_TERMINAL_VIEW:"+id): finish();return','if not check(view.get("ok")==true,"SOURCE_TERMINAL_VIEW:"+id):\n\t\t\terrors.append({"strict_source_diagnostic":source_math.diagnose(id,original,inputs,helpers)})\n\t\t\tfinish();return')
key=emit('publish_finish8_components03_NOTREADY.gd',keytext.encode())
back=keytext
for h in reversed(keyhunks):back=back.replace(h['new'],h['old'])
assert back.encode()==oldkey
proof=emit('publication03_gate_exact_polygon_key_inverse_BUILD.json',(json.dumps(dict(status='FINITE_GATE_INTERACTION_STORAGE_KEY_CONSUMER_FIX_NOT_READY',source_views=view,input=ip,entry=key,views_parent_sha256=sha(old),view_hunks=hunks,view_diagnostic_addition=diagnostic,key_parent_sha256=sha(oldkey),key_hunks=keyhunks,whole_byte_inverse=True,unchanged='All coordinate values/native/donor/geometry/pixel priors/classification and checks. Only correct the existing city_v3 interaction-polygon storage field and preserve diagnostic on any further first refusal.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(entry=key,input=ip,source_views=view,proof=proof)))
