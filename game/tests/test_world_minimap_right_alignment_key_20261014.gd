extends SceneTree
## Finite real HUD layout probe only; no Field, world travel or save mutation.
const HUD_PATH := "res://scenes/ui/field_primary_hud.tscn"
const MINI_PATH := "res://scripts/ui/world_travel_minimap.gd"
const PINS := {
	MINI_PATH:"f7f79cd541e6a13d8f67a4c112c23bc644b6a5547c427a5b5ca7a145304edc4b",
	HUD_PATH:"e1fc9134ea81e38db5895d4b632bfad94dcfa859c2a210db04800dc87cdee1ce",
	"res://scripts/ui/field_primary_hud.gd":"9232f5a427461b127178e16eef1851e7d3960592e0dccd852f79bd714000a8ab",
	"res://art/maps/world_map_v15_complete_v9c/overview.png":"bcfb11f3fb026ad9c1ed5647da7553514a25fdd5a77bc52dc3be25f19a3909b8",
	"res://art/ui/field_hud/v1/hud_quest_panel.png":"a27b3eedfa584505391d4ed30a0c9d2e28c247579df973db4b66b6a503a752b9",
	"res://art/ui/field_hud/v2/hud_map_info_panel.png":"0d54f59440e8e352c7c2e3bcd2c521b249806c66d411ceec17d2b8964e08452d",
}
class LayoutPawn:
	extends Node2D
	var _direction: String = "down"
var checks: int = 0
var failures: int = 0
var rows: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> bool:
	checks += 1
	if not value: failures += 1; push_error("[MINIMAP RIGHT KEY] "+label)
	return value
func _rect(rect: Rect2) -> Array: return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
func _art_rect(art: TextureRect) -> Rect2:
	var box: Rect2 = art.get_global_rect()
	var texture_size: Vector2 = art.texture.get_size()
	var image: Image = art.texture.get_image()
	if image.is_compressed():
		if not _check(image.decompress() == OK,"actual plaque alpha image decompressed"): return Rect2()
	var used: Rect2i = image.get_used_rect()
	_check(used.has_area(),"plaque actual alpha-used rect is nonempty")
	var fit: float = minf(box.size.x / texture_size.x,box.size.y / texture_size.y)
	var drawn_size: Vector2 = texture_size*fit
	return Rect2(box.get_center()-drawn_size*.5+Vector2(used.position)*fit,Vector2(used.size)*fit)

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	var prior: bool = platform.call("is_checkpoint_saves_suspended")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before await")
	_check("--world-minimap-right-key" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless","explicit finite GPU UI mode")
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"exact source "+path)
	var started: int = Time.get_ticks_msec()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080); viewport.world_2d = World2D.new(); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var hud: Control = (ResourceLoader.load(HUD_PATH) as PackedScene).instantiate() as Control
	viewport.add_child(hud)
	var plaque: Control = hud.get_node("MapInfoPanel") as Control
	var art: TextureRect = plaque.get_node("MapPanelArt") as TextureRect
	var original_position: Vector2 = plaque.position
	var original_art_size: Vector2 = art.size
	var world := Node2D.new(); viewport.add_child(world)
	var player := LayoutPawn.new(); player.position = Vector2(6144,4096); world.add_child(player)
	var camera := Camera2D.new(); camera.enabled = false; world.add_child(camera)
	var scene := SceneScript.new(); scene.scene_id = &"world_map_jianghu"; scene.background_path = "res://art/maps/world_map_v15_complete_v9c/overview.png"
	var layout := WalkableMapLayout.new(); layout.schema_version = 15; layout.design_size = Vector2i(12288,8192); scene.map_layout = layout
	var mini: Control = (ResourceLoader.load(MINI_PATH) as Script).new() as Control; hud.add_child(mini)
	await process_frame
	_check(bool(mini.call("configure",scene,player,camera,world)),"production minimap configured with minimal owned world")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/minimap_right_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"unique evidence directory")
	var captures: Array[Dictionary] = []
	for dimensions: Vector2i in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1920,1080)]:
		viewport.size = dimensions
		await process_frame; await process_frame
		mini.call("update_view")
		var state: Dictionary = mini.call("get_debug_state")
		var panel: Rect2 = state.panel_rect
		var art_rect: Rect2 = _art_rect(art)
		var map_rect: Rect2 = state.map_rect
		var scale_value: float = clampf(float(dimensions.y)/1080.0,.72,1.0)
		var margin: float = 16.0*scale_value
		_check(absf(panel.get_center().x-art.get_global_rect().get_center().x) < .001,"original plaque canvas and minimap share center")
		_check(absf(panel.end.x-(dimensions.x-margin)) < .001,"minimap itself has scaled16 right margin; no transparent canvas reserve")
		_check(panel.position.x >= 8.0 and art_rect.position.x >= 8.0 and panel.end.x <= dimensions.x and art_rect.end.x <= dimensions.x,"actual artwork remains horizontally within viewport")
		_check(panel.position.y >= art_rect.end.y and panel.end.y <= dimensions.y and panel.size.distance_to(Vector2(280,210)*scale_value) < .001 and art.size == original_art_size,"vertical separation/scaling/plaque size unchanged")
		_check(absf(map_rect.size.x/map_rect.size.y-1.5) < .00001 and state.mouse_filter == Control.MOUSE_FILTER_IGNORE and mini.focus_mode == Control.FOCUS_NONE and state.visible == true,"aspect and passthrough unchanged")
		rows.append({"viewport":[dimensions.x,dimensions.y],"drawn_art_rect":_rect(art_rect),"art_fit_box":_rect(art.get_global_rect()),"minimap_rect":_rect(panel),"map_rect":_rect(map_rect),"right_margin":margin,"elapsed_ms":Time.get_ticks_msec()-started})
		if captures.is_empty() or dimensions == Vector2i(1280,720):
			await RenderingServer.frame_post_draw
			var image: Image = viewport.get_texture().get_image()
			var path: String = output+"actual_hud_minimap_%d.png" % dimensions.y
			_check(image != null and image.get_size() == dimensions and image.save_png(path) == OK,"actual GPU UI capture")
			captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":[dimensions.x,dimensions.y]})
	hud.call("hide_for_system_ui"); mini.call("update_view")
	_check(not mini.is_visible_in_tree(),"system UI hide")
	hud.call("show_after_system_ui"); mini.call("update_view")
	_check(mini.is_visible_in_tree(),"system UI restore")
	mini.call("release")
	var released: Dictionary = mini.call("get_debug_state")
	_check(plaque.position == original_position and released.configured == false and released.visible == false and not mini.is_processing(),"release restores original plaque position")
	var nonworld := SceneScript.new(); nonworld.scene_id = &"ch4_s3_luoyang_market"
	_check(not bool(mini.call("configure",nonworld,player,camera,world)) and plaque.position == original_position and not mini.visible,"nonworld refused without shifting plaque")
	viewport.queue_free(); hud = null; mini = null; player = null; camera = null; world = null; scene = null; layout = null; nonworld = null
	await process_frame; await process_frame
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"source unchanged "+path)
	platform.call("set_checkpoint_saves_suspended",prior)
	_check(platform.call("is_checkpoint_saves_suspended") == prior,"checkpoint restored")
	_check(Time.get_ticks_msec()-started < 10000,"finite UI-only budget")
	var result: Dictionary = {"scope":"OWNED_REAL_HUD_MINIMAP_RIGHT_ALIGNMENT_ONLY","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"captures":captures,"elapsed_ms":Time.get_ticks_msec()-started,"source_pins":PINS,"Field_loaded":false,"world_scene_loaded":false,"marker_semantics_tested":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write result")
	if file != null: file.store_string(JSON.stringify(result,"\t")); file.close()
	print("MINIMAP_RIGHT_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
