extends RefCounted
## Pure independent linear selection. No streamer index/bins/query/view_rect call.
## Complete physical bodies/16Areas are a separate actual-Field assertion.
static func render_box(entry: Dictionary,size: Vector2) -> Rect2:
	if not entry.get("pos") is Vector2 or not entry.get("render_size_px") is Vector2: return Rect2()
	var extent: Vector2=entry.render_size_px
	var foot: Vector2=entry.pos*size
	var angle: float=deg_to_rad(float(entry.get("rotation",0.0)))
	if not extent.is_finite() or not foot.is_finite() or not is_finite(angle) or extent.x<=0.0 or extent.y<=0.0: return Rect2()
	var origin: Vector2=-extent*.5 if bool(entry.get("centered",true)) else Vector2.ZERO
	var transform:=Transform2D(angle,foot)
	var local_corners: Array[Vector2]=[origin,origin+Vector2(extent.x,0),origin+extent,origin+Vector2(0,extent.y)]
	var box:=Rect2(transform*local_corners[0],Vector2.ZERO)
	for corner: Vector2 in local_corners: box=box.expand(transform*corner)
	return box

static func visible_world_rect(world: Node2D,viewport_rect: Rect2) -> Rect2:
	# Actual canvas transform includes current Camera2D zoom/offset. Do not
	# substitute player position, logical viewport size or guessed clamp state.
	var inverse: Transform2D=world.get_global_transform_with_canvas().affine_inverse()
	var corners: Array[Vector2]=[viewport_rect.position,Vector2(viewport_rect.end.x,viewport_rect.position.y),viewport_rect.end,Vector2(viewport_rect.position.x,viewport_rect.end.y)]
	var box:=Rect2(inverse*corners[0],Vector2.ZERO)
	for corner: Vector2 in corners: box=box.expand(inverse*corner)
	return box

static func selection(objects: Array,size: Vector2,view: Rect2) -> Dictionary:
	var entries: Dictionary={};var viewport: Dictionary={};var required: Dictionary={};var allowed: Dictionary={}
	if not view.has_area() or not view.position.is_finite() or not view.size.is_finite(): return {"ok":false,"error":"VIEW_RECT"}
	for value: Variant in objects:
		if not value is Dictionary: return {"ok":false,"error":"ENTRY_TYPE"}
		var entry: Dictionary=value
		var id: String=String(entry.get("id",""))
		var box: Rect2=render_box(entry,size)
		if id.is_empty() or entries.has(id) or not box.has_area(): return {"ok":false,"error":"ID_OR_RENDER_BOX","id":id}
		entries[id]={"entry":entry,"bounds":box}
		if box.intersects(view,true): viewport[id]=true
		if box.intersects(view.grow(512.0),true): required[id]=true
		if box.intersects(view.grow(1024.0),true): allowed[id]=true
	return {"ok":true,"entries":entries,"viewport":viewport,"required512":required,"allowed1024":allowed,"view":view}

static func actual_sets(expected: Dictionary,actual_ids: Array,initial_prime: bool) -> Dictionary:
	var seen: Dictionary={};var missing: Array[String]=[];var invalid: Array[String]=[]
	for value: Variant in actual_ids:
		if not value is String: return {"ok":false,"error":"ACTUAL_ID_TYPE"}
		var id: String=value
		if seen.has(id) or not expected.entries.has(id) or not expected.allowed1024.has(id): invalid.append(id)
		seen[id]=true
	for id: String in expected.required512:
		if not seen.has(id): missing.append(id)
	if initial_prime:
		for id: String in seen:
			if not expected.required512.has(id): invalid.append(id)
	return {"ok":missing.is_empty() and invalid.is_empty(),"missing_required512":missing,"invalid_or_duplicate":invalid,"actual_count":seen.size(),"required_count":expected.required512.size(),"retained_outside512_allowed_only_inside1024":not initial_prime}
