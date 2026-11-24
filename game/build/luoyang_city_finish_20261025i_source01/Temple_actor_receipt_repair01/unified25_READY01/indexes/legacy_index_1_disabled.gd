extends RefCounted
## External authority; never pinned back into its own AO manifest.
const SELF="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const MANIFEST="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA="4bbe30ea0234144de0c6b1bc23c1271d2aa6ea893e25a8f3342ac89e4b1338e0"
const FORMAL_ENABLED=false
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST,"manifest_sha256":MANIFEST_SHA}
