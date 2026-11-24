extends RefCounted
## Activation authority only; the immutable CPU geometry module is not flipped.
const FORMAL_ENABLED=true
const MANIFEST_SHA="7328baeb8ab91ad2a6371ab93d06fcabbcc9e9d70f622ec96b05509303782400"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json","manifest_sha256":MANIFEST_SHA}
