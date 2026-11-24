extends "res://tests/test_luoyang_harbour_life_key_20261016.gd"
## Ordinary formal smoke only. Never executes candidate motion/dialog/routes.
## Parent finite120s/arrival60 cleanup/source/save guards are reused unchanged.
const FORMAL_SOURCE_READY = true
const PATCH_PATH = "res://scripts/city/luoyang_harbour_water_patch_20261016.gd"
const PATCH_META = "city_harbour_water_patch_20261016"
const PATCH_NODE = "HarbourSameCaptureWaterPatch"
const PATCH_BYTES_FIELD = "bytes"
const FINAL_PINS = {
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"7bd8039b41636caae462c1e1420637230964ecf8dfdfea9a513f69ab9591a60b",
	"res://scripts/field/field_walkable_controller.gd":"7cded3f8ae434427cb3fb0657d35cb5697007c685a5037786759792ac461bbd3",
	"res://scripts/city/luoyang_harbour_water_patch_20261016.gd":"fa857da43bba211d18722358600cf479bd45f071d59efe12b0112013608c0cc2"
}
const FALSE_RUNTIME_PATH = "res://build/luoyang_harbour_life_20261016_root01/runtime_51B5E84F_before_formal.source"
const FALSE_RUNTIME_SHA = "51b5e84f59aa88fd6a9e59fa7b2cbcc0217d737614e998b47c246bfe39bc322a"
const PATCH_CPU_PATH = "res://build/luoyang_harbour_life_20261016_system01/water_patch_cpu_99604_3378.json"
const PATCH_CPU_SHA = "75508589b4d8ea008276d47f9f8693fc614a5c9ace9c1f0c1188dded13e54d0f"
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
	var cpu: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PATCH_CPU_PATH))
	if not _check(water!=null and cpu.passed and cpu.local_equals_full_lanczos_core and cpu.border_changed==0 and cpu.border_samples==3776 and cpu.bytes==224000 and cpu.rgba_sha256==water.RGBA_SHA,"Actual bounded local Lanczos exact/full-core and zero-border proof, final literal pins measured RGBA"): return false
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
	if not _check(image.get_size()==Vector2i(200,280) and image.get_mipmap_count()==0 and image.get_data()==bytes and bytes.size()==224000 and sprite.position==Vector2(2500,1292) and not sprite.centered and sprite.z_index==-999 and sprite.scale==Vector2.ONE and sprite.texture is ImageTexture and sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR and sprite.is_visible_in_tree(),"Actual224KB OFF-derived local image/UV/placement, not full6144 GPU texture or color approximation"): return false
	rows.append({"kind":"FORMAL_BOUND_LOCAL_WATER_PATCH","scene_id":String(scene.scene_id),"sprite":String(sprite.name),"size":image.get_size(),"position":sprite.position,"z_index":sprite.z_index,"bytes":bytes.size(),"roi":packet.roi,"off_sha256":packet.off_sha256,"rgba_sha256":packet.rgba_sha256,"scene_owned_metadata":true,"old_png_import_nav_and_cpu_publication_not_rewritten":true})
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

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	var path:=output.path_join(label+".png")
	if not _check(image.save_png(path)==OK,"Actual ordinary formal GPU whole-layout capture"): return
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":image.get_size(),"formal_no_candidate_flag":true})
	if String(scene.scene_id)!="ch4_s2_canal_docks": return
	var world:=field.get("world_container") as Node2D
	var transform: Transform2D=world.get_global_transform_with_canvas()
	var from: Vector2=transform*Vector2(2500,1292)
	var to: Vector2=transform*Vector2(2700,1572)
	var region:=Rect2i(Vector2i(from.round()),Vector2i((to-from).round()))
	if not _check(region.size.x>0 and region.size.y>0 and Rect2i(Vector2i.ZERO,image.get_size()).encloses(region),"Actual water ROI inside same GPU frame with source-to-viewport transform"): return
	var crop_path:=output.path_join(label+"_water_roi.png")
	if _check(image.get_region(region).save_png(crop_path)==OK,"Same rendered frame water detail; original pixels, no retouch/resample"):
		captures.append({"path":crop_path,"sha256":FileAccess.get_sha256(crop_path),"kind":"ACTUAL_GPU_SAME_FRAME_SUBREGION","parent_capture":path,"viewport_region":region,"source_world_roi":Rect2i(2500,1292,200,280),"frame":Engine.get_process_frames()})

