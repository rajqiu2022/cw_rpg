extends Node2D
## Architecture stays opaque. Only a copy of the live actor is translucent.
var town: Node2D
var overlay: Sprite2D
var occluders: Array[CanvasItem]=[]
var images: Dictionary={}
var blocked:=false

func setup(owner_town: Node2D) -> void:
	town=owner_town;overlay=Sprite2D.new();overlay.z_as_relative=false;overlay.z_index=4095;overlay.modulate=Color(1,1,1,.42);add_child(overlay)
	for subtree: Node in [town.get_node("Town"),town.get_node("Terrain")]:
		for art: CanvasItem in subtree.find_children("*","CanvasItem",true,false):
			if not (art is Sprite2D or art is Polygon2D) or art.texture==null:continue
			var ancestor: Node=art;var is_actor:=false
			while ancestor!=town:
				if ancestor is CharacterBody2D:is_actor=true;break
				ancestor=ancestor.get_parent()
			if is_actor or depth(art)<0:continue
			occluders.append(art)
			if not images.has(art.texture):images[art.texture]=art.texture.get_image()

func depth(art: CanvasItem) -> int:
	var value:=art.z_index;var parent: CanvasItem=art
	while parent.z_as_relative and parent.get_parent() is CanvasItem:
		parent=parent.get_parent();value+=parent.z_index
	return value

func uv_at(art: CanvasItem,point: Vector2) -> Vector2:
	var local: Vector2=art.to_local(point)
	if art is Sprite2D:
		var rect: Rect2=art.get_rect()
		if not rect.has_point(local):return Vector2(-1,-1)
		var uv:=local-rect.position
		if art.region_enabled:uv+=art.region_rect.position
		return uv
	var vertices: PackedVector2Array=art.polygon;var uvs: PackedVector2Array=art.uv
	if vertices.size()!=uvs.size() or not Geometry2D.is_point_in_polygon(local,vertices):return Vector2(-1,-1)
	var indices:=Geometry2D.triangulate_polygon(vertices)
	for i: int in range(0,indices.size(),3):
		var a:=vertices[indices[i]];var b:=vertices[indices[i+1]];var c:=vertices[indices[i+2]]
		var ab:=b-a;var ac:=c-a;var ap:=local-a;var determinant:=ab.cross(ac)
		if absf(determinant)<.0001:continue
		var v:=ap.cross(ac)/determinant;var w:=ab.cross(ap)/determinant
		if v>=-.0001 and w>=-.0001 and v+w<=1.0001:return uvs[indices[i]]*(1-v-w)+uvs[indices[i+1]]*v+uvs[indices[i+2]]*w
	return Vector2(-1,-1)

func opaque_at(art: CanvasItem,point: Vector2) -> bool:
	for slot: Array in art.get_meta("repair_static_stair_slots",[]):
		if point.x>=float(slot[0]) and point.y>=float(slot[1]) and point.x<=float(slot[2]) and point.y<=float(slot[3]):return false
	var uv:=uv_at(art,point);var im: Image=images[art.texture];var pixel:=Vector2i(uv)
	return uv.x>=0 and uv.y>=0 and pixel.x<im.get_width() and pixel.y<im.get_height() and im.get_pixelv(pixel).a>.35

func refresh() -> void:
	blocked=false
	if town.view_mode!=1:overlay.hide();return
	var sprite:=town.actor.get_node("Sprite2D") as Sprite2D;var foot: Vector2=town.terrain.projected_foot()
	for art: CanvasItem in occluders:
		if not art.is_visible_in_tree() or depth(art)<=depth(sprite):continue
		for height: float in [25.0,60.0,95.0,125.0]:
			if opaque_at(art,foot-Vector2(0,height)):blocked=true;break
		if blocked:break
	overlay.visible=blocked
	if not blocked:return
	overlay.texture=sprite.texture;overlay.hframes=sprite.hframes;overlay.vframes=sprite.vframes;overlay.frame=sprite.frame
	overlay.region_enabled=sprite.region_enabled;overlay.region_rect=sprite.region_rect;overlay.region_filter_clip_enabled=sprite.region_filter_clip_enabled
	overlay.flip_h=sprite.flip_h;overlay.flip_v=sprite.flip_v;overlay.centered=sprite.centered;overlay.offset=sprite.offset;overlay.global_transform=sprite.global_transform

func get_debug_state() -> Dictionary:
	return {"blocked":blocked,"overlay_visible":overlay.visible,"overlay_alpha":overlay.modulate.a,"actor_sprite":town.actor.get_node("Sprite2D").get_path(),"overlay":overlay.get_path(),"occluder_count":occluders.size()}
