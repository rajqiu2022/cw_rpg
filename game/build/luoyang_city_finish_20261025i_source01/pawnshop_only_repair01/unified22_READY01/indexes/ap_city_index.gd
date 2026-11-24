extends RefCounted
const FORMAL_ENABLED=true
const MARKET_MANIFEST="res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
const MARKET_MANIFEST_SHA="12a892f800296e335c454c1327be1d55de8ea8d1de47180dd115d6163cda98b5"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func market_entry() -> Dictionary: return {"manifest_path":MARKET_MANIFEST,"manifest_sha256":MARKET_MANIFEST_SHA}

static func finite_geometry_enabled() -> bool: return true
static func finite_geometry_entries() -> Dictionary:
	return {"ch4_s3_luoyang_market":{"manifest_path":"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_market_manifest_READY.json","manifest_sha256":"ec7beb299cd1202f5237a1848ceb35ba50ee35dca4d7c9a37a7594566bab0a27"},"ch4_s1_luoyang_yamen":{"manifest_path":"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_yamen_manifest_READY.json","manifest_sha256":"c0442cb6ccb91156de5a884b7066c5c4ce488dd3f269457fe524e17388a8e1f9"}}
