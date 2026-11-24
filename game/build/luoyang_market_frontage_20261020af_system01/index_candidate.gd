extends RefCounted
const FORMAL_ENABLED=false
const MANIFEST_PATH="res://data/maps/luoyang_market_frontage_20261020af/runtime/ch4_s3_luoyang_market/manifest.json"
const MANIFEST_SHA256="PENDING_AF_SINGLE_MARKET_CPU_AND_IMPORT"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"manifest_path":MANIFEST_PATH,"manifest_sha256":MANIFEST_SHA256}
