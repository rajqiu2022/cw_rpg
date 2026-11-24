extends SceneTree
const NEW_ROOMS = preload("res://scripts/city/luoyang_functional_interiors_20261016.gd")
const CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const RESIDENT = preload("res://scripts/city/luoyang_resident_field_20261016.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var ok:=true
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd","res://scripts/field/field_walkable_controller.gd"]:
		var source:=load(path) as Script
		var eligible: bool=source!=null and source.can_instantiate()
		print(JSON.stringify({"source":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":eligible}))
		ok=ok and eligible
	quit(0 if ok else 1)
