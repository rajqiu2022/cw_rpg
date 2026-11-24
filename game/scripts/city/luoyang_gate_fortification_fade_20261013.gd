extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Same native snapshot/source-alpha fade. Only six new masonry IDs are added.
const GATE_BUILDINGS := ["gate_wall_333","gate_wall_950","gate_wall_2122","gate_wall_2739","gate_tower_140","gate_tower_2932"]

func add_prop(sprite: Sprite2D, id: String, foot_y: float) -> void:
	super.add_prop(sprite,id,foot_y)
	if _fade_scene != "ch4_s0_luoyang_gate" or id not in GATE_BUILDINGS or not is_instance_valid(sprite) or not _finite_color(sprite.self_modulate): return
	for record: Dictionary in _fade_records:
		if record.sprite.get_ref() == sprite: return
	for prop: Dictionary in _props:
		if prop.sprite == sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false})
			return

func get_fade_runtime_state() -> Dictionary:
	var state := super.get_fade_runtime_state()
	state.scope = "VALIDATED_GATE_FORTIFICATION_BUILDINGS_ONLY"
	return state
