extends SceneTree
## Root-only independent layout/source preflight. No Field instance, no new
## import, no old geometry job, and no claim of visual/Physics admission.
const BUILD="res://build/luoyang_city_full_rollout_20261022ap_system01/"
const AUTHOR=BUILD+"environment_author.json"
const HELPER=BUILD+"environment_layer.gd"
const IDS=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
var error: String=""
var first: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func need(value: bool,label: String) -> bool:
	if not value and error.is_empty(): error=label;push_error(label)
	return value
func track(path: String,expected: String="") -> bool:
	var sha: String=FileAccess.get_sha256(path)
	if not need(sha.length()==64 and (expected.is_empty() or sha==expected) and (not first.has(path) or first[path]==sha),"EXACT_SOURCE:"+path): return false
	first[path]=sha;return true
func number(value: Variant) -> bool: return (value is int or value is float) and is_finite(float(value))
func work() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty(),"NO_UNDECLARED_ARGS"): return {}
	if not track(AUTHOR) or not track(HELPER) or not track(get_script().resource_path): return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not need(raw is Dictionary and raw.get("status")=="ROOT_BOUND_AP_EIGHT_FIELD_ENVIRONMENT" and raw.get("no_collision_navigation_or_interaction_delta")==true and raw.get("scenes",{}).size()==8 and raw.get("assets",{}).size()==4,"BOUND_EIGHT_FIELD_AUTHOR"): return {}
	for path: String in raw.source_sha256:
		if not track(path,raw.source_sha256[path]): return {}
	var textures: Array=[]
	for key: String in raw.assets:
		var asset: Dictionary=raw.assets[key]
		var image: Image=Image.load_from_file(asset.texture)
		if not need(image!=null and Vector2(image.get_size())==Vector2(asset.source_size[0],asset.source_size[1]),"SOURCE_SIZE:"+key): return {}
		var cfg:=ConfigFile.new()
		if not need(cfg.load(asset.texture+".import")==OK,"EXISTING_IMPORT:"+key): return {}
		var compiled: Variant=cfg.get_value("remap","path",null)
		if not need(compiled is String and compiled.ends_with(".ctex") and raw.source_sha256.has(compiled) and raw.source_sha256.has(asset.texture+".import"),"EXACT_CTEX_CLOSURE:"+key): return {}
		textures.append({"key":key,"texture":asset.texture,"source_size":image.get_size(),"existing_import_and_compiled_leaf_exact":true})
	var fields: Array=[]
	for id: String in IDS:
		if not need(raw.scenes.has(id),"SCENE_CLOSED_DOMAIN:"+id): return {}
		var rows: Array=raw.scenes[id].ground;var seen: Dictionary={};var area_sum: float=0
		for row: Variant in rows:
			if not need(row is Dictionary and row.keys().size()==4 and row.has("id") and row.has("asset") and row.has("rect") and row.has("uniform_scale") and raw.assets.has(row.asset) and not seen.has(row.id),"EXACT_VISUAL_ONLY_ROW:"+id): return {}
			if not need(row.rect is Array and row.rect.size()==4 and number(row.uniform_scale) and float(row.uniform_scale)>0,"RECT_AND_UNIFORM_SCALE:"+id): return {}
			for scalar: Variant in row.rect:
				if not need(number(scalar),"FINITE_RECT:"+id): return {}
			var area:=Rect2(row.rect[0],row.rect[1],row.rect[2],row.rect[3])
			if not need(area.has_area() and Rect2(0,0,3072,2048).encloses(area),"WORLD_RECT:"+id): return {}
			seen[row.id]=true;area_sum+=area.get_area()
		if not need(not rows.is_empty(),"VISIBLE_FIELD_DELTA_REQUIRED:"+id): return {}
		fields.append({"scene_id":id,"rows":rows.duplicate(true),"count":rows.size(),"covered_area_sum":area_sum,"parent_native_NAV_NPC_portals_untouched":true})
	return {"textures":textures,"fields":fields,"native_tiles_not_program_colors":true,"supported_field_count":8,"no_new_collision_support_ghost_or_interaction":true,"formal_owner_install_executed":false,"Field_or_renderer_run":false}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var result: Dictionary=work();var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path);need(final[path]==first[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<=30000,"FIXED_30S_LAYOUT_PREFLIGHT")
	result.merge({"passed":error.is_empty() and result.get("supported_field_count")==8,"error":error,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":30000,"source_first":first,"source_final":final,"scope":"AP_EIGHT_FIELD_LAYOUT_AND_EXISTING_MEDIA_PREFLIGHT_NOT_FIELD_ART_OR_PHYSICS"},true)
	var path: String=BUILD+"environment_preflight/"+str(OS.get_process_id())+"/result.json"
	var writable: bool=not FileAccess.file_exists(path) and DirAccess.make_dir_recursive_absolute(path.get_base_dir())==OK
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE) if writable else null
	if file!=null: file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	print(JSON.stringify({"path":path,"passed":file!=null and result.passed,"error":error}))
	quit(0 if file!=null and result.passed else 1)
