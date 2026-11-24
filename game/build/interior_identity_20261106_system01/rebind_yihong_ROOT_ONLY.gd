extends SceneTree
## Root-only exact PNG/import rebind of 44632's already accepted typed geometry.
## Output remains isolated until the full source closure is reviewed.
const HOME := "res://build/interior_identity_20261106_system01/"
const CORE = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const ALIAS = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")
const CANDIDATE := HOME+"publish_candidate_actual/44632/payload_CANDIDATE.bin"
const CANDIDATE_SHA := "9048c4443a5cd2f8463c1cde7b222303b90f3f03b6cf63b83e7c98fe341eb540"
const MEDIA := "res://build/interior_identity_20261106_art01/yihong_media_formal_install_receipt.json"
const MEDIA_SHA := "78378c1615fed152453e2e98505c0ad24b3f73e0e93b6ce4a382f42f43b3addc"
const QUALITY := "res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json"
const PREFIX := "res://build/interior_identity_20261106_art01/"
const SHELL := "res://art/modules/interior_identity_20261106/yihongyuan_luxury_shell.png"
const CHAR_PREFIX := "res://art/characters/yihongyuan_identity_20261106/"
const LIVE := "res://build/interior_identity_20261107_runtime01/yihongyuan27n_interior.bin"
const OLD_BIN := "res://build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/yihongyuan27n_interior.bin"
const OLD_SHA := "4871b3e428bedd5c0c4c06882d5ebe36cc1660824100adb648027f82dec31d65"
const RUG := "res://art/modules/luoyang_quality_20261101b/salon_rug_v1.png"
const RUG_CTEXT := "res://.godot/imported/salon_rug_v1.png-49ca292cec5fdb4fb79171924da57e39.ctex"
const ROOM := "yihongyuan27n_interior"
const ROLES := ["musician","singer","tea_attendant","receptionist"]
const HALF := Vector2(17,12)
var errors: Array[String] = []
var checks := 0
var output := ""

func _initialize() -> void: call_deferred("run")

func check(value: bool,label: String) -> bool:
	checks += 1
	if not value:
		errors.append(label)
		push_error(label)
	return value

func finish(extra: Dictionary = {}) -> void:
	var report := {"checks":checks,"failures":errors,"production_writes":0,"real_field":false,"real_save_content_access":false}
	report.merge(extra,true)
	var fd := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if fd!=null: fd.store_string(JSON.stringify(report,"  ")+"\n");fd.close()
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)

func key_from_target(absolute: String) -> String:
	var prefix := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")+"/"
	var normalized := absolute.replace("\\","/")
	if not normalized.to_lower().begins_with(prefix.to_lower()): return ""
	return "res://"+normalized.substr(prefix.length())

func _matches_import(path: String,paths: Dictionary) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path+".import")!=OK or cfg.get_value("deps","source_file","")!=path: return false
	var actual: String = cfg.get_value("remap","path","")
	return actual==paths.get("ctex") and cfg.get_value("deps","dest_files",[])==[actual]

func run() -> void:
	output=HOME+"rebind_actual/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(output)
	if not check(FileAccess.get_sha256(CANDIDATE)==CANDIDATE_SHA and FileAccess.get_sha256(OLD_BIN)==OLD_SHA,"TWO_EXACT_PUBLISHED_PREIMAGES"): finish();return
	if not check(FileAccess.get_sha256(MEDIA)==MEDIA_SHA,"ROOT_APPROVED_EXACT_MEDIA_RECEIPT"): finish();return
	var before: Variant = bytes_to_var(FileAccess.get_file_as_bytes(CANDIDATE))
	if not check(before is Dictionary and CORE.plain(before) and before.get("id")==ROOM and before.get("interior_identity_20261106_candidate",{}).get("candidate_only")==true,"TYPED_CANDIDATE_IDENTITY"): finish();return
	var paths_by_role: Dictionary = {}
	var sha_by_path: Dictionary = {}
	var media: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MEDIA))
	if not check(media.targets.size()==15,"EXACT_FIVE_TEXTURE_TRIPLES"):finish();return
	for row: Dictionary in media.targets:
		var path := key_from_target(row.target)
		var role: String = row.role
		var kind: String = row.kind
		if not paths_by_role.has(role): paths_by_role[role]={}
		if not check((role in ROLES or role=="yihongyuan_luxury_shell") and kind in ["png","import","ctex"] and not paths_by_role[role].has(kind) and not sha_by_path.has(path) and String(row.after_sha256).length()==64 and FileAccess.get_sha256(path)==row.after_sha256,"EXACT_MEDIA_LEAF:"+role+":"+kind):finish();return
		paths_by_role[role][kind]=path
		sha_by_path[path]=row.after_sha256
	var path_replace: Dictionary = {PREFIX+"processed/yihongyuan_luxury_shell_native_padded64.png":SHELL}
	for role: String in ROLES: path_replace[PREFIX+"processed/"+role+"_idle_native_candidate.png"]=CHAR_PREFIX+role+"_idle_native.png"
	for role: String in paths_by_role:
		var row: Dictionary = paths_by_role[role]
		var expected := SHELL if role=="yihongyuan_luxury_shell" else CHAR_PREFIX+role+"_idle_native.png"
		if not check(row.get("png")==expected and row.get("import")==expected+".import" and String(row.get("ctex","")).begins_with("res://.godot/imported/"+expected.get_file()+"-") and _matches_import(expected,row),"EXACT_IMPORT_REMAP:"+role):finish();return
	var room: Dictionary = before.duplicate(true)
	for path: String in path_replace:
		if not check(room.sources.get(path)==sha_by_path[path_replace[path]],"SAME_CANDIDATE_AND_RUNTIME_PNG_BYTES:"+path):finish();return
		room.sources.erase(path)
	for path: String in [HOME+"room_layout_candidate.gd",PREFIX+"shell_processing_receipt.json",PREFIX+"women_processing_receipt.json"]:
		if not check(room.sources.erase(path),"EXACT_CANDIDATE_AUTHOR_ONLY_PIN:"+path):finish();return
	room.sources.merge(sha_by_path,false)
	var quality: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(QUALITY))
	for path: String in [RUG,RUG+".import",RUG_CTEXT]:
		var pin: String = quality.source_pins.get(path,"")
		if not check(pin.length()==64 and FileAccess.get_sha256(path)==pin,"INHERITED_RUG_MEDIA_PIN:"+path):finish();return
		room.sources[path]=pin
	room.sources[OLD_BIN]=OLD_SHA
	var changed_render := 0
	for render: Dictionary in room.render:
		if path_replace.has(render.texture):
			render.texture=path_replace[render.texture]
			changed_render+=1
	var changed_actors := 0
	for actor: Dictionary in room.npcs:
		if path_replace.has(actor.data.sprite_path):
			actor.data.sprite_path=path_replace[actor.data.sprite_path]
			changed_actors+=1
	if not check(changed_render==1 and changed_actors==4 and path_replace.get(room.room_enclosure.native_complete_shell)==SHELL,"EXACT_ONE_SHELL_AND_FOUR_NEW_SPRITE_REBINDS"):finish();return
	room.room_enclosure.native_complete_shell=SHELL
	room.erase("interior_identity_20261106_candidate")
	room["interior_identity_20261107"]="YIHONG_NATIVE_ROOM_20261107_V1"
	var inverse: Dictionary = room.duplicate(true)
	for key: String in ["render","npcs","room_enclosure","sources"]: inverse[key]=before[key]
	inverse.erase("interior_identity_20261107")
	inverse["interior_identity_20261106_candidate"]=before["interior_identity_20261106_candidate"]
	if not check(var_to_bytes(inverse)==var_to_bytes(before) and CORE.plain(room),"ALL_GEOMETRY_PORTALS_BUSINESS_SOURCE_TYPED_REVERSE"):finish();return
	for source: String in room.sources:
		if not check(not source.begins_with(PREFIX) and not source.begins_with(HOME),"NO_IGNORED_CANDIDATE_SOURCE_IN_RUNTIME:"+source):finish();return
	# Find one actual old-legal position obstructed by the new room. This is a
	# public synthetic restore fixture seed; never a user's saved position.
	var old: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(OLD_BIN))
	var moved := Vector2.INF
	for y: int in range(482,820,8):
		for x: int in range(228,1310,8):
			var foot := Vector2(x,y)
			if CORE.safe_body(old,foot,HALF) and CORE.npc_route_clear(old,foot,foot,HALF) and (not CORE.safe_body(room,foot,HALF) or not CORE.npc_route_clear(room,foot,foot,HALF)):
				moved=foot;break
		if moved.is_finite(): break
	if not check(moved.is_finite() and CORE.safe_body(room,Vector2(768,850),HALF) and CORE.npc_route_clear(room,Vector2(768,850),Vector2(768,850),HALF),"NARROW_PREDECESSOR_RESTORE_FIXTURE_SEED"):finish();return
	var bytes := var_to_bytes(room)
	var out_path := output+"yihongyuan27n_interior.bin"
	var fd := FileAccess.open(out_path,FileAccess.WRITE)
	if not check(fd!=null,"NEW_BIN_STAGE_FILE"):finish();return
	fd.store_buffer(bytes);fd.close()
	check(var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(out_path)))==bytes,"FORMAL_STAGE_ROUNDTRIP")
	finish({"runtime_bin":LIVE,"candidate":out_path,"sha256":FileAccess.get_sha256(out_path),"bytes":bytes.size(),"synthetic_old_legal_blocked_foot":[moved.x,moved.y]})
