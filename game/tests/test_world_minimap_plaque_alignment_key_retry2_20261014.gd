extends SceneTree
## Owned real HUD + production minimap; no Field/world scene, travel or marker semantics.
const HUD_PATH := "res://scenes/ui/field_primary_hud.tscn"
const MINI_PATH := "res://scripts/ui/world_travel_minimap.gd"
const PINS := {
	MINI_PATH:"932401fe8ba609589d084db32fc28ad35bfae395e1e32871adc9e329a33e911b",
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
	if not value: failures += 1; push_error("[MINIMAP ALIGNMENT KEY] "+label)
	return value
func _rect(rect: Rect2) -> Array: return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	var prior: bool = platform.call("is_checkpoint_saves_suspended")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	_check("--world-minimap-alignment-key" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless","explicit short GPU UI mode")
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"exact UI source "+path)
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
	_check(bool(mini.call("configure",scene,player,camera,world)),"real minimap bound to owned minimal world layout")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/minimap_alignment_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"unique UI evidence")
	var image_record: Dictionary = {}
	for dimensions: Vector2i in [Vector2i(1920,1080),Vector2i(1280,720)]:
		viewport.size = dimensions
		await process_frame; await process_frame
		mini.call("update_view")
		var state: Dictionary = mini.call("get_debug_state")
		var panel: Rect2 = state.panel_rect
		var art_rect: Rect2 = art.get_global_rect()
		var map_rect: Rect2 = state.map_rect
		var scale_value: float = clampf(float(dimensions.y)/1080.0,.72,1.0)
		_check(absf(panel.get_center().x-art_rect.get_center().x) < .001,"actual MapPanelArt center equals minimap center")
		_check(panel.position.x >= 8.0 and art_rect.position.x >= 8.0 and panel.end.x <= dimensions.x-100.0+.001 and art_rect.end.x <= dimensions.x-100.0+.001,"full rect bounds preserve GM right100 reserve")
		_check(panel.position.y >= art_rect.end.y and panel.end.y <= dimensions.y and panel.size.distance_to(Vector2(280,210)*scale_value) < .001 and art.size == original_art_size,"vertical separation/bounds/unchanged panel scaling and plaque size")
		_check(absf(map_rect.size.x/map_rect.size.y-1.5) < .00001 and state.mouse_filter == Control.MOUSE_FILTER_IGNORE and mini.focus_mode == Control.FOCUS_NONE and state.visible == true,"map aspect/content and mouse passthrough unchanged")
		rows.append({"viewport":[dimensions.x,dimensions.y],"art_rect":_rect(art_rect),"minimap_rect":_rect(panel),"map_rect":_rect(map_rect),"center_x":panel.get_center().x,"art_center_x":art_rect.get_center().x,"parent_panel_center_x":plaque.get_global_rect().get_center().x,"elapsed_ms":Time.get_ticks_msec()-started,"marker_semantics_tested":false})
		if dimensions == Vector2i(1920,1080):
			await RenderingServer.frame_post_draw
			var image: Image = viewport.get_texture().get_image()
			var path: String = output+"actual_hud_minimap_1080.png"
			_check(image != null and image.get_size() == dimensions and image.save_png(path) == OK,"one actual GPU UI capture")
			image_record = {"path":path,"sha256":FileAccess.get_sha256(path),"size":[dimensions.x,dimensions.y]}
	hud.call("hide_for_system_ui"); mini.call("update_view")
	_check(not mini.is_visible_in_tree(),"real HUD system hide also hides minimap")
	hud.call("show_after_system_ui"); mini.call("update_view")
	_check(mini.is_visible_in_tree(),"real HUD restoration shows minimap")
	mini.call("release")
	var released: Dictionary = mini.call("get_debug_state")
	_check(plaque.position == original_position and released.configured == false and released.visible == false and not mini.is_processing(),"release restores original plaque position and hides/stops minimap")
	viewport.queue_free(); hud = null; mini = null; player = null; camera = null; world = null; scene = null; layout = null
	await process_frame; await process_frame
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"UI source unchanged "+path)
	platform.call("set_checkpoint_saves_suspended",prior)
	_check(platform.call("is_checkpoint_saves_suspended") == prior,"checkpoint restored")
	_check(Time.get_ticks_msec()-started < 10000,"bounded UI-only test, no Field/world initialization")
	var result: Dictionary = {"scope":"OWNED_REAL_HUD_MINIMAP_ALIGNMENT_ONLY","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"capture":image_record,"elapsed_ms":Time.get_ticks_msec()-started,"source_pins":PINS,"Field_loaded":false,"world_scene_loaded":false,"marker_semantics_tested":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write finite UI result")
	if file != null: file.store_string(JSON.stringify(result,"\t")); file.close()
	print("MINIMAP_ALIGNMENT_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
