extends RefCounted
## Activation authority only; the immutable CPU geometry module is not flipped.
const FORMAL_ENABLED=false
const MANIFEST_SHA="611ae848238673e3e4badc1103cbf5c23828a92e5e4968175b5fc7ecffc4ff4a"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json","manifest_sha256":MANIFEST_SHA}
