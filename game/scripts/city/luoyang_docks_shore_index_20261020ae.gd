extends RefCounted
## Candidate authority only. No production path is installed by this file.
const FORMAL_ENABLED=true
const MANIFEST_PATH="res://data/maps/luoyang_docks_shore_20261020ae/manifest.json"
const MANIFEST_SHA256="97e4595f43fc9c2636c53a97dd0c148a36085752462d911cc6c99012a707e63c"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST_PATH,"manifest_sha256":MANIFEST_SHA256}
