extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Pure exact8-path validator only; PENDING approval must remain fail-closed.
const STRICT=preload("res://scripts/city/luoyang_gate_stable_imports_20261017.gd")
const STRICT_SHA="ab7fcbfce29987e7f8ec0b7c9a0e69a6332c452489664732fa3f77e8a7ae03cf"
const ISOLATED="F:/Code/RPG_GAME/game/build/luoyang_gate_stable_import_20261017_system01/"
const PREPARED_SHA="ad0ad8f8dd8ee8fc5c2c25e46b8063393c1fec1d825594eb7709f16c102646f5"
func _run_cases() -> bool:
	if not track(STRICT.SELF_PATH,STRICT_SHA) or not track(ISOLATED+"prepared.json",PREPARED_SHA): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)) or not track("res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd","a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895"): return false
	if not check(STRICT.APPROVAL_SHA=="PENDING","Pure validator does not grant final approval"): return false
	var prepared: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ISOLATED+"prepared.json"))
	if not check(prepared.rows.size()==4 and STRICT.ROWS.size()==4,"Exactly four immutable source pairs/eight eligible paths"): return false
	var tested:=0
	for item: Dictionary in prepared.rows:
		for pair: Array in [[String(item.new_import_path),String(item.old_import_sha256),String(item.new_import_sha256)],[String(item.compiled_path),String(item.expected_compiled_sha256),""]]:
			var path: String=pair[0];var historical: String=pair[1]
			var actual_path: String=ISOLATED+path.trim_prefix("res://")
			var bytes: PackedByteArray=FileAccess.get_file_as_bytes(actual_path)
			if not track(actual_path,FileAccess.get_sha256(actual_path)) or not check(not bytes.is_empty() and STRICT.handles(path),"Exact controlled current bytes and eligible path "+path): return false
			if not check(STRICT.validate_variant(path,historical,bytes),"Actual isolated approved variant pure byte match "+path): return false
			if not check(not STRICT.validate_variant(path,"f".repeat(64),bytes),"Exact path with wrong historical SHA rejected"): return false
			var altered: PackedByteArray=bytes.duplicate();var offset: int=altered.size() >> 1;altered[offset]=altered[offset]^1
			if not check(not STRICT.validate_variant(path,historical,altered),"Single arbitrary byte mutation rejected, not just known header"): return false
			if not check(not STRICT.validate_variant(path,historical,bytes.slice(0,bytes.size()-1)),"Truncated candidate bytes rejected"): return false
			if not check(not STRICT.validate_variant("res://project.godot",historical,bytes) and not STRICT.validate_variant(path+".neighbour",historical,bytes),"Fifth/unlisted neighbouring path cannot borrow four pair authority"): return false
			if not check(not STRICT.matches(path,historical) and STRICT.effective_sha(path,historical).is_empty(),"PENDING approval refuses live authorization regardless pure success"): return false
			records.append({"kind":"PURE_EXACT_VARIANT_CASES","path":path,"historical_sha256":historical,"isolated_sha256":FileAccess.get_sha256(actual_path),"positive":true,"wrong_old_sha_rejected":true,"one_byte_rejected":true,"truncation_rejected":true,"fifth_path_rejected":true,"pending_live_authorization_refused":true})
			tested+=1
		if not check(not STRICT.handles(item.texture),"Raw JPEG/PNG itself is NOT granted an import-hash exception"): return false
	return check(tested==8 and not STRICT.handles("res://project.godot"),"Exactly eight pure variants; no arbitrary hash fallback")
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=_run_cases()
	finish("res://build/luoyang_gate_stable_import_variants_cpu_20261017/%d_%d"%[OS.get_process_id(),began],began,complete,"PURE_EXACT8_PATH_VALIDATOR_NEGATIVES_NOT_LIVE_APPROVAL_OR_FIELD")
