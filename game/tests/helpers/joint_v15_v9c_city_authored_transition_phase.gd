extends "res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd"
## NEW context adapter. The immutable 542483 parent owns every gameplay,
## dialogue45s, battle30s/180s, arrival, timer-grace and BGM predicate.
## The full original reverse-input method selects actual V9c RAW. New note
## source/current manifests are bound before the inherited full875/17/Physics
## probe; all action stations still come from actual manifest gameplay_slots.
const V9C_WORLD_RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const V9C_CITY_ORIGIN_PATH := "res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd"
const V9C_CITY_ORIGIN_SHA := "542483133d1dfd79422ac99dff5c79ee4cd3baea6a62001439f016c6055aaf72"


const NOTE_SUBJECT_PATH: String="res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const NOTE_SUBJECT_SHA: String="4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1"
const NOTE_MANIFEST_SHA: Dictionary={
 "ch4_s0_luoyang_gate":"2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d",
 "ch4_s1_luoyang_yamen":"b7bfdd920ba69858b70c9cf77c5d3b65161f14032ae3eb0e1f5f5f0b04385315",
 "ch4_s2_canal_docks":"5ac079c73a9ab7716c62d7ba540d39a513be93ed17f5feef0effbd2e1ac26cdb",
 "ch4_s3_luoyang_market":"bc100b541f74ddaa49391ccb7e8a5161905f3586c243dc74eded840284f8dc5f"
}

func _bind_field(id: String) -> bool:
	if not _check(FileAccess.get_sha256(NOTE_SUBJECT_PATH).to_lower()==NOTE_SUBJECT_SHA,"exact current note candidate C bytes; original authored lifecycle parent stays immutable"): return false
	if not _check(NOTE_MANIFEST_SHA.has(id) and FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json").to_lower()==NOTE_MANIFEST_SHA[id],"actual note revision current manifest bytes, not old73 credit"): return false
	# Original configure_city reads ALL current raw PNG/solids and the original
	# fine probe configures ALL current manifest IDs, including nonblocking scroll.
	# Do not substitute a QA station or edit original NPC/action fixtures.
	return super._bind_field(id)

func _input_existing_exit_to(source: String) -> Dictionary:
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var is_world: bool=String(definition.scene_id) in ["world_map_jianghu_v15","world_map_jianghu"]
	var actual_raw: RefCounted=V9C_WORLD_RAW.new() if is_world else RAW.new()
	var ok: bool=bool(actual_raw.call("configure_city",definition,candidate)) if IDS.has(String(definition.scene_id)) else bool(actual_raw.call("configure",definition.map_layout if is_world else definition))
	var result: Dictionary={"returned":false,"target_scene":String(definition.scene_id)}
	if not _check(ok,"target's original raw native/legacy navigation configured independently"): actual_raw.call("release"); return result
	var size: Vector2=field.get("_world_size")
	var clear: Callable=func(p: Vector2)->bool: return bool(actual_raw.call("clear",p)) and _actual_body_clear(field,p)
	var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
		var count: int=maxi(1,ceili(a.distance_to(b)/4))
		for index in range(count+1):
			if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false,"index":index}
		return {"clear":true,"centers":count+1}
	var zone: Node
	# Ordinary ancient-temple doors are genuinely generated from original
	# SceneScript.hotspots. Inspect the live ExitZone rather than assuming every
	# original reverse door was authored in map_layout.portals.
	for actual_zone: Node in field.get("_exit_nodes"):
		if String(actual_zone.get("target_scene_id"))==source and not bool(actual_zone.get("is_locked")):
			zone=actual_zone
			break
	if not _check(zone!=null,"real target has original reverse route"): actual_raw.call("release"); return result
	var target: Vector2=zone.position
	result["original_reverse_zone"]={"node_path":str(zone.get_path()),"name":String(zone.name),"target_scene_id":String(zone.get("target_scene_id")),"target_spawn_pos":zone.get("target_spawn_pos"),"original_scene_sha256":FileAccess.get_sha256(definition.resource_path) if not definition.resource_path.is_empty() else "IN_MEMORY_CANDIDATE"}
	var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,target,size,clear,segment)
	var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
	_check(bool(driven.get("ok",false)) and bool(zone.get("_in_range")),"normal target input reaches enabled reverse area with complete feet/physics")
	if bool(driven.get("ok",false)):
		await driver.call("key",KEY_SPACE)
		result.returned=await _wait_field(source)
	result["drive"]=driven
	actual_raw.call("release")
	return result
