extends RefCounted
## Root may activate only after native/source/media and actual travel checks.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json"
const MANIFEST_SHA="0273ba799a44218a88bb67d6e335e1c50b1d70c69354e84169db2b03dc965290"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
