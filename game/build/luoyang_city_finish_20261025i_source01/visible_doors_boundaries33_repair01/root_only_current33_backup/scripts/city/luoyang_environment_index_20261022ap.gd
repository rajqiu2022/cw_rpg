extends RefCounted
const FORMAL_ENABLED=true
const AUTHOR="res://data/maps/luoyang_full_city_20261022ap/environment.json"
const AUTHOR_SHA="64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2"
static func formal_enabled() -> bool: return FORMAL_ENABLED
static func entry() -> Dictionary: return {"path":AUTHOR,"sha256":AUTHOR_SHA}
