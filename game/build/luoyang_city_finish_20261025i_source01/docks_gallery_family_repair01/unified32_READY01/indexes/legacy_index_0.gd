extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="eaf14f1009cfafc6b3568d85af575d6c0cd36a5a25a6d485ecdc0bd06f09260d"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
