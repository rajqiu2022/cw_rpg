extends SceneTree
## Root-only one-quad additive publication. No current source/bin/media writes.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const HOME:="res://build/luoyang_threshold_20261029o_system01/"
const MANIFEST:="res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const OLD_SHA:="6ba977ae05994d9e3210ac1756a96a2b95c172c1abc033cad8fb9aa0c7ee2d61"
const ESTATE:="luoyang_estate_region_27d"
const OLD_ESTATE_SHA:="07d64efe26073bc666d04916d2539c7e3b63ed2d5526068f413f823f527a4e22"
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
	if not check(FileAccess.get_sha256(MANIFEST)==OLD_SHA,"FORMAL29N_MANIFEST"):finish();return
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var previous_bindings: Dictionary=manifest.compiled_bindings.duplicate(true)
	var old_binding: Dictionary=manifest.compiled_bindings[ESTATE]
	if not check(old_binding.sha256==OLD_ESTATE_SHA and FileAccess.get_sha256(old_binding.path)==OLD_ESTATE_SHA,"ORIGINAL_ESTATE_BIN_SOURCE"):finish();return
	var estate: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(old_binding.path))
	var before: Dictionary=estate.duplicate(true)
	var rows: Array=estate.render.filter(func(row: Dictionary)->bool:return row.get("owner_id")=="estate_ak_main_hall")
	var doors: Array=estate.portals.filter(func(row: Dictionary)->bool:return row.get("id")=="estate27d_hall_door")
	if not check(rows.size()==1 and rows[0].texture=="res://art/modules/luoyang_estate_components_20261021am/main_hall.png" and doors.size()==1,"EXACT_SCREENSHOT_HALL_AND_SINGLE_DOOR"):finish();return
	if not check(doors[0].foot==Vector2(1536,1984) and doors[0].size_px==Vector2(144,32) and doors[0].return_foot==Vector2(1536,2060),"ORIGINAL_PORTAL_AND_RETURN_CONTRACT"):finish();return
	if not check(estate.solids[6][1]==Vector2(1472.2962646484375,1881.688720703125) and estate.solids[7][0]==Vector2(1599.25830078125,1881.688720703125),"EXACT_ORIGINAL_JAMB_ENDPOINTS"):finish();return
	var spec_path: String=HOME+"repair_definition_READY.json"
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	var polygon:=PackedVector2Array()
	for p: Variant in spec.new_threshold_polygon_px:polygon.append(Core.vec(p))
	Core._append_solid(estate,polygon)
	estate.sources[spec_path]=FileAccess.get_sha256(spec_path)
	estate.sources[old_binding.path]=OLD_ESTATE_SHA
	estate["threshold29o"]={"spec":spec_path,"source_sha256":FileAccess.get_sha256(spec_path)}
	var rollback: Dictionary=estate.duplicate(true)
	rollback.solids=before.solids;rollback.solid_cells=before.solid_cells;rollback.sources=before.sources
	rollback.erase("threshold29o")
	if not check(var_to_bytes(rollback)==var_to_bytes(before),"ALL_OTHER_TYPED_ESTATE_FIELDS_IDENTICAL"):finish();return
	check(estate.solids.size()==before.solids.size()+1,"EXACTLY_ONE_ADDITIVE_QUAD")
	check(Core.safe_body(estate,Vector2(1536,1984),Vector2(17,12)),"ORIGINAL_INTERACTION_FOOT_STILL_FULL_BODY_SAFE")
	check(Core.safe_segment(estate,Vector2(1536,2060),Vector2(1536,1984),Vector2(17,12)),"RETURN_TO_INTERACTION_APRON_STILL_CLEAR")
	check(not Core.safe_body(estate,Vector2(1536,1960),Vector2(17,12)),"CENTER_WALK_THROUGH_REJECTED")
	check(not Core.safe_segment(estate,Vector2(1536,1984),Vector2(1536,1850),Vector2(17,12)),"NORTHWARD_PASSAGE_CLOSED")
	check(Core.safe_body(estate,Vector2(1536,3760),Vector2(17,12))==Core.safe_body(before,Vector2(1536,3760),Vector2(17,12)),"SEPARATE_OUTER_GATE_UNCHANGED")
	if not failures.is_empty():finish();return
	var bin_path: String=output+ESTATE+".bin"
	var file:=FileAccess.open(bin_path,FileAccess.WRITE);file.store_buffer(var_to_bytes(estate));file.close()
	check(var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(bin_path)))==var_to_bytes(estate),"NEW_ESTATE_TYPED_ROUNDTRIP")
	manifest.compiled_bindings[ESTATE]=binding(bin_path)
	for id: String in previous_bindings:
		if id!=ESTATE:check(var_to_bytes(manifest.compiled_bindings[id])==var_to_bytes(previous_bindings[id]),"OTHER_NINE_BINDINGS_IDENTICAL:"+id)
	manifest["threshold29o"]=binding(spec_path)
	manifest.runtime_modules["res://build/luoyang_regions_20261027d_source01/region_entry.gd"]=FileAccess.get_sha256(HOME+"region_entry_READY.gd")
	manifest.runtime_modules[HOME+"threshold_restore.gd"]=FileAccess.get_sha256(HOME+"threshold_restore.gd")
	write_json(output+"region_runtime_manifest_READY.json",manifest)
	var result: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"manifest":binding(output+"region_runtime_manifest_READY.json"),"estate":manifest.compiled_bindings[ESTATE],"only_one_solid_plus_cells_and_source_pin":true,"all_original_portals_render_NPCs_and_other_nine_bins_inherited":true,"production_writes":0}
	write_json(output+"result.json",result);print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
