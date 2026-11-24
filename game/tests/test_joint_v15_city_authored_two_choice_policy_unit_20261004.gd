extends SceneTree
## SOURCE UNIT only. No Field/UI input/rewards/save/approval or FULL credit.
## The actual UI path is the new helper's explicit _finish_dialogs override.
const POLICY_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd"
const POLICY_SHA: String="97a8d255a7148074ff5a2fbb334a675c92697b992b12565b0d14fb52d859b126"
const ORIGIN_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_choice_phase.gd"
const ORIGIN_SHA: String="6ac90705b6c40866f307af188a7382f70fed0a4d1d08d2cf5ac607306b40ef79"
const UNIT_ORIGIN_PATH: String="res://tests/test_joint_v15_city_authored_choice_policy_unit_20261004.gd"
const UNIT_ORIGIN_SHA: String="2ed9fa17fcfd57779c4c2f26c6741c790a81ab33b64029d5573a591115c9849b"
const SUBJECTS: Array[Dictionary]=[
	{"path":"res://data/dialogs/huilan_openworld_water_rule.tres","sha":"e6bb99f246af07f4d447881c05d1b0591aea9bd8be14426341d7e92a95e1acd5","dialog":"huilan_openworld_water_rule","node":"choice","index":1},
	{"path":"res://data/dialogs/ch4_guyun_sword_notches.tres","sha":"1fc1354cbc1b8df3d3f5375760e1e5fe77041c2efbc1fa987d75070324433f02","dialog":"ch4_guyun_sword_notches","node":"puzzle","index":2}
]
var policy_script: GDScript
var policy_instance: RefCounted
var checks: int=0
var failed: int=0
var cases: Array[Dictionary]=[]

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		push_error("[TWO AUTHORED CHOICE SOURCE UNIT] "+label)

func _normal_files() -> Dictionary:
	var files: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[slot,suffix]
			var row: Dictionary={"exists":FileAccess.file_exists(path)}
			if bool(row.exists):
				var file: FileAccess=FileAccess.open(path,FileAccess.READ)
				row["readable"]=file!=null
				row["bytes"]=file.get_length() if file!=null else -1
				if file!=null: file.close()
				row["sha256"]=FileAccess.get_sha256(path)
				row["mtime_seconds"]=FileAccess.get_modified_time(path)
			files[path]=row
	return files

func _state() -> Dictionary:
	return {"files":_normal_files(),"active_slot":root.get_node("SaveManager").get("active_slot"),"flags":(root.get_node("GameState").get("flags") as Dictionary).duplicate(true),"navigation":root.get_node("SceneRouter").call("get_navigation_state"),"inventory":root.get_node("Inventory").call("to_dict"),"dialog_playing":root.get_node("DialogPlayer").call("is_playing")}


func _case(label: String,row: Dictionary,options: Variant,valid: bool,index: int,exact: bool) -> void:
	var actual: Variant=policy_instance.call("two_authored_choice_policy",String(row.path),String(row.sha),String(row.dialog),String(row.node),options)
	var passed: bool=actual is Dictionary and actual.get("valid")==valid and actual.get("selected_index")==index and actual.get("exact_authored_policy")==exact
	_check(passed,label)
	cases.append({"label":label,"source_identity":row.duplicate(true),"expected_valid":valid,"expected_index":index,"expected_exact":exact,"actual":actual,"passed":passed})

func _pins() -> Dictionary:
	var paths: Dictionary={POLICY_PATH:POLICY_SHA,ORIGIN_PATH:ORIGIN_SHA,UNIT_ORIGIN_PATH:UNIT_ORIGIN_SHA,"res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd":"a5877e5940262baa74737d9e28ba06d5367a1b5823f51896a52068ee98077e2a"}
	for row: Dictionary in SUBJECTS: paths[row.path]=row.sha
	return paths

func _run() -> void:
	var before: Dictionary=_state()
	var pins: Dictionary=_pins()
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==pins[path],"exact frozen source: "+path)
	policy_script=load(POLICY_PATH) as GDScript
	_check(policy_script!=null and policy_script.can_instantiate(),"new two-policy sibling compiles after normal autoload registration")
	if policy_script!=null and policy_script.can_instantiate(): policy_instance=policy_script.new() as RefCounted
	_check(policy_instance!=null,"actual new sibling instance supplies explicit policy method")
	var code: String=FileAccess.get_file_as_string(POLICY_PATH)
	_check(code.contains("func _finish_dialogs() -> Array[Dictionary]:") and code.contains("var policy: Dictionary=two_authored_choice_policy(script.resource_path,source_sha,String(script.dialog_id),String(node.node_id),node.choices)") and code.contains("expected_options[index].text"),"actual UI override explicitly dispatches new policy and corresponding labels, not inherited static shadow")
	if failed==0:
		for row: Dictionary in SUBJECTS:
			var resource: DialogScript=load(String(row.path)) as DialogScript
			_check(resource!=null and String(resource.dialog_id)==String(row.dialog),"actual immutable authored resource identity")
			var node: DialogNode=resource.find_node_by_id(StringName(row.node)) if resource!=null else null
			_check(node!=null,"actual authored node identity")
			if node==null: continue
			var authored: Array=node.choices.duplicate(true)
			_case(String(row.dialog)+" actual normal UI answer",row,authored,true,int(row.index),true)
			var wrong: Dictionary=row.duplicate(true)
			wrong.sha="0".repeat(64)
			_case("wrong SHA refuses authored answer",wrong,authored,false,-1,false)
			wrong=row.duplicate(true); wrong.path="res://data/dialogs/other.tres"
			_case("wrong concrete path refuses authored answer",wrong,authored,false,-1,false)
			wrong=row.duplicate(true); wrong.node="other"
			_case("unknown node preserves original first choice",wrong,authored,true,0,false)
			wrong=row.duplicate(true); wrong.dialog="unknown"
			_case("unknown dialog preserves original first choice",wrong,authored,true,0,false)
			_case("wrong options container refuses answer",row,{},false,-1,false)
			_case("wrong options count refuses answer",row,[authored[0]],false,-1,false)
			for index in 3:
				for key: String in ["text","next"]:
					var changed: Array=authored.duplicate(true)
					changed[index][key]="changed"
					_case("every original field exact "+str(index)+"/"+key,row,changed,false,-1,false)
			# The actual resource is Array[Dictionary]; build an untyped negative
			# so null reaches policy instead of typed assignment silently rejecting it.
			var non_dictionary: Array=[]
			for option: Dictionary in authored: non_dictionary.append(option.duplicate(true))
			non_dictionary[1]=null
			_case("actual untyped null option refuses answer",row,non_dictionary,false,-1,false)
			var extra: Array=authored.duplicate(true)
			extra[2]["set_flag"]={"forged":true}
			_case("extra side effect is not an authored answer",row,extra,false,-1,false)
			_check(node.choices==authored,"policy never mutates actual resource/flags")
			node=null; resource=null
	var instance_ref: WeakRef=weakref(policy_instance) if policy_instance!=null else null
	policy_instance=null; policy_script=null
	var cleanup_start: int=Time.get_ticks_usec()
	var natural_frames: int=0
	while Time.get_ticks_usec()-cleanup_start<9000000:
		await process_frame
		natural_frames+=1
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	var drain_start: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain_start<250000: await process_frame
	var cleanup_end: int=Time.get_ticks_usec()
	_check(instance_ref==null or instance_ref.get_ref()==null,"owned policy instance naturally released")
	instance_ref=null
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==pins[path],"exact unchanged frozen source after unit: "+path)
	var after: Dictionary=_state()
	_check(before==after,"normal files/active slot/flags/navigation/inventory/dialog state unchanged")
	print(JSON.stringify({"scope":"SOURCE_UNIT_TWO_AUTHORED_CHOICE_POLICIES_ONLY_NOT_FIELD_UI_OR_FULL","checks":checks,"failed":failed,"cases":cases,"source_sha256":pins,"before":before,"after":after,"actual_dialog_input":"NOT_RUN","field":"NOT_RUN","GPU":"NOT_RUN","visual_approved":false,"engine_pid":OS.get_process_id(),"natural_cleanup":{"start_ticks_usec":cleanup_start,"public_stop_ticks_usec":drain_start,"end_ticks_usec":cleanup_end,"natural_process_frames":natural_frames,"elapsed_usec":cleanup_end-cleanup_start,"public_stop_bgm_fade_seconds":.15,"drain_usec":cleanup_end-drain_start,"timer_cancelled":false}}))
	quit(0 if failed==0 else 1)
