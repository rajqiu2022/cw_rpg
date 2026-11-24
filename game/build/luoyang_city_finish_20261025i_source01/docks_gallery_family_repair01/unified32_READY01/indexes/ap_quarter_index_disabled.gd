extends RefCounted
## Root sets one final manifest authority only after native/source/Field admission.
const FORMAL_ENABLED=false
const MANIFEST="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
const MANIFEST_SHA="e5ad8f512c2a135015b1796fad7fb781c627b95eaf06cfd65a7f8118d798a49c"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":MANIFEST,"sha256":MANIFEST_SHA}
