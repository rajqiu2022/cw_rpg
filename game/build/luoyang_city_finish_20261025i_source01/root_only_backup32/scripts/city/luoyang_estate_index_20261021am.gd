extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="737145e0ee468ea7fc7902a0b02fc8398f601502416367c00a6b84ccbfb58559"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
