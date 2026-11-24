extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="68e5317af0afba036771f6c5faf9cc5b172c6aa234a285b2e87b8664c7406f37"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
