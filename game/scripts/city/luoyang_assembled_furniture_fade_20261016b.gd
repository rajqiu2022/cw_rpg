extends "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
## Same native Float32 actor/prop order, real per-frame source alpha and fade
## math. New configuration accepts ONLY the source-bound assembled prop list.
var _assembly_ids: Array=[]
var _assembly_fade_ids: Array=[]

func configure_assembly(world: Node2D,id: StringName,ids: Array,fade_ids: Array) -> bool:
	release()
	if not is_instance_valid(world) or id!=&"luoyang_market_shop_interior_20261015" or ids.size()!=6: return false
	var seen: Dictionary={}
	for key: Variant in ids:
		if not key is String or key.is_empty() or seen.has(key): return false
		seen[key]=true
	for key: Variant in fade_ids:
		if not key is String or not seen.has(key): return false
	configure(world)
	_assembly_ids=ids.duplicate(); _assembly_fade_ids=fade_ids.duplicate()
	_fade_scene=String(id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true
	return true

func add_prop(sprite: Sprite2D,id: String,foot_y: float) -> void:
	if id not in _assembly_ids: return
	super.add_prop(sprite,id,foot_y)
	if id not in _assembly_fade_ids or not is_instance_valid(sprite) or not _finite_color(sprite.self_modulate): return
	for record: Dictionary in _fade_records:
		if record.sprite.get_ref()==sprite: return
	for prop: Dictionary in _props:
		if prop.sprite==sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false}); return

func release() -> void:
	super.release()
	_assembly_ids.clear(); _assembly_fade_ids.clear()

func get_fade_runtime_state() -> Dictionary:
	var result:=super.get_fade_runtime_state()
	result.scope="EXACT_ASSEMBLED_FURNITURE_ONLY"
	result.prop_ids=_assembly_ids.duplicate(); result.fade_ids=_assembly_fade_ids.duplicate()
	return result
