extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
## GUI/glcompat resource slice only: no Field, C.prepare, joined workspace or city birth.
const OLD_PATH="res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_candidate.gd"
const NEW_PATH="res://build/luoyang_tree_pair_reuse_20261017n_source01/original_checker_candidate.gd"
const OLD=preload("res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_candidate.gd")
const NEW=preload("res://build/luoyang_tree_pair_reuse_20261017n_source01/original_checker_candidate.gd")
const M_RESULT="res://build/luoyang_module_source_cold_gate_20261017m/29348_2549/result.json"
const ID=&"ch4_s0_luoyang_gate"
var expected_sources: Dictionary={}
var old_stem: String=OLD.OLD_ROOT+String(ID)+"/entities/native_tree"
var new_stem: String=OLD.NEW_ROOT+String(ID)+"/entities/native_tree"

class SliceObserver extends RefCounted:
	var stages: Array[Dictionary]=[]
	func record_main_stage(id: StringName,label: String,usec: int) -> void:
		stages.append({"id":String(id),"label":label,"usec":usec})
	func owner_before_mesh() -> bool:
		return stages.is_empty() # Actual live slice rejects immediately after its mesh stage.
	func owner_valid() -> bool: return true

func _initialize() -> void:
	atom_name="TREE_PAIR_REUSE_20261017N_30S";budget_ms=30000
	super._initialize()

func _function_text(source: String,name: String) -> String:
	var begin: int=source.find("static func "+name+"(")
	if begin<0: return ""
	var end: int=source.find("\nstatic func ",begin+1)
	return source.substr(begin) if end<0 else source.substr(begin,end-begin)

func _asset(path: String) -> bool:
	return check(expected_sources.has(path),"Real slice dependency belongs to finalized m source proof "+path) and track(path,expected_sources.get(path,""))

func precheck() -> bool:
	var pins: Dictionary={OLD_PATH:"17297869279c43e068e442e7269c57cc4d986b5b26c9a2374883d6ff97cb5481",NEW_PATH:"fb11c1dd600587666a00fec57c67aea4ae597fb1f8a3302fdd6746117c2fcff5",M_RESULT:"ff19bc8134b378b7a716242cdd1b6d2590c6069fbe0b106f0a6419dc52b1032f","res://tests/helpers/cold_sha_qa_retry2_20261017k.gd":"001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	var result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(M_RESULT))
	if not check(result.get("complete")==true and result.get("failures")==0,"Pinned actual m Gate result passed"): return false
	for row: Dictionary in result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF":
			if not check(row.proof.get("sources_finalized")==true,"Pinned complete actual owner first/final source proof"): return false
			expected_sources=row.proof.sources.duplicate(true)
	if not check(expected_sources.size()==625,"Full proof retained; only this slice's used leaves freshly read"): return false
	for stem: String in [old_stem,new_stem]:
		for suffix: String in [".res",".json",".png","_raw.png","_raw_repeat.png"]:
			if not _asset(stem+suffix): return false
	var before: String=FileAccess.get_file_as_string(OLD_PATH)
	var after: String=FileAccess.get_file_as_string(NEW_PATH)
	for name: String in ["_validation_unaffected","_unaffected_state","_unaffected_mapping_bytes","_unaffected_load","_unaffected_material","_surface_error","_material_equal_error","_value_error"]:
		var text_before: String=_function_text(before,name)
		if not check(not text_before.is_empty() and text_before==_function_text(after,name),"Original protected complete function unchanged "+name): return false
	return true

func _state() -> Dictionary:
	return {"old_stem":old_stem,"stem":new_stem,"kind":"tree","metadata":JSON.parse_string(FileAccess.get_file_as_string(new_stem+".json")),"old_metadata":JSON.parse_string(FileAccess.get_file_as_string(old_stem+".json"))}

func _live_state(local: Dictionary) -> Dictionary:
	return {"object_old_stem":local.old_stem,"object_stem":local.stem,"object_kind":local.kind,"object_metadata":local.metadata,"object_old_metadata":local.old_metadata}

func _texture_dependency(texture: Texture2D) -> bool:
	var path: String=texture.resource_path
	if path.is_empty() or path.contains("::"): return true # Embedded content is covered by the exact .res source SHA.
	if not _asset(path): return false
	if FileAccess.file_exists(path+".import"):
		if not _asset(path+".import"): return false
		var config:=ConfigFile.new()
		if not check(config.load(path+".import")==OK,"Native imported texture config readable"): return false
		var compiled: Variant=config.get_value("remap","path",null)
		if not check(compiled is String,"Exact compiled texture resource path"): return false
		if not _asset(compiled): return false
	return true

func _material_dependencies(material: Material) -> bool:
	if material is ShaderMaterial:
		for uniform: Dictionary in material.shader.get_shader_uniform_list():
			var value: Variant=material.get_shader_parameter(uniform.name)
			if value is Texture2D and not _texture_dependency(value): return false
	else:
		for property: Dictionary in material.get_property_list():
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0: continue
			var value: Variant=material.get(property.name)
			if value is Texture2D and not _texture_dependency(value): return false
	return true

func _triangle(delta: float) -> ArrayMesh:
	var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3.ZERO,Vector3(1.0+delta,0,0),Vector3(0,1,0)])
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _negative_slots() -> bool:
	var a: ArrayMesh=_triangle(0.0);var b: ArrayMesh=_triangle(1.0)
	var path_a: String=folder.path_join("fixture_a.res");var path_b: String=folder.path_join("fixture_vertex_changed.res")
	if not check(ResourceSaver.save(a,path_a)==OK and ResourceSaver.save(b,path_b)==OK,"Own temporary two equal-count ArrayMesh fixtures saved"): return false
	var old_error: String=OLD._meshes_error(path_a,path_b,"tree")
	var pair: Dictionary={"stale":true}
	var new_error: String=NEW._meshes_error(path_a,path_b,"tree",pair)
	if not check(not old_error.is_empty() and old_error==new_error and pair.is_empty(),"Actual same-count vertex slot mismatch gives exact old error and no pair",{"old":old_error,"new":new_error}): return false
	pair={"stale":true}
	if not check(not NEW._meshes_error(path_a,path_a,"not_tree",pair).is_empty() and pair.is_empty(),"Only tree output is accepted; non-tree error clears sink"): return false
	return true

func exercise() -> bool:
	var local: Dictionary=_state()
	var old_state: Dictionary=_live_state(local)
	var began: int=Time.get_ticks_usec()
	var old_error: String=OLD._validation_unaffected(old_state)
	var old_usec: int=Time.get_ticks_usec()-began
	if not check(old_error.is_empty(),"Actual old complete tree geometry/mapping/second-load/material pipeline",old_error): return false
	var observer:=SliceObserver.new()
	began=Time.get_ticks_usec()
	var new_error: String=await NEW._validation_unaffected_live(old_state,observer,ID,observer.owner_valid)
	var new_usec: int=Time.get_ticks_usec()-began
	records.append({"kind":"OLD_NEW_REAL_TREE_SLICE","old_error":old_error,"new_error":new_error,"old_sync_usec":old_usec,"new_live_including_yields_usec":new_usec,"new_stages":observer.stages.duplicate(true),"fixed_order_os_cache_not_speed_benchmark":true})
	if not check(new_error==old_error,"New actual live slice exact complete return, no full workspace or Field credit"): return false
	if not check(NEW._unaffected_mesh(local,true).is_empty(),"Real first full mesh validation returns retained pair"): return false
	var pair: Dictionary=local.retained_pair
	if not check(pair.size()==6 and pair.mesh_a is Mesh and pair.mesh_b is Mesh,"Success output exactly six keys with two actual Mesh resources"): return false
	var weak_a: WeakRef=weakref(pair.mesh_a);var weak_b: WeakRef=weakref(pair.mesh_b)
	if not check(NEW._unaffected_mapping_bytes(local).is_empty() and NEW._unaffected_retained_load(local).is_empty(),"Original mapping bytes precede retained identity handoff"): return false
	if not check(local.mesh_a.get_instance_id()==pair.mesh_a_id and local.mesh_b.get_instance_id()==pair.mesh_b_id,"Material stage consumes the first pair, not reloaded resources"): return false
	for index: int in local.mesh_a.get_surface_count():
		var aa: Array=local.mesh_a.surface_get_arrays(index);var bb: Array=local.mesh_b.surface_get_arrays(index)
		if not check(aa.size()==Mesh.ARRAY_MAX and bb.size()==Mesh.ARRAY_MAX,"Actual complete native surface slots"): return false
		for slot: int in Mesh.ARRAY_MAX:
			if not check(var_to_bytes(aa[slot])==var_to_bytes(bb[slot]),"Independent all-slot byte exact "+str(index)+"/"+str(slot)): return false
		var ma: Material=local.mesh_a.surface_get_material(index);var mb: Material=local.mesh_b.surface_get_material(index)
		if not _material_dependencies(ma) or not _material_dependencies(mb): return false
		var before_error: String=OLD._material_equal_error(ma,mb)
		var after_error: String=NEW._unaffected_material(local,index)
		if not check(before_error.is_empty() and after_error.is_empty(),"Original actual material class/storage/shader/uniform/texture fullRGBA+all mip bytes "+str(index)): return false
	var saved_id: int=pair.mesh_a_id;pair.mesh_a_id=-1
	if not check(not NEW._unaffected_retained_load(local).is_empty(),"Forged original resource ID rejected"): return false
	pair.mesh_a_id=saved_id
	var saved_path: String=pair.old_path;pair.old_path="res://unrelated.res"
	if not check(not NEW._unaffected_retained_load(local).is_empty(),"Wrong original path rejected without disk fallback"): return false
	pair.old_path=saved_path
	local.clear();pair.clear()
	await process_frame
	if not check(weak_a.get_ref()==null and weak_b.get_ref()==null,"Explicit test helper local/pair holders cleared and both Mesh weakrefs released; not proof of internal live-local leak freedom"): return false
	var cancellation:=SliceObserver.new()
	var cancelled_error: String=await NEW._validation_unaffected_live(old_state,cancellation,ID,cancellation.owner_before_mesh)
	records.append({"kind":"ACTUAL_LIVE_OWNER_CANCEL_AFTER_MESH","error":cancelled_error,"stages":cancellation.stages.duplicate(true),"internal_local_release_evidence":"source-reviewed local.clear; internal local not exposed or directly weak-observed"})
	if not check(cancelled_error=="LIVE_OWNER_CANCELLED" and cancellation.stages.size()==1 and String(cancellation.stages[0].label).ends_with(".mesh"),"Actual live function cancels after real first pair validation, before mapping/material"): return false
	return _negative_slots()
