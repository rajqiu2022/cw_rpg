extends RefCounted
## Activation authority only; the immutable CPU geometry module is not flipped.
const FORMAL_ENABLED=true
const MANIFEST_SHA="4dbb5a725869a869cdac71b7a1c4e43b8571c879f4de8d8c00f80bb3d818ccdd"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json","manifest_sha256":MANIFEST_SHA}
