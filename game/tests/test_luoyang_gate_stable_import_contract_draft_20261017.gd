extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Controlled negative inputs only; never mutates any live import or source.
const CONTRACT_READY=false
const STRICT_HELPER_PATH="PENDING_SYSTEM_STRICT_HELPER"
const STRICT_HELPER_SHA="PENDING_SYSTEM_STRICT_HELPER_SHA"
const APPROVED_PREPARED_PATH="PENDING_SYSTEM_APPROVED_PREPARED"
const APPROVED_PREPARED_SHA="PENDING_SYSTEM_APPROVED_PREPARED_SHA"
func _contract_cases() -> bool:
	if not check(CONTRACT_READY,"Wait exact strict helper/approval freeze; no invented contract"): return false
	if not track(STRICT_HELPER_PATH,STRICT_HELPER_SHA) or not track(APPROVED_PREPARED_PATH,APPROVED_PREPARED_SHA): return false
	var helper: Script=load(STRICT_HELPER_PATH) as Script
	var prepared: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(APPROVED_PREPARED_PATH))
	if not check(helper!=null and helper.has_method("matches") and prepared.rows.size()==4,"Frozen actual helper API and four approved identities"): return false
	for row: Dictionary in prepared.rows:
		if not check(bool(helper.call("matches",row.texture+".import",row.old_import_sha256)),"Exact approved4 old->new replacement "+String(row.id)): return false
		if not check(not bool(helper.call("matches",row.texture+".import","f".repeat(64))),"Same path arbitrary historical hash cannot borrow authorization"): return false
		# A config with another parameter changed has a different historical hash.
		# This is a counterfeit expected-input negative, not an on-disk mutation test.
		var original: String=FileAccess.get_file_as_string(row.old_import_snapshot)
		var altered: String=original.replace("compress/mode=0","compress/mode=2")
		var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(altered.to_utf8_buffer())
		if not check(altered!=original and not bool(helper.call("matches",row.texture+".import",hash.finish().hex_encode())),"Non-detect parameter change not authorized by approved oldSHA"): return false
	var first_row: Dictionary=prepared.rows[0]
	if not check(not bool(helper.call("matches","res://project.godot",first_row.old_import_sha256)),"Fifth existing path cannot use four-path historical authorization"): return false
	return check(not bool(helper.call("matches",String(first_row.texture)+".unapproved.import",first_row.old_import_sha256)),"Unapproved neighbouring path not normalized into allowlist")
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=_contract_cases()
	finish("res://build/luoyang_gate_stable_import_contract_20261017/%d_%d"%[OS.get_process_id(),began],began,complete,"ONLY_FOUR_PATH_AUTHORIZATION_NEGATIVE_INPUTS_NO_LIVE_FILE_MUTATION")
