extends RefCounted
## Root sets one final manifest authority only after native/source/Field admission.
const FORMAL_ENABLED=true
const MANIFEST="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const MANIFEST_SHA="40b5c5ba496b101f4c432dc4ca4b16b0bf281cbcfb546dd275821b8aece5a24a"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
