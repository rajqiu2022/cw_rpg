extends SceneTree
## Root only. Load final new scripts/resources once; do not instantiate fields.
const PATHS := [
	"res://build/bianzhou_city_20261028_system01/city_author.gd",
	"res://build/bianzhou_city_20261028_system01/router_entry.gd",
	"res://build/bianzhou_city_20261028_system01/bianzhou_field.gd",
	"res://build/bianzhou_city_20261028_system01/bianzhou_field.tscn",
	"res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
]
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var failed: bool=false
	for path: String in PATHS:
		var resource: Resource=load(path)
		var good: bool=resource!=null and (not resource is GDScript or (resource as GDScript).can_instantiate())
		print(JSON.stringify({"path":path,"sha256":FileAccess.get_sha256(path),"loaded":good}))
		failed=failed or not good
	print(JSON.stringify({"scope":"BIANZHOU_FOUR_NEW_RESOURCES_AND_QA_SCRIPT_ONLY","passed":not failed,"fields_instantiated":0,"save_writes":0}))
	quit(1 if failed else 0)
