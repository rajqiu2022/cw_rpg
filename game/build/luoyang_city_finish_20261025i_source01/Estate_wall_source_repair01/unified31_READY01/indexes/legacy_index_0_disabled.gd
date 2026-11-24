extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="a05cc77e1dc7d93a6db22114a4cf8fcbeaafe81e096d65c1595889b5f26f979e"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
