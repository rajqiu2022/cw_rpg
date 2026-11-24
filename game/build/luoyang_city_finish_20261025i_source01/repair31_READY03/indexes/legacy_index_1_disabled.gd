extends RefCounted
## External authority; never pinned back into its own AO manifest.
const SELF="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const MANIFEST="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA="9c3afd8697a918966bff9a88325adbcf53633fc9f7b1a05960e418474b1ca895"
const FORMAL_ENABLED=false
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST,"manifest_sha256":MANIFEST_SHA}
