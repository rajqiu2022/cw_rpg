extends RefCounted
## External authority; never pinned back into its own AO manifest.
const SELF="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const MANIFEST="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA="929d0966cc32181015e5f29f41ad086840a3077bc2c279abeb6acc081b66126c"
const FORMAL_ENABLED=true
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST,"manifest_sha256":MANIFEST_SHA}
