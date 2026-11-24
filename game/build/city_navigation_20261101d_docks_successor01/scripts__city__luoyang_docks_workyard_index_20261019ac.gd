extends RefCounted
## Activation authority only; the immutable CPU geometry module is not flipped.
const FORMAL_ENABLED=true
const MANIFEST_SHA="9d92b60062dac402c776158f7d3b22d3f775fb38d4e57e9e0da8503956760568"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json","manifest_sha256":MANIFEST_SHA}
