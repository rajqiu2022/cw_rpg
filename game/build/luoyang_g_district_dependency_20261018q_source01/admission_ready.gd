extends SceneTree
## ROOT-only light admission draft. Never run room geometry or Field/GPU here.
## Requires explicit READY revision and actual atomic source deployment first.
const KEY_READY=true
const LIMIT_MS=60000
const MODULE="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const MODULE_SHA="d82232b96035f365652831238bad490e79dc973b75d3550c79d6ab6b2070b979"
const REGISTRY="res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json"
const REGISTRY_SHA="959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5"
const PRIOR="res://data/maps/luoyang_assembled_interiors_20261016g/registry_candidate_three_doors_v2.json"
const PRIOR_SHA="725551952029cfabc92d5d875484a2b09e37fa64a451c3410351036cfa13d144"
const DISTRICT="res://scripts/city/luoyang_district_life_20261016f.gd"
const DISTRICT_SHA="6921fa796c419202fc9707559addabdb013ea0b37ec51e6303e9f4923a79fc17"
var checks: int=0
var failures: Array=[]
func _initialize() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not KEY_READY: print("G District dependency admission NOTREADY; no source/runtime acceptance"); quit(1); return
	call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func _facts() -> Dictionary:
	var out: Dictionary={}
	for path: String in [MODULE,REGISTRY,PRIOR,DISTRICT]: out[path]=FileAccess.get_sha256(path)
	return out
func _run() -> void:
	var started: int=Time.get_ticks_msec(); var before: Dictionary=_facts()
	_check(before[MODULE]==MODULE_SHA and before[REGISTRY]==REGISTRY_SHA and before[PRIOR]==PRIOR_SHA and before[DISTRICT]==DISTRICT_SHA,"exact_atomic_deployment_source")
	if failures.is_empty():
		var module: Variant=load(MODULE)
		var current: Variant=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
		var prior: Variant=JSON.parse_string(FileAccess.get_file_as_string(PRIOR))
		_check(current is Dictionary and prior is Dictionary,"registry_data_types")
		if current is Dictionary and prior is Dictionary:
			var history: Dictionary=module.dependency_history(current,prior)
			_check(not history.is_empty() and JSON.stringify(history,"",true,true)==JSON.stringify(prior,"",true,true),"all_fields_exact_inverse_only11pins")
			var live: Dictionary=module.catalogue()
			_check(live.get("rooms",{}).size()==11,"actual_catalogue_admits11")
			_check(module.source_paths().has(PRIOR),"prior_registry_in_actual_source_closure")
			var count: int=0
			for id: String in current.rooms:
				var row: Dictionary=current.rooms[id]
				if row.get("reuse_existing_accepted")==true: continue
				_check(row.source_sha256.get(DISTRICT)==DISTRICT_SHA,"current_room_District_pin:"+id)
				_check(module.room_path(StringName(id))==row.scene_path,"actual_room_path_full_source_hashes:"+id)
				count+=1
			_check(count==10,"exact10newrows_not_smith")
			# Memory-only clones; never edit a source file to exercise a negative.
			var bad: Dictionary=current.duplicate(true)
			bad.source_sha256[DISTRICT]="0".repeat(64)
			_check(module.dependency_history(bad,prior).is_empty(),"wrong_approved_source_sha_rejected")
			bad=current.duplicate(true); bad.source_sha256["res://unapproved_fifth_path.gd"]=DISTRICT_SHA
			_check(module.dependency_history(bad,prior).is_empty(),"extra_source_path_rejected")
			bad=current.duplicate(true); bad["unapproved_registry_field"]=true
			_check(module.dependency_history(bad,prior).is_empty(),"unapproved_field_rejected")
			bad=current.duplicate(true); bad.district_spacing_dependency_revision.old_sha256="0".repeat(64)
			_check(module.dependency_history(bad,prior).is_empty(),"wrong_historical_old_sha_rejected")
			bad=current.duplicate(true)
			for id: String in bad.rooms:
				if bad.rooms[id].get("reuse_existing_accepted")==true: continue
				bad.rooms[id].scene_path="res://unapproved_room.tres"; break
			_check(module.dependency_history(bad,prior).is_empty(),"room_mapping_change_rejected")
	var after: Dictionary=_facts()
	_check(JSON.stringify(before,"",true,true)==JSON.stringify(after,"",true,true),"same_actual_four_sources_first_final")
	_check(Time.get_ticks_msec()-started<LIMIT_MS,"original60s_budget")
	var result: Dictionary={"complete":true,"checks":checks,"failures":failures,"source_before":before,"source_after":after,"elapsed_ms":Time.get_ticks_msec()-started,"scope":"LIGHT_SOURCE_ADMISSION_ONLY_NOT2140_GEOMETRY_NOT_GPU_NOT_FIELD","no_source_writes":true}
	var path: String="res://build/luoyang_g_district_dependency_20261018q_source01/admission_"+str(OS.get_process_id())+".json"
	if FileAccess.file_exists(path): quit(1); return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(result,"\t",true,true)); file.close()
	print(JSON.stringify({"checks":checks,"failures":failures,"path":path})); quit(0 if failures.is_empty() else 1)
