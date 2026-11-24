extends RefCounted
const FORMAL_ENABLED=false
const AUTHOR="res://data/maps/luoyang_full_city_20261022ap/environment.json"
const AUTHOR_SHA="51f203d144ebdb0e1acbe9fdd994690a8f9e53f421f0d75ee4aaa16bd171ac12"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":AUTHOR,"sha256":AUTHOR_SHA}
