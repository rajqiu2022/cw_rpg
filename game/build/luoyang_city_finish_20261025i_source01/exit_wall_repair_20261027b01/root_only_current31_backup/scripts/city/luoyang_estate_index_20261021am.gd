extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="0fbd1278af3680b828937361ecff1034705e6bcbf4b2f25c0fb96cda4563681f"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
