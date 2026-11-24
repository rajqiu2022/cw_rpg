extends "res://tests/helpers/joint_v15_v8_city_prepared_phase.gd"
## NEW V8 FULL city context: same wall_street v4 predicates and natural grace unchanged.
const V8_GRACE_ORIGIN_PATH: String="res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd"
const V8_GRACE_ORIGIN_SHA: String="fdf51d2e5ab0ac3f35aa72214bc565e4c1addccb17fc19eb576695c0d0588bf8"
const FROZEN_GRACE_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_street_detail_city_gameplay_lifecycle_grace_phase.gd"
const FROZEN_GRACE_ORIGIN_SHA: String = "8c8f92a1fb9bb45e5637574ed49e64888cb921a56f47a24e143f38d16618cb99"
## NEW lifecycle sibling bound to the root-approved current gameplay parent. The frozen
## parent's gameplay/input/effect predicates and 45s dialog budget are retained.
const FROZEN_PARENT_PATH: String="res://tests/helpers/joint_v15_v8_city_prepared_phase.gd"
const FROZEN_PARENT_SHA: String="1b0ba69d9867b075f7e939c6009468d6f7dacbbf6a955babbb5a881ce1d57bae"
const GRACE_USEC: int=2600000
const NORMAL_FIELD_PATH: String="res://scripts/field/field_walkable_controller.gd"
var natural_grace_records: Array[Dictionary]=[]

func _open(id: String,at: Variant=null) -> bool:
	if not _check(FileAccess.get_sha256(V8_GRACE_ORIGIN_PATH).to_lower()==V8_GRACE_ORIGIN_SHA,"exact unchanged prior lifecycle predicates and evidence"): return false
	if not _check(FileAccess.get_sha256(FROZEN_GRACE_ORIGIN_PATH).to_lower()==FROZEN_GRACE_ORIGIN_SHA and FileAccess.get_sha256(FROZEN_PARENT_PATH).to_lower()==FROZEN_PARENT_SHA,"natural grace adapter keeps exact frozen prepared gameplay parent"): return false
	var grace: Dictionary=await natural_field_grace("before_super_open:"+id)
	if not bool(grace.get("complete",false)): return false
	return await super._open(id,at)

func _finish() -> Dictionary:
	# The last Field also owns ordinary reward/toast callbacks. Let them finish
	# while their node is live, just as when replacing an intermediate Field.
	await natural_field_grace("before_super_finish")
	records["own_natural_grace"] = natural_grace_records.duplicate(true)
	return await super._finish()

func natural_field_grace(reason: String) -> Dictionary:
	# Do not create a SceneTreeTimer, cancel a coroutine, force refresh, or remove
	# a toast. Its existing public event handler gets normal live-node stages.
	var start_ticks: int=Time.get_ticks_usec()
	var previous: Node=tree.current_scene if tree!=null else null
	var is_normal_field: bool=is_instance_valid(previous) and previous.is_inside_tree() and not previous.is_queued_for_deletion() and previous.get_script()!=null and previous.get_script().resource_path==NORMAL_FIELD_PATH
	var evidence: Dictionary={"reason":reason,"start_ticks_usec":start_ticks,"end_ticks_usec":start_ticks,"required_grace_usec":GRACE_USEC,"elapsed_usec":0,"natural_process_frames":0,"waited":false,"old_field_id":previous.get_instance_id() if is_instance_valid(previous) else 0,"old_field_script":previous.get_script().resource_path if is_instance_valid(previous) and previous.get_script()!=null else "","old_field_live_before":is_normal_field,"old_field_weakref_alive_before":is_normal_field,"old_field_live_after":false,"old_field_weakref_alive_after":false,"toast_serial_before":-1,"toast_serial_after":-1,"toast_present_before":false,"toast_present_after":false,"toast_weakref_alive_after":false,"complete":false,"timer_created":false,"production_timer_cancelled":false,"ROOT087_six_timer_creation_cause":"NOT_PROVEN_BY_THIS_GRACE"}
	if not is_normal_field:
		evidence["complete"]=true
		evidence["status"]="NO_LIVE_NORMAL_FIELD_TO_DRAIN"
		previous=null
		natural_grace_records.append(evidence)
		return evidence
	var old_ref: WeakRef=weakref(previous)
	var toast_value: Variant=previous.get("_item_toast")
	var toast_ref: WeakRef=weakref(toast_value) if is_instance_valid(toast_value) else null
	evidence["toast_serial_before"]=int(previous.get("_item_toast_serial"))
	evidence["toast_present_before"]=is_instance_valid(toast_value)
	toast_value=null
	var frames: int=0
	var stayed_live: bool=true
	while Time.get_ticks_usec()-start_ticks<GRACE_USEC:
		await tree.process_frame
		frames+=1
		stayed_live=is_instance_valid(previous) and old_ref.get_ref()==previous and tree.current_scene==previous and previous.is_inside_tree() and not previous.is_queued_for_deletion()
		if not stayed_live: break
	var end_ticks: int=Time.get_ticks_usec()
	var live_after: bool=stayed_live and is_instance_valid(previous) and tree.current_scene==previous and previous.is_inside_tree() and not previous.is_queued_for_deletion()
	evidence["end_ticks_usec"]=end_ticks
	evidence["elapsed_usec"]=end_ticks-start_ticks
	evidence["natural_process_frames"]=frames
	evidence["waited"]=true
	evidence["old_field_live_after"]=live_after
	evidence["old_field_weakref_alive_after"]=old_ref.get_ref()!=null
	evidence["toast_serial_after"]=int(previous.get("_item_toast_serial")) if live_after else -1
	evidence["toast_present_after"]=is_instance_valid(previous.get("_item_toast")) if live_after else false
	evidence["toast_weakref_alive_after"]=toast_ref!=null and toast_ref.get_ref()!=null
	evidence["complete"]=live_after and frames>0 and end_ticks-start_ticks>=GRACE_USEC
	evidence["status"]="LIVE_NORMAL_STAGE_GRACE_COMPLETE" if bool(evidence.complete) else "FIELD_CHANGED_OR_DETACHED_DURING_OWN_GRACE"
	_check(bool(evidence.complete),"owned old Field remains live throughout >=2.6s natural stages before replacement/release: "+reason)
	previous=null
	old_ref=null
	toast_ref=null
	natural_grace_records.append(evidence)
	return evidence

func _finish_dialogs() -> Array[Dictionary]:
	var visited: Array[Dictionary]=[]
	var dialog: Node=tree.root.get_node("DialogPlayer")
	var start_ticks: int=Time.get_ticks_msec()
	var deadline: int=start_ticks+45000
	var last: String=""
	var ui_seen: Dictionary={}
	var ui_records: Array[Dictionary]=[]
	while bool(dialog.call("is_playing")) and Time.get_ticks_msec()<deadline:
		await driver.call("completed_actor_stage")
		var node: DialogNode=dialog.get("_current_node") as DialogNode
		var script: DialogScript=dialog.get("_current_script") as DialogScript
		# DialogPlayer owns the actual tscn CanvasLayer root, not its Control child.
		# Resolve exactly that live child's normal UI; never call advance/choose.
		var layer: Node=dialog.get("_box") as Node
		var box: Control=null
		if is_instance_valid(layer) and layer is CanvasLayer:
			box=layer.get_node_or_null("DialogBox") as Control
		var ui_valid: bool=is_instance_valid(layer) and layer is CanvasLayer and layer.is_inside_tree() and not layer.is_queued_for_deletion() and layer.get_parent()==dialog and layer.scene_file_path=="res://scenes/ui/dialog_box.tscn" and is_instance_valid(box) and box.is_inside_tree() and not box.is_queued_for_deletion() and box.get_parent()==layer and String(box.name)=="DialogBox" and box.get_script()!=null and box.get_script().resource_path=="res://scripts/ui/dialog_box.gd"
		var ui_identity: Dictionary={"observed_ticks_msec":Time.get_ticks_msec(),"dialog_player_id":dialog.get_instance_id(),"dialog_player_path":String(dialog.get_path()),"dialog_player_script":dialog.get_script().resource_path,"root_instance_id":layer.get_instance_id() if is_instance_valid(layer) else 0,"root_class":layer.get_class() if is_instance_valid(layer) else "MISSING","root_path":String(layer.get_path()) if is_instance_valid(layer) and layer.is_inside_tree() else "","root_scene_path":layer.scene_file_path if is_instance_valid(layer) else "","root_parent_is_actual_dialog_player":is_instance_valid(layer) and layer.get_parent()==dialog,"control_instance_id":box.get_instance_id() if is_instance_valid(box) else 0,"control_class":box.get_class() if is_instance_valid(box) else "MISSING","control_path":String(box.get_path()) if is_instance_valid(box) and box.is_inside_tree() else "","control_script":box.get_script().resource_path if is_instance_valid(box) and box.get_script()!=null else "","control_parent_is_actual_root":is_instance_valid(box) and box.get_parent()==layer,"control_visible_in_tree":box.is_visible_in_tree() if is_instance_valid(box) else false,"node_present":node!=null,"script_present":script!=null,"exact_root_and_control_identity":ui_valid}
		var ui_key: String=str(ui_identity.root_instance_id)+"/"+str(ui_identity.control_instance_id)+"/"+(String(script.dialog_id)+"/"+String(node.node_id) if script!=null and node!=null else "MISSING_NODE_OR_SCRIPT")
		if not ui_seen.has(ui_key):
			ui_seen[ui_key]=true
			ui_records.append(ui_identity)
			_check(ui_valid,"ordinary dialog uses live actual CanvasLayer root and its exact normal DialogBox Control child")
		if node==null or script==null or box==null or not ui_valid: continue
		var identity: String=String(script.dialog_id)+"/"+String(node.node_id)
		if identity!=last:
			var flag_checks: Dictionary={}
			for flag: Dictionary in node.set_flags:
				var key: String=String(flag.get("key",""))
				var actual: Variant=(tree.root.get_node("GameState").get("flags") as Dictionary).get(key)
				flag_checks[key]=actual
				_check(not key.is_empty() and actual==flag.get("value",true),"authored node flag effect really executes: "+identity+" "+key)
			visited.append({"id":identity,"source_path":script.resource_path,"source_sha256":FileAccess.get_sha256(script.resource_path),"node_flags":flag_checks,"before_next_input":_state(),"actual_dialog_ui_identity":ui_identity})
			last=identity
		var choices: Array=box.get("_choice_rects") if box.get("_choice_rects") is Array else []
		if box.get("choices_container")!=null and box.get("choices_container").is_visible_in_tree() and not choices.is_empty():
			await driver.call("pointer",(choices[0] as Rect2).get_center())
		else: await driver.call("key",KEY_SPACE)
	_check(not bool(dialog.call("is_playing")),"ordinary dialogue completes through normal Space/choice UI within finite budget")
	records.dialog_nodes.append_array(visited)
	if not records.has("dialog_ui_identity"): records["dialog_ui_identity"]=[]
	(records.dialog_ui_identity as Array).append({"scope":"ACTUAL_NORMAL_DIALOG_LAYER_AND_CONTROL_NOT_DIRECT_API","start_ticks_msec":start_ticks,"deadline_ticks_msec":deadline,"end_ticks_msec":Time.get_ticks_msec(),"wall_budget_msec":45000,"is_playing_after":bool(dialog.call("is_playing")),"ui_observations":ui_records,"visited_count":visited.size(),"input_semantics":"UNCHANGED_NORMAL_SPACE_OR_FIRST_VISIBLE_CHOICE_RECT_POINTER"})
	return visited


