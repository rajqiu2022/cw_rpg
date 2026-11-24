extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## One immutable author / three conjuncts, no geometry or production mutation.
const AUTHOR_PATH="res://data/maps/luoyang_assembled_interiors_20261016g/cloth_shop_author.json"
const AUTHOR_SHA="b65a25c64dc917217cb0383d1d5f3692cc4820d28dc4754dac9bcfd69de3c6d2"
func _number(value: Variant) -> Dictionary:
	var bytes:=PackedByteArray();bytes.resize(8);bytes.encode_double(0,float(value))
	return {"typeof":typeof(value),"decimal20":"%.20f"%float(value),"float64_le_hex":bytes.hex_encode()}
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+10000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=track(AUTHOR_PATH,AUTHOR_SHA) and track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path))
	if complete:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
		var model: Dictionary=data.geometry.actor_clearance_model
		var expected: Array=[-90,-171,180,181]
		var literal: float=1.18
		var rows: Array=[]
		for i: int in expected.size(): rows.append({"actual":_number(model.envelope_world_px[i]),"expected":_number(expected[i]),"scalar_equal":model.envelope_world_px[i]==expected[i]})
		var actual_scale: Variant=model.room_player_visual_scale
		var witness: Variant=JSON.parse_string("1.18")
		records.append({"kind":"EXACT_THREE_CONJUNCTS","env_equal":model.envelope_world_px==expected,"env_type":typeof(model.envelope_world_px),"env_expected_type":typeof(expected),"env_elements":rows,"coordinate_value":model.coordinate_domain,"coordinate_type":typeof(model.coordinate_domain),"coordinate_equal":model.coordinate_domain=="actual_world_pixels","actual_scale":_number(actual_scale),"literal_scale":_number(literal),"scale_equal":actual_scale==literal,"standalone_json_1_18":_number(witness),"actual_equal_standalone_json":actual_scale==witness,"no_epsilon_or_geometry_change":true})
	finish("res://build/luoyang_eleven_envelope_diagnostic_20261016g/%d_%d"%[OS.get_process_id(),began],began,complete,"SINGLE_AUTHOR_NATIVE_JSON_SCALAR_DOMAIN_ONLY")
