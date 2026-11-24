extends "res://scripts/city/luoyang_assembled_furniture_fade_20261016b.gd"
## Local workshop policy: opaque low furniture, source-alpha actor ghost above
## only the occluded current-frame pixels. Native feet/depth/solids stay intact.
const OPAQUE_LOW_IDS=["anvil_stump","bellows","quench_tub","workbench"]

func configure_assembly(world: Node2D,id: StringName,ids: Array,fade_ids: Array) -> bool:
	if id==&"luoyang_market_shop_interior_20261015": return super.configure_assembly(world,id,ids,fade_ids)
	release()
	var rooms: Variant=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
	var author: Dictionary=rooms.author_for_id(id)
	if not rooms.known(id) or not is_instance_valid(world) or author.is_empty(): return false
	var expected: Array=[]; var high: Array=[]
	for item: Dictionary in author.furniture:
		expected.append(String(item.id))
		if item.height_behavior=="HIGH_FURNITURE_FADE": high.append(String(item.id))
	if ids!=expected or fade_ids!=high or ids.is_empty(): return false
	configure(world)
	_assembly_ids=ids.duplicate(); _assembly_fade_ids=fade_ids.duplicate()
	_fade_scene=String(id); _fade_opacity=.55; _fade_seconds=.18
	_fade_status="READY_PREVIEW_ONLY"; _runtime_bound=true
	return true

func add_prop(sprite: Sprite2D,id: String,foot_y: float) -> void:
	# Keep EVERY prop in inherited native order and occlusion mask registration.
	# Only remove the low prop's furniture-fade record, never its depth/alpha data.
	super.add_prop(sprite,id,foot_y)
	if id not in OPAQUE_LOW_IDS: return
	for index: int in range(_fade_records.size()-1,-1,-1):
		var record: Dictionary=_fade_records[index]
		if record.id==id and record.sprite.get_ref()==sprite:
			_restore_record(record,sprite)
			_fade_records.remove_at(index)

func get_fade_runtime_state() -> Dictionary:
	var result: Dictionary=super.get_fade_runtime_state()
	result["low_furniture_policy"]="OPAQUE_WITH_SOURCE_ALPHA_ACTOR_GHOST"
	var opaque: Array=[]
	for id: String in _assembly_ids:
		if id in OPAQUE_LOW_IDS or id not in _assembly_fade_ids: opaque.append(id)
	result["opaque_low_ids"]=opaque
	result["actor_ghost_opacity"]=.46
	return result
