extends Node2D
var town:Node2D
var overlay:Sprite2D
var occluders:Array[Sprite2D]=[]
var images:Dictionary={}
var blocked:=false
func setup(owner_town:Node2D)->void:
	town=owner_town
	overlay=Sprite2D.new();overlay.z_as_relative=false;overlay.z_index=4095;overlay.modulate=Color(1,1,1,.42);add_child(overlay)
	for item in town.get_node("Town").get_children():
		if item is CharacterBody2D:continue
		for child in item.find_children("*","Sprite2D",true,false):
			if child.z_index<0 or child.texture==null:continue
			occluders.append(child)
			if not images.has(child.texture):images[child.texture]=child.texture.get_image()
func opaque_at(art:Sprite2D,p:Vector2)->bool:
	var rect:Rect2=art.get_rect();var local:Vector2=art.to_local(p)
	if not rect.has_point(local):return false
	var uv:=local-rect.position
	if art.region_enabled:uv+=art.region_rect.position
	var im:Image=images[art.texture]
	var v:=Vector2i(uv)
	return v.x>=0 and v.y>=0 and v.x<im.get_width() and v.y<im.get_height() and im.get_pixelv(v).a>.35
func refresh()->void:
	blocked=false
	if town.in_hall or town.view_mode!=1:overlay.hide();return
	var actor:Node2D=town.actor;var sprite:Sprite2D=actor.get_node("Sprite2D")
	for art in occluders:
		if not art.is_visible_in_tree() or actor.global_position.y>=art.get_parent().global_position.y:continue
		for h in [35.0,75.0,105.0]:
			if opaque_at(art,actor.global_position-Vector2(0,h)):blocked=true;break
		if blocked:break
	overlay.visible=blocked
	if not blocked:return
	overlay.texture=sprite.texture;overlay.hframes=sprite.hframes;overlay.vframes=sprite.vframes;overlay.frame=sprite.frame
	overlay.flip_h=sprite.flip_h;overlay.flip_v=sprite.flip_v;overlay.centered=sprite.centered;overlay.offset=sprite.offset
	overlay.global_transform=sprite.global_transform
