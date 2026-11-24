extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Only explicit four frontage IDs. Original native/current-alpha math unchanged.
const MARKET = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
func add_prop(sprite: Sprite2D, id: String, foot_y: float) -> void:
	super.add_prop(sprite,id,foot_y)
	if _fade_scene != String(MARKET.ID) or id not in MARKET.NEW_BUILDINGS or not is_instance_valid(sprite) or not _finite_color(sprite.self_modulate): return
	for record: Dictionary in _fade_records:
		if record.sprite.get_ref() == sprite: return
	for prop: Dictionary in _props:
		if prop.sprite == sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false})
			return
func get_fade_runtime_state() -> Dictionary:
	var state := super.get_fade_runtime_state()
	state.scope = "VALIDATED_MARKET_ENRICHMENT_BUILDINGS_ONLY"
	return state
