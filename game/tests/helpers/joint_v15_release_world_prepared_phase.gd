extends "res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd"
## DISTINCT RELEASE adapter: all original methods/predicates are inherited.
## Delta: fixed representative object input, all1344 static seams +112 actual crossings,
## and explicit RELEASE report. This never emits exhaustive FULL completion credit.
const RELEASE_WORLD_ORIGIN_PATH: String="res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd"
const RELEASE_WORLD_ORIGIN_SHA: String="16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970"
const RELEASE_OBJECTS:=preload("res://tests/helpers/joint_v15_release_world_object_input_probe.gd")
const RELEASE_CONTEXT_PATH: String="res://tests/helpers/joint_v15_v9e_source_context_oracle.gd"
const RELEASE_ARTIFACT_PATH: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
var release_seam_static: Array[Dictionary]=[]
const RELEASE_LAYERED_GEOMETRY=preload("res://tests/helpers/joint_v15_release_layered_seam_geometry_20261007.gd")
const PHYSICAL_SEAM_PLAN_PATH: String="res://build/joint_world_luoyang_20261003_qa/v9e_physical_seam_plan_1791382780_55287449_11796/physical_seam_plan.json"
const PHYSICAL_SEAM_PLAN_SHA: String="024e9a09f37721e787990ba035416996e75d69518e8d18698fdc9f0a4c1f3bd8"
var physical_seam_plan: Dictionary={}
var physical_seams_by_id: Dictionary={}
var original_raster_seam_records: Array[Dictionary]=[]
var original_source_collision_negative_records: Array[Dictionary]=[]
var original_raw_seam_classifications: Array[Dictionary]=[]
var fixture_navigation_evidence: Dictionary={}
const RELEASE_SOURCE_ENTRY_SCENE: String="res://data/scenes/linxi_village_scrollmap.tres"
const RELEASE_SOURCE_ENTRY_LAYOUT: String="res://data/maps/linxi_village_scrollmap_layout_v1.tres"
const RELEASE_SOURCE_ENTRY_ROOT: String="res://art/maps/world_map_v15_outskirts_complete_v5_retry1/"
const RELEASE_SOURCE_ENTRY_STRIP: String="res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png"
const RELEASE_SOURCE_ENTRY_PINS: Dictionary={
	RELEASE_SOURCE_ENTRY_SCENE:"4b733d3ff600d0117573aa41c1e943d49a0d9372fb5de956a112f81dfdcc9819",
	RELEASE_SOURCE_ENTRY_LAYOUT:"6c859cff6ef58d3440a087d34412edbbd4dcb47d9dfc8c921796d0201dd13650",
	RELEASE_SOURCE_ENTRY_STRIP:"0b53fb179bf82722d90fd13594fd845de40a4f4eec06d8ed6944d86b2fc626df",
	"res://scripts/domain/scene_script.gd":"e01a01ba69d13492441960972109d32ba0c62b1e0e881c5b805b11b73cb41bef",
	"res://scripts/domain/walkable_map_layout.gd":"c90f62df3f1b3f88b2e361568903e5f35c7440e445115c3003656c3312eed451",
	"res://scripts/world/outskirts_native_contract.gd":"0a6ebb105751b8beb2ff17f709672fcc7c07f71bdfad90d3750cfffd72127f87",
	RELEASE_SOURCE_ENTRY_ROOT+"bamboo/art_contract.json":"6ad6eb7473cee3cd97db997adee735ac68c82189a1df1ebbdd08f52cf88fb768",
	RELEASE_SOURCE_ENTRY_ROOT+"forest/art_contract.json":"e895744716ef0683bff47c9cdf6e343095b8d36a9243f9ddfdac37cc5a2795d5",
	RELEASE_SOURCE_ENTRY_ROOT+"marsh/art_contract.json":"f0bcc7abce4d25424104cc5412fe883f87a0bb0e209d770e8da48760f79a9c25"
}

func _release_source_entry_domain(args: Variant,adoption: Variant,current: Variant) -> bool:
	if typeof(args)!=TYPE_PACKED_STRING_ARRAY or not adoption is Dictionary or not current is Dictionary or current.size()!=3: return false
	for biome: String in ["bamboo","forest","marsh"]:
		var path: String=RELEASE_SOURCE_ENTRY_ROOT+biome+"/art_contract.json"
		if typeof(current.get(biome))!=TYPE_STRING or current[biome]!=RELEASE_SOURCE_ENTRY_PINS[path]: return false
	for key: Variant in current:
		if typeof(key)!=TYPE_STRING or key not in ["bamboo","forest","marsh"]: return false
	if args.has("--outskirts-candidate-preview") or args.has("--outskirts-complete-v5") or args.has("--outskirts-visual-v4"):
		return args.has("--outskirts-candidate-preview") and args.has("--outskirts-complete-v5") and not args.has("--outskirts-visual-v4")
	var version: Variant=adoption.get("schema_version")
	if typeof(version) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(version)) or version!=1: return false
	if typeof(adoption.get("status"))!=TYPE_STRING or adoption.status!="APPROVED_LOCAL_FIELDS" or typeof(adoption.get("art_root"))!=TYPE_STRING or adoption.art_root!=RELEASE_SOURCE_ENTRY_ROOT: return false
	return _release_source_entry_equal(adoption.get("contract_sha256"),current)

func _release_source_entry_script_fields(left_path: Variant,right_path: Variant,left_code: Variant,right_code: Variant) -> bool:
	for value: Variant in [left_path,right_path,left_code,right_code]:
		if typeof(value)!=TYPE_STRING: return false
	if left_path!=right_path or left_path not in ["res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]: return false
	return FileAccess.get_sha256(left_path)==RELEASE_SOURCE_ENTRY_PINS[left_path] and left_code==right_code and left_code==FileAccess.get_file_as_string(left_path)

func _release_source_entry_equal(a: Variant,b: Variant) -> bool:
	# Typed recursive semantic equality: dictionary insertion order is immaterial,
	# but String/StringName keys, typed arrays and every native float bit matter.
	if typeof(a)!=typeof(b): return false
	if a is Resource:
		if not a is GDScript or not b is GDScript: return false
		return _release_source_entry_script_fields(a.resource_path,b.resource_path,a.source_code,b.source_code) and _release_source_entry_metadata_equal(a,b)
	if a is Object: return false
	if a is Dictionary:
		if a.size()!=b.size(): return false
		if a.get_typed_key_builtin()!=b.get_typed_key_builtin() or a.get_typed_value_builtin()!=b.get_typed_value_builtin() or a.get_typed_key_class_name()!=b.get_typed_key_class_name() or a.get_typed_value_class_name()!=b.get_typed_value_class_name(): return false
		for scripts: Array in [[a.get_typed_key_script(),b.get_typed_key_script()],[a.get_typed_value_script(),b.get_typed_value_script()]]:
			if scripts[0]!=null or scripts[1]!=null:
				if not _release_source_entry_equal(scripts[0],scripts[1]): return false
		for key: Variant in a:
			var found: bool=false
			for other: Variant in b:
				if typeof(key)==typeof(other) and var_to_bytes(key)==var_to_bytes(other):
					if not _release_source_entry_equal(a[key],b[other]): return false
					found=true; break
			if not found: return false
		return true
	if a is Array:
		if a.size()!=b.size() or a.get_typed_builtin()!=b.get_typed_builtin() or a.get_typed_class_name()!=b.get_typed_class_name(): return false
		var left_script: Variant=a.get_typed_script(); var right_script: Variant=b.get_typed_script()
		if left_script!=null or right_script!=null:
			if not _release_source_entry_equal(left_script,right_script): return false
		for index in a.size():
			if not _release_source_entry_equal(a[index],b[index]): return false
		return true
	return var_to_bytes(a)==var_to_bytes(b)

func _release_source_entry_metadata_equal(a: Resource,b: Resource) -> bool:
	var left: Dictionary={}; var right: Dictionary={}
	for name: StringName in a.get_meta_list(): left[name]=a.get_meta(name)
	for name: StringName in b.get_meta_list(): right[name]=b.get_meta(name)
	return _release_source_entry_equal(left,right)

func _release_source_entry_storage_equal(a: Resource,b: Resource,except: Array[String]) -> bool:
	if a.get_class()!=b.get_class() or not _release_source_entry_metadata_equal(a,b): return false
	if not _release_source_entry_equal(a.get_script(),b.get_script()): return false
	var left: Dictionary={}; var right: Dictionary={}
	for property: Dictionary in a.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0 and String(property.name) not in except: left[String(property.name)]=a.get(property.name)
	for property: Dictionary in b.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0 and String(property.name) not in except: right[String(property.name)]=b.get(property.name)
	return _release_source_entry_equal(left,right)

func _release_source_entry_expected(canonical: SceneScript,data: Dictionary) -> Dictionary:
	# Independently reproduce ONLY the frozen source-entry writer append math.
	# No materialize/factory/production helper supplies expected scene values.
	var source_size: Vector2=Vector2(canonical.map_layout.design_size)
	var source_foot:=Vector2(.55,.53); var source_spawn: Vector2=source_foot
	var strip: Texture2D=load(RELEASE_SOURCE_ENTRY_STRIP)
	if strip==null: return {}
	if not canonical.actor_positions_are_feet: source_spawn-=Vector2(0,float(strip.get_height())*.945*canonical.player_visual_scale*.45)/source_size
	var post: Dictionary=data.source_entry_object.duplicate(true)
	var old_foot: Vector2=_point(post.world_foot_px); var foot: Vector2=source_foot*source_size+Vector2(32,0)
	if post.get("blocking")==true: post.physical_center_px=foot+_point(post.physical_center_px)-old_foot
	var size: Vector2=_point(post.render_size_px); var uv: Vector2=_point(post.foot_uv)
	var center: Vector2=foot-(uv-Vector2(.5,.5))*size
	var object: Dictionary={"id":"outskirts_bamboo_routepost","texture":post.texture,"pos":center/source_size,"render_size_px":size,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/source_size.y,"interaction_action":"outskirts_entry:bamboo","interaction_size":Vector2(64,48)/source_size,"interaction_offset":source_foot-center/source_size}
	if post.get("blocking")==true:
		object["collision_size"]=_point(post.collision_size_px)/source_size
		object["collision_offset"]=(post.physical_center_px-center)/source_size
	var portal: Dictionary={"id":"outskirts_bamboo_entrance","label":"前往竹溪林","destination_name":"竹溪林","pos":source_foot,"source_foot_pos":source_foot,"source_spawn_pos":source_spawn,"size":Vector2(64,48)/source_size,"target_scene":"openworld_v15_bamboo_outskirts","target_pos":_point(data.return_foot_px)/Vector2(1536,1024),"marker_offset":Vector2(0,18)/source_size,"show_destination_label":true}
	return {"object":object,"portal":portal}

func _release_source_entry_matches(actual: Variant,canonical: Variant,control: Variant,expected: Variant,clone: bool) -> bool:
	if not actual is SceneScript or not canonical is SceneScript or not control is WalkableMapLayout or not expected is Dictionary: return false
	if actual.scene_id!=&"linxi_village_scrollmap" or canonical.scene_id!=actual.scene_id or canonical.resource_path!=RELEASE_SOURCE_ENTRY_SCENE or control.resource_path!=RELEASE_SOURCE_ENTRY_LAYOUT: return false
	if actual.map_layout==null or canonical.map_layout==null or expected.size()!=2 or not expected.get("object") is Dictionary or not expected.get("portal") is Dictionary: return false
	if not _release_source_entry_storage_equal(canonical.map_layout,control,["resource_path"]): return false
	if not _release_source_entry_storage_equal(actual,canonical,["map_layout","resource_path"]): return false
	if not _release_source_entry_storage_equal(actual.map_layout,control,["visual_objects","portals","resource_path"]): return false
	if not clone:
		return actual.resource_path==RELEASE_SOURCE_ENTRY_SCENE and _release_source_entry_equal(actual.map_layout.visual_objects,control.visual_objects) and _release_source_entry_equal(actual.map_layout.portals,control.portals)
	if not actual.resource_path.is_empty() or is_same(actual,canonical) or is_same(actual.map_layout,canonical.map_layout) or is_same(actual.map_layout,control): return false
	for field_name: String in ["visual_objects","portals"]:
		var values: Array=actual.map_layout.get(field_name); var original: Array=control.get(field_name)
		if is_same(values,canonical.map_layout.get(field_name)) or is_same(values,original) or values.size()!=original.size()+1: return false
		if values.get_typed_builtin()!=original.get_typed_builtin() or values.get_typed_class_name()!=original.get_typed_class_name() or values.get_typed_script()!=original.get_typed_script(): return false
		for index in original.size():
			if not _release_source_entry_equal(values[index],original[index]): return false
		if not _release_source_entry_equal(values.back(),expected.object if field_name=="visual_objects" else expected.portal): return false
	return true

func _release_source_entry_identity(definition: Variant) -> bool:
	for path: String in RELEASE_SOURCE_ENTRY_PINS:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=RELEASE_SOURCE_ENTRY_PINS[path]: return false
	var canonical: SceneScript=ResourceLoader.load(RELEASE_SOURCE_ENTRY_SCENE,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var control: WalkableMapLayout=ResourceLoader.load(RELEASE_SOURCE_ENTRY_LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var cached: SceneScript=load(RELEASE_SOURCE_ENTRY_SCENE)
	if canonical==null or control==null or cached==null: return false
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(RELEASE_SOURCE_ENTRY_ROOT+"bamboo/art_contract.json"))
	if not data is Dictionary or not data.get("source_entry_object") is Dictionary: return false
	var texture: Variant=data.source_entry_object.get("texture")
	var hashes: Variant=data.get("asset_sha256")
	if typeof(texture)!=TYPE_STRING or not hashes is Dictionary or typeof(hashes.get(texture))!=TYPE_STRING or FileAccess.get_sha256(texture)!=hashes[texture]: return false
	var expected: Dictionary=_release_source_entry_expected(canonical,data)
	if not _release_source_entry_matches(cached,canonical,control,expected,false): return false
	if definition is SceneScript and definition.resource_path==RELEASE_SOURCE_ENTRY_SCENE: return _release_source_entry_matches(definition,canonical,control,expected,false)
	var current: Dictionary={}
	for biome: String in ["bamboo","forest","marsh"]: current[biome]=FileAccess.get_sha256(RELEASE_SOURCE_ENTRY_ROOT+biome+"/art_contract.json")
	var adoption: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/config/outskirts_native_adoption.json"))
	return _release_source_entry_domain(OS.get_cmdline_user_args(),adoption,current) and _release_source_entry_matches(definition,canonical,control,expected,true)

func _release_target_identity(definition: SceneScript,destination: StringName) -> bool:
	if destination==&"linxi_village_scrollmap": return _release_source_entry_identity(definition)
	var target_ok: bool=definition.resource_path=="res://data/scenes/%s.tres"%destination
	if String(destination) in CITY_IDS: target_ok=_configure_ordinary(definition)
	return target_ok

var release_legacy_source_size: Vector2=Vector2.ZERO
var release_legacy_actual_size: Vector2=Vector2.ZERO
var release_legacy_context: bool=false

func _release_ordinary_is_legacy(definition: SceneScript) -> bool:
	return definition!=null and not ordinary_native_city and not bool(root.get_node("SceneRouter").call("is_world_map_scene",definition.scene_id))

func _portal_roundtrip(id: String, mode: String, measurement: Dictionary) -> void:
	var failures_at_start: int = failures
	var router: Node = root.get_node("SceneRouter")
	var door: Vector2 = _point(measurement.door_foot_px)
	# Fixture placement is only the first local approach point. The door itself
	# must then be reached by real movement along independently checked edges.
	var approach: PackedVector2Array = PackedVector2Array()
	for route: Dictionary in world.map_layout.travel_routes:
		if String(route.get("id", "")) == "portal_" + id:
			var values: Variant = route.get("points")
			if values is PackedVector2Array or values is Array:
				for value: Variant in values: approach.append(_point(value) * SIZE)
	_check(approach.size() >= 2 and approach[approach.size() - 1].distance_to(door) < .01, "actual approach route terminates at measured doorstep: " + id)
	if approach.size() < 2: return
	if not bool(oracle.call("clear", approach[0])):
		_check(false, "approach fixture first point is not full17 safe: " + id)
		return
	router.call("go_field_smart", scene_id, approach[0] / SIZE, "", 15)
	if not await _wait_field(scene_id): return
	if not await _normal_intro(): return
	_check(field.get("_world_size") == SIZE, "actual production Field uses expanded world canvas")
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(approach[0]) < .02, "explicit version15 fixture origin is preserved exactly")
	var driven: Dictionary = await input_driver.call("follow", field, approach, _world_clear, _world_segment)
	_check(bool(driven.get("ok", false)), "real movement reaches doorstep with every physics foot legal: %s/%s %s" % [id, mode, driven])
	if not bool(driven.get("ok", false)): return
	await _capture_world("portal_"+id+"_"+mode+"_approach")
	var zone: Node2D
	for entry: Node2D in field.get("_exit_nodes"):
		if String(entry.get("target_scene_id")) == String(DESTINATIONS[id]): zone = entry
	_check(zone != null and bool(zone.get("_in_range")), "actual physics overlap reaches doorway, not radius across wall: " + id)
	if zone == null: return
	var input_evidence: Dictionary = {"mode": mode}
	if mode == "space": await input_driver.call("key", KEY_SPACE)
	elif mode == "door_mouse":
		var container: Node2D = field.get("world_container") as Node2D
		_check(container != null, "actual production world canvas transform exists")
		if container == null: return
		input_evidence.merge(await input_driver.call("pointer", container.get_global_transform_with_canvas() * door), true)
	else:
		var marker: Sprite2D = zone.get("marker_visual") as Sprite2D
		_check(marker != null and marker.texture != null and marker.visible, "actual drawn arrow exists and is visible: " + id)
		if marker == null: return
		input_evidence.merge(await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin), true)
	var destination: StringName = StringName(DESTINATIONS[id])
	if not await _wait_field(destination): return
	await _capture_world("portal_"+id+"_"+mode+"_target")
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var target_ok: bool = _release_target_identity(definition,destination)
	_check(target_ok,"normal unchanged target identity; only current SHA-bound exact candidate city clone allowed: "+id)
	if not target_ok: return
	player = field.get("_player") as Node2D
	_check(int(player.get_meta("depth_band_max", -1)) == 255, "ordinary target restores player depth255 after v15: " + id)
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc): _check(int(npc.get_meta("depth_band_max", -1)) == 255, "normally spawned target NPC restores depth255: " + id)
	if not _configure_ordinary(definition): return
	_check(_ordinary_clear(player.position), "actual target arrival full17/raw source/physics legal: " + id)
	if not await _normal_intro(): return
	if not await _actual_return(destination): return
	player = field.get("_player") as Node2D
	_check(player.position.distance_to(door) < .02 and bool(oracle.call("clear", player.position)), "actual paired exit restores exact door with complete feet: " + id)
	var navigation: Dictionary = router.call("get_navigation_state")
	_check(int(navigation.get("world_map_version", -1)) == 15, "paired target roundtrip retains world coordinate version15")
	actual_portal_roundtrips.append({"id": id, "mode": mode, "passed": failures == failures_at_start, "target_scene": String(destination), "target_resource": definition.resource_path, "door_foot_px": [door.x, door.y], "source_doorstep_uv": measurement.source_doorstep_uv, "approach": driven, "input": input_evidence, "actual_return_px": [player.position.x, player.position.y], "world_map_version": navigation.get("world_map_version")})
	await _capture_world("portal_"+id+"_"+mode+"_returned")


func _configure_ordinary(definition: SceneScript) -> bool:
	release_legacy_context=false
	release_legacy_source_size=Vector2.ZERO
	release_legacy_actual_size=Vector2.ZERO
	if not super._configure_ordinary(definition): return false
	# Native city and world contracts retain the immutable reader unchanged.
	if not _release_ordinary_is_legacy(definition): return true
	var actual: Variant=field.get("_world_size") if is_instance_valid(field) else null
	var declared: Vector2=Vector2(definition.map_layout.design_size)
	var valid: bool=typeof(actual)==TYPE_VECTOR2 and actual.is_finite() and actual.x>0 and actual.y>0 and declared.is_finite() and declared.x>0 and declared.y>0 and ordinary_raw!=null and ordinary_raw.get("size")==declared and ordinary_raw.get("sampling")=="normalized_image_round"
	_check(valid,"legacy actual canvas/source logical domain explicitly bound before normal input")
	if not valid: return false
	release_legacy_source_size=declared
	release_legacy_actual_size=actual
	release_legacy_context=true
	# Only planner/segment coordinates change domain. Raw source metadata,
	# pixels, polygons and grown margins remain in their original source units.
	ordinary_size=actual
	return true

func _release_legacy_foot_evidence(raw: Variant, source_size: Variant, actual_size: Variant, actor_root: Variant, visible_offset: Variant) -> Dictionary:
	var denied: Dictionary={"clear":false,"kind":"invalid_legacy_domain"}
	for value: Variant in [source_size,actual_size,actor_root,visible_offset]:
		if typeof(value)!=TYPE_VECTOR2 or not value.is_finite(): return denied
	if source_size.x<=0 or source_size.y<=0 or actual_size.x<=0 or actual_size.y<=0: return denied
	if not raw is RefCounted or not raw.has_method("pixel_evidence") or not raw.has_method("samples") or raw.get("valid")!=true or typeof(raw.get("size"))!=TYPE_VECTOR2 or raw.get("size")!=source_size or raw.get("sampling")!="normalized_image_round": return denied
	var foot: Vector2=actor_root+visible_offset
	var samples: PackedVector2Array=raw.call("samples",foot)
	if samples.size()!=17: return denied
	var records: Array=[]
	var all_clear: bool=true
	for index in samples.size():
		var shoe: Vector2=samples[index]
		# No clamp: actual 10x6 ellipse first, then EACH actual point maps into
		# source coordinates. Scaling only its center would change foot coverage.
		if not shoe.is_finite() or shoe.x<0 or shoe.y<0 or shoe.x>=actual_size.x or shoe.y>=actual_size.y:
			all_clear=false
			records.append({"shoe_index":index,"actual_point_px":[shoe.x,shoe.y],"clear":false,"kind":"outside_actual_canvas"})
			continue
		var source_point: Vector2=(shoe/actual_size)*source_size
		var pixel: Dictionary=raw.call("pixel_evidence",source_point)
		var solid_hits: Array=[]
		for solid: Dictionary in raw.get("solids"):
			var blocked: bool=Geometry2D.is_point_in_polygon(source_point,solid.polygon) if solid.kind=="exact_world_polygon" else (solid.rect as Rect2).has_point(source_point)
			if blocked: solid_hits.append({"id":solid.id,"kind":solid.kind})
		var clear: bool=pixel.get("clear")==true and solid_hits.is_empty()
		all_clear=all_clear and clear
		records.append({"shoe_index":index,"actual_point_px":[shoe.x,shoe.y],"source_point_px":[source_point.x,source_point.y],"pixel_evidence":pixel,"source_solid_hits":solid_hits,"clear":clear})
	return {"clear":all_clear,"kind":"actual17_mapped_to_original_legacy_source","actual_size_px":[actual_size.x,actual_size.y],"source_size_px":[source_size.x,source_size.y],"actor_root_px":[actor_root.x,actor_root.y],"visible_offset_px":[visible_offset.x,visible_offset.y],"visible_foot_px":[foot.x,foot.y],"samples":records,"source_grown_margins_changed":false,"Physics_claimed":false}

func _ordinary_static_clear(center: Vector2) -> bool:
	if not release_legacy_context: return super._ordinary_static_clear(center)
	if not is_instance_valid(field) or field.get("_world_size")!=release_legacy_actual_size or ordinary_size!=release_legacy_actual_size: return false
	var player: Node2D=field.get("_player") as Node2D
	var container: Node2D=field.get("world_container") as Node2D
	if not is_instance_valid(player) or container==null: return false
	var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
	return _release_legacy_foot_evidence(ordinary_raw,release_legacy_source_size,release_legacy_actual_size,center,offset).get("clear")==true

func _ensure_runtime_fixture() -> void:
	if runtime_started: return
	# Preserve the complete immutable public new-game/reset setup first.
	super._ensure_runtime_fixture()
	var router: Node=root.get_node("SceneRouter")
	var raw_navigation: Dictionary=router.call("get_navigation_state").duplicate(true)
	var target_versions: Dictionary=router.call("_city_target_versions").duplicate(true)
	var before: int=failures
	_check(not is_instance_valid(field) and raw_navigation==prior_navigation,"first runtime fixture normalization precedes every Field and retains raw reset baseline")
	_check(target_versions.size()==CITY_IDS.size(),"real Router city contract supplies exactly four canonical target versions")
	for id: String in CITY_IDS: _check(target_versions.has(id),"real navigation target-version contract contains canonical city: "+id)
	# Public restore adds the actual city-contract version ledger even to an empty
	# reset navigation. Capture a genuinely restorable process baseline, not the
	# pre-restore incomplete ledger. No production state or player file is written.
	router.call("restore_navigation_state",raw_navigation)
	var normalized: Dictionary=router.call("get_navigation_state").duplicate(true)
	var raw_other: Dictionary=raw_navigation.duplicate(true)
	var normalized_other: Dictionary=normalized.duplicate(true)
	raw_other.erase("local_layout_versions")
	normalized_other.erase("local_layout_versions")
	_check(raw_other==normalized_other and normalized.get("local_layout_versions")==target_versions,"normalization only inserts exact real-contract city versions; all other navigation fields unchanged")
	router.call("restore_navigation_state",normalized)
	var second: Dictionary=router.call("get_navigation_state").duplicate(true)
	_check(second==normalized,"public restore of normalized process fixture is strictly idempotent")
	_check(before_saves==_actual_saves() and int(root.get_node("SaveManager").get("active_slot"))==prior_slot,"normal public baseline normalization preserves all15 player paths and active slot")
	fixture_navigation_evidence={"scope":"PUBLIC_PRE_FIELD_PROCESS_FIXTURE_NORMALIZATION_NOT_SAVED_PLAYER_MIGRATION","raw_reset_navigation":raw_navigation,"actual_city_target_versions":target_versions,"normalized_navigation":normalized,"second_public_restore_navigation":second,"idempotent":second==normalized,"other_navigation_fields_unchanged":raw_other==normalized_other,"before_any_Field":not is_instance_valid(field),"player_files_unchanged":before_saves==_actual_saves(),"valid":failures==before}
	if failures==before:
		prior_navigation=normalized.duplicate(true)
		prior_active=StringName(router.get("_active_world_map_scene"))

func _parse_phase() -> bool:
	_check(FileAccess.get_sha256(RELEASE_WORLD_ORIGIN_PATH).to_lower()==RELEASE_WORLD_ORIGIN_SHA,"exact immutable exhaustive world origin")
	_check(FileAccess.get_sha256(V9C_ORIGINAL_PARENT_PATH).to_lower()==V9C_ORIGINAL_PARENT_SHA,"exact original parent provenance")
	_check(requested_phase=="release" and requested_portal.is_empty() and requested_mode=="all","distinct RELEASE never filters sixteen portals or normal modes")
	_check(Engine.time_scale==1.0,"ordinary clock1x, no accelerated physics/audio/BGM")
	return failures==0

func _default_phase() -> String:
	return "release"

func _read_physical_seam_plan() -> bool:
	var before: int=failures
	_check(FileAccess.get_sha256("res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd")==RELEASE_LAYERED_GEOMETRY.ORIGIN_SHA,"immutable saved geometry parent unchanged before any Field")
	_check(FileAccess.get_sha256(PHYSICAL_SEAM_PLAN_PATH)==PHYSICAL_SEAM_PLAN_SHA,"exact ROOT332 preexecution physical seam plan; never live reselection")
	if failures!=before: return false
	physical_seam_plan=_json(PHYSICAL_SEAM_PLAN_PATH)
	var plan: Dictionary=physical_seam_plan
	_check(plan.get("scope")=="PREEXECUTION_FIXED_PHYSICAL_SEAM_SELECTION_NOT_FIELD_RELEASE_OR_APPROVAL" and plan.get("edge_count")==112 and plan.get("physical_static_witness_count")==1344 and plan.get("candidate_count")==35168 and plan.get("original_source_collision_negative_count")==94 and plan.get("selection_frozen_before_execution")==true and plan.get("runtime_reselection_permitted")==false and plan.get("selection_replacement_after_failure_permitted")==false and plan.get("Field_executed")==false and plan.get("actual_Physics_checked")==false and plan.get("formal_approval")==false,"strict distinct preparation-only complete112/1344/94 plan")
	var pins: Variant=plan.get("input_sha256")
	_check(pins is Dictionary and pins.size()==74,"algorithm+original selection+S/M/layout+64PNG exact input closure")
	if not pins is Dictionary: return false
	for path: Variant in pins:
		_check(path is String and _review_hash(pins[path]) and FileAccess.file_exists(path) and FileAccess.get_sha256(path)==pins[path],"all physical-plan original inputs still exact: "+str(path))
	_check(pins.get(SOURCE_PATH)==FileAccess.get_sha256(SOURCE_PATH) and pins.get(MANIFEST_PATH)==FileAccess.get_sha256(MANIFEST_PATH) and pins.get(RELEASE_OBJECTS.SELECTION_PATH)==RELEASE_OBJECTS.SELECTION_SHA,"plan explicitly binds current S/M and immutable ROOT234")
	var old: Dictionary=_json(RELEASE_OBJECTS.SELECTION_PATH)
	var original_by_id: Dictionary={}
	for row: Dictionary in old.get("seams",[]): original_by_id[row.id]=row
	var source_by_id: Dictionary={}
	for row: Dictionary in source.get("seams",[]): source_by_id[row.id]=row
	physical_seams_by_id.clear()
	var physical_count: int=0
	for row: Dictionary in plan.get("seams",[]):
		var id: String=String(row.get("id",""))
		var identity: bool=not physical_seams_by_id.has(id) and original_by_id.has(id) and source_by_id.has(id)
		_check(identity,"unique all112 actual source/ROOT234 physical-plan edge: "+id)
		if not identity: continue
		_check(_release_review_exact_value(row.get("original_captured_witnesses"),source_by_id[id].get("projected_witnesses")) and _release_review_exact_value(row.get("original_captured_witnesses"),original_by_id[id].get("projected_witnesses")),"all original1344 captured coordinates remain unchanged: "+id)
		var legal: Array=[]
		for candidate: Dictionary in row.get("all_candidates",[]):
			if candidate.get("clear")==true: legal.append(candidate)
		var selected: Array=row.get("physical_witnesses",[])
		var ranks: Array=row.get("selected_legal_ranks",[])
		_check(legal.size()==row.get("legal_candidate_count") and legal.size()>=12 and selected.size()==12 and ranks.size()==12 and row.get("runtime_reselection_permitted")==false,"exact12 fixed legal witnesses/complete candidate domain: "+id)
		for wi in mini(selected.size(),12):
			var rank: int=floori(float(wi)*float(legal.size()-1)/11.)
			_check(wi<ranks.size() and ranks[wi]==rank and rank>=0 and rank<legal.size() and _release_review_exact_value(selected[wi],legal[rank]),"ROOT332 exact equal-rank candidate cannot be replaced: "+id+"/"+str(wi))
		physical_count+=selected.size()
		physical_seams_by_id[id]=row
	_check(physical_seams_by_id.size()==112 and source_by_id.size()==112 and original_by_id.size()==112 and physical_count==1344 and plan.get("original_source_collision_negatives",[]).size()==94,"all112/1344 selected and all94 original source collision negatives")
	return failures==before

func _neighbor_geometry_checks() -> void:
	if oracle == null or not bool(oracle.get("valid")): return
	var independent: RefCounted=RELEASE_LAYERED_GEOMETRY.new()
	independent.call("configure_derived_inputs",derived_geometry_inputs)
	saved_geometry_report=independent.call("run",manifest,source,oracle)
	checks+=int(saved_geometry_report.get("checks",0))
	for message: String in saved_geometry_report.get("errors",[]):
		failures+=1
		push_error("[JOINT layered geometry FAIL] "+message)
	original_raster_seam_records.assign(saved_geometry_report.get("original_raster_seam_records",[]))
	_check(original_raster_seam_records.size()==1344,"all original1344 raster proofs present without source-solid/Physics credit")
	_check(_write_json("actual_saved_geometry_112_references.json",saved_geometry_report),"independent saved global mesh/RF/all112 five-role references and original raster proofs persist")
	independent.call("release")
	independent=null
	if int(saved_geometry_report.get("failures",1))==0: completed_phases.append("saved_global_mesh_RF_and112_actual_reference_edges")

func _blocked_shoe_own_Physics(negative: Dictionary) -> Dictionary:
	var id: String=String(negative.get("id",""))
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var container: Node2D=field.get("world_container") as Node2D
	var kinds: Dictionary={}
	for blocker: Dictionary in oracle.get("blockers"):
		if blocker.get("id")==id: kinds[String(blocker.get("kind",""))]=true
	var kind: String=String(kinds.keys()[0]) if kinds.size()==1 else ""
	var expected_name: String=("ObjectCollision_" if kind=="visual_objects" else "Collision_")+id
	var bodies: Array[StaticBody2D]=[]
	for body: StaticBody2D in field.get("_collision_bodies"):
		if String(body.name)==expected_name: bodies.append(body)
	var identity: bool=kinds.size()==1 and kind in ["visual_objects","blockers"] and bodies.size()==1 and player!=null and container!=null
	_check(identity,"negative blocked shoe belongs to unique real source object/live ownRID: "+id)
	if not identity: return {"own_rid_hit":false,"identity_valid":false}
	var body: StaticBody2D=bodies[0]
	var expected_rid: int=body.get_rid().get_id()
	var query:=PhysicsPointQueryParameters2D.new()
	var point: Vector2=_point(negative.get("point"))
	query.position=container.to_global(point)
	query.collision_mask=int(player.collision_mask)
	query.exclude=[player.get_rid()]
	query.collide_with_areas=false
	var hits: Array[Dictionary]=player.get_world_2d().direct_space_state.intersect_point(query,4096)
	var rows: Array=[]
	var own: bool=false
	for hit: Dictionary in hits:
		var rid: RID=hit.get("rid",RID())
		var collider: Object=hit.get("collider")
		var matched: bool=rid==body.get_rid() and collider==body
		own=own or matched
		rows.append({"rid":rid.get_id(),"path":str((collider as Node).get_path()) if collider is Node else str(collider),"own_object_rid":matched})
	_check(own,"exact originally blocked SHOE point intersects matched object's ownRID, not claimed Player-center collision: "+id)
	return {"query_kind":"ACTUAL_POINT_AT_ORIGINAL_BLOCKED_SHOE","query_point_px":[point.x,point.y],"expected_own_rid":expected_rid,"expected_body_path":str(body.get_path()),"source_kind":kind,"actual_body":{"id":id,"path":str(body.get_path()),"rid":expected_rid,"source_collision_kind":kind},"own_rid_hit":own,"hits":rows,"player_center_collision_claimed":false,"player_was_not_moved":true}

func _release_raw_reason_matches(stored: Variant,live_expectation: Dictionary) -> bool:
	# ROOT332 saved this raw reason inside JSON.stringify(plan,"\t",true).
	# Only the independently observed LIVE expectation crosses that writer once;
	# never cast/round/re-encode the untouched saved reason or use an epsilon.
	var encoded_expectation: Variant=JSON.parse_string(JSON.stringify(live_expectation,"\t",true))
	return _release_review_exact_value(stored,encoded_expectation)

func _release_layered_static_seams() -> void:
	var began: int=failures
	if physical_seam_plan.is_empty() and not _read_physical_seam_plan(): return
	if not await _open_owned_world_fixture(world.player_spawn*SIZE): return
	var expected_denials: Dictionary={}
	for negative: Dictionary in physical_seam_plan.get("original_source_collision_negatives",[]):
		expected_denials[String(negative.seam_id)+"/"+str(int(negative.original_witness_index))]=negative
	var actual_denied: int=0
	for id: String in physical_seams_by_id:
		var old: Array=physical_seams_by_id[id].original_captured_witnesses
		for wi in old.size():
			var reason: Dictionary=oracle.call("segment_evidence",_point(old[wi].from_px),_point(old[wi].to_px))
			var key: String=id+"/"+str(wi)
			var denied: bool=reason.get("clear")==false
			_check(denied==expected_denials.has(key),"all original1344 source-solid classifications remain honest: "+key)
			if denied:
				actual_denied+=1
				_check(expected_denials.has(key) and _release_raw_reason_matches(expected_denials.get(key,{}).get("actual_segment_evidence"),reason),"original denied full17 precise reason unchanged: "+key)
			original_raw_seam_classifications.append({"seam_id":id,"original_witness_index":wi,"actual_raw_segment":reason,"actual_Physics_pass_claimed":false,"old_failure_claimed_passed":false})
	_check(original_raw_seam_classifications.size()==1344 and actual_denied==94,"exact all1344 original source classifications include94 denied; never relabeled passed")
	# New fixed positives: actual raw full17 AND actual current Player shape.
	for id: String in physical_seams_by_id:
		var seam: Dictionary=physical_seams_by_id[id]
		for index in (seam.get("physical_witnesses",[]) as Array).size():
			var witness: Dictionary=seam.physical_witnesses[index]
			var a: Vector2=_point(witness.from_px)
			var b: Vector2=_point(witness.to_px)
			var proof: Dictionary=_world_segment(a,b)
			var centers: Array=[]
			for ci in 3:
				var point: Vector2=a.lerp(b,float(ci)/2.)
				var raw_proof: Dictionary=oracle.call("foot_evidence",point)
				var physical: bool=_physical_clear(point)
				centers.append({"center_px":[point.x,point.y],"raw_full17":raw_proof,"actual_Physics_clear":physical})
				_check(raw_proof.get("clear")==true and physical,"each new fixed witness center full17 source solids AND live actual Physics: "+id+"/"+str(index)+"/"+str(ci))
			_check(proof.get("clear")==true and a.distance_to(b)==8.,"all1344 NEW fixed complete17 <=4px shoes AND actual live Physics witnesses: "+id+"/"+str(index))
			release_seam_static.append({"id":id,"witness_index":index,"candidate_index":witness.candidate_index,"selected_legal_rank":seam.selected_legal_ranks[index],"from_px":[a.x,a.y],"to_px":[b.x,b.y],"full17_actual_physics":proof,"three_center_proofs":centers,"normal_input_executed":false})
	# Original94 are NOT forgiven or relabeled as legal: reproduce exact reason.
	for negative: Dictionary in physical_seam_plan.get("original_source_collision_negatives",[]):
		var seam: Dictionary=physical_seams_by_id.get(String(negative.seam_id),{})
		var original: Dictionary=seam.original_captured_witnesses[int(negative.original_witness_index)]
		var actual: Dictionary=oracle.call("segment_evidence",_point(original.from_px),_point(original.to_px))
		_check(_release_raw_reason_matches(negative.actual_segment_evidence,actual) and actual.get("clear")==false and actual.get("kind")=="source_collision","original source collision denial retains exact id/center/shoe/point/witness: "+str(negative.seam_id)+"/"+str(negative.original_witness_index))
		var row: Dictionary=negative.duplicate(true)
		row["actual_raw_denial"]=actual
		row["blocked_shoe_Physics"]=_blocked_shoe_own_Physics(negative)
		original_source_collision_negative_records.append(row)
	_check(release_seam_static.size()==1344 and original_source_collision_negative_records.size()==94,"all1344 new physical witnesses AND all94 preserved actual original negative attributions")
	_check(FileAccess.get_sha256(PHYSICAL_SEAM_PLAN_PATH)==PHYSICAL_SEAM_PLAN_SHA and bool(oracle.call("verify_sources")),"same fixed plan/source through entire physical phase")
	_check(_write_json("release_layered_seams_static.json",{"scope":"NEW_FIXED1344_FULL17_ACTUAL_PHYSICS_AND_ORIGINAL94_BLOCKED_SHOE_OWNRID_NOT_NORMAL_INPUT","physical_seam_plan_path":PHYSICAL_SEAM_PLAN_PATH,"physical_seam_plan_sha256":PHYSICAL_SEAM_PLAN_SHA,"records":release_seam_static,"original_source_collision_negative_records":original_source_collision_negative_records}),"layered static evidence checked readback")
	if failures==began: completed_phases.append("new1344_fixed_physical_and_original94_blocked_shoe_ownRID")

func _actual_open_seam_input_phase() -> void:
	var began_failures: int=failures
	await _release_layered_static_seams()
	if failures!=began_failures: return
	for id: String in physical_seams_by_id:
		var seam: Dictionary=physical_seams_by_id[id]
		var witness: Dictionary=seam.physical_witnesses[0]
		var a: Vector2=_point(witness.from_px)
		var b: Vector2=_point(witness.to_px)
		if not await _open_owned_world_fixture(a): continue
		var record: Dictionary=await input_driver.call("follow",field,PackedVector2Array([a,b]),_world_clear,_world_segment)
		record["id"]=id
		record["witness_index"]=0
		record["candidate_index"]=witness.candidate_index
		record["physical_seam_plan_sha256"]=PHYSICAL_SEAM_PLAN_SHA
		_check(bool(record.get("ok",false)),"real normal input completes ROOT332 fixed first physical witness, never replacement: "+id)
		actual_open_seam_crossings.append(record)
		await _capture_world("release_seam_"+id)
	_check(actual_open_seam_crossings.size()==112,"all112 fixed physical boundary representatives actually driven once")
	_check(_write_json("release_112_seams_actual_input.json",{"scope":"NEW_PLAN_FIXED112_BOUNDARY_NORMAL_INPUT_NOT_ALL1344","physical_seam_plan_path":PHYSICAL_SEAM_PLAN_PATH,"physical_seam_plan_sha256":PHYSICAL_SEAM_PLAN_SHA,"records":actual_open_seam_crossings}),"actual112 crossing evidence checked readback")
	if failures==began_failures and release_seam_static.size()==1344 and actual_open_seam_crossings.size()==112: completed_phases.append("all1344_seam_17shoe_Physics_and_fixed112_normal_input")

func _run() -> void:
	var phase_valid: bool = _parse_phase()
	var fresh_start_only: bool = "--fresh-start-only" in OS.get_cmdline_user_args()
	output = "res://build/joint_world_luoyang_20261003_qa/world_%s_%d/" % [requested_phase if phase_valid else "invalid_request", Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique v15 QA evidence output")
	before_saves = _actual_saves()
	var router := root.get_node("SceneRouter")
	prior_navigation = router.call("get_navigation_state").duplicate(true)
	prior_active = StringName(router.get("_active_world_map_scene"))
	prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	if not phase_valid:
		await _finish()
		return
	manifest = _json(MANIFEST_PATH)
	source = _json(SOURCE_PATH)
	if not _read_physical_seam_plan():
		await _finish()
		return
	# Dynamic current E context in normal autoload scope; the inherited V9D
	# lexical constant is original provenance, not the executed E preflight.
	var context_script: GDScript=load(RELEASE_CONTEXT_PATH) as GDScript
	_check(context_script!=null and context_script.can_instantiate(),"explicit NEW E source-context can instantiate, never old V9D fallback")
	if context_script==null or not context_script.can_instantiate():
		await _finish()
		return
	var pins_reader: RefCounted = context_script.new() as RefCounted
	context_script=null
	var pins_ok: bool = pins_reader.call("validate_v9c_world_pins",execution_sha256,v9c_artifact_sha256,manifest,derived_geometry_inputs)
	_check(pins_ok,"fixed current v7 execution AND final artifact pins before any Field: "+str(pins_reader.get("errors")))
	pins_reader = null
	_check(("--candidate-before-cutover" in OS.get_cmdline_user_args()) == (scene_id == &"world_map_jianghu_v15"), "explicit candidate/canonical stage agrees with exact selected normal resource")
	_check(source.get("status") == "ART_ASSETS_READY" and source.get("schema_version") == 15 and manifest.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"], "full same-revision artifacts ready, not macro/local/partial")
	_check(manifest.get("capture_protocol")=="COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1" and manifest.get("source_contract_path")==SOURCE_PATH,"literal whole-v7 FULL capture protocol/source, no v5 local-frustum substitution")
	_check(source.get("pixel_sampling")=="round_world_pixel" and source.get("physical_navigation_margin_px")==0,"explicit direct logical round sampler/margin; independent oracle must not share legacy W-1 offset")
	_read_independent_door_review()
	_check(ResourceLoader.exists(scene_path), "published v15 production candidate exists")
	# Final owner status/compiler schema will be explicitly bound after SOURCE_READY.
	if failures > 0:
		await _finish()
		return
	world = load(scene_path) as SceneScript
	_check(world != null and world.scene_id == scene_id and world.map_layout != null and world.map_layout.schema_version == 15 and world.map_layout.design_size == Vector2i(SIZE), "actual candidate ID/layout/schema/full logical size")
	if failures > 0:
		await _finish()
		return
	oracle = RAW_ORACLE.new()
	_check(oracle.call("configure", world.map_layout), "independent original tile/margin/full17 oracle is complete: " + str(oracle.get("errors")))
	_static_portals_and_spacing()
	if failures > 0:
		await _finish()
		return
	await _default_spawn_actual_field_check()
	if failures > 0:
		await _finish()
		return
	if requested_phase in ["raw", "full", "release"]:
		_route_fullfoot_checks()
		_neighbor_geometry_checks()
		# Explicit NEW E independent math oracle; no V9D identity/recipe fallback.
		var artifact_script: GDScript=load(RELEASE_ARTIFACT_PATH) as GDScript
		_check(artifact_script!=null and artifact_script.can_instantiate(),"explicit NEW E artifact oracle compiles; all old64/112/body/mips predicates retained")
		if artifact_script==null or not artifact_script.can_instantiate():
			await _finish()
			return
		var artifacts: RefCounted=artifact_script.new() as RefCounted
		artifact_script=null
		artifacts.call("configure_final_pins",v9c_artifact_sha256)
		artifacts.call("configure_derived_inputs",derived_geometry_inputs,execution_sha256)
		artifact_report=artifacts.call("run",self)
		artifacts=null
		if bool(artifact_report.get("complete",false)): completed_phases.append("all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions")
		if failures > 0:
			await _finish()
			return
		await _route_input_phase()
		await _actual_open_seam_input_phase()
	if requested_phase in ["portal", "full", "release"]:
		await _portal_runtime_phase()
		await _door_negative_phase()
	if requested_phase in ["migration", "full", "release"]:
		if fresh_start_only:
			saved_context_report={"scope":"HISTORICAL_COMPATIBILITY_NOT_EXECUTED","complete":false,"historical_compatibility_tested":false,"records":[]}
		else:
			_migration_prepare_phase()
			await _migration_isolated_save_phase()
			var contexts: RefCounted=SAVED_CONTEXTS.new()
			saved_context_report=await contexts.call("run",self)
			contexts=null
			if bool(saved_context_report.get("complete",false)): completed_phases.append("actual_free_indoor_native15_and_unknown_version_zero_mutation_saves")
		await _gameplay_return_phase()
	if requested_phase in ["depth", "full", "release"]:
		await _depth_runtime_phase()
		await _normal_npc_patrol_phase()
		var all_objects: RefCounted=RELEASE_OBJECTS.new()
		all_object_report=await all_objects.call("run",self)
		all_objects=null
		if bool(all_object_report.get("release_complete",false)): completed_phases.append("all2687_binding_2322_ownRID_physics_and_fixed130_actual_inputs")
	var unfinished: Array[String] = []
	if requested_phase in ["raw", "full", "release"] and not bool(artifact_report.get("complete",false)): unfinished.append("all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions")
	if requested_phase in ["depth", "full", "release"] and not bool(all_object_report.get("release_complete",false)): unfinished.append("all_model_current_frame_alpha_and_ordinary_depth_cleanup")
	if not fresh_start_only and requested_phase in ["migration", "full", "release"] and not bool(saved_context_report.get("complete",false)): unfinished.append("actual_nonportal_and_indoor_historic_saved_contexts")
	# Visual approval is an independent producer decision, never an automatic
	# PASS produced by this suite. The GPU run must still actually capture its
	# normal-input paths/current-alpha cases rather than inherit headless images.
	if requested_phase=="release" and DisplayServer.get_name()!="headless":
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args() and not raw_screenshots.is_empty(),"actual separately authorized GPU input capture exists; visual verdict remains NOT_REVIEWED")
	for phase: String in unfinished:
		incomplete_phases.append(phase)
		_check(false, "required actual v15 phase incomplete/failed: " + phase)
	await _finish()


func _finish() -> void:
	# Only this process's fixture ownership. Runtime baseline was established by
	# the public new-game operation before candidate travel, not a hidden slot.
	if input_driver != null: input_driver.call("release")
	input_driver = null
	if alpha_oracle != null: alpha_oracle.call("release")
	alpha_oracle = null
	if is_instance_valid(isolated_slots):
		var slots_reference: WeakRef = weakref(isolated_slots)
		if isolated_slots.get_parent() != null: isolated_slots.get_parent().remove_child(isolated_slots)
		isolated_slots.queue_free()
		isolated_slots = null
		for settle in 4: await process_frame
		_check(slots_reference.get_ref() == null, "owned isolated SaveManager actually released")
	ordinary_images.clear()
	ordinary_blockers.clear()
	if runtime_started:
		if is_instance_valid(current_scene):
			var owned_scene: Node = current_scene
			var reference: WeakRef = weakref(owned_scene)
			current_scene = null
			owned_scene.queue_free()
			owned_scene = null
			field = null
			for settle in 8: await process_frame
			_check(reference.get_ref() == null, "owned production Field actually freed after natural stages")
		var router: Node = root.get_node("SceneRouter")
		router.call("restore_navigation_state", prior_navigation)
		router.set("_active_world_map_scene", prior_active)
		var audio: Node = root.get_node_or_null("AudioManager")
		if audio != null:
			audio.call("stop_bgm", 0.0)
			audio.call("stop_music_sting")
			audio.call("stop_ambience", 0.0)
			audio.call("stop_all_sfx")
			audio.call("stop_dialog_audio")
		await create_timer(.20).timeout
		for settle in 8: await process_frame
	if oracle != null:
		_check(bool(oracle.call("verify_sources")),"all64 current raw navigation PNG SHA unchanged after actual phase")
		oracle.call("release")
	if ordinary_raw != null:
		_check(bool(ordinary_raw.call("verify_sources")),"actual current target nav remains frozen through final input")
		ordinary_raw.call("release")
	ordinary_raw = null
	oracle = null
	world = null
	_check(before_saves == _actual_saves(), "normal player files unchanged before and after requested phase")
	_check(int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "normal active save slot unchanged")
	_check(root.get_node("SceneRouter").call("get_navigation_state") == prior_navigation, "test cleanup preserves managed fixture baseline without slot I/O or version drift")
	_check(StringName(root.get_node("SceneRouter").get("_active_world_map_scene")) == prior_active, "source-only suite does not change active world")
	var actual_portal_ids: Dictionary={}
	for trip: Dictionary in actual_portal_roundtrips:
		var portal_id: String=String(trip.get("id",trip.get("portal_id","")))
		if not portal_id.is_empty(): actual_portal_ids[portal_id]=true
	var fresh_start_only: bool="--fresh-start-only" in OS.get_cmdline_user_args()
	var saved_context_done: bool=bool(saved_context_report.get("complete",false)) if not fresh_start_only else saved_context_report=={"scope":"HISTORICAL_COMPATIBILITY_NOT_EXECUTED","complete":false,"historical_compatibility_tested":false,"records":[]}
	var complete: bool=requested_phase=="release" and failures==0 and incomplete_phases.is_empty() and runtime_started and bool(artifact_report.get("complete",false)) and bool(all_object_report.get("release_complete",false)) and saved_context_done and actual_portal_roundtrips.size()==48 and actual_portal_ids.size()==16 and saved_geometry_report.get("edges",[]).size()==112 and release_seam_static.size()==1344 and actual_open_seam_crossings.size()==112 and driven_world_routes.size()==27 and original_raster_seam_records.size()==1344 and original_source_collision_negative_records.size()==94 and not physical_seam_plan.is_empty() and FileAccess.get_sha256(PHYSICAL_SEAM_PLAN_PATH)==PHYSICAL_SEAM_PLAN_SHA
	var report: Dictionary = {"schema": 1, "scope": "RELEASE_WORLD_RISK_STRATIFIED_ACTUAL_INPUT_NOT_EXHAUSTIVE_FULL", "requested_phase": requested_phase, "source_complete": false, "release_complete": complete, "legacy_full_executed": false, "exhaustive_2687_normal_input_executed": false, "checks": checks+1, "failures": failures, "completed_phases": completed_phases, "incomplete_phases": incomplete_phases, "route_4px_full17_centers": route_centers, "field_input_executed": runtime_started, "portal_ids":actual_portal_ids.keys(),"core_ids":CORE_IDS,"chunk_count":(artifact_report.get("records",{}) as Dictionary).get("chunks",[]).size(),"seam_count":saved_geometry_report.get("edges",[]).size(),"portal_roundtrips": actual_portal_roundtrips, "GPU_executed": not raw_screenshots.is_empty(), "player_saves_unchanged": before_saves == _actual_saves(), "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path),"output":output,"saved_geometry_112":saved_geometry_report.duplicate(true),"artifact_semantics":artifact_report.duplicate(true),"all_current_objects":all_object_report.duplicate(true),"actual_saved_contexts":saved_context_report.duplicate(true),"actual_route_input":driven_world_routes.duplicate(true),"actual_open_seam_input":actual_open_seam_crossings.duplicate(true),"raw_screenshots":raw_screenshots.duplicate(true),"visual_verdict":"NOT_REVIEWED"}
	report["fresh_start_only"]=fresh_start_only
	report["historical_compatibility_tested"]=not fresh_start_only
	if fresh_start_only: report["scope"]="FRESH_START_WORLD_ACTUAL_INPUT_NOT_HISTORICAL_COMPATIBILITY"
	report["seam_static_witness_count"]=release_seam_static.size()
	report["physical_seam_plan_path"]=PHYSICAL_SEAM_PLAN_PATH
	report["physical_seam_plan_sha256"]=PHYSICAL_SEAM_PLAN_SHA
	report["original_raster_seam_records"]=original_raster_seam_records.duplicate(true)
	report["original_source_collision_negative_records"]=original_source_collision_negative_records.duplicate(true)
	report["original_raw_seam_classifications"]=original_raw_seam_classifications.duplicate(true)
	report["original_raster_witness_count"]=original_raster_seam_records.size()
	report["original_source_collision_negative_count"]=original_source_collision_negative_records.size()
	report["old_ROOT330_94_failures_preserved"]=true
	report["seam_actual_input_count"]=actual_open_seam_crossings.size()
	report["all1344_seam_witnesses_normal_input_executed"]=false
	report["static_seam_records"]=release_seam_static.duplicate(true)
	report["selection_path"]=RELEASE_OBJECTS.SELECTION_PATH
	report["selection_sha256"]=RELEASE_OBJECTS.SELECTION_SHA
	report["execution_sha256"]=execution_sha256.duplicate(true)
	report["v9c_artifact_sha256"]=v9c_artifact_sha256.duplicate(true)
	report["independent_visual_review_binding"]=visual_review_evidence.duplicate(true)
	report["actual_first_default_spawn"]=default_spawn_evidence.duplicate(true)
	_check(_write_json("result.json", report), "actual world phase result checked write/readback")
	print("[WorldV15] ACTUAL_PHASE checks=%d failures=%d complete=%s output=%s" % [checks, failures,complete,output])
	result = report.duplicate(true)
	result["checks"] = checks
	result["failures"] = failures
	result["source_complete"]=false
	result["release_complete"]=complete and failures==0
	owner_tree = null

## Narrow RELEASE reader repairs only; frozen exhaustive parent stays immutable.
func _release_review_exact_value(saved: Variant, expected: Variant) -> bool:
	# Independent comparison of untouched saved values to only the expectation
	# encoded once in its original writer domain. No epsilon or Float32 recast.
	if typeof(saved) in [TYPE_INT,TYPE_FLOAT] and typeof(expected) in [TYPE_INT,TYPE_FLOAT]:
		return is_finite(float(saved)) and is_finite(float(expected)) and float(saved)==float(expected)
	if typeof(saved)!=typeof(expected): return false
	if saved is Array:
		if saved.size()!=expected.size(): return false
		for i in saved.size():
			if not _release_review_exact_value(saved[i],expected[i]): return false
		return true
	if saved is Dictionary:
		if saved.size()!=expected.size(): return false
		for key: Variant in saved:
			if not expected.has(key) or not _release_review_exact_value(saved[key],expected[key]): return false
		return true
	return saved==expected

func _review_negative_probes(portal: Dictionary, approval: Dictionary, catalog: Dictionary, footprints: Dictionary, id: String) -> void:
	_check(approval.get("negative_source_footprint_path")==REVIEW_FOOTPRINTS and _review_bound(REVIEW_FOOTPRINTS,approval.get("negative_source_footprint_sha256"),catalog),"negative review binds actual original footprint file/current catalog SHA "+id)
	var landmark: Variant=(footprints.get("landmarks",{}) as Dictionary).get(id) if footprints.get("landmarks") is Dictionary else null
	var original: String=String(portal.get("source",""))
	# Frozen V7 exporter retains measured Double UV in portal; original default
	# JSON writer encodes that expectation once. Never encode/cast saved UV.
	var measured_uv: Variant=landmark.get("source_doorstep_uv") if landmark is Dictionary else null
	var expected_uv: Variant=JSON.parse_string(JSON.stringify(measured_uv,"\t")) if _review_pair(measured_uv) else null
	_check(landmark is Dictionary and landmark.get("source")==original and _review_bound(original,landmark.get("source_sha256"),catalog) and landmark.get("compound_id")==portal.get("compound_id") and _review_pair(measured_uv) and _review_pair(portal.get("source_doorstep_uv")) and _release_review_exact_value(portal.get("source_doorstep_uv"),expected_uv),"negative footprint independently binds original PNG/compound/source doorway UV "+id)
	var probes: Variant=approval.get("input_negative_probes")
	if portal.has("input_negative_probes"):
		_check(approval.get("negative_origin")=="CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1" and portal.get("input_negative_probes") is Array and probes==portal.get("input_negative_probes"),"existing negative source record must match exact, invalid/null key has no fallback "+id)
	else:
		_check(approval.get("negative_origin")=="INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1","source-absent negatives only from explicit root-authored independent review "+id)
	_check(probes is Array and probes.size()==3,"exact three reviewed negative records per doorway "+id)
	if not probes is Array or probes.size()!=3: return
	var kinds: Dictionary={}
	for probe: Variant in probes:
		_check(probe is Dictionary,"typed independent reviewed negative record "+id)
		if not probe is Dictionary: continue
		var kind: String=String(probe.get("kind",""))
		_check(kind in ["wall_approach","roof_click","wrongside"] and not kinds.has(kind) and probe.get("semantic_review_status")=="APPROVED","distinct approved original semantic negative mechanism "+id+"/"+kind)
		kinds[kind]=true
		var keys: Array=["legal_start_px","blocked_foot_px"] if kind=="wall_approach" else ["legal_stand_px","world_click_px"]
		for key: String in keys:
			var point: Variant=probe.get(key)
			_check(_review_pair(point) and _point(point).x>=0 and _point(point).y>=0 and _point(point).x<SIZE.x and _point(point).y<SIZE.y,"reviewed negative world coordinate finite/in domain "+id+"/"+kind+"/"+key)
		if kind=="roof_click":
			var uv: Variant=probe.get("source_uv")
			_check(_review_pair(uv) and _point(uv).x>=0 and _point(uv).y>=0 and _point(uv).x<1 and _point(uv).y<1,"reviewed roof source UV strict original pixel domain "+id)
	_check(kinds.size()==3,"wall/roof/wrongside mechanism coverage cannot be dropped "+id)

func _read_independent_door_review() -> void:
	# Independent current-bytes reader: do not call the subject publication gate,
	# change captured PENDING statuses, or call visual approval a Field result.
	var start_failures: int=failures
	var review: Dictionary=_json(REVIEW_PATH)
	_check(typeof(review.get("schema_version")) in [TYPE_INT,TYPE_FLOAT] and review.get("schema_version")==1 and typeof(review.get("version")) in [TYPE_INT,TYPE_FLOAT] and review.get("version")==15 and review.get("capture_protocol")==WHOLE_PROTOCOL and review.get("scope")=="ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL","independent review exact version/protocol/visual-only scope")
	_check(review.get("reviewer_role")=="producer/root" and review.get("review_method")=="actual_png_individual_review" and review.get("reviewer") is String and not String(review.get("reviewer","")).strip_edges().is_empty() and typeof(review.get("visual_approved"))==TYPE_BOOL and review.get("visual_approved")==true,"explicit named root current capture review, not QA self-signed visual verdict")
	for binding: Array in [[SOURCE_PATH,"source_sha256"],[MANIFEST_PATH,"manifest_sha256"],[WHOLE_REPORT_PATH,"whole_capture_report_sha256"]]:
		var path: String=binding[0]
		var sha: Variant=review.get(binding[1])
		_check(_review_hash(sha) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(sha).to_lower(),"review binds exact current source/manifest/report bytes "+path)
	_check(review.get("whole_capture_report_path")==WHOLE_REPORT_PATH,"review references literal FULL report, not a pilot")
	var catalog_value: Variant=manifest.get("asset_sha256")
	var doors_value: Variant=review.get("doors")
	var assets_value: Variant=review.get("reviewed_assets_sha256")
	_check(catalog_value is Dictionary and doors_value is Dictionary and doors_value.size()==16 and assets_value is Dictionary,"typed current catalog/exact16 approvals/reviewed PNG index")
	if not catalog_value is Dictionary or not doors_value is Dictionary or doors_value.size()!=16 or not assets_value is Dictionary: return
	var catalog: Dictionary=catalog_value
	var doors: Dictionary=doors_value
	var assets: Dictionary=assets_value
	for key: Variant in doors: _check(key is String and DESTINATIONS.has(key),"no unknown separately reviewed door "+str(key))
	var originals: Dictionary={}
	var portals_value: Variant=source.get("portals")
	_check(portals_value is Array and portals_value.size()==16,"exact sixteen captured original source doors")
	if not portals_value is Array: return
	for portal_value: Variant in portals_value:
		_check(portal_value is Dictionary,"typed captured original doorway")
		if not portal_value is Dictionary: continue
		var id: String=String(portal_value.get("id",""))
		_check(DESTINATIONS.has(id) and not originals.has(id),"unique original door identity "+id)
		originals[id]=portal_value
	var compounds: Dictionary={}
	var footprints: Dictionary=_json(REVIEW_FOOTPRINTS)
	var objects_value: Variant=source.get("objects")
	_check(objects_value is Array,"typed source object array for independent doorway review")
	if not objects_value is Array: return
	for object: Variant in objects_value:
		if object is Dictionary:
			var id: String=String(object.get("id",""))
			_check(not compounds.has(id),"unique current object identity for review "+id)
			compounds[id]=object
	for id: String in DESTINATIONS:
		var portal_value: Variant=originals.get(id)
		var approval_value: Variant=doors.get(id)
		_check(portal_value is Dictionary and approval_value is Dictionary,"independent review/source both contain door "+id)
		if not portal_value is Dictionary or not approval_value is Dictionary: continue
		var portal: Dictionary=portal_value
		var approval: Dictionary=approval_value
		var original: String=String(portal.get("source",""))
		var image: String=String(portal.get("doorstep_review_image_path",""))
		var uv: Variant=portal.get("source_doorstep_uv")
		var foot: Variant=portal.get("door_foot_px")
		var compound: Variant=compounds.get(String(portal.get("compound_id","")))
		_check(approval.get("status")=="APPROVED" and approval.get("source")==original and _review_bound(original,portal.get("source_sha256"),catalog) and _review_bound(original,approval.get("source_sha256"),catalog),"review-approved original source PNG exact current SHA "+id)
		_check(_review_pair(uv) and _review_pair(foot) and _point(uv).x>=0 and _point(uv).x<=1 and _point(uv).y>=0 and _point(uv).y<=1 and _point(foot).x>=0 and _point(foot).y>=0 and _point(foot).x<SIZE.x and _point(foot).y<SIZE.y and approval.get("compound_id")==portal.get("compound_id") and approval.get("source_doorstep_uv")==uv and approval.get("door_foot_px")==foot,"review exact compound/source UV/actual projected foot, never source XZ "+id)
		# Frozen V7 exporter constructs compound UV through native Vector2, while
		# portal UV retains measured Double. Reconstruct only from bound ORIGINAL
		# footprint, never from either saved UV or an approval fallback.
		var landmark: Variant=(footprints.get("landmarks",{}) as Dictionary).get(id) if footprints.get("landmarks") is Dictionary else null
		var measured_uv: Variant=landmark.get("source_doorstep_uv") if landmark is Dictionary else null
		var expected_compound_uv: Variant=null
		if _review_pair(measured_uv):
			var native_uv:=Vector2(float(measured_uv[0]),float(measured_uv[1]))
			expected_compound_uv=JSON.parse_string(JSON.stringify([native_uv.x,native_uv.y],"\t"))
		_check(compound is Dictionary and compound.get("source")==original and landmark is Dictionary and landmark.get("source")==original and landmark.get("compound_id")==portal.get("compound_id") and _review_bound(original,landmark.get("source_sha256"),catalog) and _review_pair(measured_uv) and _review_pair(compound.get("foot_uv")) and _release_review_exact_value(compound.get("foot_uv"),expected_compound_uv) and compound.get("world_foot_px")==foot,"review door belongs to current actual rendered compound "+id)
		_check(approval.get("doorstep_review_image_path")==image and _review_bound(image,portal.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,approval.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,assets.get(image),catalog),"explicit root reviewed exact actual doorway capture PNG "+id)
		_review_negative_probes(portal,approval,catalog,footprints,id)
	if source.has("player_spawn_px"):
		var explicit: Variant=source.get("player_spawn_px")
		_check(_review_pair(explicit),"invalid existing authored spawn rejected without review fallback")
		if _review_pair(explicit): reviewed_default_spawn=_point(explicit)
	else:
		var declaration: Variant=review.get("default_spawn")
		var linxi: Variant=originals.get("linxi_village")
		var valid: bool=declaration is Dictionary and linxi is Dictionary and typeof(declaration.get("approved"))==TYPE_BOOL and declaration.get("approved")==true and declaration.get("policy")=="EXACT_REVIEWED_LINXI_DOOR_V1" and declaration.get("portal_id")=="linxi_village" and _review_pair(declaration.get("foot_px")) and declaration.get("foot_px")==linxi.get("door_foot_px")
		_check(valid,"default absence-only policy selects root-reviewed actual projected Linxi door")
		if valid: reviewed_default_spawn=_point(declaration.foot_px)
	_check(reviewed_default_spawn.is_finite() and reviewed_default_spawn.x>=0 and reviewed_default_spawn.y>=0 and reviewed_default_spawn.x<SIZE.x and reviewed_default_spawn.y<SIZE.y,"independently selected default spawn in logical world domain")
	visual_review_evidence={"path":REVIEW_PATH,"sha256":FileAccess.get_sha256(REVIEW_PATH) if FileAccess.file_exists(REVIEW_PATH) else "","source_sha256":review.get("source_sha256"),"manifest_sha256":review.get("manifest_sha256"),"whole_capture_report_sha256":review.get("whole_capture_report_sha256"),"doors":doors.duplicate(true),"default_spawn_px":[reviewed_default_spawn.x,reviewed_default_spawn.y] if reviewed_default_spawn.is_finite() else [],"scope":"VISUAL_REVIEW_BINDING_NOT_FIELD_INPUT_APPROVAL","binding_valid":failures==start_failures}
	if failures==start_failures: reviewed_doors=doors.duplicate(true)
	_check(_write_json("independent_visual_review_binding.json",visual_review_evidence),"independent review binding evidence checked write/readback")

func _portal_runtime_phase() -> void:
	var preflight_failures: int = failures
	if not bool(oracle.get("valid")): return
	# Preflight ALL selected measurements before any Field load. A pending/null
	# doorstep can never be silently replaced by a sprite bbox or old stone.
	var selected: Array[String] = []
	for id: String in DESTINATIONS:
		if requested_portal.is_empty() or requested_portal == id: selected.append(id)
	var doors: Dictionary = {}
	for id: String in selected:
		var measured: Dictionary = _source_door(id)
		if measured.is_empty(): continue
		var published: Dictionary = portals_by_id.get(id, {})
		var polygon: Variant = published.get("interaction_polygon_px")
		_check(polygon is PackedVector2Array and polygon.size() >= 3, "published doorway uses an independent reviewed pixel polygon: " + id)
		var foot := _point(measured.door_foot_px)
		_check(_point(published.get("pos")) * SIZE == foot, "runtime door is exactly measured projected doorstep, not source XZ: " + id)
		_check(polygon is PackedVector2Array and Geometry2D.is_point_in_polygon(foot, polygon), "actual measured foot lies inside its doorway polygon: " + id)
		_check(bool(oracle.call("clear", foot)), "measured doorway has independent full17 clearance: " + id)
		doors[id] = measured
	if failures != preflight_failures or doors.size() != selected.size(): return
	_ensure_runtime_fixture()
	var modes: Array = ["space", "door_mouse", "arrow"] if requested_mode == "all" else [requested_mode]
	for id: String in selected:
		for mode: String in modes:
			await _portal_roundtrip(id, mode, doors[id])
	var passed := 0
	for record: Dictionary in actual_portal_roundtrips:
		if bool(record.get("passed", false)): passed += 1
	_check(passed == selected.size() * modes.size(), "every requested real mode completes destination AND actual paired return")
	_check(_write_json("portal_roundtrips.json", {"scope": "LIMITED_REAL_PORTAL_INPUT_NOT_FULL_WORLD" if requested_phase != "full" else "FULL_PORTAL_CATEGORY", "door_modes": modes, "selected_ids": selected, "records": actual_portal_roundtrips, "source_sha256": FileAccess.get_sha256(SOURCE_PATH)}), "actual roundtrip input evidence persists with source SHA")
	if passed == 48 and requested_portal.is_empty() and requested_mode == "all": completed_phases.append("all16_space_door_mouse_arrow_actual_returns")


## Author/source association only. The source has already passed exact E pins;
## each original PNG and runtime texture must still bind the actual catalog.
func _release_landmark_binding(portal_id: String) -> Dictionary:
	if world == null or world.map_layout == null or not DESTINATIONS.has(portal_id): return {}
	var authored_portals: Array[Dictionary] = []
	var runtime_portals: Array[Dictionary] = []
	for entry: Dictionary in source.get("portals",[]):
		if typeof(entry.get("id")) == TYPE_STRING and entry.get("id") == portal_id: authored_portals.append(entry)
	for entry: Dictionary in world.map_layout.portals:
		if typeof(entry.get("id")) == TYPE_STRING and entry.get("id") == portal_id: runtime_portals.append(entry)
	if authored_portals.size() != 1 or runtime_portals.size() != 1: return {}
	var authored: Dictionary = authored_portals[0]
	var runtime: Dictionary = runtime_portals[0]
	var compound: Variant = authored.get("compound_id")
	if typeof(compound) != TYPE_STRING or String(compound).is_empty() or typeof(runtime.get("compound_id")) != TYPE_STRING or runtime.get("compound_id") != compound: return {}
	if typeof(authored.get("source")) != TYPE_STRING or String(authored.source).is_empty() or typeof(runtime.get("source")) != TYPE_STRING or runtime.get("source") != authored.source: return {}
	var authored_objects: Array[Dictionary] = []
	var runtime_objects: Array[Dictionary] = []
	for entry: Dictionary in source.get("objects",[]):
		if typeof(entry.get("id")) == TYPE_STRING and entry.get("id") == compound: authored_objects.append(entry)
	for entry: Dictionary in world.map_layout.visual_objects:
		if typeof(entry.get("id")) == TYPE_STRING and entry.get("id") == compound: runtime_objects.append(entry)
	if authored_objects.size() != 1 or runtime_objects.size() != 1: return {}
	var original: Dictionary = authored_objects[0]
	var object: Dictionary = runtime_objects[0]
	for key: String in ["id","source","source_sha256","texture","role"]:
		if typeof(original.get(key)) != TYPE_STRING or typeof(object.get(key)) != TYPE_STRING or String(original[key]).is_empty() or object[key] != original[key]: return {}
	if original.role != "independent_generated_compound" or original.source != authored.source: return {}
	# Match the publisher's actual Array -> native Vector2 consumer, not Double
	# JSON text against Float32 resource coordinates, and never epsilon/saved-round.
	if not _review_pair(original.get("pos")) or not object.get("pos") is Vector2: return {}
	var native_position: Vector2 = Vector2(float(original.pos[0]),float(original.pos[1]))
	if not native_position.is_finite() or object.pos != native_position: return {}
	var catalog: Dictionary = manifest.get("asset_sha256",{})
	# These sixteen authored compound PNGs are exact-byte runtime copies. The
	# unchanged source UV therefore addresses the same image, never a proxy/remap.
	if not _review_bound(original.source,original.source_sha256,catalog) or not _review_bound(original.texture,original.source_sha256,catalog): return {}
	return {"portal":runtime,"authored_portal":authored,"object":object,"authored_object":original}

func _actual_landmark_sprite(portal_id: String) -> Sprite2D:
	var binding: Dictionary = _release_landmark_binding(portal_id)
	if binding.is_empty() or not is_instance_valid(field): return null
	var object: Dictionary = binding.object
	var nodes: Variant = field.get("_scene_object_nodes")
	var screen_size: Variant = field.get("_screen_size")
	if not nodes is Array or not screen_size is Vector2 or screen_size != SIZE: return null
	var matches: Array[Sprite2D] = []
	for node: Variant in nodes:
		if node is Sprite2D and is_instance_valid(node) and String(node.name) == "SceneObject_"+String(object.id):
			matches.append(node)
	if matches.size() != 1: return null
	var prop: Sprite2D = matches[0]
	if prop.texture == null or prop.texture.resource_path != object.texture: return null
	# Exact same scalar multiplication as Field._norm_to_screen; no screen-pixel
	# tolerance and no proxy marker. Root/roof tests consume this actual Sprite.
	var expected_position: Vector2 = Vector2(object.pos.x*screen_size.x,object.pos.y*screen_size.y)
	if not prop.position.is_finite() or prop.position != expected_position: return null
	return prop

func _static_portals_and_spacing() -> void:
	var portals: Array = world.map_layout.portals
	_check(portals.size() == 16, "exact sixteen existing target entrances preserved")
	for portal: Dictionary in portals:
		var id: String = portal.get("id", "")
		_check(DESTINATIONS.has(id) and not portals_by_id.has(id), "unique unchanged portal ID: " + id)
		_check(String(portal.get("target_scene", "")) == String(DESTINATIONS.get(id, "INVALID")), "actual unchanged destination: " + id)
		var point := _point(portal.get("pos")) * SIZE
		_check(point.is_finite() and point.x >= 0 and point.y >= 0 and point.x < SIZE.x and point.y < SIZE.y, "finite in-domain portal foot: " + id)
		if oracle.get("valid"): _check(oracle.call("clear", point), "independent complete17 portal landing is clear: %s %s" % [id, oracle.call("foot_evidence", point)])
		portals_by_id[id] = portal
	var landmarks: Dictionary = {}
	# Published author contract: portal.compound_id -> unique visual_object.id.
	# No guessed compound_<portal> ID or obsolete visual_object.portal_id fallback.
	for portal: Dictionary in portals:
		var id: String = portal.get("id", "")
		var binding: Dictionary = _release_landmark_binding(id)
		_check(not binding.is_empty() and not landmarks.has(id), "unique actual central landmark, not arbitrary portal marker: " + id)
		if not binding.is_empty() and not landmarks.has(id): landmarks[id] = binding.object
	for first in CORE_IDS.size():
		var id: String = CORE_IDS[first]
		_check(landmarks.has(id), "core city/sect owns a real runtime landmark: " + id)
		if not landmarks.has(id): continue
		var a := _point(landmarks[id].get("pos")) * SIZE
		for second in range(first + 1, CORE_IDS.size()):
			var other: String = CORE_IDS[second]
			if not landmarks.has(other): continue
			var b := _point(landmarks[other].get("pos")) * SIZE
			_check(a.distance_to(b) >= 3072, "core actual landmark logical spacing >=3072 (not screen pixels): %s/%s actual=%.6f" % [id, other, a.distance_to(b)])
			var first_door: Vector2=_point((portals_by_id.get(id,{}) as Dictionary).get("pos"))*SIZE
			var second_door: Vector2=_point((portals_by_id.get(other,{}) as Dictionary).get("pos"))*SIZE
			_check(first_door.is_finite() and second_door.is_finite() and first_door.distance_to(second_door)>=3072,"all36 actual core DOOR pairs also satisfy3072 independently of compound center: "+id+"/"+other)
	completed_phases.append("static_16_targets_and_9_core_logical_spacing")







