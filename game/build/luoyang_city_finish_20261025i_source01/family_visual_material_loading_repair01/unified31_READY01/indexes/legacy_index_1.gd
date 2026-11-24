extends RefCounted
## External authority; never pinned back into its own AO manifest.
const SELF="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const MANIFEST="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA="fa51bd22c2c80b400bd3403e47a40b297314e2df6f919c153d1a06cb7f6f0312"
const FORMAL_ENABLED=true
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST,"manifest_sha256":MANIFEST_SHA}
