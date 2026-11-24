extends "res://tests/test_luoyang_harbour_life_key_20261016.gd"
## Preparation only. Never executes the candidate motion/dialog/route exercise.
## Parent finite120s/arrival60 cleanup/source/save guards are reused unchanged.
const FORMAL_SOURCE_READY = false
const PATCH_PATH = "PENDING_SYSTEM_WATER_HELPER_PATH"
const PATCH_META = "city_harbour_water_patch_20261016"
const PATCH_NODE = "PENDING_SYSTEM_NODE_NAME"
const PATCH_BYTES_FIELD = "PENDING_SYSTEM_BYTE_FIELD"
const FINAL_PINS = {}
const FALSE_RUNTIME_PATH = "PENDING_ROOT_EXACT_PRE_FORMAL_FALSE_BACKUP"
const FALSE_RUNTIME_SHA = "PENDING"
const PATCH_CPU_PATH = "PENDING_ROOT_ACTUAL_PATCH_CPU_RESULT"
const PATCH_CPU_SHA = "PENDING"
const KEY_SOURCE = "res://tests/test_luoyang_harbour_life_key_20261016.gd"
const KEY_SHA = "c12972d754cb713229395fbc6e3082d859537f61a41472a33b0b2b0ecf423a71"
const CANDIDATE_RESULT = "res://build/luoyang_harbour_life_key_20261016/107864_2583/result.json"
const CANDIDATE_SHA = "eb3bb908e9b13e76a52e795cff78fb0b46006e7e3ac948fcfc4b5930a9e6f5d7"
var water: Variant

func _precheck() -> bool:
	if not _check(FORMAL_SOURCE_READY and H.FORMAL_ENABLED and H.enabled() and H.FLAG not in OS.get_cmdline_user_args(),"Ordinary no-candidate two-birth formal smoke, source readiness not inferred"): return false
	for path: String in FINAL_PINS:
		if not _track(path,FINAL_PINS[path]): return false
	for path: String in KEY_PINS:
		if path in ["res://scripts/city/luoyang_harbour_life_runtime_20261016.gd","res://scripts/field/field_walkable_controller.gd"]: continue
		if not _track(path,KEY_PINS[path]): return false
	if not _track(KEY_SOURCE,KEY_SHA) or not _track(CANDIDATE_RESULT,CANDIDATE_SHA) or not _track(FALSE_RUNTIME_PATH,FALSE_RUNTIME_SHA) or not _track(PATCH_CPU_PATH,PATCH_CPU_SHA): return false
	var old:=FileAccess.get_file_as_string(FALSE_RUNTIME_PATH)
	var actual:=FileAccess.get_file_as_string("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
	if not _check(old.count("const FORMAL_ENABLED=false")==1 and old.replace("const FORMAL_ENABLED=false","const FORMAL_ENABLED=true")==actual,"Exact sole bool edit from approved patch-bearing false runtime"): return false
	var candidate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_RESULT))
	if not _check(candidate.complete and candidate.checks==282 and candidate.failures==0 and candidate.captures.size()==2,"Reuse exact actual282 functional result; do not replay those cases"): return false
	if not _track(H.BIND_PATH,BIND_PIN) or not _check(H.BIND_SHA==BIND_PIN,"Original58 binding unchanged; new patch sources separately explicit"): return false
	binding=JSON.parse_string(FileAccess.get_file_as_string(H.BIND_PATH))
	if not _check(binding.source_sha256.size()==58,"Exactly original58 source leaves kept"): return false
	for path: String in binding.source_sha256:
		if not _track(path,binding.source_sha256[path]): return false
	for path: String in H.source_paths():
		if not source_before.has(path) and not _track(path): return false
	for id: String in binding.cities:
		var item: Dictionary=binding.cities[id]
		if not _track(item.manifest_path,item.manifest_sha256) or not _track(item.parent_canonical_path,item.parent_canonical_sha256): return false
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.manifest_path))
		manifest_records[id]=manifest.record; candidate_manifest_paths[id]=item
	water=load(PATCH_PATH)
	return _check(water!=null,"Exact new bounded-water helper exists") and _track(get_script().resource_path)

func _patch_actual() -> bool:
	var node: Node=(field.get("_visual_layer") as Node).get_node_or_null(NodePath(PATCH_NODE))
	if String(scene.scene_id)==cases[0].id:
		return _check(not scene.has_meta(PATCH_META) and node==null,"Dock-only patch absent from ordinary Gate")
	var packet: Dictionary=scene.get_meta(PATCH_META,{})
	if not _check(bool(water.packet_valid(packet)) and node is Sprite2D,"Strict Scene-owned bounded render packet and live patch sprite"): return false
	var sprite:=node as Sprite2D
	var image:=sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var bytes: PackedByteArray=packet.get(PATCH_BYTES_FIELD,PackedByteArray())
	if not _check(image.get_size()==Vector2i(200,280) and image.get_mipmap_count()==0 and image.get_data()==bytes and bytes.size()==224000 and sprite.position==Vector2(2500,1292) and not sprite.centered and sprite.z_index==-999 and sprite.is_visible_in_tree(),"Actual224KB OFF-derived local image/UV/placement, not full6144 GPU texture or color approximation"): return false
	rows.append({"kind":"FORMAL_BOUND_LOCAL_WATER_PATCH","scene_id":String(scene.scene_id),"sprite":String(sprite.name),"size":image.get_size(),"position":sprite.position,"z_index":sprite.z_index,"bytes":bytes.size(),"scene_owned_metadata":true,"old_png_import_nav_and_cpu_publication_not_rewritten":true})
	return true

func _exercise() -> bool:
	rows.append({"kind":"ORDINARY_FORMAL_SMOKE_SCOPE","candidate_result":CANDIDATE_RESULT,"candidate_sha256":CANDIDATE_SHA,"two_public_births_only":true,"no_4second_observation_no_task_dialog_no_original_route_replay":true})
	for item: Dictionary in cases:
		if not await _setup(item): return false
		var state: Dictionary=field.call("get_harbour_life_state")
		var count:=0; var moving:=0
		for npc: Node2D in field.get("_npc_nodes"):
			if not String(npc.get("npc_id")).begins_with("harbour_life_"): continue
			count+=1; crowd_refs.append(weakref(npc))
			if npc.get("movement_mode")=="patrol":
				moving+=1
				if not _check(not String(npc.get("walk_sprite_path")).is_empty(),"Formal native patrol retains real walk strip"): return false
		if not _check(count==10 and moving==6 and state.npcs.size()==10 and state.receipt.binding_sha256==BIND_PIN,"Ordinary default actually spawns10/6, no candidate flag"): return false
		if not _boats() or not _patch_actual() or not await _overview("formal_"+String(item.id)): return false
	return true
