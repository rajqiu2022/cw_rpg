extends "res://tests/test_luoyang_city_full_rollout_bounded_groups_author_anchor_returns_READY_20261022ap.gd"
## Only one ordinary public request and its terminal snapshot. No collector,
## raw source load, private Router loader, resolve, geometry, doors or captures.
const TERMINAL_FIXTURE="res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_remaining_v6_BDE_joint_estate_READY.json"
const TERMINAL_FIXTURE_SHA="85ba5cf802c63c0fb8567a07a20d415de65e508739067e8f950e7695d0d72926"

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	output="res://build/luoyang_city_full_rollout_20261022ap_qa01/market_request_terminal_v6/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete: bool=false
	var pinned: bool=track(TERMINAL_FIXTURE,TERMINAL_FIXTURE_SHA)
	if pinned and check(OS.get_cmdline_user_args().is_empty(),"No product/candidate flags; one fixed diagnostic request"):
		var fixed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TERMINAL_FIXTURE))
		var market: Dictionary={}
		for row: Dictionary in fixed.scenes:
			if row.id=="ch4_s3_luoyang_market": market=row
		for path: String in fixed.core_source_sha256:
			if not track(path,fixed.core_source_sha256[path]): pinned=false
		if not track("res://tests/test_luoyang_city_full_rollout_bounded_groups_author_anchor_returns_READY_20261022ap.gd","6a6297513780eaedd5875d62dd51ab7a7d5dcd776f30f980ff97f48285b332f4"): pinned=false
		if pinned and check(not market.is_empty() and fixed.source_authority.owners_sha256=="c0e45a006f73b3759bcc2fe8fc7346ead6f322b3dc7ac441cd5b209b49298a10","Exact independent new-two-target source epoch"):
			for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
			root.get_node("GameState").set("current_chapter",4)
			ap_state_before=_state_ap()
			var router: Node=root.get_node("SceneRouter")
			var accepted: bool=router.call("go_field_smart",&"ch4_s3_luoyang_market",_v(market.setup_uv),"",-1,3)
			var until: int=mini(deadline,Time.get_ticks_msec()+60000)
			var public: Dictionary=router.call("get_public_city_preparation_state")
			while accepted and Time.get_ticks_msec()<until:
				public=router.call("get_public_city_preparation_state")
				if public.get("scene_id")=="ch4_s3_luoyang_market" and public.get("phase") in ["FAILED","HANDED_OFF"]: break
				await process_frame
			# No await or loader between terminal observation and original C details.
			var terminal: Dictionary={"kind":"AP_MARKET_SINGLE_REQUEST_TERMINAL_V6","accepted":accepted,"public":public.duplicate(true),"C_errors":C.errors(),"transition":C.transition_validation_state(),"request_count":1,"diagnostic_only":true,"second_resolve_count":0,"collector_calls":0,"geometry_calls":0,"QA_Field_setup_calls":0}
			records.append(terminal)
			var immediate:=FileAccess.open(output.path_join("terminal.json"),FileAccess.WRITE)
			if immediate!=null: immediate.store_string(JSON.stringify(terminal,"\t"));immediate.close()
			print("AP_MARKET_ORIGINAL_TERMINAL=",JSON.stringify(terminal))
			complete=check(immediate!=null and accepted and public.get("scene_id")=="ch4_s3_luoyang_market" and public.get("phase") in ["FAILED","HANDED_OFF"],"Captured exact request terminal; not admission/geometry acceptance")
	if not await _cleanup(): complete=false
	if not ap_state_before.is_empty() and not check(C._equal_value(ap_state_before,_state_ap()),"Only diagnostic request; no task/flag/reward mutation"): complete=false
	finish(output,began,complete,"AP_V6_SINGLE_PUBLIC_REQUEST_TERMINAL_DIAGNOSTIC_NO_SECOND_RESOLVE")
