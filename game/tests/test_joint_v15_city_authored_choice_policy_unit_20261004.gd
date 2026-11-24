extends SceneTree
## Pure policy SOURCE UNIT; no DialogPlayer action, Field, reward, save or approval.
## Dynamic load occurs only after normal autoload registration. ROOT owns execution.
const POLICY_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_choice_phase.gd"
const POLICY_SHA: String="6ac90705b6c40866f307af188a7382f70fed0a4d1d08d2cf5ac607306b40ef79"
const ORIGIN_PATH: String="res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd"
const ORIGIN_SHA: String="a5877e5940262baa74737d9e28ba06d5367a1b5823f51896a52068ee98077e2a"
const WATER_PATH: String="res://data/dialogs/huilan_openworld_water_rule.tres"
const WATER_SHA: String="e6bb99f246af07f4d447881c05d1b0591aea9bd8be14426341d7e92a95e1acd5"
const DIALOG_ID: String="huilan_openworld_water_rule"
const NODE_ID: String="choice"
var policy_script: GDScript
var checks: int=0
var failed: int=0
var cases: Array[Dictionary]=[]

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		push_error("[AUTHORED CHOICE SOURCE UNIT] "+label)

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

func _case(label: String,options: Variant,expected_valid: bool,expected_index: int,path: String=WATER_PATH,sha: String=WATER_SHA,dialog_id: String=DIALOG_ID,node_id: String=NODE_ID) -> void:
	var actual: Variant=policy_script.call("authored_choice_policy",path,sha,dialog_id,node_id,options)
	var exact: bool=actual is Dictionary and actual.get("valid")==expected_valid and actual.get("selected_index")==expected_index and actual.get("exact_authored_policy")== (expected_valid and expected_index==1)
	_check(exact,label)
	cases.append({"label":label,"expected_valid":expected_valid,"expected_index":expected_index,"actual":actual,"passed":exact})

func _run() -> void:
	var before: Dictionary=_state()
	for pair: Array in [[POLICY_PATH,POLICY_SHA],[ORIGIN_PATH,ORIGIN_SHA],[WATER_PATH,WATER_SHA]]:
		_check(FileAccess.get_sha256(pair[0]).to_lower()==pair[1],"exact frozen source: "+pair[0])
	policy_script=load(POLICY_PATH) as GDScript
	_check(policy_script!=null and policy_script.can_instantiate(),"new inherited policy compiles in normal autoload context")
	var source: DialogScript=load(WATER_PATH) as DialogScript
	_check(source!=null and String(source.dialog_id)==DIALOG_ID,"actual authored source identity")
	var node: DialogNode=source.find_node_by_id(StringName(NODE_ID)) if source!=null else null
	_check(node!=null,"actual authored choice node exists")
	if failed==0 and node!=null:
		var authored: Array=node.choices.duplicate(true)
		_case("actual three authored options select second normal UI option",authored,true,1)
		_case("uppercase exact SHA is equivalent digest identity",authored,true,1,WATER_PATH,WATER_SHA.to_upper())
		_case("wrong source SHA cannot authorize second option",authored,false,-1,WATER_PATH,"0".repeat(64))
		_case("missing source SHA cannot authorize second option",authored,false,-1,WATER_PATH,"")
		_case("wrong source path cannot authorize second option",authored,false,-1,"res://data/dialogs/other.tres")
		_case("wrong node keeps original first-option default",authored,true,0,WATER_PATH,WATER_SHA,DIALOG_ID,"wrong")
		_case("wrong dialog keeps original first-option default",authored,true,0,WATER_PATH,WATER_SHA,"other",NODE_ID)
		_case("unknown dialog choices are not a generic answer solver",[{"text":"other","next":"loop"}],true,0,"unknown","unknown","unknown","unknown")
		for invalid: Variant in [null,{},"choices",[],[authored[0]],[authored[0],authored[1]],[authored[0],authored[1],authored[2],authored[0]]]:
			_case("malformed count/type rejects: "+str(invalid),invalid,false,-1)
		for index in 3:
			for key: String in ["text","next"]:
				var changed: Array=authored.duplicate(true)
				changed[index][key]="changed"
				_case("all authored fields matter: "+str(index)+"/"+key,changed,false,-1)
				changed=authored.duplicate(true)
				changed[index].erase(key)
				_case("missing authored field rejects: "+str(index)+"/"+key,changed,false,-1)
				changed=authored.duplicate(true)
				changed[index][key]=17
				_case("non-string authored field rejects: "+str(index)+"/"+key,changed,false,-1)
			var extra: Array=authored.duplicate(true)
			extra[index]["set_flag"]={"huilan_water_rule_understood":true}
			_case("extra side effect must never be authorized: "+str(index),extra,false,-1)
			# duplicate(true) retains Array[Dictionary] from the actual Resource.
			# Build an untyped negative input so null really reaches the policy.
			var non_dictionary: Array=[]
			for option: Dictionary in authored: non_dictionary.append(option.duplicate(true))
			non_dictionary[index]=null
			_case("non-dictionary option rejects: "+str(index),non_dictionary,false,-1)
		var reordered: Array=[authored[1],authored[0],authored[2]]
		_case("reordered answer index cannot shortcut",reordered,false,-1)
		var forged: Array=authored.duplicate(true)
		for option: Dictionary in forged: option.next="right"
		_case("forged all-right next nodes reject",forged,false,-1)
		_check(node.choices==authored,"pure policy never mutates actual authored resource")
	node=null
	source=null
	policy_script=null
	# Same natural owned-process exit grace as ROOT184; no timer cancellation
	# or autoload/cache removal. Retain actual verbose exit warnings for ROOT.
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
	for pair: Array in [[POLICY_PATH,POLICY_SHA],[ORIGIN_PATH,ORIGIN_SHA],[WATER_PATH,WATER_SHA]]:
		_check(FileAccess.get_sha256(pair[0]).to_lower()==pair[1],"exact unchanged source after pure policy: "+pair[0])
	var after: Dictionary=_state()
	_check(before==after,"normal files/active slot/flags/navigation/inventory/dialog state unchanged")
	print(JSON.stringify({"scope":"SOURCE_UNIT_AUTHORED_CHOICE_POLICY_ONLY_NOT_FIELD_INPUT_OR_FULL","checks":checks,"failed":failed,"cases":cases,"source_sha256":{POLICY_PATH:POLICY_SHA,ORIGIN_PATH:ORIGIN_SHA,WATER_PATH:WATER_SHA},"before":before,"after":after,"actual_dialog_input":"NOT_RUN","field":"NOT_RUN","GPU":"NOT_RUN","visual_approved":false,"engine_pid":OS.get_process_id(),"natural_cleanup":{"start_ticks_usec":cleanup_start,"public_stop_ticks_usec":drain_start,"end_ticks_usec":cleanup_end,"natural_process_frames":natural_frames,"elapsed_usec":cleanup_end-cleanup_start,"public_stop_bgm_fade_seconds":.15,"drain_usec":cleanup_end-drain_start,"timer_cancelled":false}}))
	quit(0 if failed==0 else 1)
