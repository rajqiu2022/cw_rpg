extends RefCounted
const ESTATE=preload("res://scripts/city/luoyang_estate_family_20261021am.gd")
const REGISTRY_PATH="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const REGISTRY_SHA="6ee6ad3a24c2b2907636ad5220b039c77847adad0d0d54f921f097ea26a4731c"
static func formal_enabled() -> bool: return load("res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd").formal_enabled()
static func registry() -> Dictionary:
	return ESTATE.registry_source() if ESTATE.requested() else {"path":REGISTRY_PATH,"sha256":REGISTRY_SHA}
static func source_registry() -> Dictionary: return ESTATE.registry_source()

