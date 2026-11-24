extends RefCounted
## One exact execution dependency successor; not a geometry/author migration.
const SELF="res://scripts/city/luoyang_ac_district_predecessor_20261020ae.gd"
const APPROVAL="res://build/luoyang_shore_market_20261020ae_system01/runtime_dependency_retry1/approval.json"
const APPROVAL_SHA="b016fd41ef6ac3f6a9b52ce5c2bc9b2855c1b55d1ea6fe880cc5207244fee386"
const TARGET="res://scripts/city/luoyang_district_life_20261016f.gd"
const OLD_SHA="0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea"
const NEW_SHA="c4fb86ebd6d7683a9a7ddc96c6f72f98fe614fc8c6d4ac18424bfe3ebf09d351"
const OLD_SNAPSHOT="res://build/luoyang_shore_market_20261020ae_root01/predeploy_backup/scripts/city/luoyang_district_life_20261016f.gd"
static func source_paths() -> Dictionary:
	return {SELF:true,APPROVAL:true,OLD_SNAPSHOT:true}
static func admitted(path: String,expected: String) -> bool:
	if path!=TARGET or expected!=OLD_SHA or FileAccess.get_sha256(TARGET)!=NEW_SHA or FileAccess.get_sha256(OLD_SNAPSHOT)!=OLD_SHA or FileAccess.get_sha256(APPROVAL)!=APPROVAL_SHA: return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVAL))
	if not value is Dictionary or value.get("schema_version")!=1 or value.get("status")!="EXACT_AC_EXECUTION_DEPENDENCY_SUCCESSOR_MARKET_ONLY_FOUR_HUNKS" or value.get("path")!=TARGET or value.get("old_sha256")!=OLD_SHA or value.get("new_sha256")!=NEW_SHA or value.get("old_snapshot")!=OLD_SNAPSHOT or value.get("navigation_unchanged")!=true or value.get("whole_inverse_exact")!=true: return false
	if not value.get("replacements") is Array or value.replacements.size()!=4 or not value.get("navigation_source") is String or not value.navigation_source.begins_with("func navigation_objects("): return false
	var old_bytes: PackedByteArray=FileAccess.get_file_as_bytes(OLD_SNAPSHOT)
	var current: String=FileAccess.get_file_as_string(TARGET)
	var old: String=old_bytes.get_string_from_utf8()
	var navigation: String=String(value.navigation_source)
	if old.count(navigation)!=1 or current.count(navigation)!=1: return false
	var inverse: String=current
	for row: Variant in value.replacements:
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or inverse.count(String(row.new))!=1: return false
		inverse=inverse.replace(String(row.new),String(row.old))
	return inverse.to_utf8_buffer()==old_bytes
