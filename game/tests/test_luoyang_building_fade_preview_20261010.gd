extends SceneTree
## NEW synthetic API units / real asset GPU comparison only. No Field or approval.
const SELF_PATH := "res://tests/test_luoyang_building_fade_preview_20261010.gd"
const FADE_PATH := "res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd"
const FADE_SHA := "bb5d12158c01aad7bc6e36f53e0bf103af016e195ba690b97a04f6669f8c7bca"
const FADE = preload("res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd")
const BASE = preload("res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const INN := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/inn.png"
const GATE := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s0_luoyang_gate/entities/south_gate.png"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const PINNED := {
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scenes/player.tscn":"db2ecb970904c4c7242b44cbdb1a7befe5d7ad5c2af6f4fc561a0a04edbc55b8",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"}
var checks := 0
var failures := 0
var sources: Dictionary = {}
var first: Dictionary = {}
var players: Dictionary = {}
var slot: Variant
var output := ""
var cases: Array[Dictionary] = []
var screenshots: Array[Dictionary] = []
var preview_helpers: Array[RefCounted] = []
var baseline_helpers: Array[RefCounted] = []
var layers: Array[Node2D] = []
var gpu := false
var asset_pairs: Array[Dictionary] = []
var cursor_cleanup: Dictionary = {}

func _cursor_resources() -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	var manager: Node=root.get_node_or_null("CursorManager")
	if manager==null: return rows
	for field: String in ["_arrow","_hand","_wait"]:
		var texture: Texture2D=manager.get(field) as Texture2D
		if texture==null:
			rows.append({"field":field,"present":false})
		else:
			rows.append({"field":field,"present":true,"resource_path":texture.resource_path,"class":texture.get_class(),"instance_id":str(texture.get_instance_id()),"rid_id":str(texture.get_rid().get_id()),"width":texture.get_width(),"height":texture.get_height()})
	return rows

func _release_process_cursors() -> void:
	var before:=_cursor_resources()
	_check(before.size()==3,"three actual cursor owner resources recorded")
	for row: Dictionary in before: _check(row.get("present")==true,"actual cursor resource present "+String(row.field))
	# Only the process-local public Input registrations. Never assign autoload
	# private fields, mutate original textures, or change OS configuration.
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_WAIT)
	var after:=_cursor_resources()
	_check(before==after,"cursor owner resource fields unchanged by public process-local release")
	cursor_cleanup={"process_local_public_release_only":true,"reset_shapes":["ARROW","POINTING_HAND","WAIT"],"resources_before":before,"owner_resources_after":after,"custom_cursor_resource_getter_available":false,"original_462_GL_ID_ownership_proven":false,"shutdown_error_causality_requires_actual_rerun":true}

func _asset_pair(path: String) -> void:
	var original := _image(path)
	var texture := ResourceLoader.load(path) as Texture2D
	if not _check(original!=null and texture!=null,"actual source/import load "+path): return
	var imported := texture.get_image()
	if imported.is_compressed(): imported.decompress()
	imported.convert(Image.FORMAT_RGBA8)
	if not _check(original.get_size()==imported.get_size(),"actual source/import canvas "+path): return
	var alpha_changes := 0
	for y: int in original.get_height():
		for x: int in original.get_width():
			if original.get_pixel(x,y).a!=imported.get_pixel(x,y).a: alpha_changes+=1
	_check(alpha_changes==0,"actual source/import full alpha "+path)
	asset_pairs.append({"path":path,"original_rgba_sha256":_bytes_sha(original.get_data()),"imported_rgba_sha256":_bytes_sha(imported.get_data()),"all_RGBA_exact":original.get_data()==imported.get_data(),"alpha_changes":alpha_changes,"RGB_edge_processing_not_claimed_absent":true})

func _bytes_sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()

static func fixture_sources() -> Array[String]:
	var paths: Array[String] = [SELF_PATH,FADE_PATH,
		"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd",
		"res://scripts/city/luoyang_v3_modular_overlap.gd",
		"res://scripts/world/outskirts_modular_overlap.gd",
		"res://scripts/world/v14_modular_overlap.gd",
		"res://scripts/field/player.gd","res://scenes/player.tscn","res://project.godot",
		"res://scripts/autoload/platform_bridge.gd","res://scripts/autoload/save_manager.gd",
		INN,GATE,"res://art/characters/hero_idle_down_25d_runtime_4f.png",
		"res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png",
		"res://data/scenes/world_map_jianghu.tres",
		"res://data/maps/world_map_jianghu_layout_v14.tres",
		"res://data/config/outskirts_native_adoption.json"]
	for id: String in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
		paths.append("res://data/scenes/"+id+".tres")
		paths.append("res://data/maps/luoyang_enclosure_v11_candidates/"+id+"_layout.tres")
	return paths

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[BUILDING FADE PREVIEW FAIL] "+label)
	return ok

func _file(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	return {"exists":file!=null,"bytes":file.get_length() if file!=null else 0,"sha256":FileAccess.get_sha256(path) if file!=null else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if file!=null else 0}

func _players() -> Dictionary:
	var rows: Dictionary = {}
	for i: int in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path := "user://save_%d.json%s"%[i,suffix]
			rows[path] = _file(path)
	return rows

func _track(path: String) -> void:
	if path.is_empty() or sources.has(path): return
	sources[path] = true
	if not _check(FileAccess.file_exists(path),"required source "+path): return
	if path.get_extension() in ["gd","tscn","tres","godot"]:
		var regex := RegEx.new()
		regex.compile('res://[^"\\r\\n]+(?=["\\r\\n])')
		for source_match: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
			var dependency: String = source_match.get_string()
			if FileAccess.file_exists(dependency): _track(dependency)
	if not FileAccess.file_exists(path+".import"): return
	_track(path+".import")
	var config := ConfigFile.new()
	if not _check(config.load(path+".import")==OK,"actual import config "+path): return
	if config.has_section_key("remap","path"):
		var remap: Variant = config.get_value("remap","path")
		if remap is String: _track(remap)
	for key: String in config.get_section_keys("remap"):
		if key.begins_with("path."):
			var remap: Variant = config.get_value("remap",key)
			if remap is String: _track(remap)
	if config.has_section_key("deps","dest_files"):
		for compiled: String in config.get_value("deps","dest_files"): _track(compiled)

func _image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image != null: image.convert(Image.FORMAT_RGBA8)
	return image

func _layer() -> Node2D:
	var layer := Node2D.new()
	root.add_child(layer)
	layers.append(layer)
	return layer

func _player(layer: Node2D) -> Player:
	var actor := PLAYER_SCENE.instantiate() as Player
	layer.add_child(actor)
	actor.set_ground_anchored(true)
	actor.set_can_move(false)
	actor.set_physics_process(false)
	actor.set_process(false)
	actor.position = Vector2(0,180)
	return actor

func _prop(layer: Node2D,image: Image,id: String,color: Color=Color.WHITE) -> Sprite2D:
	var node := Sprite2D.new()
	node.name = id
	node.texture = ImageTexture.create_from_image(image)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.self_modulate = color
	layer.add_child(node)
	return node

func _opaque() -> Image:
	var image := Image.create(512,512,false,Image.FORMAT_RGBA8)
	image.fill(Color(0.7,0.55,0.4,1))
	return image

func _alpha(image: Image,pixel: Vector2) -> float:
	var x := int(floor(pixel.x))
	var y := int(floor(pixel.y))
	var fx := pixel.x-x
	var fy := pixel.y-y
	var a := image.get_pixel(clampi(x,0,image.get_width()-1),clampi(y,0,image.get_height()-1)).a
	var b := image.get_pixel(clampi(x+1,0,image.get_width()-1),clampi(y,0,image.get_height()-1)).a
	var c := image.get_pixel(clampi(x,0,image.get_width()-1),clampi(y+1,0,image.get_height()-1)).a
	var d := image.get_pixel(clampi(x+1,0,image.get_width()-1),clampi(y+1,0,image.get_height()-1)).a
	return (a*(1-fx)+b*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy

func _independent_hits(actor: Player,prop: Sprite2D,base: Color) -> int:
	# Independent original RGBA/current frame sampling, never production hit/cache.
	var texture := actor.sprite.texture.get_image()
	if texture.is_compressed(): texture.decompress()
	var image := prop.texture.get_image()
	if image.is_compressed(): image.decompress()
	var cell := Vector2i(texture.get_width()/actor.sprite.hframes,texture.get_height()/actor.sprite.vframes)
	var origin := actor.sprite.frame_coords*cell
	var ar := actor.sprite.get_rect()
	var pr := prop.get_rect()
	var count := 0
	for y: int in cell.y:
		for x: int in cell.x:
			if texture.get_pixelv(origin+Vector2i(x,y)).a<=0: continue
			var uv := (Vector2(x,y)+Vector2(.5,.5))/Vector2(cell)
			if actor.sprite.flip_h: uv.x=1-uv.x
			if actor.sprite.flip_v: uv.y=1-uv.y
			var point := actor.sprite.to_global(ar.position+uv*ar.size)
			var puv := (prop.to_local(point)-pr.position)/pr.size
			if puv.x<0 or puv.y<0 or puv.x>=1 or puv.y>=1: continue
			if prop.flip_h: puv.x=1-puv.x
			if prop.flip_v: puv.y=1-puv.y
			if _alpha(image,puv*Vector2(image.get_size())-Vector2(.5,.5))*prop.modulate.a*base.a>0: count+=1
	return count

func _color(color: Color) -> Array:
	return [color.r,color.g,color.b,color.a]

func _case(label: String,kind: String,base: Color=Color.WHITE) -> void:
	var layer := _layer()
	var actor := _player(layer)
	var image := _opaque()
	if kind=="hole": image.fill(Color.TRANSPARENT); image.set_pixel(0,0,Color.WHITE)
	if kind=="no_overlap": actor.position.x=800
	var prop := _prop(layer,image,"inn",base)
	var helper: RefCounted = FADE.new()
	_check(helper.call("configure_preview",layer,"ch4_s3_luoyang_market",.55,.18)==true,label+" configure")
	helper.call("add_prop",prop,"inn",200.)
	helper.call("add_actor",actor)
	if kind=="front": actor.position.y=220
	if kind=="tie": actor.position.y=200
	var second: Sprite2D
	if kind=="two":
		second=_prop(layer,image,"shop"); second.position.x=20
		helper.call("add_prop",second,"shop",200.)
	# Original getter is Double; independently encode the native render foot.
	# Do not use production depth codec, an epsilon, or a fixture position change.
	var actor_raw: float=actor.get_depth_sort_y()
	var prop_raw: float=layer.to_global(Vector2(prop.position.x,200.)).y
	var actor_native_bytes:=PackedFloat32Array([actor_raw]).to_byte_array()
	var prop_native_bytes:=PackedFloat32Array([prop_raw]).to_byte_array()
	var actor_native: float=actor_native_bytes.decode_float(0)
	var prop_native: float=prop_native_bytes.decode_float(0)
	var expect_hit := _independent_hits(actor,prop,base)>0 and actor_native<prop_native
	var rows: Array[Dictionary]=[]
	for tick: int in 12:
		_check(helper.call("refresh_preview",actor,.03,false)==true,label+" finite refresh")
		var state: Dictionary=helper.call("get_fade_preview_state")
		var row: Dictionary=state.buildings[0]
		_check(row.hit==expect_hit,label+" independent current-frame alpha hit")
		_check(actor.sprite.modulate.a==1 and actor.sprite.self_modulate.a==1,label+" body opacity not changed")
		_check(prop.self_modulate.r==base.r and prop.self_modulate.g==base.g and prop.self_modulate.b==base.b,label+" RGB unchanged")
		rows.append({"frame":actor.sprite.frame,"factor":row.factor,"hit":row.hit})
	_check(is_equal_approx(prop.self_modulate.a,base.a*(.55 if expect_hit else 1.)),label+" bounded settled factor")
	if kind=="tie":
		_check(actor_native==prop_native and not expect_hit and helper.call("get_fade_preview_state").buildings[0].hit==false and helper.call("get_fade_preview_state").buildings[0].factor==1.,label+" independently encoded native equal feet remain opaque")
	if kind=="two": _check(is_equal_approx(second.self_modulate.a,.55),label+" both buildings independently faded")
	if kind=="leave":
		actor.position.x=800
		for tick: int in 8: helper.call("refresh_preview",actor,.03,false)
		_check(var_to_bytes(prop.self_modulate)==var_to_bytes(base),label+" leave exact authored Color recovery")
	if kind=="invalid":
		_check(helper.call("refresh_preview",null,.03,false)==false,label+" invalid player rejects")
		_check(var_to_bytes(prop.self_modulate)==var_to_bytes(base),label+" invalid player restores immediately")
		helper.call("refresh_preview",actor,.3,false)
		var original_texture: Texture2D=actor.sprite.texture
		actor.sprite.texture=null
		_check(helper.call("refresh_preview",actor,.03,false)==false,label+" invalid frame texture rejects")
		_check(var_to_bytes(prop.self_modulate)==var_to_bytes(base),label+" invalid texture restores immediately")
		actor.sprite.texture=original_texture
	if kind=="standing":
		for frame: int in 4:
			actor.sprite.frame=frame
			var expected := _independent_hits(actor,prop,base)>0
			helper.call("refresh_preview",actor,.03,false)
			_check(helper.call("get_fade_preview_state").buildings[0].hit==expected,label+" changed current frame without movement")
	var result: Dictionary=helper.call("get_fade_preview_state")
	cases.append({"label":label,"synthetic_fixture":true,"independent_alpha_hit":expect_hit,"actor_raw_double":actor_raw,"prop_raw_double":prop_raw,"actor_raw_float64_hex":PackedFloat64Array([actor_raw]).to_byte_array().hex_encode(),"prop_raw_float64_hex":PackedFloat64Array([prop_raw]).to_byte_array().hex_encode(),"actor_native_float32":actor_native,"prop_native_float32":prop_native,"actor_native_float32_hex":actor_native_bytes.hex_encode(),"prop_native_float32_hex":prop_native_bytes.hex_encode(),"independent_native_codec":"PackedFloat32Array_bytes_decode_float","base_color":_color(base),"display_color":_color(prop.self_modulate),"samples":rows,"final_factor":result.buildings[0].factor})
	helper.call("release_preview")
	_check(var_to_bytes(prop.self_modulate)==var_to_bytes(base),label+" release exact Color recovery")
	_check(helper.call("get_fade_preview_state").building_count==0,label+" release weak records empty")
	_check(helper.get("_images").is_empty() and helper.get("_actor_pixels").is_empty(),label+" release image/current-frame caches empty")
	_check(actor.get_node("BuildingOverlapGhost").visible==false,label+" release original ghost restored")
	layers.erase(layer); layer.free()

func _units() -> void:
	for row: Array in [
		["behind","behind"],["front","front"],["same_feet","tie"],
		["clear_alpha_hole","hole"],["no_alpha_overlap","no_overlap"],
		["two_buildings","two"],["standing_frames","standing"],
		["leave_recovery","leave"],["release_recovery","behind"],
		["invalid_player_recovery","invalid"]]:
		_case(row[0],row[1])
	_case("authored_RGB_and_custom_alpha_0_8","behind",Color(.65,.8,.9,.8))
	_case("authored_zero_alpha_no_hit","behind",Color(.65,.8,.9,0))
	var layer := _layer()
	var actor := _player(layer)
	var prop := _prop(layer,_opaque(),"crate")
	var helper: RefCounted=FADE.new()
	helper.call("configure_preview",layer,"ch4_s3_luoyang_market",.55,.18)
	helper.call("add_prop",prop,"crate",200.); helper.call("add_actor",actor)
	helper.call("refresh_preview",actor,.3,true)
	_check(helper.call("get_fade_preview_state").building_count==0 and prop.self_modulate==Color.WHITE,"nonbuilding excluded")
	_check(helper.call("refresh_preview",actor,-.1)==false,"negative clock rejected")
	_check(helper.call("refresh_preview",actor,NAN)==false,"NaN clock rejected")
	_check(helper.call("refresh_preview",actor,INF)==false,"infinite clock rejected")
	helper.call("release_preview"); layers.erase(layer); layer.free()

func _gpu_pair(texture_path: String,id: String,scene_id: String,actor_foot: float) -> Array[Player]:
	var actors: Array[Player]=[]
	for side: int in 2:
		var layer := _layer(); layer.position=Vector2(470+side*960,110)
		var actor := _player(layer); actor.position=Vector2(0,actor_foot)
		actor.set_physics_process(true); actor.set_process(true)
		var prop := Sprite2D.new(); layer.add_child(prop)
		prop.texture=ResourceLoader.load(texture_path) as Texture2D
		prop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		prop.scale=Vector2.ONE*.48; prop.position=Vector2(0,280)
		if side==0:
			var base: RefCounted=BASE.new(); base.call("configure",layer)
			base.call("add_prop",prop,id,500.); base.call("add_actor",actor)
			baseline_helpers.append(base)
		else:
			var fade: RefCounted=FADE.new()
			_check(fade.call("configure_preview",layer,scene_id,.55,.18)==true,"GPU configure")
			fade.call("add_prop",prop,id,500.); fade.call("add_actor",actor)
			preview_helpers.append(fade)
		actors.append(actor)
	return actors

func _natural_capture(label: String,actors: Array[Player]) -> void:
	# First normal refresh owns lazy image/mask work and initializes the clock.
	# Only then measure natural elapsed fade time; never supply a synthetic delta.
	baseline_helpers[0].call("refresh",actors[0],false)
	preview_helpers[0].call("refresh",actors[1],false)
	var start := Time.get_ticks_usec()
	var frames := 0
	while frames<8 or Time.get_ticks_usec()-start<250000:
		await process_frame
		frames+=1
		baseline_helpers[0].call("refresh",actors[0],false)
		preview_helpers[0].call("refresh",actors[1],false)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := output+label+".png"
	_check(image.save_png(path)==OK,"actual GPU PNG "+label)
	var state: Dictionary=preview_helpers[0].call("get_fade_preview_state")
	var rows: Array=[]
	for row: Dictionary in state.buildings:
		var prop: Sprite2D=preview_helpers[0].get("_props")[0].sprite
		var independent_hits:=_independent_hits(actors[1],prop,row.base_color)
		var actor_native: float=Vector2(0,actors[1].get_depth_sort_y()).y
		var prop_native: float=Vector2(0,layers[1].to_global(Vector2(prop.position.x,500.)).y).y
		var expected_hit:=actor_native<prop_native and independent_hits>0
		_check(row.hit==expected_hit,"GPU independent base-alpha/native-foot trigger "+label)
		_check(is_equal_approx(row.factor,.55 if expected_hit else 1.),"GPU natural elapsed settled factor "+label)
		if label in ["01_behind","06_inn_deep_behind"]:
			_check(expected_hit and row.hit==true and is_equal_approx(row.factor,.55),"real existing inn positive cannot be an empty comparison")
		elif label in ["02_native_same_feet","03_front_restored","04_leave_restored"]:
			_check(not expected_hit and row.hit==false and row.factor==1.,"real tie/front/leave must restore authored building")
		rows.append({"id":row.id,"factor":row.factor,"hit":row.hit,"independent_alpha_hit_count":independent_hits,"independent_actor_native_foot":actor_native,"independent_prop_native_foot":prop_native,"base_color":_color(row.base_color),"display_color":_color(row.display_color)})
	screenshots.append({"label":label,"path":path,"sha256":FileAccess.get_sha256(path),"frames":frames,"elapsed_usec":Time.get_ticks_usec()-start,"current_actor_frames":[actors[0].sprite.frame,actors[1].sprite.frame],"building_state":rows,"baseline_ghost":baseline_helpers[0].call("get_debug_state").active,"fade_ghost":preview_helpers[0].call("get_debug_state").active})
	_check(actors[0].sprite.modulate.a==1 and actors[1].sprite.modulate.a==1,"GPU both body opacity remain one")

func _gpu() -> void:
	_check(DisplayServer.get_name()!="headless","real GPU display required")
	_check(root.get_visible_rect().size==Vector2(1920,1080),"actual 1920x1080 viewport contains both panels")
	var backdrop:=ColorRect.new()
	backdrop.color=Color(.13,.17,.18,1); backdrop.size=Vector2(1920,1080); backdrop.z_index=-10
	root.add_child(backdrop)
	var labels:=CanvasLayer.new(); labels.layer=10; root.add_child(labels)
	for side: int in 2:
		var label:=Label.new(); label.position=Vector2(80+960*side,35)
		label.text="BASELINE: original character ghost" if side==0 else "PREVIEW: mild building fade + retained ghost"
		labels.add_child(label)
	var actors := _gpu_pair(INN,"inn","ch4_s3_luoyang_market",496.)
	await _natural_capture("01_behind",actors)
	for actor: Player in actors: actor.position.y=500.
	await _natural_capture("02_native_same_feet",actors)
	for actor: Player in actors: actor.position.y=510.
	await _natural_capture("03_front_restored",actors)
	for actor: Player in actors: actor.position=Vector2(700,496.)
	await _natural_capture("04_leave_restored",actors)
	preview_helpers[0].call("release_preview")
	preview_helpers.clear(); baseline_helpers.clear()
	for layer: Node2D in layers: layer.free()
	layers.clear()
	actors=_gpu_pair(GATE,"south_gate","ch4_s0_luoyang_gate",460.)
	await _natural_capture("05_original_gate",actors)
	preview_helpers[0].call("release_preview")
	preview_helpers.clear(); baseline_helpers.clear()
	for layer: Node2D in layers: layer.free()
	layers.clear()
	actors=_gpu_pair(INN,"inn","ch4_s3_luoyang_market",420.)
	await _natural_capture("06_inn_deep_behind",actors)
	labels.free(); backdrop.free()

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_players(); slot=root.get_node("SaveManager").get("active_slot")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	gpu="--building-fade-gpu-preview" in args
	if not _check(("--building-fade-units" in args)!=gpu and "--audio-preview-dummy" in args,"explicit single preview mode and audio NOT TESTED"): quit(1); return
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"public suspension before any await")
	_check(AudioServer.get_driver_name()=="Dummy" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"explicit Dummy preview and installed executable")
	_check(FileAccess.get_sha256(FADE_PATH)==FADE_SHA,"exact NEW helper SHA")
	for path: String in PINNED: _check(FileAccess.get_sha256(path)==PINNED[path],"exact existing source pin "+path)
	for path: String in fixture_sources(): _track(path)
	for path: String in sources: first[path]=_file(path)
	if failures>0: await _finish(); return
	output="res://build/joint_world_luoyang_20261003_qa/building_fade_preview_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique BUILD output"): quit(1); return
	_asset_pair(INN); _asset_pair(GATE)
	_units()
	if gpu: await _gpu()
	await _finish()

func _finish() -> void:
	for helper: RefCounted in preview_helpers: helper.call("release_preview")
	preview_helpers.clear(); baseline_helpers.clear()
	for layer: Node2D in layers:
		if is_instance_valid(layer): layer.free()
	layers.clear()
	_release_process_cursors()
	for frame: int in 8: await process_frame
	var same := true
	for path: String in first:
		if first[path]!=_file(path): same=false
	_check(same,"all consumed source/import/compiled unchanged")
	_check(players==_players() and slot==root.get_node("SaveManager").get("active_slot"),"all15 player files and active slot unchanged")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"checkpoint suspended through quit")
	_check(AudioServer.get_driver_name()=="Dummy","finish remains explicit untested audio Dummy")
	if output.is_empty(): quit(1); return
	var result := {"scope":"BUILDING_FADE_SYNTHETIC_UNITS_AND_EXISTING_ASSET_GPU_PREVIEW_NOT_APPROVAL","complete":failures==0,"checks":checks,"failures":failures,"audio_tested":false,"production_field_integrated":false,"approval":false,"normal_input_tested":false,"collision_tested":false,"ghost_retained_not_full_solid_character_claim":true,"dummy_audio_explicit":true,"source_before":first,"source_unchanged":same,"player_unchanged":players==_players(),"cases":cases,"asset_pairs":asset_pairs,"screenshots":screenshots,"cursor_cleanup":cursor_cleanup,"helper_sha256":FADE_SHA}
	var file := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(result,"\t",true)); file.close()
	var parser:=JSON.new()
	_check(parser.parse(FileAccess.get_file_as_string(output+"result.json"))==OK,"saved JSON readback")
	print("BUILDING_FADE_PREVIEW_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)

