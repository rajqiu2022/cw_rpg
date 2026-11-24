extends RefCounted
const REGISTRY_PATH="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const REGISTRY_SHA="6ee6ad3a24c2b2907636ad5220b039c77847adad0d0d54f921f097ea26a4731c"
const AF_INDEX="res://scripts/city/luoyang_market_frontage_index_20261021ai.gd"
const AF_REGISTRY_PATH="res://data/maps/luoyang_market_frontage_rooms_20261021ai/registry.json"
const AF_REGISTRY_SHA="PENDING_AF_THREE_RETURN_ONLY_NATIVE_PUBLICATION"
static func formal_enabled() -> bool: return load("res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd").formal_enabled()
static func source_registry() -> Dictionary: return {"path":AF_REGISTRY_PATH,"sha256":AF_REGISTRY_SHA}
static func registry() -> Dictionary:
	var authority: Variant=load(AF_INDEX)
	if not OS.has_feature("web") and not load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").forced_authoring() and authority is GDScript and authority.resource_path==AF_INDEX and authority.formal_enabled()==true: return source_registry()
	return {"path":REGISTRY_PATH,"sha256":REGISTRY_SHA}
