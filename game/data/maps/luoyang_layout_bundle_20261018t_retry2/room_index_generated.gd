extends RefCounted
const REGISTRY_PATH="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const REGISTRY_SHA="accd1b022004c08892879f60595ab1d8fe1332c30e29bc260878d6a1fffb6138"
static func formal_enabled() -> bool: return load("res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd").formal_enabled()
static func registry() -> Dictionary: return {"path":REGISTRY_PATH,"sha256":REGISTRY_SHA}
