extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="d231437f043bec904f19b2b73a7fcf3c6372d1fb5b5e18b91a93271a0c6e6f6d"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
