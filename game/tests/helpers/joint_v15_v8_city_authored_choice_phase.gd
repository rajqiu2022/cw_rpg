extends "res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd"
## SOURCE-ONLY sibling: one SHA-bound authored answer, through the normal UI.
## All inherited gameplay, natural grace and dialog effect/end predicates remain.
const CHOICE_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd"
const CHOICE_ORIGIN_SHA: String = "a5877e5940262baa74737d9e28ba06d5367a1b5823f51896a52068ee98077e2a"
const WATER_PATH: String = "res://data/dialogs/huilan_openworld_water_rule.tres"
const WATER_SHA: String = "e6bb99f246af07f4d447881c05d1b0591aea9bd8be14426341d7e92a95e1acd5"
const WATER_DIALOG: String = "huilan_openworld_water_rule"
const WATER_NODE: String = "choice"
const WATER_OPTIONS: Array = [
	{"text":"只开中渠，正面泄洪","next":"wrong"},
	{"text":"开东、西两渠，让两股回流彼此削势","next":"right"},
	{"text":"三渠全开，越快越好","next":"wrong"}
]

static func authored_choice_policy(source_path: String, source_sha: String, dialog_id: String, node_id: String, options: Variant) -> Dictionary:
	var policy: Dictionary = {"valid":true,"policy":"UNCHANGED_FIRST_VISIBLE_CHOICE","selected_index":0,"exact_authored_policy":false,"reason":"UNKNOWN_CHOICE_USES_ORIGINAL_DEFAULT"}
	if dialog_id != WATER_DIALOG or node_id != WATER_NODE: return policy
	policy = {"valid":false,"policy":"REJECT_MALFORMED_SHA_BOUND_AUTHORED_CHOICE","selected_index":-1,"exact_authored_policy":false,"reason":"SOURCE_OR_AUTHORED_OPTIONS_DIFFER"}
	if source_path != WATER_PATH or source_sha.to_lower() != WATER_SHA: return policy
	if not options is Array or options.size() != WATER_OPTIONS.size(): return policy
	for index in WATER_OPTIONS.size():
		if not options[index] is Dictionary or options[index].size() != 2: return policy
		for key: String in ["text","next"]:
			if not options[index].has(key) or typeof(options[index][key]) != TYPE_STRING or options[index][key] != WATER_OPTIONS[index][key]: return policy
	return {"valid":true,"policy":"EXACT_SHA_AUTHORED_HUILAN_WATER_RULE_RIGHT_V1","selected_index":1,"exact_authored_policy":true,"reason":"ALL_THREE_AUTHORED_TEXT_AND_NEXT_FIELDS_EXACT"}

func _finish_dialogs() -> Array[Dictionary]:
	var visited: Array[Dictionary]=[]
	if not _check(FileAccess.get_sha256(CHOICE_ORIGIN_PATH).to_lower()==CHOICE_ORIGIN_SHA,"authored choice sibling keeps exact unchanged lifecycle/dialog parent"): return visited
	var dialog: Node=tree.root.get_node("DialogPlayer")
	var start_ticks: int=Time.get_ticks_msec()
	var deadline: int=start_ticks+45000
	var last: String=""
	var ui_seen: Dictionary={}
	var ui_records: Array[Dictionary]=[]
	var choice_records: Array[Dictionary]=[]
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
			var source_sha: String=FileAccess.get_sha256(script.resource_path)
			var policy: Dictionary=authored_choice_policy(script.resource_path,source_sha,String(script.dialog_id),String(node.node_id),node.choices)
			var selected: int=int(policy.selected_index)
			var labels: Array=box.get("_choice_labels") if box.get("_choice_labels") is Array else []
			var label_texts: Array[String]=[]
			var displayed_exact: bool=true
			if bool(policy.exact_authored_policy):
				displayed_exact=choices.size()==3 and labels.size()==3
				for index in labels.size():
					var label: Label=labels[index] as Label
					var text: String=label.text if is_instance_valid(label) else ""
					label_texts.append(text)
					displayed_exact=displayed_exact and index<3 and is_instance_valid(label) and label.is_visible_in_tree() and text=="  %d. %s" % [index+1,WATER_OPTIONS[index].text]
			var selection_valid: bool=bool(policy.valid) and displayed_exact and selected>=0 and selected<choices.size() and choices[selected] is Rect2 and (choices[selected] as Rect2).has_area()
			var choice_record: Dictionary={"observed_ticks_msec":Time.get_ticks_msec(),"identity":identity,"source_path":script.resource_path,"source_sha256":source_sha,"policy":policy.duplicate(true),"authored_options":node.choices.duplicate(true),"actual_ui_label_texts":label_texts,"displayed_authored_options_exact":displayed_exact,"selection_valid":selection_valid,"selected_index":selected,"input_kind":"NORMAL_POINTER_AT_ACTUAL_VISIBLE_CHOICE_RECT_CENTER","actual_dialog_ui_identity":ui_identity}
			if selection_valid:
				var rectangle: Rect2=choices[selected]
				choice_record["pointer_px"]=[rectangle.get_center().x,rectangle.get_center().y]
			choice_records.append(choice_record)
			if not _check(selection_valid,"choice selection is original default or exact SHA-bound authored UI answer: "+identity): continue
			await driver.call("pointer",(choices[selected] as Rect2).get_center())
		else: await driver.call("key",KEY_SPACE)
	_check(not bool(dialog.call("is_playing")),"ordinary dialogue completes through normal Space/choice UI within finite budget")
	records.dialog_nodes.append_array(visited)
	if not records.has("dialog_ui_identity"): records["dialog_ui_identity"]=[]
	(records.dialog_ui_identity as Array).append({"scope":"ACTUAL_NORMAL_DIALOG_LAYER_AND_CONTROL_NOT_DIRECT_API","start_ticks_msec":start_ticks,"deadline_ticks_msec":deadline,"end_ticks_msec":Time.get_ticks_msec(),"wall_budget_msec":45000,"is_playing_after":bool(dialog.call("is_playing")),"ui_observations":ui_records,"visited_count":visited.size(),"input_semantics":"NORMAL_SPACE_OR_ORIGINAL_FIRST_CHOICE_EXCEPT_EXACT_SHA_AUTHORED_WATER_RULE_OPTION_1","authored_choice_inputs":choice_records})
	return visited
