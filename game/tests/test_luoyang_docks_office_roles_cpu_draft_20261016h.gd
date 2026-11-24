extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Schema-only fail-closed draft; ROOT alone may compile/run the future final.
const KEY_READY=false
const HELPER_PATH="PENDING_SYSTEM_OFFICE_ROLES_HELPER_PATH"
const HELPER_SHA="PENDING_SYSTEM_FINAL_HELPER_SHA"
const CONTRACT_PATH="PENDING_SYSTEM_FINAL_CONTRACT_PATH"
const CONTRACT_SHA="PENDING_SYSTEM_FINAL_CONTRACT_SHA"
const TARGET_IDS=["harbour_life_docks_loading_attendant","harbour_life_docks_booking_attendant"]
const TARGET_FEET=[[2000,1430],[2010,1900]]
const PROPOSED_CPU_LIMIT_MS=30000
const SCHEMA={
	"textures":{"new_count":3,"raw_actors_retained":2,"actor_runtime_cells_px":[160,160],"actor_derivation":"ONE_NATIVE_LANCZOS_FROM_ORIGINAL_RAW_NO_THRESHOLD_OR_CROP","full_rgba_pairs":"rawOffice-import-directCTEX; derived160-import-directCTEX; rawActor-singleLanczos-derived160","mips":0,"lossless_params":23},
	"crowd":{"only_sprite_path_changed_ids":TARGET_IDS,"original_docks_other_rows":8,"original_gate_rows":10,"movement_mode":"idle","sprite_scale":1.0,"native_body_px":[22.4,28.8],"visible_height_px":140,"ground_anchored":true,"alpha_foot_world_abs_limit_px":12,"new_dialog_or_action":false},
	"office":{"exact_id":"PENDING_SYSTEM_BUILDING_ID","render_only_delta":true,"parent_objects":28,"other_objects":27,"original_solid_foot_depth_and_doors_unchanged":true,"new_transformed_ground_base_must_be_inside_union_of_original_solids":true,"original_NAV_and_record_unchanged":true},
	"scope":{"whole_world_or_city_prepare":false,"old_harbour_282_replayed":false,"rooms11_or_imports28_replayed":false,"Field_GPU_Physics_claimed":false}
}
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+PROPOSED_CPU_LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var ready: bool=check(KEY_READY,"Wait for actual3 assets, exact source/import proof and narrow helper schema freeze")
	records.append({"kind":"PROPOSED_SCHEMA_NOT_IMPLEMENTED_ACCEPTANCE","schema":SCHEMA,"assets_or_hook_pass_claimed":false})
	finish("res://build/luoyang_docks_office_roles_cpu_20261016h/draft_%d_%d"%[OS.get_process_id(),began],began,ready,"DRAFT_NOT_READY_NOT_ASSET_OR_RUNTIME_PASS")
