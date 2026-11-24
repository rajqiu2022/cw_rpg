extends RefCounted
## Generated authority is separate from frozen input code, avoiding self-hash.
const FORMAL_ENABLED=false
const REGISTRY_PATH="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const REGISTRY_SHA=""
static func formal_enabled() -> bool: return load("res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd").formal_enabled()
static func registry() -> Dictionary: return {"path":REGISTRY_PATH,"sha256":REGISTRY_SHA}
