extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="3c7600d44f48c91cfacbfacca74e5f080d482a76ecd3e677f511f5d69b4cfbd6"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
