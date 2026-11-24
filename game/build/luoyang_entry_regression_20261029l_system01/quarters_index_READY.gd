extends RefCounted
## Root sets one final manifest authority only after native/source/Field admission.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const MANIFEST_SHA="12910993b652374b84df807c11921fde5dadf013dc42b5e0fdab439a006a372e"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
