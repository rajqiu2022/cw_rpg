extends SceneTree
## Root-only module manifest successor; all ten compiled bins stay identical.
const HOME:="res://build/luoyang_hall_boundary_20261029p_system01/"
const MANIFEST:="res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const EXPECTED:="f7bcd35c9f0c1d5c2d5fcd77b8d979810771fa088f510626c9fc1fea0bf85661"
const FIELD:="res://build/luoyang_regions_20261027d_source01/region_field.gd"
var output: String
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(test: bool,label: String) -> bool:
	checks+=1
	if not test:failures.append(label);push_error(label)
	return test
func write_json(path: String,data: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data,"  ")+"\n");file.close()
func binding(path: String) -> Dictionary:
	return {"path":path,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size()}
func finish() -> void:
	write_json(output+"result.json",{"passed":false,"checks":checks,"failures":failures,"production_writes":0});quit(1)
func run() -> void:
	output=HOME+"output/"+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(output)
	if not check(FileAccess.get_sha256(MANIFEST)==EXPECTED,"CURRENT29O_MANIFEST"):finish();return
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var before: Dictionary=manifest.duplicate(true)
	if not check(FileAccess.get_sha256(FIELD)==manifest.runtime_modules[FIELD],"CURRENT_REGION_FIELD_MODULE"):finish();return
	var candidate_path: String=HOME+"region_field_READY.gd"
	var candidate: GDScript=load(candidate_path) as GDScript
	if not check(candidate!=null and candidate.can_instantiate(),"NEW_FIELD_AND_HELPER_PARSE"):finish();return
	manifest.runtime_modules[FIELD]=FileAccess.get_sha256(candidate_path)
	for path: String in [HOME+"hall_boundary.gd",HOME+"room_patch.gdshader"]:
		if not check(FileAccess.file_exists(path),"NEW_LOCAL_MODULE_PRESENT:"+path):finish();return
		manifest.runtime_modules[path]=FileAccess.get_sha256(path)
	var rollback: Dictionary=manifest.duplicate(true);rollback.runtime_modules=before.runtime_modules
	if not check(var_to_bytes(rollback)==var_to_bytes(before),"ALL_TEN_BINDINGS_AND_ALL_OTHER_MANIFEST_FIELDS_IDENTICAL"):finish();return
	var material: Dictionary=manifest.compiled_bindings.estate27d_living_hall
	if not check(material.sha256=="29ed8da76c40359e8815d0a0ef672112d8490d29509598202771278a9775b1c4","ORIGINAL_ROOM_BIN_KEPT"):finish();return
	write_json(output+"region_runtime_manifest_READY.json",manifest)
	var result: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"manifest":binding(output+"region_runtime_manifest_READY.json"),"all_ten_compiled_bindings_identical":true,"only_RegionField_and_two_exact_room_module_pins":true,"production_writes":0}
	write_json(output+"result.json",result);print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
