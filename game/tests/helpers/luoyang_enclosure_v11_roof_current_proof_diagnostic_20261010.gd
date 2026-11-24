extends "res://tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd"
## Observations only. Every original proof/result/input/assertion is inherited.
const DIAGNOSTIC_SCOPE := "SIX_ROOF_CURRENT_PROOF_GATES_DIAGNOSTIC_NOT_APPROVAL"
const OBSERVED_SOURCES: Dictionary = {
	"res://tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd":"6c19ac175b452419eb2a2790c3106d823ae8641122dd35a3fbb4f93c2c47301d",
	"res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd":"8a82284236fe033f770fc4ff803106abd04c23c64728d713d157c0e11a66b891",
	"res://scripts/field/field_walkable_controller.gd":"6073da1018dcc1c4fc6a9e8b254b2d0b472c7b434a5bf1751cbe5aea5fe3e6e7",
	"res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd":"b0c4dbedb0e8f48668a7d191049c5fbd9ae7b2866ea389e1ac2797ae3a0f9e7f",
	"res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd":"bb5d12158c01aad7bc6e36f53e0bf103af016e195ba690b97a04f6669f8c7bca",
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419"
}
var receipt_directory := ""
var proof_calls: Dictionary = {}
var proof_receipts: Array[Dictionary] = []

func set_receipt_directory(path: String) -> bool:
	if not receipt_directory.is_empty() or not path.begins_with("res://build/joint_world_luoyang_20261003_qa/six_roof_current_proof_diagnostic_") or not path.ends_with("/") or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): return false
	receipt_directory=path
	return true

func observed_sources_exact() -> bool:
	for path: String in OBSERVED_SOURCES:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=OBSERVED_SOURCES[path]: return false
	return true

func _identity_observation() -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var sprite: Sprite2D=player.get("sprite") as Sprite2D if player!=null else null
	var result: Dictionary={"player_present":player!=null,"sprite_present":sprite!=null,"actual_original_identity":super._current_identity()}
	if player==null: return result
	var script: Script=player.get_script() as Script
	var family: Variant=player.get("_weapon_style"); var moving: Variant=player.get("_is_moving"); var direction: Variant=player.get("_direction")
	var key: Variant=player.get("_applied_visual_key")
	result.merge({"script_present":script!=null,"script_path":script.resource_path if script!=null else "","player_disk_sha256":FileAccess.get_sha256(ROOF_PROOF.PLAYER),"script_path_exact":script!=null and script.resource_path==ROOF_PROOF.PLAYER,"player_sha_exact":FileAccess.get_sha256(ROOF_PROOF.PLAYER)==ROOF_PROOF.PLAYER_SHA,"family":family,"family_type":typeof(family),"moving":moving,"moving_type":typeof(moving),"direction":direction,"direction_type":typeof(direction),"applied_visual_key":key,"applied_visual_key_type":typeof(key),"ground_anchored":player.get("_ground_anchored"),"actual_root":player.position,"actual_global_root":player.global_position,"actual_depth_foot":player.call("get_depth_sort_y")})
	var typed: bool=typeof(family)==TYPE_STRING_NAME and typeof(moving)==TYPE_BOOL and typeof(direction)==TYPE_STRING
	var enums: bool=typed and String(family) in ["sword","dao","staff","palm","hidden"] and direction in ["up","down","left","right"]
	result["typed_fields_exact"]=typed; result["field_enums_exact"]=enums
	if sprite==null: return result
	result.merge({"texture_present":sprite.texture!=null,"texture_path":sprite.texture.resource_path if sprite.texture!=null else "","frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"region_enabled":sprite.region_enabled,"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"actor_position":sprite.position,"actor_scale":sprite.scale,"actor_offset":sprite.offset,"actor_rect":sprite.get_rect(),"actor_transform":sprite.global_transform,"actor_modulate":sprite.modulate,"actor_self_modulate":sprite.self_modulate})
	if enums:
		var state: String="walk" if moving else "idle"
		var frames: int=8 if moving else 4
		var expected: String=ROOF_PROOF.ROOT+String(family)+"/lengguyun_"+String(family)+"_"+state+"_"+direction+"_25d_"+str(frames)+"f.png"
		result.merge({"expected_texture":expected,"expected_visual_key":String(family)+":"+direction+":"+state,"visual_key_exact":typeof(key)==TYPE_STRING and key==String(family)+":"+direction+":"+state,"texture_exact":sprite.texture!=null and sprite.texture.resource_path==expected,"hframes_exact":sprite.hframes==frames,"vframes_exact":sprite.vframes==1,"frame_in_range":sprite.frame>=0 and sprite.frame<frames})
	return result

func _live_observation(object: Dictionary) -> Dictionary:
	var sprite: Sprite2D=prop(String(object.id))
	var runtime: Variant=field.get("_v14_modular_overlap")
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var values: Dictionary={"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"identity":_identity_observation(),"roof_ready":roof_ready,"canonical_scene_id":manifest.get("canonical_scene_id"),"definition_present":definition!=null,"definition_feet":definition.actor_positions_are_feet if definition!=null else null,"visual_scale":definition.player_visual_scale if definition!=null else null,"prop_present":sprite!=null,"runtime_present":is_instance_valid(runtime)}
	if sprite!=null:
		values["prop"]={"instance_id":sprite.get_instance_id(),"texture_path":sprite.texture.resource_path if sprite.texture!=null else "","centered":sprite.centered,"offset":sprite.offset,"region_enabled":sprite.region_enabled,"hframes":sprite.hframes,"vframes":sprite.vframes,"frame":sprite.frame,"rotation":sprite.rotation,"scale":sprite.scale,"texture_filter":sprite.texture_filter,"position":sprite.position,"global_transform":sprite.global_transform,"rect":sprite.get_rect(),"flip_h":sprite.flip_h,"flip_v":sprite.flip_v,"modulate":sprite.modulate,"self_modulate":sprite.self_modulate,"modulate_bytes_hex":var_to_bytes(sprite.modulate).hex_encode(),"self_modulate_bytes_hex":var_to_bytes(sprite.self_modulate).hex_encode(),"band":sprite.z_index,"sibling_index":sprite.get_index()}
	if is_instance_valid(runtime):
		var script: Script=runtime.get_script() as Script
		values["runtime_script_path"]=script.resource_path if script!=null else ""
		var chain: Array[Dictionary]=[]
		for depth: int in 3:
			if script==null: break
			var gd_script: GDScript=script as GDScript
			chain.append({"class":script.get_class(),"path":script.resource_path,"disk_sha256":FileAccess.get_sha256(script.resource_path),"source_code_exact":gd_script!=null and gd_script.source_code==FileAccess.get_file_as_string(script.resource_path)})
			script=script.get_base_script()
		values["runtime_actual_script_chain"]=chain
		if runtime.has_method("get_fade_runtime_state"): values["fade_state"]=runtime.call("get_fade_runtime_state")
	values["field_overlap_debug"]=_json_values(field.call("get_v14_modular_overlap_debug"))
	if field.has_method("get_v14_depth_order_debug"): values["field_depth_order_debug"]=field.call("get_v14_depth_order_debug")
	if field.has_method("get_city_building_fade_debug"): values["field_fade_debug"]=field.call("get_city_building_fade_debug")
	return values

func _gate_observation(object: Dictionary) -> Dictionary:
	var gates: Dictionary={}; var values: Dictionary={}
	var id: String=String(object.id)
	var rows: Dictionary=roof_proof.get("records") as Dictionary
	var sprite: Sprite2D=prop(id)
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D if player!=null else null
	var container: Node2D=field.get("world_container") as Node2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	gates["wrapper_ready"]=roof_ready; gates["wrapper_scene"]=String(manifest.get("canonical_scene_id",""))=="ch4_s1_luoyang_yamen"
	gates["wrapper_current_identity"]=not super._current_identity().is_empty()
	gates["wrapper_definition"]=definition!=null
	gates["wrapper_feet"]=definition!=null and definition.actor_positions_are_feet
	gates["wrapper_ground_anchor"]=player!=null and player.get("_ground_anchored")==true
	gates["id_fixed"]=id in ROOF_PROOF.IDS; gates["record_present"]=rows.has(id)
	gates["prop_present"]=sprite!=null; gates["texture_present"]=sprite!=null and sprite.texture!=null
	gates["proof_source_unchanged"]=roof_proof.call("unchanged")
	if sprite==null or sprite.texture==null or not rows.has(id): return {"gates":gates,"values":values,"downstream_unavailable":true}
	var row: Dictionary=rows[id]
	gates.merge({"prop_texture_exact":sprite.texture.resource_path==row.texture,"prop_centered":sprite.centered,"prop_offset_zero":sprite.offset==Vector2.ZERO,"prop_region_disabled":not sprite.region_enabled,"prop_hframes_one":sprite.hframes==1,"prop_vframes_one":sprite.vframes==1,"prop_frame_zero":sprite.frame==0,"prop_rotation_zero":sprite.rotation==0.,"prop_scale_one":sprite.scale==Vector2.ONE,"prop_linear":sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"prop_modulate_alpha_one":sprite.modulate.a==1.,"prop_self_modulate_alpha_one":sprite.self_modulate.a==1.})
	var render: Vector2=roof_proof.call("_point",row.render_size_px)
	var foot: Vector2=roof_proof.call("_point",row.world_foot_px)
	var uv: Vector2=roof_proof.call("_point",row.foot_uv)
	var center: Vector2=(foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048)
	values.merge({"row":row,"render":render,"foot":foot,"foot_uv":uv,"expected_center":center,"expected_position":center*Vector2(3072,2048)})
	gates["center_finite"]=center.is_finite(); gates["position_exact"]=sprite.position==center*Vector2(3072,2048)
	var parent: Node2D=sprite.get_parent() as Node2D
	gates["container_present"]=parent!=null
	gates["actor_parent_chain"]=parent!=null and actor!=null and actor.get_parent()!=null and actor.get_parent().get_parent()==parent
	gates["container_basis_exact"]=parent!=null and parent.global_transform.x==Vector2.RIGHT and parent.global_transform.y==Vector2.DOWN
	gates["container_origin_finite"]=parent!=null and parent.global_transform.origin.is_finite()
	if container==null or player==null or actor==null or definition==null: return {"gates":gates,"values":values,"downstream_unavailable":true}
	var actor_foot: float=float(player.call("get_depth_sort_y"))
	var prop_foot: float=container.to_global(point(object.world_foot_px)).y
	values.merge({"actor_foot":actor_foot,"actor_foot_float64_hex":PackedFloat64Array([actor_foot]).to_byte_array().hex_encode(),"actor_foot_float32_hex":PackedFloat32Array([actor_foot]).to_byte_array().hex_encode(),"prop_foot":prop_foot,"container_transform":container.global_transform})
	gates["prop_foot_exact"]=parent!=null and prop_foot==parent.to_global(foot).y
	# These read-only downstream subcalls do NOT replace the actual early-return
	# result. Their records explicitly have diagnostic-only status.
	var original: Image=roof_proof.call("_rgba",Image.load_from_file(row.texture))
	var imported: Image=roof_proof.call("_rgba",sprite.texture.get_image())
	var separate_texture: Texture2D=ResourceLoader.load(row.texture,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var separate_image: Image=roof_proof.call("_rgba",separate_texture.get_image()) if separate_texture!=null else null
	gates["source_canvas_exact"]=original!=null and original.get_size()==Vector2i(render)
	gates["source_actual_RGBA_exact"]=roof_proof.call("rgba_pair_exact",original,imported)
	gates["source_independent_import_RGBA_exact"]=roof_proof.call("rgba_pair_exact",original,separate_image)
	gates["inventory_40_240_valid"]=roof_proof.call("inventory_valid",roof_proof.get("inventory"))
	var member: Dictionary={}
	for inventory_row: Dictionary in roof_proof.get("inventory"):
		if actor.texture!=null and inventory_row.path==actor.texture.resource_path: member=inventory_row
	gates["actor_inventory_member"]=not member.is_empty()
	if not member.is_empty():
		gates["actor_inventory_hframes_exact"]=actor.hframes==member.hframes
		gates["actor_inventory_vframes_one"]=actor.vframes==1
		gates["actor_inventory_frame_in_range"]=actor.frame>=0 and actor.frame<member.hframes
	var scale_value: float=.945*definition.player_visual_scale
	var actor_parent: Node2D=actor.get_parent() as Node2D
	var actor_transform: Transform2D=actor.global_transform
	gates.merge({"actor_depth_finite":is_finite(actor_foot),"actor_visual_scale_finite_positive":is_finite(definition.player_visual_scale) and definition.player_visual_scale>0.,"actor_scale_product_finite":is_finite(scale_value),"actor_scale_exact":actor.scale==Vector2.ONE*scale_value,"actor_centered":actor.centered,"actor_region_disabled":not actor.region_enabled,"actor_rotation_zero":actor.rotation==0.,"actor_offset_zero":actor.offset==Vector2.ZERO,"actor_position_exact":actor.position==Vector2(0.,-160.*actor.scale.y*.45),"actor_rect_exact":actor.get_rect()==Rect2(-80,-80,160,160),"actor_parent_present":actor_parent!=null,"actor_parent_rotation_zero":actor_parent!=null and actor_parent.rotation==0.,"actor_parent_scale_one":actor_parent!=null and actor_parent.scale==Vector2.ONE,"actor_transform_finite":actor_transform.x.is_finite() and actor_transform.y.is_finite() and actor_transform.origin.is_finite(),"actor_transform_axis_aligned":actor_transform.x.y==0. and actor_transform.y.x==0.})
	if actor_parent!=null and actor.texture!=null:
		var expected_actor_foot: float=actor_parent.global_position.y+actor.position.y+actor.texture.get_height()*actor.scale.y*.45
		values["actor_bound_expected_foot"]=expected_actor_foot
		gates["actor_bound_expected_foot_exact"]=expected_actor_foot==actor_foot
	var corners: Array[Vector2]=[]
	var minimum: float=INF
	for corner: Vector2 in [Vector2(-80,-80),Vector2(80,-80),Vector2(80,80),Vector2(-80,80)]:
		var world: Vector2=actor_transform*corner
		corners.append(world); minimum=minf(minimum,float(world.y)-actor_foot)
	values["actor_full_drawrect_world_corners"]=corners; values["actor_minimum_relative_y"]=minimum
	gates["actor_minimum_finite"]=is_finite(minimum)
	var bound: Dictionary=roof_proof.call("actor_bound",actor,actor_foot,definition.player_visual_scale,true)
	values["actor_bound_actual_core"]=bound; gates["actor_bound_nonempty"]=not bound.is_empty()
	if not bound.is_empty():
		var support: Dictionary=roof_proof.call("support_gap",imported,sprite.get_rect(),sprite.global_transform,sprite.flip_h,sprite.flip_v,bound.minimum_relative_y,prop_foot)
		values["support_gap_actual_core"]=support; gates["support_nonempty"]=not support.is_empty(); gates["support_proved"]=support.get("proved")==true
	values["downstream_subcalls_are_diagnostic_only"]=true
	var rejected: Array[String]=[]
	for key: String in gates:
		if gates[key]!=true: rejected.append(key)
	return {"gates":gates,"values":values,"false_gate_names":rejected,"first_false_gate_in_source_order":rejected[0] if not rejected.is_empty() else "NONE","early_return_not_bypassed":true}

func _json_values(value: Variant) -> Variant:
	if typeof(value)==TYPE_FLOAT and (not is_finite(value) or absf(value)>1e100): return {"type":"float","value_symbol":str(value),"float64_hex":PackedFloat64Array([value]).to_byte_array().hex_encode()}
	if typeof(value)==TYPE_COLOR: return {"type":"Color","rgba":[value.r,value.g,value.b,value.a],"native_bytes_hex":var_to_bytes(value).hex_encode()}
	if typeof(value)==TYPE_ARRAY:
		var rows: Array=[]
		for child: Variant in value: rows.append(_json_values(child))
		return rows
	if typeof(value)==TYPE_DICTIONARY:
		var result: Dictionary={}
		for key: Variant in value: result[String(key)]=_json_values(value[key])
		return result
	return _scalar_evidence(value)

func _save_receipt(name: String,value: Dictionary) -> Dictionary:
	var paths: Dictionary={"json":receipt_directory+name+".json","native":receipt_directory+name+".native"}
	if receipt_directory.is_empty() or FileAccess.file_exists(paths.json) or FileAccess.file_exists(paths.native): return {"saved":false}
	var bytes: PackedByteArray=var_to_bytes(value)
	var native_file:=FileAccess.open(paths.native,FileAccess.WRITE)
	if native_file==null: return {"saved":false}
	native_file.store_buffer(bytes); native_file.flush()
	var native_ok: bool=native_file.get_error()==OK; native_file.close()
	var json_file:=FileAccess.open(paths.json,FileAccess.WRITE)
	if json_file==null: return {"saved":false}
	json_file.store_string(JSON.stringify(_json_values(value),"\t",true)); json_file.flush()
	var json_ok: bool=json_file.get_error()==OK; json_file.close()
	var parser:=JSON.new()
	var parsed: bool=parser.parse(FileAccess.get_file_as_string(paths.json))==OK and parser.data is Dictionary
	return {"saved":native_ok and json_ok and parsed and FileAccess.get_file_as_bytes(paths.native)==bytes,"json_path":paths.json,"json_sha256":FileAccess.get_sha256(paths.json),"native_path":paths.native,"native_sha256":FileAccess.get_sha256(paths.native)}

func _front_proof(object: Dictionary) -> Dictionary:
	var id: String=String(object.id)
	var sequence: int=int(proof_calls.get(id,0)); proof_calls[id]=sequence+1
	var before: Dictionary=_live_observation(object)
	var original_result: Dictionary=super._front_proof(object)
	var after: Dictionary=_live_observation(object)
	var audit: Dictionary=_gate_observation(object)
	var after_audit: Dictionary=_live_observation(object)
	var receipt: Dictionary={"scope":DIAGNOSTIC_SCOPE,"id":id,"call_index":sequence,"expected_call_site":["initial","behind","front"][sequence] if sequence<3 else "UNEXPECTED_EXTRA","before":before,"after_original":after,"after_observation":after_audit,"synchronous_original_state_exact":var_to_bytes(before)==var_to_bytes(after),"synchronous_observation_state_exact":var_to_bytes(after)==var_to_bytes(after_audit),"original_identity_nonempty":not (after.identity.actual_original_identity as Dictionary).is_empty(),"original_front_proof":original_result,"original_front_proof_nonempty":not original_result.is_empty(),"original_front_proof_proved":original_result.get("proved")==true,"gate_observation":audit,"source_pins_exact":observed_sources_exact(),"source_pins":OBSERVED_SOURCES,"original_return_unchanged":true,"diagnostic_only":true,"approval":false}
	var saved: Dictionary=_save_receipt(id+"_proof_"+str(sequence),receipt)
	proof_receipts.append({"id":id,"call_index":sequence,"receipt":saved,"original_identity_nonempty":receipt.original_identity_nonempty,"original_proof_nonempty":receipt.original_front_proof_nonempty,"original_proof_proved":receipt.original_front_proof_proved,"synchronous_original_state_exact":receipt.synchronous_original_state_exact,"synchronous_observation_state_exact":receipt.synchronous_observation_state_exact})
	_check(saved.get("saved")==true,"immediate original proof-gate observation saved without replacing original verdict: "+id+" "+str(sequence))
	return original_result

func diagnostic_summary() -> Dictionary:
	var complete: bool=proof_receipts.size()==18 and proof_calls.size()==6
	for id: String in ROOF_PROOF.IDS:
		complete=complete and proof_calls.get(id)==3
	for row: Dictionary in proof_receipts:
		complete=complete and row.receipt.get("saved")==true and row.synchronous_original_state_exact==true and row.synchronous_observation_state_exact==true
	return {"scope":DIAGNOSTIC_SCOPE,"diagnostic_collection_complete":complete,"proof_calls":proof_calls.duplicate(true),"receipts":proof_receipts.duplicate(true),"expected_six_initial_and_twelve_actual_relation_observations":18,"original_failures_are_NOT_collection_success":true,"NPC_raw_band_loop_inherited_unchanged":true,"approval":false,"formal_approved":false}
