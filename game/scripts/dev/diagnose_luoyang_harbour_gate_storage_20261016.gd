extends SceneTree
## Fixed-source CPU diagnostic only, no parent preparation/image decode/GPU.
const A=preload("res://scripts/city/luoyang_harbour_life_author_20261016.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const PREFIX="res://build/luoyang_harbour_life_publication_20261016/111568_1777/"
const SCENE=PREFIX+"ch4_s0_luoyang_gate/scene.tres"
const LAYOUT=PREFIX+"ch4_s0_luoyang_gate/layout.tres"
const MANIFEST="res://art/maps/luoyang_gate_fortification_v3_refined/runtime_manifest.json"
const PINS={SCENE:"eb244266cd4be1632834d8e54cdb587947be9b414f94213cf39c5e01fe01412f",LAYOUT:"0235def8d8653660bb245581c5847aacdd151e0bdd538e004b9c898e6994c23c",MANIFEST:"6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0",A.PATH:"36674bfeb8583b2c417cac0d62866002aebdf78b1b18420867ae6d735eb06684"}
var differences: Array=[]
func _initialize() -> void: call_deferred("_run")
func _walk(left: Variant,right: Variant,path: Array,visual: bool=false) -> void:
	if visual and C.equal_visual_serialized_value(left,right,path): return
	if not visual and C._equal_value(left,right): return
	if typeof(left)==typeof(right) and left is Array and left.size()==right.size():
		for index: int in left.size(): _walk(left[index],right[index],path+[index],visual)
		return
	if typeof(left)==typeof(right) and left is Dictionary and left.size()==right.size():
		for key: Variant in left:
			if right.has(key): _walk(left[key],right[key],path+[key],visual)
			else: differences.append({"path":path+[key],"missing_right":true})
		return
	var row: Dictionary={"path":path,"left_type":type_string(typeof(left)),"right_type":type_string(typeof(right)),"left":var_to_str(left),"right":var_to_str(right)}
	if typeof(left)==TYPE_FLOAT and typeof(right)==TYPE_FLOAT:
		row["left_f32"]=PackedFloat32Array([left]).to_byte_array().hex_encode(); row["right_f32"]=PackedFloat32Array([right]).to_byte_array().hex_encode()
		row["native_f32_exact"]=row.left_f32==row.right_f32
	differences.append(row)
func _storage(left: Resource,right: Resource,label: String) -> void:
	for property: Dictionary in right.get_property_list():
		var key:=String(property.name)
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
		_walk(left.get(key),right.get(key),[key] if key=="visual_objects" else [label,key],key=="visual_objects")
func _run() -> void:
	var good: bool=true
	for path: String in PINS:
		if FileAccess.get_sha256(path)!=PINS[path]: good=false
	var parent:=ResourceLoader.load("res://data/scenes/ch4_s0_luoyang_gate.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var published:=ResourceLoader.load(SCENE,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var fresh: SceneScript=null
	if good and parent!=null and published!=null and source is Dictionary:
		fresh=A.apply_scene(parent,{"objects":source.objects,"harbour_author_sha":A.author_sha()},PREFIX+"ch4_s0_luoyang_gate/walk.png")
		good=fresh!=null
	if good:
		_storage(fresh,published,"Scene"); _storage(fresh.map_layout,published.map_layout,"Layout")
	var report: Dictionary={"diagnostic_completed":good,"sources":PINS,"differences":differences,"count":differences.size(),"fixed_original_gate_objects_not_live_C_receipt":true,"no_geometry_or_production_mutation":true}
	var output: String="res://build/luoyang_harbour_life_20261016_system01/gate_storage_diagnostic_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"diagnostic_completed":good,"count":differences.size(),"result":output})); quit(0 if good else 1)
