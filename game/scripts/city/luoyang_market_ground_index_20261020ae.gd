extends RefCounted
const FORMAL_ENABLED=true
const MANIFEST_PATH="res://data/maps/luoyang_market_ground_20261020ae/manifest.json"
const MANIFEST_SHA256="0d6d850abc0a33483100dc0b491c8e9e1213a8ef556662c3a9884666408ebe3c"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary:
	return {"manifest_path":MANIFEST_PATH,"manifest_sha256":MANIFEST_SHA256}
