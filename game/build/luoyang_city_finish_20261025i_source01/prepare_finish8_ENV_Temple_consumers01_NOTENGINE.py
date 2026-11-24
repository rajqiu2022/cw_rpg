from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
RP='res://build/luoyang_city_finish_20261025i_system01/finish8_runtime07_NOTREADY.gd';RH='fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be'
AP=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd';AH='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
def authority():
    p=G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json'
    b=p.read_bytes();assert sha(b)=='ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'
    r=json.loads(b);out={}
    for node in r['nodes'].values():
        if isinstance(node,dict) and isinstance(node.get('value'),dict):
            for k,v in node['value'].get('source_sha256',{}).items():
                assert k not in out or out[k]==v;out[k]=v
    for row in r['targets']:out[row['target']]=row['candidate_sha256']
    return out
fixed=authority();outputs=[]

for kind,rel in [('Temple','scripts/city/luoyang_temple_assembly_20261016.gd'),('ENV','scripts/city/luoyang_environment_layer_20261022ap.gd')]:
    old=(G/rel).read_bytes();assert sha(old)==fixed['res://'+rel]
    t=old.decode('utf-8');hunks=[]
    def change(o,n):
        global t
        assert t.count(o)==1,(kind,o,t.count(o));t=t.replace(o,n);hunks.append(dict(old=o,new=n))
    constants='''const FINISH25I_ENABLED: bool=false
const FINISH25I_RUNTIME: String="@RP@"
const FINISH25I_RUNTIME_SHA: String="@RH@"
'''.replace('@RP@',RP).replace('@RH@',RH)
    if kind=='Temple':
        constants+='const FINISH25I_ADAPTER: String="'+AP+'"\n'
        change('extends RefCounted\n','extends RefCounted\n'+constants)
        change('\tresult.merge(people_paths);return result', '''	result.merge(people_paths)
	if FINISH25I_ENABLED:
		if FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return {}
		var finish_runtime: Variant=load(FINISH25I_RUNTIME)
		if not finish_runtime is GDScript or finish_runtime.resource_path!=FINISH25I_RUNTIME: return {}
		var finish_paths: Dictionary=finish_runtime.source_paths_for(ID)
		if finish_paths.is_empty(): return {}
		result.merge(finish_paths,true);result[FINISH25I_ADAPTER]=true
	return result''')
    else:
        spec_path=NS+'eight_fields_purpose_surface04_explicit_repeat_NOTREADY.json'
        sb=(N/'eight_fields_purpose_surface04_explicit_repeat_NOTREADY.json').read_bytes();assert sha(sb)=='7b95cbb5f9ff62541e259ac8779aff76ebb8e6f3cdbaf161cacbf06f96ffd63d'
        spec=json.loads(sb)
        pins={spec_path:sha(sb),spec['factory']['path']:spec['factory']['sha256'],spec['shader']['path']:spec['shader']['sha256']}
        for row in spec['textures'].values():pins[row['path']]=row['sha256']
        constants+='const FINISH25I_PURPOSE_SPEC: String="'+spec_path+'"\n'
        constants+='const FINISH25I_PURPOSE_PINS: Dictionary='+json.dumps(pins,ensure_ascii=False,separators=(',',':'))+'\n'
        helper='''static func _finish25i_purpose_spec() -> Dictionary:
	if not FINISH25I_ENABLED or FileAccess.get_sha256(FINISH25I_PURPOSE_SPEC)!=FINISH25I_PURPOSE_PINS[FINISH25I_PURPOSE_SPEC]: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FINISH25I_PURPOSE_SPEC))
	if not value is Dictionary or not value.get("textures") is Dictionary or value.textures.size()!=4 or not value.get("scenes") is Dictionary or value.scenes.size()!=8: return {}
	if value.get("factory",{}).get("path")!="@FACTORY@" or value.factory.get("sha256")!=FINISH25I_PURPOSE_PINS[value.factory.path] or value.get("shader",{}).get("path")!="@SHADER@" or value.shader.get("sha256")!=FINISH25I_PURPOSE_PINS[value.shader.path]: return {}
	for role: String in value.textures:
		var row: Dictionary=value.textures[role]
		if FINISH25I_PURPOSE_PINS.get(row.get("path"))!=row.get("sha256"): return {}
	return value
static func _finish25i_purpose_node(scene: SceneScript,spec: Dictionary,owner: Callable) -> Node2D:
	if not FINISH25I_ENABLED or scene==null or spec.is_empty() or not owner.is_valid() or not owner.call() or FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var runtime: Variant=load(FINISH25I_RUNTIME)
	if not runtime is GDScript or runtime.resource_path!=FINISH25I_RUNTIME or runtime.state_for(scene).is_empty(): return null
	var textures: Dictionary={}
	for role: String in spec.textures:
		var row: Dictionary=spec.textures[role]
		var texture: Texture2D=ResourceLoader.load(row.path) as Texture2D
		if texture==null or texture.resource_path!=row.path: return null
		if row.has("source_size") and texture.get_size()!=Vector2(float(row.source_size[0]),float(row.source_size[1])): return null
		textures[role]=texture
	var factory: Variant=load(spec.factory.path)
	var shader: Shader=ResourceLoader.load(spec.shader.path) as Shader
	if not factory is GDScript or factory.resource_path!=spec.factory.path or shader==null or shader.resource_path!=spec.shader.path or not owner.call(): return null
	return factory.create(spec.scenes[String(scene.scene_id)],textures,shader)
'''.replace('@FACTORY@',spec['factory']['path']).replace('@SHADER@',spec['shader']['path'])
        change('extends RefCounted\n','extends RefCounted\n'+constants+helper)
        change('\treturn out\nstatic func install(', '\tif FINISH25I_ENABLED:\n\t\tfor p: String in FINISH25I_PURPOSE_PINS: out[p]=true\n\treturn out\nstatic func install(')
        change('\tfor p: String in source_pins:\n', '''	var finish_spec: Dictionary={}
	if FINISH25I_ENABLED:
		finish_spec=_finish25i_purpose_spec()
		if finish_spec.is_empty(): return fail("FINISH25I_PURPOSE_FIXED_SPEC")
		for p: String in FINISH25I_PURPOSE_PINS:
			if source_pins.has(p) and source_pins[p]!=FINISH25I_PURPOSE_PINS[p]: return fail("FINISH25I_PURPOSE_CONFLICTING_SOURCE",p)
			source_pins[p]=FINISH25I_PURPOSE_PINS[p]
	for p: String in source_pins:
''')
        change('\tvar source_final: Dictionary={}\n','''	var finish_purpose: Node2D=null
	if FINISH25I_ENABLED:
		if world.get_node_or_null("CityPurposeGround25i")!=null: layer.free();return fail("FINISH25I_PURPOSE_DUPLICATE")
		finish_purpose=_finish25i_purpose_node(scene,finish_spec,owner)
		if finish_purpose==null: layer.free();return fail("FINISH25I_PURPOSE_SOURCE_OR_OWNER")
		# Temporary unattached ownership means every later rejection frees this too.
		# At successful commit it becomes a world sibling with factory z=-3 intact.
		layer.add_child(finish_purpose)
	var source_final: Dictionary={}
''')
        change('\tlayer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)\n', '''	if finish_purpose!=null:
		if not owner.call(): layer.free();return fail("FINISH25I_PURPOSE_COMMIT_OWNER")
		layer.remove_child(finish_purpose);world.add_child(finish_purpose)
		receipt["finish25i_purpose_material"]={"count":finish_purpose.get_child_count(),"source_spec":FINISH25I_PURPOSE_SPEC,"world_position":finish_purpose.position,"z_index":finish_purpose.z_index,"visual_only":true,"geometry_mask_NPC_unchanged":true}
	layer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)
''')
    back=t
    for h in reversed(hunks):
        assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==old
    candidate=emit(kind+'_finish8_purpose_source01_CANDIDATE.gd',t.encode('utf-8'))
    proof=emit(kind+'_finish8_purpose_source01_whole_inverse_BUILD.json',(json.dumps(dict(status='HARD_FALSE_SOURCE_CONSUMER_ONLY',target='res://'+rel,parent_sha256=sha(old),parent_bytes=len(old),candidate=candidate,hunks=hunks,whole_byte_inverse=True,old_geometry_native_and_source_gates_preserved=True,Temple_preparation_stage_not_moved=True,no_new_image_import=True,engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    outputs.append(dict(candidate=candidate,proof=proof))
print(json.dumps(outputs))
