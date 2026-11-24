extends RefCounted
## Exact C4FB execution successor, plus the unchanged AE0137 predecessor proof.
const SELF="res://scripts/city/luoyang_ao_district_predecessor_20261021ao.gd"
const APPROVAL="res://build/luoyang_market_two_shops_20261021ao_system01/district_source_successor_approval.json"
const APPROVAL_SHA="aaae237af34297324bf0ce5c046d5dcdf66fed7682ae8c5f35695e6c5cb87d3e"
const TARGET="res://scripts/city/luoyang_district_life_20261016f.gd"
const OLD_SHA="c4fb86ebd6d7683a9a7ddc96c6f72f98fe614fc8c6d4ac18424bfe3ebf09d351"
const NEW_SHA="1b44e7452f7fac5056c6da65af1560d0dafdb2ad61d0020291ad2a17a7842fa9"
const OLD_SNAPSHOT="res://build/luoyang_market_two_shops_20261021ao_system01/before/District_C4FB.gd"
const AE_HELPER="res://scripts/city/luoyang_ac_district_predecessor_20261020ae.gd"
const AE_HELPER_SHA="34b8d7d563a8c001f67651f7da4fa14ea8354dfda4c8f202c8a6c6f9c3a987a8"
const AE_APPROVAL="res://build/luoyang_shore_market_20261020ae_system01/runtime_dependency_retry1/approval.json"
const AE_APPROVAL_SHA="b016fd41ef6ac3f6a9b52ce5c2bc9b2855c1b55d1ea6fe880cc5207244fee386"
const AE_OLD_SHA="0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea"
const AE_OLD_SNAPSHOT="res://build/luoyang_shore_market_20261020ae_root01/predeploy_backup/scripts/city/luoyang_district_life_20261016f.gd"
static func source_paths() -> Dictionary:
	return {SELF:true,APPROVAL:true,OLD_SNAPSHOT:true,AE_HELPER:true,AE_APPROVAL:true,AE_OLD_SNAPSHOT:true}
static func source_pins() -> Dictionary:
	return {SELF:FileAccess.get_sha256(SELF),APPROVAL:APPROVAL_SHA,OLD_SNAPSHOT:OLD_SHA,AE_HELPER:AE_HELPER_SHA,AE_APPROVAL:AE_APPROVAL_SHA,AE_OLD_SNAPSHOT:AE_OLD_SHA}
static func _inverse(value: Dictionary,current: String,old_bytes: PackedByteArray,count: int) -> bool:
	if value.get("navigation_unchanged")!=true or value.get("whole_inverse_exact")!=true or not value.get("navigation_source") is String or not value.navigation_source.begins_with("func navigation_objects(") or not value.get("replacements") is Array or value.replacements.size()!=count: return false
	var old: String=old_bytes.get_string_from_utf8()
	if current.count(value.navigation_source)!=1 or old.count(value.navigation_source)!=1: return false
	var inverse: String=current
	for row: Variant in value.replacements:
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old==row.new or row.old.is_empty() or row.new.is_empty() or inverse.count(row.new)!=1: return false
		inverse=inverse.replace(row.new,row.old)
	return inverse.to_utf8_buffer()==old_bytes
static func admitted(path: String,expected: String) -> bool:
	if path!=TARGET or expected not in [OLD_SHA,AE_OLD_SHA] or FileAccess.get_sha256(TARGET)!=NEW_SHA or FileAccess.get_sha256(OLD_SNAPSHOT)!=OLD_SHA or FileAccess.get_sha256(APPROVAL)!=APPROVAL_SHA: return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVAL))
	if not value is Dictionary or value.get("schema_version")!=1 or value.get("status")!="EXACT_AO_DISTRICT_EXECUTION_SUCCESSOR_ONE_SOURCE_GATE_ONLY" or value.get("path")!=TARGET or value.get("old_sha256")!=OLD_SHA or value.get("new_sha256")!=NEW_SHA or value.get("old_snapshot")!=OLD_SNAPSHOT or not _inverse(value,FileAccess.get_file_as_string(TARGET),FileAccess.get_file_as_bytes(OLD_SNAPSHOT),1): return false
	if expected==OLD_SHA: return true
	# Re-evaluate the existing four-hunk AE proof on the immutable C4FB
	# predecessor, not by pretending the current executable is still C4FB.
	if FileAccess.get_sha256(AE_HELPER)!=AE_HELPER_SHA or FileAccess.get_sha256(AE_APPROVAL)!=AE_APPROVAL_SHA or FileAccess.get_sha256(AE_OLD_SNAPSHOT)!=AE_OLD_SHA: return false
	var prior: Variant=JSON.parse_string(FileAccess.get_file_as_string(AE_APPROVAL))
	return prior is Dictionary and prior.get("path")==TARGET and prior.get("old_sha256")==AE_OLD_SHA and prior.get("new_sha256")==OLD_SHA and prior.get("old_snapshot")==AE_OLD_SNAPSHOT and _inverse(prior,FileAccess.get_file_as_string(OLD_SNAPSHOT),FileAccess.get_file_as_bytes(AE_OLD_SNAPSHOT),4)
