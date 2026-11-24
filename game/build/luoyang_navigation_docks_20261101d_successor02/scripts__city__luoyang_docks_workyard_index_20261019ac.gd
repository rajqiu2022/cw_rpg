extends RefCounted
## Activation authority only; the immutable CPU geometry module is not flipped.
const FORMAL_ENABLED=true
const MANIFEST_SHA="1ce6ccbc184c730775500d0c70cc45d498c5ac68ccf824afcc7d18ced2489941"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json","manifest_sha256":MANIFEST_SHA}
