extends RefCounted
## Narrow compatibility authority, not a general import-hash exemption.
## The four immutable historical pairs remain in their original manifests.
const SELF_PATH := "res://scripts/city/luoyang_gate_stable_imports_20261017.gd"
const APPROVAL_PATH := "res://data/maps/luoyang_gate_stable_imports_20261017/approval.json"
const APPROVAL_SHA := "2bfe7f6208d389f8829748a1bf2127c9f92008994f4e79f39d48dbff6f3b5a75"
const MANIFEST_SHA := "6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0"
const PREPARED_PATH := "res://build/luoyang_gate_stable_import_20261017_system01/prepared.json"
const PREPARED_SHA := "ad0ad8f8dd8ee8fc5c2c25e46b8063393c1fec1d825594eb7709f16c102646f5"
const CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const ROWS := [
	{"id":"rock_01_arm_2k","texture":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg","raw_sha":"a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c","old_import":"61c7d4a5938895f7ba6411f0839b71038a3b7930faa49b366311e6fb04bf6003","new_import":"41daa90e50c2c164e47dab5257506be89deec265cea7755759305d873cd720ee","compiled":"res://.godot/imported/rock_01_arm_2k.jpg-24a96ad79bdc1eed19aa5ac280f55f91.ctex","old_compiled":"55b4b4aed87356ead56bf32ec28ca4c39a804714d20e66d6faf2f713851c3d8d","new_compiled":"ef812b807519b8b0a08933ea74d7f626d191abefeecdce645013c69223de6f93"},
	{"id":"rock_01_diff_2k","texture":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg","raw_sha":"fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c","old_import":"4226182873b5033a1c756cab335ad5e3bac7f3cad80b2d5cfba7ad68682f8c9b","new_import":"7a47daa16b9118aa81a50ab2462a59ecc7e16190420ac681f621a8be131ea4f4","compiled":"res://.godot/imported/rock_01_diff_2k.jpg-f2f68f237a523c754af31e1c3ba77bfc.ctex","old_compiled":"a04212a70bc69ce536ccfc6bbd2040e5e7dc6009ca470b0fd181233332d9cace","new_compiled":"ef697d68eca4d0958e9e4dcfa5b40f57ad8f1b648b50186115d61a55452fddbc"},
	{"id":"rock_01_nor_gl_2k","texture":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg","raw_sha":"70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89","old_import":"79e15a58ff6040e7bcc11d44df3ffbc1c8370f9b918e1412563e8b569d889b1c","new_import":"221cff7cd1c74a185dec85d9d8d2b7ade055a672c0c3855b14f553773947e6ce","compiled":"res://.godot/imported/rock_01_nor_gl_2k.jpg-656cdf21c38471bc9ec01a3137e07d69.ctex","old_compiled":"3746c1447ae4630267cc397459f7973c33cb1f694d11d9b559cb7d9e8181b5ee","new_compiled":"0829dbbf8a84a1e963b689b6932567c0e9f3be12961ad2576e42e268636f78bc"},
	{"id":"worn_bluestone_v2","texture":"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png","raw_sha":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d","old_import":"4f9144ae8c4fc6c17427c65647a23e29bfdcdff96752b53bfde8f27372c2c928","new_import":"91af25e369715ec4417c5fae837c1c48bb9e44e0912ac2a63838cd0c0247a448","compiled":"res://.godot/imported/worn_bluestone_v2.png-cc6a68e14573ac0b0b51e0099de5fb19.ctex","old_compiled":"03bd39241c5f5b4878188e2fb64069257e2850369c711e8a2a87d48788cee6a0","new_compiled":"b9f2ba05848127f4178fc23988fa11bfbc4267e78a9dc15c99bd75afba76ddec"}
]

static func _row(path: String) -> Dictionary:
	for row: Dictionary in ROWS:
		if path == String(row.texture) + ".import" or path == row.compiled: return row
	return {}

static func handles(path: String) -> bool:
	return not _row(path).is_empty()

static func _pair(path: String, historical_sha: String) -> Dictionary:
	var row := _row(path)
	if row.is_empty(): return {}
	var imported: bool = path == String(row.texture) + ".import"
	if historical_sha != String(row.old_import if imported else row.old_compiled): return {}
	return {"row":row,"effective":String(row.new_import if imported else row.new_compiled)}

static func validate_variant(path: String, historical_sha: String, bytes: PackedByteArray) -> bool:
	## Pure byte-domain validator for QA negatives; this does NOT grant approval.
	var pair := _pair(path, historical_sha)
	if pair.is_empty(): return false
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK: return false
	return hash.finish().hex_encode() == pair.effective

static func _approval() -> Dictionary:
	# Exact approved evidence only; the retained whole-report failure is not relabelled.
	if APPROVAL_SHA.length() != 64 or FileAccess.get_sha256(APPROVAL_PATH) != APPROVAL_SHA: return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPROVAL_PATH))
	if not value is Dictionary or value.get("status") != "APPROVED_EXACT_EIGHT_PATH_VARIANTS" or value.get("gate_manifest_sha256") != MANIFEST_SHA or value.get("prepared_sha256") != PREPARED_SHA or FileAccess.get_sha256(PREPARED_PATH) != PREPARED_SHA: return {}
	if value.get("rows") != ROWS or not value.get("source_sha256") is Dictionary or value.source_sha256.is_empty(): return {}
	var verification: Variant = value.get("verification")
	if not verification is Dictionary or typeof(verification.get("path")) != TYPE_STRING or typeof(verification.get("sha256")) != TYPE_STRING or verification.sha256.length() != 64 or value.source_sha256.get(verification.path) != verification.sha256: return {}
	for path: Variant in value.source_sha256:
		var sha: Variant = value.source_sha256[path]
		if typeof(path) != TYPE_STRING or not path.begins_with("res://") or ".." in path or typeof(sha) != TYPE_STRING or sha.length() != 64 or FileAccess.get_sha256(path) != sha: return {}
	return value

static func matches(path: String, historical_sha: String) -> bool:
	var pair := _pair(path, historical_sha)
	if pair.is_empty() or _approval().is_empty(): return false
	var row: Dictionary = pair.row
	return FileAccess.get_sha256(row.texture) == row.raw_sha and FileAccess.get_sha256(String(row.texture) + ".import") == row.new_import and FileAccess.get_sha256(row.compiled) == row.new_compiled

static func effective_sha(path: String, historical_sha: String) -> String:
	var pair := _pair(path, historical_sha)
	return String(pair.effective) if not pair.is_empty() and matches(path, historical_sha) else ""

static func _receipt_sha(cpu_context: RefCounted,token: int,id: StringName,path: String) -> String:
	# A real joined workspace's current first-SHA map, never historical catalog values.
	if cpu_context==null or cpu_context.get_script()!=CPU_WORKSPACE or id!=&"ch4_s0_luoyang_gate" or token<=0 or not cpu_context.matches_owner(token,id): return ""
	return cpu_context.source_sha(id,path)

static func _approval_from_receipt(cpu_context: RefCounted,token: int,id: StringName) -> Dictionary:
	# Identical approval predicates; only complete-file SHA reads use the joined receipt.
	if APPROVAL_SHA.length()!=64 or _receipt_sha(cpu_context,token,id,APPROVAL_PATH)!=APPROVAL_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVAL_PATH))
	if not value is Dictionary or value.get("status")!="APPROVED_EXACT_EIGHT_PATH_VARIANTS" or value.get("gate_manifest_sha256")!=MANIFEST_SHA or value.get("prepared_sha256")!=PREPARED_SHA or _receipt_sha(cpu_context,token,id,PREPARED_PATH)!=PREPARED_SHA: return {}
	if value.get("rows")!=ROWS or not value.get("source_sha256") is Dictionary or value.source_sha256.is_empty(): return {}
	var verification: Variant=value.get("verification")
	if not verification is Dictionary or typeof(verification.get("path"))!=TYPE_STRING or typeof(verification.get("sha256"))!=TYPE_STRING or verification.sha256.length()!=64 or value.source_sha256.get(verification.path)!=verification.sha256: return {}
	for path: Variant in value.source_sha256:
		var sha: Variant=value.source_sha256[path]
		if typeof(path)!=TYPE_STRING or not path.begins_with("res://") or ".." in path or typeof(sha)!=TYPE_STRING or sha.length()!=64 or _receipt_sha(cpu_context,token,id,path)!=sha: return {}
	return value

static func matches_from_receipt(path: String,historical_sha: String,cpu_context: RefCounted,token: int,id: StringName) -> bool:
	var pair:=_pair(path,historical_sha)
	if pair.is_empty() or _approval_from_receipt(cpu_context,token,id).is_empty(): return false
	var row: Dictionary=pair.row
	return _receipt_sha(cpu_context,token,id,row.texture)==row.raw_sha and _receipt_sha(cpu_context,token,id,String(row.texture)+".import")==row.new_import and _receipt_sha(cpu_context,token,id,row.compiled)==row.new_compiled

static func source_paths() -> Dictionary:
	var result: Dictionary = {SELF_PATH:true,APPROVAL_PATH:true,PREPARED_PATH:true}
	for row: Dictionary in ROWS:
		result[row.texture] = true
		result[String(row.texture) + ".import"] = true
		result[row.compiled] = true
	var approval := _approval()
	if not approval.is_empty():
		for path: String in approval.source_sha256: result[path] = true
	return result
