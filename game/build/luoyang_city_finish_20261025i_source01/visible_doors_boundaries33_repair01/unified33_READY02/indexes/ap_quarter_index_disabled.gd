extends RefCounted
## Root sets one final manifest authority only after native/source/Field admission.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const MANIFEST_SHA="60bcef0d517175208b2329b8bae5ef1baf001bdf8672b085d77b7d159c7f1b45"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
