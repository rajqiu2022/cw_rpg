extends SceneTree
## ROOT-only native numeric-domain diagnosis. No Field, geometry suite or files modified.
const REGISTRY="res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json"
const REGISTRY_SHA="959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5"
const MODULE="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const MODULE_SHA="d82232b96035f365652831238bad490e79dc973b75d3550c79d6ab6b2070b979"
const CITY="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const CITY_SHA="06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d"
const SIZE=Vector2(3072,2048)
var failures: Array=[]
var facts: Dictionary={}
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	call_deferred("_run")
func _require(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _track(path: String,expected: String) -> void:
	var actual: String=FileAccess.get_sha256(path)
	facts[path]=actual
	_require(expected.length()==64 and actual==expected,"source:"+path)
func _bits(value: Vector2) -> String:
	var bytes:=PackedByteArray(); bytes.resize(8)
	bytes.encode_float(0,value.x); bytes.encode_float(4,value.y)
	return bytes.hex_encode()
func _run() -> void:
	var started: int=Time.get_ticks_msec()
	_track(REGISTRY,REGISTRY_SHA); _track(MODULE,MODULE_SHA); _track(CITY,CITY_SHA)
	var rows: Array=[]
	var old_differences: int=0
	if failures.is_empty():
		var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
		var city: Variant=load(CITY)
		var module: Variant=load(MODULE)
		for id: String in config.rooms:
			var row: Dictionary=config.rooms[id]
			if row.get("reuse_existing_accepted")==true: continue
			_track(row.author_path,row.author_sha256)
			_track(row.layout_path,row.source_sha256.get(row.layout_path,""))
			if not failures.is_empty(): break
			var author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.author_path))
			var raw: Array=author.room.return_foot_px
			var layout: Resource=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE)
			if layout==null: failures.append("layout_load:"+id); break
			var portals: Array=layout.get("portals")
			_require(portals.size()==1,"one_return_portal:"+id)
			if portals.size()!=1: break
			var loaded: Vector2=portals[0].target_pos
			var from_c: Dictionary=city.revision_room_binding(StringName(id))
			var from_g: Dictionary=module.return_binding(StringName(id))
			_require(JSON.stringify(from_c,"",true,true)==JSON.stringify(from_g,"",true,true),"current_C_binding_already_delegates_to_g:"+id)
			var old: Vector2=city._vec(from_c.return_foot_px)/SIZE
			var scalar_first:=Vector2(float(raw[0])/3072.0,float(raw[1])/2048.0)
			if old!=loaded: old_differences+=1
			_require(scalar_first==loaded,"scalar_first_exact_published_native_uv:"+id)
			rows.append({"id":id,"raw_return_foot_px":raw,"layout":row.layout_path,"loaded_uv":loaded,"old_native_first_uv":old,"scalar_first_uv":scalar_first,"loaded_float32_le":_bits(loaded),"old_float32_le":_bits(old),"scalar_float32_le":_bits(scalar_first),"old_exact":old==loaded,"scalar_exact":scalar_first==loaded,"old_world":old*SIZE,"loaded_world":loaded*SIZE,"C_binding_equals_g":from_c==from_g})
	_require(rows.size()==10,"all10newrooms_not_smith")
	var after: Dictionary={}
	for path: String in facts: after[path]=FileAccess.get_sha256(path)
	_require(JSON.stringify(facts,"",true,true)==JSON.stringify(after,"",true,true),"same_sources_first_final")
	_require(Time.get_ticks_msec()-started<10000,"bounded10s_no_geometry_Field_or_GPU")
	var result: Dictionary={"passed":failures.is_empty(),"failures":failures,"rows":rows,"old_native_first_differences":old_differences,"source_before":facts,"source_after":after,"elapsed_ms":Time.get_ticks_msec()-started,"scope":"NATIVE_RETURN_UV_DOMAIN_ONLY_NOT_GEOMETRY_OR_RUNTIME_ACCEPTANCE"}
	var path: String="res://build/luoyang_room_return_uv_20261018q_source01/diagnostic_"+str(OS.get_process_id())+".json"
	if FileAccess.file_exists(path): quit(1); return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(result,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":result.passed,"failures":failures,"rows":rows.size(),"old_native_first_differences":old_differences,"path":path}))
	quit(0 if failures.is_empty() else 1)
