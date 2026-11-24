extends "res://tests/helpers/joint_v15_wall_street_world_parent_parsefix_phase.gd"
## NEW city-root adapter; parent copies A902 with only the owner_tree identifier fix.
const FROZEN_WORLD_PATH: String = "res://tests/helpers/joint_v15_wall_street_world_parent_parsefix_phase.gd"
const FROZEN_WORLD_SHA: String = "3ac990ad2073fe516837cd512e01024f6837b5e79953a4c9fefc27d1307f52d1"
const WALL_STREET_ORDINARY_RAW := preload("res://tests/helpers/joint_v15_wall_street_ordinary_raw_oracle.gd")

func _configure_ordinary(definition: SceneScript) -> bool:
	var frozen_world_matches: bool = FileAccess.get_sha256(FROZEN_WORLD_PATH).to_lower()==FROZEN_WORLD_SHA
	_check(frozen_world_matches,"exact new A902 parent copy with owner_tree identifier fix; all world input and negative predicates inherited")
	if not frozen_world_matches: return false
	ordinary_images.clear()
	ordinary_blockers.clear()
	if ordinary_raw != null:
		_check(bool(ordinary_raw.call("verify_sources")),"actual target raw PNG bytes frozen through normal input/return")
		ordinary_raw.call("release")
	ordinary_raw = null
	var layout: Resource = definition.map_layout
	_check(layout != null,"actual target source layout is present")
	if layout == null: return false
	ordinary_size = Vector2(layout.get("design_size"))
	ordinary_native_city = String(definition.scene_id) in CITY_IDS and layout.get("schema_version")==3
	ordinary_raw = WALL_STREET_ORDINARY_RAW.new()
	var sampling: String = "round_world_pixel" if ordinary_native_city else "normalized_image_round"
	var configured: bool = ordinary_raw.call("configure_city",definition,"--luoyang-v3-candidate" in OS.get_cmdline_user_args()) if ordinary_native_city else ordinary_raw.call("configure",layout,sampling,-1.0)
	_check(configured,"independent actual target original PNG or explicitly legacy polygon navigation: "+str(ordinary_raw.get("errors")))
	if ordinary_native_city:
		_check(ordinary_size == Vector2(3072,2048),"new city ordinary full-body context, not world-circle inheritance")
	return configured


