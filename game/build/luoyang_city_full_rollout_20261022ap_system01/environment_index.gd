extends RefCounted
const FORMAL_ENABLED=false
const AUTHOR="res://data/maps/luoyang_full_city_20261022ap/environment.json"
const AUTHOR_SHA="PENDING_FINAL_EIGHT_FIELD_GROUND_SOURCE_BINDING"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":AUTHOR,"sha256":AUTHOR_SHA}
