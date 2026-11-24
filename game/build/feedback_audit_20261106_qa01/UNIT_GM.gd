extends SceneTree
const HELPER := preload("res://gm_minimap_avoidance_candidate.gd")
class FakeGM:
	extends CanvasLayer
	var _drag_candidate := false
	var _dragged := false
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func need(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("GM_AVOID_FAIL ",label)

func run() -> void:
	root.size = Vector2i(1920,1080)
	var gm := FakeGM.new(); gm.name = "GMConsole"; root.add_child(gm)
	var button := Button.new(); button.name = "GMFloatingButton"; button.size = Vector2(72,46); button.position = Vector2(1826,150); gm.add_child(button)
	var mini := Control.new(); mini.position = Vector2(1624,116); mini.size = Vector2(280,210); root.add_child(mini)
	var owner := Control.new(); mini.add_child(owner)
	var map_rect := Rect2(18,32,244,162)
	var helper := HELPER.new()
	await process_frame
	var original := button.position
	helper.sync(owner,mini,map_rect,true)
	var exclusion: Rect2 = helper._viewport_rect(mini,map_rect.grow(8)).grow(10)
	need(not exclusion.intersects(helper._viewport_rect(button,Rect2(Vector2.ZERO,button.size))),"INITIAL_NONOVERLAP")
	need(mini.position == Vector2(1624,116) and mini.size == Vector2(280,210),"MAP_TRANSFORM_UNCHANGED")
	need(helper.get_debug_state().moves == 1,"ONE_MOVE")
	for index in range(10): helper.sync(owner,mini,map_rect,true)
	need(helper.get_debug_state().moves == 1,"NO_POSITION_JITTER")
	helper.release()
	need(button.position == original,"OWNED_RELEASE_RESTORES")
	helper.sync(owner,mini,map_rect,true)
	gm._drag_candidate = true; gm._dragged = false
	helper.sync(owner,mini,map_rect,true)
	gm._dragged = true; button.position = original
	helper.sync(owner,mini,map_rect,true)
	gm._drag_candidate = false
	for index in range(10): helper.sync(owner,mini,map_rect,true)
	need(button.position == original and helper.get_debug_state().user_override,"DRAG_RELEASE_NEVER_RECLAIMS")
	helper.sync(owner,mini,map_rect,false); helper.sync(owner,mini,map_rect,true)
	need(button.position == original and helper.get_debug_state().user_override,"HIDE_SHOW_PRESERVES_USER_CHOICE")
	root.size = Vector2i(1280,720); mini.position = Vector2(984,83); button.position = Vector2(1186,150)
	await process_frame
	helper.sync(owner,mini,map_rect,true)
	exclusion = helper._viewport_rect(mini,map_rect.grow(8)).grow(10)
	need(not exclusion.intersects(helper._viewport_rect(button,Rect2(Vector2.ZERO,button.size))),"RESIZE_REEVALUATES")
	need(not helper.get_debug_state().user_override,"RESIZE_CLEARS_OVERRIDE")
	button.position += Vector2(-60,0)
	var manual := button.position
	helper.sync(owner,mini,map_rect,true); helper.release()
	need(button.position == manual,"EXTERNAL_MOVE_NOT_RESTORED")
	var next_mini := Control.new(); next_mini.position = mini.position; next_mini.size = mini.size; root.add_child(next_mini)
	button.position = Vector2(1186,150)
	helper.sync(owner,next_mini,map_rect,true)
	need(not helper.get_debug_state().user_override and helper.get_debug_state().leased,"NEW_WORLD_REEVALUATES")
	helper.release()
	# Actual CanvasLayer + transformed parent basis, not a hardcoded GUI scale.
	gm.transform = Transform2D(Vector2(1.2,0),Vector2(0,1.1),Vector2.ZERO)
	button.position = Vector2(990,125)
	var transformed_helper := HELPER.new()
	transformed_helper.sync(owner,next_mini,map_rect,true)
	exclusion = transformed_helper._viewport_rect(next_mini,map_rect.grow(8)).grow(10)
	need(not exclusion.intersects(transformed_helper._viewport_rect(button,Rect2(Vector2.ZERO,button.size))),"TRANSFORMED_PARENT_NONOVERLAP")
	transformed_helper.release()
	print("GM_AVOID_FIXTURE ",JSON.stringify({"checks":checks,"errors":errors,"passed":errors.is_empty(),"isolated_project":true,"autoloads":0,"save_access":false}))
	quit(0 if errors.is_empty() else 1)
