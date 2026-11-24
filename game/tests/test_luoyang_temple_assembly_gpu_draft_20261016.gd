extends "res://tests/test_luoyang_temple_assembly_cpu_draft_20261016.gd"
## NEW temple-only draft. No inherited city precheck/Field/receipt/frame chain.
## Frozen proposed budget90s/arrival45s. Geometry/stations remain fail-closed.
const GPU_READY=false
const INPUT=preload("res://tests/helpers/v15_input_driver.gd")
const LIMIT_MS=90000
const ARRIVAL_MS=45000
const CPU_RESULT="PENDING_ACTUAL_NEW_TEMPLE_CPU_RESULT"
const CPU_SHA="PENDING_ACTUAL_NEW_TEMPLE_CPU_SHA"
var plan: Array[Dictionary]=[] # Final author: route points, propid/expectedalpha/ghost/empty.
var field: Node
var driver: RefCounted
var captures: Array[Dictionary]=[]
func actual_clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec()>=deadline or not geometry.clear(foot): return false
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=1; query.collide_with_areas=false
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func segment(a: Vector2,b: Vector2) -> Dictionary:
	var result: Dictionary=geometry.segment(a,b)
	if not result.clear: return result
	var n: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(n+1):
		if not actual_clear(a.lerp(b,float(i)/n)): return {"clear":false,"native_physics":false,"index":i}
	return result
func wait_arrival() -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<until:
		await process_frame
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_temple_assembly_state"): continue
		var state: Dictionary=current_scene.call("get_temple_assembly_state")
		if not String(state.get("error","")).is_empty(): return check(false,"Actual temple setup refused",state)
		var player:=current_scene.get("_player") as CharacterBody2D
		if player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not state.get("finalized",false): continue
		var definition:=current_scene.get("_current_scene") as SceneScript
		if not A.is_scene(definition): continue
		var screen: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
		if panel!=null and panel.is_visible_in_tree(): continue
		field=current_scene; child=definition
		var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
		return check(state.source_first==state.source_final and state.source_count>0 and not state.worker_active and (shape.shape as RectangleShape2D).size==Vector2(34,24) and shape.position==Vector2.ZERO and actual_clear(player.position),"Actual own finalized proof/native34x24/zerooffset/full87517/Physics")
	return check(false,"Fixed45s actual own-Field arrival, no C receipt substitution")
func exercise_gpu() -> bool:
	if not check(not plan.is_empty(),"Final independently reviewed alpha/geometry stations required"): return false
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",A.ID,null,"",-1,-1)
	if not check(accepted,"Real public temple entry") or not await wait_arrival(): return false
	# Final source must implement exact source-alpha station/neighbor negatives,
	# four natural frames, visible-alpha foot <=12 and two native exit can_enter.
	# Draft deliberately refuses rather than claiming unimplemented acceptance.
	return check(false,"Pending frozen author stations and actual per-frame alpha audit")
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if check(GPU_READY,"GPU draft not executable") and precheck() and track(CPU_RESULT,CPU_SHA) and track("res://tests/helpers/v15_input_driver.gd","a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"):
		driver=INPUT.new(); driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		complete=await exercise_gpu()
		root.get_node("SceneRouter").call("reset_for_new_game")
		await process_frame; await process_frame
	if driver!=null: driver.release(); driver=null
	field=null; child=null; geometry=null
	finish("luoyang_temple_assembly_gpu_20261016",began,complete)
