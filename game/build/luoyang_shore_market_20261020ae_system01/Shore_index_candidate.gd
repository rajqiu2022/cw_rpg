extends RefCounted
## Candidate authority only. No production path is installed by this file.
const FORMAL_ENABLED=false
const MANIFEST_PATH="res://data/maps/luoyang_docks_shore_20261020ae/manifest.json"
const MANIFEST_SHA256="PENDING_ART_LAYOUT_AND_ISOLATED_IMPORT"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST_PATH,"manifest_sha256":MANIFEST_SHA256}
