extends RefCounted
## Root sets one final manifest authority only after native/source/Field admission.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const MANIFEST_SHA="98710050b165c5d3ec24c8dc5d6f5dfb3e1059acd5b442ad9c938a81ad485c48"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
