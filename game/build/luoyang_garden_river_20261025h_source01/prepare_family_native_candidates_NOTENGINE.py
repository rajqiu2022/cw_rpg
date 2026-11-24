from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1]
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def save(name,b):
 p=P/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return {'path':R+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return save(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
report_path=R+'metadata_array04/ROOT_READY/reports/115844/result.json'
report_bytes=(G/report_path[6:]).read_bytes();report=json.loads(report_bytes)
assert report['passed'] and report['published'] and report['whole_typed_scene_layout_source_expression_match']
assert report['visual_count']==56 and report['solid_count']==16 and report['portal_count']==2
native=R+'publication01/output/native/'
child={s:{'path':native+'luoyang_riverside_garden_20261022ap/'+s,'sha256':report['artifacts'][native+'luoyang_riverside_garden_20261022ap/'+s]}for s in ['scene.res','layout.res','packet.bin','walk.png']}
required={p:h for p,h in report['artifacts'].items()}
for p in [R+'author_river_bridge03_NOTREADY.json',R+'independent_source_pixel_model02_PRIOR_PROPOSAL.json',R+'metadata_array04/garden_river_compiler03_NOTREADY.gd',R+'garden_river_visual_NOTREADY.gd',R+'river_shore_native16.gdshader']:
 required[p]=sha((G/p[6:]).read_bytes())
required[report_path]=sha(report_bytes)
input49=json.loads((P/'ROOT_READY/publication_input_ROOT_READY.json').read_bytes())
for p,h in input49['sources'].items():
 if p.endswith(('.png','.png.import','.ctex','.jpg','.jpg.import','.tres','.res')):required[p]=h
binding=dump('runtime01_NOTREADY/garden_river_binding_NOTREADY.json',{
 'status':'GARDEN_RIVER_NATIVE_BINDING_NOTREADY','ready':False,'scene_id':'luoyang_riverside_garden_20261022ap',
 'author':input49['author'],'independent_prior':input49['prior'],
 'native_publication':{'path':report_path,'sha256':sha(report_bytes)},'child':child,
 'front_region':{'path':native+'front_rail.res','sha256':report['artifacts'][native+'front_rail.res']},
 'expected_visual_count':56,'expected_solid_count':16,'expected_portal_count':2,
 'child_rgba_sha256':'d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456',
 'required_sources':required,
 'mask_import_and_direct_ctex':None,'limited_Field_trial_admission':None,
 'whole_city_or_ART_or_performance_credit':False,
 'blocking':'Only new mask import tuple and Root finite visual/Field-trial admission remain; no fake SHA or readiness.'})

family_source='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
fb=(P/'parents/luoyang_quarters_family_20261022ap.gd').read_bytes()
assert (G/family_source[6:]).read_bytes()==fb
f=fb.decode('utf-8');fh=[]
def fc(a,b):
 global f
 assert f.count(a)==1,a[:100]
 f=f.replace(a,b);fh.append({'old':a,'new':b})
addition='''const GARDEN_RIVER_READY=false
const GARDEN_RIVER_BINDING="__BIND__"
const GARDEN_RIVER_BINDING_SHA=""
static var _garden_river_fixed_binding: Dictionary={}
static func _garden_river_declared(data: Dictionary) -> bool: return data.has("garden_river_successor")
static func garden_river_spec() -> Dictionary:
	if not GARDEN_RIVER_READY or not b()._hash(GARDEN_RIVER_BINDING_SHA): return {}
	if not _garden_river_fixed_binding.is_empty(): return _garden_river_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(GARDEN_RIVER_BINDING)
	if b().bytes_sha(bytes)!=GARDEN_RIVER_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("ready")!=true or value.get("status")!="ROOT_READY_GARDEN_RIVER_NATIVE_BINDING" or value.get("scene_id")!=String(IDS[1]) or not value.get("required_sources") is Dictionary or not value.get("child") is Dictionary: return {}
	for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
		var leaf: Dictionary=value.child.get(suffix,{})
		if not leaf.get("path") is String or not leaf.path.begins_with("res://build/luoyang_garden_river_20261025h_source01/") or ".." in leaf.path or not b()._hash(leaf.get("sha256")) or value.required_sources.get(leaf.path)!=leaf.sha256: return {}
	for path: String in value.required_sources:
		if not path.begins_with("res://") or ".." in path or not b()._hash(value.required_sources[path]): return {}
	if value.get("expected_visual_count")!=56 or value.get("expected_solid_count")!=16 or value.get("expected_portal_count")!=2 or value.get("child_rgba_sha256")!="d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456" or not value.get("mask_import_and_direct_ctex") is Dictionary or not value.get("limited_Field_trial_admission") is Dictionary: return {}
	_garden_river_fixed_binding=value;return value
static func _garden_river_header_matches(data: Dictionary) -> bool:
	if not _garden_river_declared(data): return true
	var spec: Dictionary=garden_river_spec()
	if spec.is_empty(): return false
	var declaration: Variant=data.garden_river_successor
	if not declaration is Dictionary or declaration.size()!=2 or declaration.get("binding_path")!=GARDEN_RIVER_BINDING or declaration.get("binding_sha256")!=GARDEN_RIVER_BINDING_SHA or data.source_sha256.get(GARDEN_RIVER_BINDING)!=GARDEN_RIVER_BINDING_SHA: return false
	for path: String in spec.required_sources:
		if data.source_sha256.get(path)!=spec.required_sources[path]: return false
	return true
static func garden_river_source_bound_scene(scene: SceneScript) -> bool:
	return scene!=null and scene.scene_id==IDS[1] and _garden_river_declared(manifest()) and _garden_river_header_matches(manifest()) and matches(scene)
static func _garden_river_packet_valid(raw: Dictionary,data: Dictionary) -> bool:
	var spec: Dictionary=garden_river_spec()
	if spec.is_empty() or not _garden_river_header_matches(data) or raw.get("author_path")!=spec.author.path or raw.get("author_sha256")!=spec.author.sha256 or raw.get("mask_sha256")!=spec.child_rgba_sha256 or not raw.get("solids") is Array or raw.solids.size()!=16 or not raw.get("river_bridge25h") is Dictionary: return false
	if raw.river_bridge25h.get("whole_parent_outside_domains_inverse")!=true or not raw.river_bridge25h.get("water_physics_pieces") is Array or raw.river_bridge25h.water_physics_pieces.size()!=2 or not raw.river_bridge25h.get("deck") is Rect2 or raw.river_bridge25h.deck.size.y-24<128: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary: return false
	var fields: Dictionary=raw.layout_storage.fields
	return fields.get("visual_objects",{}).get("array_values",[]).size()==56 and fields.get("blockers",{}).get("array_values",[]).size()==16 and fields.get("walkable_mask_path")==spec.child["walk.png"].path
'''.replace('__BIND__',binding['path'])
fc('static func b() -> Variant: return load(B_PATH)',addition+'static func b() -> Variant: return load(B_PATH)')
fc('static func _a2_artifact_path(data: Dictionary,id: StringName,suffix: String) -> String:\n',
 '''static func _a2_artifact_path(data: Dictionary,id: StringName,suffix: String) -> String:
	if id==IDS[1] and _garden_river_declared(data):
		var river: Dictionary=garden_river_spec()
		return String(river.child[suffix].path) if not river.is_empty() and river.child.has(suffix) else ""
''')
fc('\tif not _life_header_matches(raw): return {}','\tif not _life_header_matches(raw): return {}\n\tif not _garden_river_header_matches(raw): return {}')
fc('\tvar raw: Variant=bytes_to_var(packet_bytes)\n',
 '''	if id==IDS[1] and _garden_river_declared(data):
		var river: Dictionary=garden_river_spec()
		if river.is_empty() or b().bytes_sha(packet_bytes)!=river.child["packet.bin"].sha256: return {}
	var raw: Variant=bytes_to_var(packet_bytes)
''')
fc('\telif raw.has("a2_finite_proof"): return {}',
 '\telif raw.has("a2_finite_proof"): return {}\n\tif id==IDS[1] and _garden_river_declared(data) and not _garden_river_packet_valid(raw,data): return {}\n\tif id==IDS[1] and not _garden_river_declared(data) and raw.has("river_bridge25h"): return {}')
back=f
for h in reversed(fh):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==fb
family=save('runtime01_NOTREADY/Family_garden_river_CANDIDATE.gd',f.encode())

ng_source='res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd'
nb=(P/'parents/luoyang_quarters_native_geometry_20261022ap.gd').read_bytes()
assert (G/ng_source[6:]).read_bytes()==nb
n=nb.decode();nh=[]
def nc(a,b):
 global n
 assert n.count(a)==1,a[:100]
 n=n.replace(a,b);nh.append({'old':a,'new':b})
nc('const FAMILY=', 'const RIVER="'+R+'garden_river_visual_NOTREADY.gd"\nconst FAMILY=')
nc('\treturn make_garden_water_visual(scene,entries)',
 '''	if scene.has_meta("ap_garden_river25h"):
		if not family.garden_river_source_bound_scene(scene): return fail("AP_GARDEN_RIVER_SOURCE_BOUND_FAMILY")
	return make_garden_water_visual(scene,entries)''')
nc('static func make_garden_water_visual(scene: SceneScript,entries: Array) -> Dictionary:\n',
 '''static func make_garden_water_visual(scene: SceneScript,entries: Array) -> Dictionary:
	if scene!=null and scene.scene_id==IDS[1] and scene.has_meta("ap_garden_river25h"):
		var river: Variant=load(RIVER)
		return river.make_water_visual(scene,entries)
''')
nc('\tpaths.append(SHORE_MASK_SHADER)\n\treturn paths',
 '\tpaths.append(SHORE_MASK_SHADER)\n\tpaths.append(RIVER)\n\tvar river: Variant=load(RIVER)\n\tfor path: String in river.source_paths():\n\t\tif not paths.has(path): paths.append(path)\n\treturn paths')
back=n
for h in reversed(nh):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==nb
ng=save('runtime01_NOTREADY/NativeGeometry_garden_river_CANDIDATE.gd',n.encode())
proof=dump('runtime01_NOTREADY/family_native_geometry_whole_inverse_NOTREADY.json',{
 'status':'GARDEN_NATIVE_RUNTIME_SOURCE_CANDIDATES_NOT_READY_NOT_PARSED',
 'Family':family,'NativeGeometry':ng,'binding':binding,
 'parents':{family_source:{'sha256':sha(fb),'bytes':len(fb)},ng_source:{'sha256':sha(nb),'bytes':len(nb)}},
 'family_hunks':fh,'native_geometry_hunks':nh,'whole_byte_inverse_both':True,
 'no_Artisan_life_A2_or_room_or_G_Field_or_Router_function_changes':True,
 'native_actual':{'path':report_path,'sha256':sha(report_bytes)},
 'blockers':'Root mask import two leaf actual + finite visual/trial admission, then only mechanical READY/binding hash before source Stage.',
 'engine':0,'canonical_writes':0})
print(json.dumps({'Family':family,'NativeGeometry':ng,'binding':binding,'proof':proof,'runtime_helper':{'path':R+'garden_river_visual_NOTREADY.gd','sha256':sha((P/'garden_river_visual_NOTREADY.gd').read_bytes())},'shader_sha256':sha((P/'river_shore_native16.gdshader').read_bytes())}))
