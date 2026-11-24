extends "res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd"
## The inherited opaque prove_actual is untouched. This separate actual-Field
## API binds author/source alpha and the live display state independently.
const NPC_BINDING = preload("res://tests/helpers/luoyang_enclosure_v11_toast_native_npc_band_probe_20261012.gd")
const CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const FIELD_SHA := "e545834700715e23540a5036ffaeb01e2ba412b62e14f81c5abd7b28a08ee1ed"
var display_receipts: Array[Dictionary] = []

static func _finite_color(value: Variant) -> bool:
	return typeof(value)==TYPE_COLOR and is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)

## Called by the actual reader below, as well as owned direct fixtures. A mere
## alpha in [.55,1] is insufficient: same live WeakRef, native base/display Color
## bytes and the independently read public/internal state must agree exactly.
static func display_record_error(record: Variant, sprite: Variant, public_row: Variant) -> String:
	if not record is Dictionary or not public_row is Dictionary or not sprite is Sprite2D or not is_instance_valid(sprite): return "DISPLAY_TYPES"
	for key: String in ["id","sprite","base_color","factor","target","hit","eligible"]:
		if not record.has(key): return "RECORD_MISSING:"+key
	if typeof(record.id)!=TYPE_STRING or record.id not in IDS: return "RECORD_ID"
	if not record.sprite is WeakRef or record.sprite.get_ref()!=sprite: return "RECORD_WEAKREF"
	if not _finite_color(record.base_color) or var_to_bytes(record.base_color)!=var_to_bytes(Color.WHITE): return "AUTHOR_BASE_COLOR"
	for key: String in ["factor","target"]:
		if typeof(record[key])!=TYPE_FLOAT or not is_finite(record[key]): return "RECORD_NUMBER:"+key
	for key: String in ["hit","eligible"]:
		if typeof(record[key])!=TYPE_BOOL: return "RECORD_BOOL:"+key
	if record.factor<.55 or record.factor>1.: return "FACTOR_DOMAIN"
	if record.target!=(.55 if record.hit else 1.): return "TARGET_SOURCE_RULE"
	if record.hit and not record.eligible: return "INELIGIBLE_HIT"
	if not record.eligible and record.factor!=1.: return "INELIGIBLE_NOT_RESTORED"
	for key: String in ["id","base_color","factor","target","hit","eligible","display_color"]:
		if not public_row.has(key): return "PUBLIC_MISSING:"+key
	for key: String in ["id","base_color","factor","target","hit","eligible"]:
		if typeof(public_row[key])!=typeof(record[key]) or var_to_bytes(public_row[key])!=var_to_bytes(record[key]): return "PUBLIC_INTERNAL:"+key
	if not _finite_color(sprite.modulate) or var_to_bytes(sprite.modulate)!=var_to_bytes(Color.WHITE): return "AUTHOR_MODULATE"
	var expected: Color=record.base_color
	expected.a*=record.factor
	if not _finite_color(sprite.self_modulate) or var_to_bytes(sprite.self_modulate)!=var_to_bytes(expected): return "NATIVE_DISPLAY_COLOR"
	if not _finite_color(public_row.display_color) or var_to_bytes(public_row.display_color)!=var_to_bytes(sprite.self_modulate): return "PUBLIC_DISPLAY_COLOR"
	return ""

static func current_frame_signature_error(signature: Variant, expected: Array) -> String:
	if expected.size()!=13 or not signature is Array or signature.size()<expected.size(): return "CURRENT_FRAME_SIGNATURE_MISSING"
	for index: int in expected.size():
		if typeof(signature[index])!=typeof(expected[index]) or var_to_bytes(signature[index])!=var_to_bytes(expected[index]): return "CURRENT_FRAME_SIGNATURE:"+str(index)
	return ""

static func _native_snapshot_error(runtime: RefCounted, player: Player, sprite: Sprite2D) -> String:
	if runtime.get("_native_snapshot_valid")!=true: return "NATIVE_SNAPSHOT_INVALID"
	var snapshots: Variant=runtime.get("_native_snapshot")
	if not snapshots is Dictionary or not snapshots.has(player.get_instance_id()) or not snapshots.has(sprite.get_instance_id()): return "NATIVE_SNAPSHOT_MISSING"
	for node: Node2D in [player,sprite]:
		var snap: Variant=snapshots[node.get_instance_id()]
		if not snap is Dictionary or snap.get("node")!=node or not snap.get("key") is Dictionary: return "NATIVE_SNAPSHOT_NODE"
		var entries: Array[Dictionary]=[]
		for entry: Dictionary in runtime.get("_depth_entries"):
			if entry.get("node")==node: entries.append(entry)
		if entries.size()!=1: return "NATIVE_ENTRY_UNIQUE"
		var key: Dictionary=snap.key
		if typeof(snap.get("raw_foot_y"))!=TYPE_FLOAT or not is_finite(snap.raw_foot_y) or typeof(key.get("foot_y"))!=TYPE_FLOAT or typeof(key.get("kind_rank"))!=TYPE_INT or typeof(key.get("stable_ordinal"))!=TYPE_INT or key.stable_ordinal<0: return "NATIVE_KEY_TYPES"
		var native: float=PackedFloat32Array([snap.raw_foot_y]).to_byte_array().decode_float(0)
		if not is_finite(native) or key.foot_y!=native or key.kind_rank!=(1 if node==player else 0): return "NATIVE_KEY_VALUE"
		if entries[0].get("ordinal")!=key.stable_ordinal: return "NATIVE_ORDINAL"
		var expected_raw: float=player.get_depth_sort_y() if node==player else node.to_global(entries[0].foot_local).y
		if var_to_bytes(snap.raw_foot_y)!=var_to_bytes(expected_raw): return "NATIVE_RAW_FOOT"
		if typeof(snap.get("band"))!=TYPE_INT or snap.band!=clampi(floori(native/8.),0,255) or node.z_index!=snap.band or typeof(snap.get("sibling_index"))!=TYPE_INT or snap.sibling_index!=node.get_index(): return "NATIVE_LIVE_ORDER"
	var actor: Sprite2D=player.sprite
	if actor==null or actor.texture==null: return "CURRENT_ACTOR"
	var signature: Variant=runtime.get("_signature")
	var snap: Dictionary=snapshots[player.get_instance_id()]
	var expected: Array=[actor.texture.get_instance_id(),actor.frame,actor.hframes,actor.vframes,actor.region_rect,actor.region_enabled,actor.global_transform,actor.flip_h,actor.flip_v,runtime.call("effective_z",actor),snap.key,snap.sibling_index,runtime.get("_order_revision")]
	var signature_error: String=current_frame_signature_error(signature,expected)
	if not signature_error.is_empty(): return signature_error
	var current_raw: float=player.get_depth_sort_y()
	if var_to_bytes(snap.raw_foot_y)!=var_to_bytes(current_raw): return "CURRENT_ACTOR_FOOT"
	return ""

func display_binding(field: Variant,id: String,sprite: Sprite2D,actor: Sprite2D) -> Dictionary:
	var result: Dictionary={"complete":false,"id":id,"error":"FIELD_UNBOUND","proof_kind":"FROZEN_AUTHOR_SOURCE_PLUS_BOUND_CURRENT_RUNTIME_NATIVE_DISPLAY"}
	if not field is Control or not is_instance_valid(field) or not field.is_inside_tree() or field.is_queued_for_deletion() or field.get_tree().current_scene!=field: return result
	var script: GDScript=field.get_script() as GDScript
	if script==null or script.resource_path!=FIELD_PATH or FileAccess.get_sha256(FIELD_PATH)!=FIELD_SHA or script.source_code!=FileAccess.get_file_as_string(FIELD_PATH): result.error="FIELD_SOURCE"; return result
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if definition==null or definition.scene_id!=&"ch4_s1_luoyang_yamen" or not definition.has_meta("city_enclosure_manifest_sha") or not CITY.is_v3(definition) or definition.get_meta("city_enclosure_manifest_sha")!=CITY.manifest_sha(definition.scene_id): result.error="ENCLOSURE_SOURCE"; return result
	var runtime: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	var player: Player=field.get("_player") as Player
	if runtime==null or player==null or player.sprite!=actor or not player.is_inside_tree() or not is_instance_valid(sprite) or sprite.get_parent()!=player.get_parent() or field.get("_scene_rebuilding")==true: result.error="CURRENT_NODES"; return result
	var sources_now: Dictionary={}
	for path: String in NPC_BINDING.NATIVE_NPC_PINS: sources_now[path]=FileAccess.get_sha256(path)
	var runtime_script: Script=runtime.get_script() as Script
	var base: Script=runtime_script.get_base_script() if runtime_script!=null else null
	var native: Script=base.get_base_script() if base!=null else null
	var script_error: String=NPC_BINDING.runtime_identity_error(runtime_script,base,native,sources_now)
	if not script_error.is_empty(): result.error=script_error; return result
	if runtime.get("_world")!=field.get("world_container") or runtime.get("_fade_scene")!="ch4_s1_luoyang_yamen" or runtime.get("_runtime_bound")!=true or not runtime.get("_fade_player") is WeakRef or runtime.get("_fade_player").get_ref()!=player: result.error="RUNTIME_WORLD_PLAYER"; return result
	if typeof(runtime.get("_fade_opacity"))!=TYPE_FLOAT or runtime.get("_fade_opacity")!=.55 or typeof(runtime.get("_fade_seconds"))!=TYPE_FLOAT or runtime.get("_fade_seconds")!=.18: result.error="RUNTIME_CONFIGURATION"; return result
	var matching: Array[Dictionary]=[]
	var all_records: Variant=runtime.get("_fade_records")
	if not all_records is Array: result.error="FADE_RECORDS_TYPE"; return result
	for record: Variant in all_records:
		if not record is Dictionary: result.error="FADE_RECORD_TYPE"; return result
		if record.get("id")==id or (record.get("sprite") is WeakRef and record.sprite.get_ref()==sprite): matching.append(record)
	if matching.size()!=1 or matching[0].get("id")!=id: result.error="UNIQUE_FADE_RECORD"; return result
	var prop_matches:=0
	for row: Dictionary in runtime.get("_props"):
		if row.get("sprite")==sprite and row.get("id")==id: prop_matches+=1
	if prop_matches!=1: result.error="REGISTERED_PROP"; return result
	var state: Dictionary=runtime.call("get_fade_runtime_state")
	if state.get("runtime_hooked")!=true or state.get("preview_only")!=false or state.get("scene_id")!="ch4_s1_luoyang_yamen" or state.get("status")!="READY_ENCLOSURE_RUNTIME" or typeof(state.get("opacity"))!=TYPE_FLOAT or state.opacity!=.55 or typeof(state.get("seconds"))!=TYPE_FLOAT or state.seconds!=.18: result.error="PUBLIC_RUNTIME"; return result
	var public_matches: Array[Dictionary]=[]
	for row: Dictionary in state.get("buildings",[]):
		if row.get("id")==id: public_matches.append(row)
	if public_matches.size()!=1: result.error="PUBLIC_RECORD_UNIQUE"; return result
	var error: String=display_record_error(matching[0],sprite,public_matches[0])
	if not error.is_empty(): result.error=error; return result
	error=_native_snapshot_error(runtime,player,sprite)
	if not error.is_empty(): result.error=error; return result
	# Six frozen authors contain no colour override. Field creates a fresh Sprite
	# with WHITE self colour, applies only the optional author modulate field, then
	# add_prop captures that self colour. A mutated author never gains fade credit.
	if not records.has(id) or records[id].has("modulate") or records[id].has("self_modulate"): result.error="AUTHOR_COLOUR_SCHEMA"; return result
	var authored_matches:=0
	for row: Dictionary in definition.map_layout.visual_objects:
		if row.get("id")==id:
			if row.has("modulate") or row.has("self_modulate") or row.get("texture")!=records[id].texture: result.error="CURRENT_AUTHOR_COLOUR"; return result
			authored_matches+=1
	if authored_matches!=1: result.error="CURRENT_AUTHOR_UNIQUE"; return result
	result.merge({"complete":true,"error":"","field_instance_id":field.get_instance_id(),"prop_instance_id":sprite.get_instance_id(),"player_instance_id":player.get_instance_id(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"base_color_bytes":var_to_bytes(matching[0].base_color).hex_encode(),"display_color_bytes":var_to_bytes(sprite.self_modulate).hex_encode(),"modulate_bytes":var_to_bytes(sprite.modulate).hex_encode(),"factor":matching[0].factor,"target":matching[0].target,"hit":matching[0].hit,"eligible":matching[0].eligible,"source_pins":sources_now,"runtime_script":runtime_script.resource_path,"direct_base":base.resource_path,"native_base":native.resource_path,"alpha_interval_alone_is_NOT_proof":true},true)
	return result

func prove_actual_display(id: String,prop: Sprite2D,actor: Sprite2D,actor_depth_foot: float,prop_depth_foot: float,visual_scale: float,ground_anchored: bool,field: Control) -> Dictionary:
	var display: Dictionary=display_binding(field,id,prop,actor)
	display_receipts.append(display)
	if display.get("complete")!=true: return {}
	if id not in IDS or not records.has(id) or prop==null or prop.texture==null or not unchanged(): return {}
	var row: Dictionary=records[id]
	if prop.texture.resource_path!=row.texture or not prop.centered or prop.offset!=Vector2.ZERO or prop.region_enabled or prop.hframes!=1 or prop.vframes!=1 or prop.frame!=0 or prop.rotation!=0. or prop.scale!=Vector2.ONE or prop.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR or prop.modulate.a!=1. or display.get("complete")!=true: return {}
	var render: Vector2=_point(row.render_size_px); var foot: Vector2=_point(row.world_foot_px); var uv: Vector2=_point(row.foot_uv)
	var center: Vector2=(foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048)
	if not center.is_finite() or prop.position!=center*Vector2(3072,2048): return {}
	var container: Node2D=prop.get_parent() as Node2D
	if container==null or actor==null or actor.get_parent()==null or actor.get_parent().get_parent()!=container or container.global_transform.x!=Vector2.RIGHT or container.global_transform.y!=Vector2.DOWN or not container.global_transform.origin.is_finite() or prop_depth_foot!=container.to_global(foot).y: return {}
	var texture: Texture2D=_import(row.texture)
	var original: Image=_rgba(Image.load_from_file(row.texture))
	var imported: Image=_rgba(prop.texture.get_image())
	var independent_import: Image=_rgba(texture.get_image()) if texture!=null else null
	if original==null or original.get_size()!=Vector2i(render) or not rgba_pair_exact(original,imported) or not rgba_pair_exact(original,independent_import): return {}
	var bound: Dictionary=actor_bound(actor,actor_depth_foot,visual_scale,ground_anchored)
	if bound.is_empty(): return {}
	var result: Dictionary=support_gap(imported,prop.get_rect(),prop.global_transform,prop.flip_h,prop.flip_v,bound.minimum_relative_y,prop_depth_foot)
	if result.is_empty(): return {}
	result.merge({"id":id,"source_png":row.texture,"source_sha256":sources[row.texture].sha256,"source_import_all_RGBA_exact":true,"actor":bound,"strict_six_roof_identity":true,"source_unchanged":unchanged(),"actual_Field_credit":false,"author_source_display_separated":true,"current_display_binding":display})
	return result if result.source_unchanged else {}
