extends "res://tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd"
## Only the original run_objects final eight-tick NPC observer changes domain.
## All original 79-object/875+17/Physics/Y/alpha/input checks remain mechanical.
## Non-enclosure scenes retain the original raw scalar band observation.
const NATIVE_NPC_CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const NATIVE_NPC_PINS := {
	"res://tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd":"6c19ac175b452419eb2a2790c3106d823ae8641122dd35a3fbb4f93c2c47301d",
	"res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd":"40b42c901ef05ac1971ccaae9ba049b60cfe439baea8778f796f978c4bd54450",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/field/field_walkable_controller.gd":"8c7d4cad1838e31c2693bf5711095fccba6d895a5f258f9fd967b807ece30a1c",
	"res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd":"b0c4dbedb0e8f48668a7d191049c5fbd9ae7b2866ea389e1ac2797ae3a0f9e7f",
	"res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd":"bb5d12158c01aad7bc6e36f53e0bf103af016e195ba690b97a04f6669f8c7bca",
	"res://scripts/field/npc_node.gd":"9da0e3d61185c45568071f40a4f2de4f1f1287a105fd66f4c5a9e162c3af3b72"
}


## Actual observer calls this typed core with actual Script/base resources and
## freshly read source SHAs. Units mutate owned fields, never production/cache.
static func runtime_identity_error(runtime_script: Variant, direct_base: Variant, native_base: Variant, source_sha256: Variant) -> String:
	if not source_sha256 is Dictionary or source_sha256.size()!=NATIVE_NPC_PINS.size(): return "SOURCE_TABLE"
	for key: Variant in source_sha256:
		if typeof(key)!=TYPE_STRING or not NATIVE_NPC_PINS.has(key): return "SOURCE_KEY"
	for path: String in NATIVE_NPC_PINS:
		var actual: Variant=source_sha256.get(path)
		if typeof(actual)!=TYPE_STRING or actual.to_lower()!=NATIVE_NPC_PINS[path]: return "SOURCE_SHA:"+path
	var paths: Array[String]=["res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd","res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd","res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd"]
	var scripts: Array=[runtime_script,direct_base,native_base]
	for script: Variant in scripts:
		if not script is GDScript: return "SCRIPT_TYPE"
	for index in paths.size():
		var script: Variant=scripts[index]
		var path: String=paths[index]
		if not script is GDScript: return "SCRIPT_TYPE:"+path
		if typeof(script.resource_path)!=TYPE_STRING or script.resource_path!=path: return "SCRIPT_PATH:"+path
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=NATIVE_NPC_PINS[path]: return "SCRIPT_DISK_SHA:"+path
		if script.source_code!=FileAccess.get_file_as_string(path): return "SCRIPT_CODE:"+path
		if index<2 and script.get_base_script()!=scripts[index+1]: return "SCRIPT_BASE:"+path
	return ""

func _enclosure_npc_band(npc: NPCNode) -> Dictionary:
	var receipt: Dictionary={"complete":false,"id":String(npc.npc_id),"ticks_usec":Time.get_ticks_usec(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"scope":"SAME_COMPLETED_ACTOR_STAGE_INDEPENDENT_PACKED_FLOAT32_NPC_BAND"}
	for path: String in NATIVE_NPC_PINS:
		if FileAccess.get_sha256(path).to_lower()!=NATIVE_NPC_PINS[path]: return receipt
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if definition==null or not definition.has_meta("city_enclosure_manifest_sha") or not NATIVE_NPC_CITY.is_v3(definition) or definition.get_meta("city_enclosure_manifest_sha")!=NATIVE_NPC_CITY.manifest_sha(definition.scene_id): return receipt
	if owner.current_scene!=field or not field.is_inside_tree() or field.is_queued_for_deletion() or not npc.is_inside_tree() or npc.is_queued_for_deletion() or npc.get_parent()!=field.get("_actor_layer"): return receipt
	var nodes: Array=field.get("_npc_nodes")
	if nodes.count(npc)!=1: return receipt
	var script: Script=npc.get_script() as Script
	var native_helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	if script==null or script.resource_path!="res://scripts/field/npc_node.gd" or native_helper==null or native_helper.get("_native_snapshot_valid")!=true: return receipt
	var current_sources: Dictionary={}
	for path: String in NATIVE_NPC_PINS: current_sources[path]=FileAccess.get_sha256(path)
	var runtime_script: Script=native_helper.get_script() as Script
	var direct_base: Script=runtime_script.get_base_script() if runtime_script!=null else null
	var native_base: Script=direct_base.get_base_script() if direct_base!=null else null
	if not runtime_identity_error(runtime_script,direct_base,native_base,current_sources).is_empty(): return receipt
	var sprite: Sprite2D=npc.sprite
	if sprite==null or sprite.texture==null or not sprite.is_inside_tree() or sprite.frame<0 or sprite.frame>=sprite.hframes*sprite.vframes: return receipt
	var texture_path: String=sprite.texture.resource_path
	if not texture_path.begins_with("res://") or not FileAccess.file_exists(texture_path): return receipt
	# Read actual getter once; never use the production codec to form expected.
	var raw: float=npc.get_depth_sort_y()
	var float32_bytes: PackedByteArray=PackedFloat32Array([raw]).to_byte_array()
	var native: float=float32_bytes.decode_float(0)
	receipt["foot"]=raw; receipt["band"]=npc.z_index; receipt["frame"]=sprite.frame
	receipt["raw_float64_hex"]=PackedFloat64Array([raw]).to_byte_array().hex_encode()
	receipt["native_float32_hex"]=float32_bytes.hex_encode()
	if not is_finite(raw) or not is_finite(native): return receipt
	if native==0.0: native=0.0
	var expected_band: int=clampi(floori(native/8.0),0,255)
	var entries: Array=[]
	for entry: Dictionary in native_helper.get("_depth_entries"):
		if entry.get("node")==npc: entries.append(entry)
	if entries.size()!=1: return receipt
	var states: Array=native_helper.call("get_depth_order_state")
	var matched: Array=[]
	for state: Dictionary in states:
		if state.get("id")==entries[0].get("id"): matched.append(state)
	if matched.size()!=1: return receipt
	var entry: Dictionary=entries[0]
	var state: Dictionary=matched[0]
	receipt["scene_id"]=String(definition.scene_id)
	receipt["field_instance_id"]=field.get_instance_id(); receipt["npc_instance_id"]=npc.get_instance_id(); receipt["npc_path"]=str(npc.get_path())
	receipt["sprite"]=_sprite_observation(sprite)
	receipt["texture_source_sha256"]=FileAccess.get_sha256(texture_path)
	receipt["source_script"]={"path":script.resource_path,"sha256":FileAccess.get_sha256(script.resource_path)}
	receipt["local_position"]=_scalar_evidence(npc.position); receipt["global_transform"]=_scalar_evidence(npc.global_transform)
	receipt["sprite_position"]=_scalar_evidence(sprite.position); receipt["sprite_scale"]=_scalar_evidence(sprite.scale)
	receipt["visual_foot_offset"]=raw-npc.global_position.y
	receipt["expected_native_foot"]=native; receipt["expected_native_band"]=expected_band
	receipt["legacy_raw_band"]=clampi(floori(raw/8.0),0,255)
	receipt["helper_state"]=state.duplicate(true); receipt["helper_state_native_hex"]=var_to_bytes(state).hex_encode()
	receipt["helper_raw_float64_hex"]=PackedFloat64Array([float(state.get("raw_foot_y",INF))]).to_byte_array().hex_encode()
	var exact: bool=typeof(state.get("raw_foot_y"))==TYPE_FLOAT and receipt.helper_raw_float64_hex==receipt.raw_float64_hex and typeof(state.get("foot_y"))==TYPE_FLOAT and state.foot_y==native and state.get("actor")==true and typeof(state.get("kind_rank"))==TYPE_INT and state.kind_rank==1 and typeof(state.get("stable_ordinal"))==TYPE_INT and state.stable_ordinal>=0 and state.stable_ordinal==entry.get("ordinal")
	exact=exact and typeof(state.get("band"))==TYPE_INT and state.band==expected_band and npc.z_index==expected_band and entry.get("band")==expected_band and entry.get("foot_y")==native and entry.get("actor")==true
	exact=exact and typeof(state.get("sibling_index"))==TYPE_INT and state.sibling_index==npc.get_index()
	receipt["complete"]=exact
	receipt["same_stage_no_refresh_or_input_mutation"]=true
	receipt["uses_production_codec_as_expected"]=false
	return receipt

func run_objects() -> void:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(shape != null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size == BODY and shape.position == Vector2.ZERO, "ordinary actor keeps real enabled centered 34x24 Rectangle, never travel circle")
	_check(absf(actor.scale.y - .945 * .91) < .000001 and absf(float(player.call("get_depth_sort_y")) - player.global_position.y) < .01, "normal adult .91 visual scale and grounded foot; no tiny-world identity")
	var source: Image = alpha.image_for(actor)
	var current: Rect2i = alpha.frame(actor, source)
	var top := current.size.y
	var bottom := -1
	for y in current.size.y:
		for x in current.size.x:
			if source.get_pixelv(current.position + Vector2i(x, y)).a > .12:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	# 113.5134 is DOWN reference, not a blanket current-facing height.
	var facing := ""
	for direction: String in IDLE_REFERENCES:
		var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_%s_25d_4f.png" % direction
		if actor.texture.resource_path == path: facing = direction
	_check(not facing.is_empty() and String(player.get("_direction")) == facing, "actual idle texture/facing identity matches one precise independently measured adult source")
	if not facing.is_empty():
		var expected: Dictionary = IDLE_REFERENCES[facing]
		_check(FileAccess.get_sha256(actor.texture.resource_path).to_lower() == String(expected.sha256), "actual facing original PNG exact SHA, not mutable self-reference")
		_check(bottom >= top and bottom - top + 1 == int(expected.height), "current idle-frame alpha height equals its exact facing reference (DOWN132/UP131/LR130), never widened tolerance")
		_check(absf((bottom - top + 1) * actor.scale.y - float(expected.height) * .945 * .91) < .0001, "actual current-frame effective alpha height uses actual Sprite scale and precise facing reference")
		_check(absf(float(manifest.ordinary_actor_effective_height_px) - 132 * .945 * .91) < .000001, "manifest adult height is explicitly DOWN132 reference, not all facing equality")
		data["adult_current_frame_height"] = {"facing": facing, "frame": actor.frame, "path": actor.texture.resource_path, "sha256": FileAccess.get_sha256(actor.texture.resource_path), "source_alpha_height_px": bottom - top + 1, "source_reference_height_px": expected.height, "actual_scale": actor.scale.y, "effective_height_px": (bottom - top + 1) * actor.scale.y, "down_reference_px": manifest.ordinary_actor_effective_height_px}
	_runtime_collision_inventory()
	for object: Dictionary in manifest.objects:
		var id: String = String(object.id)
		var sprite: Sprite2D = prop(id)
		_check(sprite != null and sprite.texture.resource_path == String(object.texture), "independent runtime PNG binding: " + id)
		if sprite == null: continue
		_check((sprite.get_rect().size * sprite.scale.abs()).distance_to(point(object.render_size_px)) < .01 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual rendered dimensions/filter: " + id)
		_check(_physical_binding(id), "actual StaticBody geometry exactly matches original world solids: " + id)
		var collision: Dictionary = await _collision_trial(id) if blocking_ids.has(id) else {"blocking": false, "actual_static_body_absent": _physical_binding(id), "scope": "nonblocking; no fictional solid stop"}
		var alpha_record: Dictionary
		if object.get("role","")=="ground_overlay":
			var global_alpha_depth: int = alpha.effective_z(sprite)
			_check(not blocking_ids.has(id) and sprite.z_index==-2 and object.get("ghost_occlusion")==false,"ground-only mud overlay is neither solid nor occluding foreground: "+id)
			alpha_record={"scope":"GROUND_OVERLAY_NEGATIVE_NOT_STRONG_FOREGROUND_CREDIT","effective_z":global_alpha_depth,"ghost_occlusion":false}
		elif object.get("role","")=="water_decoration":
			alpha_record=await _water_decoration_domain_trial(object)
		else: alpha_record=await _alpha_trial(object)
		var record: Dictionary = {"id": id, "blocking": blocking_ids.has(id), "collision": collision, "alpha": alpha_record}
		data.objects.append(record)
	_check(data.objects.size() == object_ids.size(), "every current city declared visual entity tested independently, no old ten-object count or first-success early exit")
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var rows: Array = []
		for tick in 8:
			await driver.completed_actor_stage()
			var definition: SceneScript=field.get("_current_scene") as SceneScript
			if definition!=null and definition.has_meta("city_enclosure_manifest_sha"):
				var observed: Dictionary=_enclosure_npc_band(npc as NPCNode)
				_check(observed.get("complete")==true, "normally spawned original enclosure NPC independent native foot band and same-stage identity: " + String(npc.npc_id))
				rows.append(observed)
			else:
				var foot: float = npc.get_depth_sort_y()
				_check(npc.z_index == clampi(floori(foot / 8), 0, 255), "normally spawned original NPC ordinary foot band: " + String(npc.npc_id))
				rows.append({"foot": foot, "band": npc.z_index, "frame": npc.sprite.frame})
		data.npcs.append({"id": npc.npc_id, "rows": rows})
	_check(data.npcs.size() == (field.get("_npc_nodes") as Array).size(), "all normally spawned current gate-visible NPCs observed; other gated identities tested in normal action phase")
