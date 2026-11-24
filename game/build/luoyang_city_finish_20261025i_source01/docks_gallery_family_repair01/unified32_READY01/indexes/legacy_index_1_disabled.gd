extends RefCounted
## External authority; never pinned back into its own AO manifest.
const SELF="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const MANIFEST="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA="16d8abf3c4a40feded30543e3fde6002f0b33258a045a5c25b660c518c481fe5"
const FORMAL_ENABLED=false
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST,"manifest_sha256":MANIFEST_SHA}
