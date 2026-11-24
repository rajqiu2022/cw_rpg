extends SceneTree
## Run only by ROOT. --check-only verifies helper/C syntax; the normal --script
## invocation also verifies project autoload context and controller reloads.
const RESIDENT = preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	var ok:=true
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd","res://scripts/field/field_walkable_controller.gd"]:
		var script:=load(path) as GDScript
		if script==null or not script.can_instantiate(): ok=false
	print("RESIDENT_SOURCE_CHECK ","PASS" if ok else "FAIL")
	quit(0 if ok else 1)
