extends "res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd"
## NEW binding-only sibling. Parent gameplay, natural grace, dialog, return,
## BGM, RAW875/full17, and cleanup predicates are inherited without alteration.
const FINE_GRACE_ORIGIN_PATH: String="res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd"
const FINE_GRACE_ORIGIN_SHA: String="fdf51d2e5ab0ac3f35aa72214bc565e4c1addccb17fc19eb576695c0d0588bf8"
const FINE_ALPHA_PATH: String="res://tests/helpers/joint_v15_wall_v4_fine_alpha_probe.gd"
const FINE_ALPHA_SHA: String="8e0ca712f6e69ddeef3b6a7cc2e6f7d86363a181481f3d393f9d6ed01b04e413"
const FINE_ALPHA := preload("res://tests/helpers/joint_v15_wall_v4_fine_alpha_probe.gd")

func _bind_field(id: String) -> bool:
	var origins_exact: bool=FileAccess.get_sha256(FINE_GRACE_ORIGIN_PATH).to_lower()==FINE_GRACE_ORIGIN_SHA and FileAccess.get_sha256(FINE_ALPHA_PATH).to_lower()==FINE_ALPHA_SHA
	if not _check(origins_exact,"binding-only fine-alpha grace keeps exact frozen parent and new probe"): return false
	_release_field_oracles()
	manifest=JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT+id+"/art_contract.json")) as Dictionary
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	_check(definition!=null and definition.scene_id==StringName(id) and definition.map_layout.schema_version==3,"actual normal Field uses current city3 resources")
	_check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd","normal production Field, no lab/dry-action subclass")
	raw=RAW.new()
	if not _check(bool(raw.call("configure_city",definition,candidate)),"independent current-city raw875/full17 source oracle"): return false
	probe=FINE_ALPHA.new()
	return _check(bool(probe.call("configure",tree,field,manifest,_check,_capture)),"actual physical/current-alpha probe uses frozen current manifest")

