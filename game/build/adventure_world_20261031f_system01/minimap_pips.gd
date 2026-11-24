extends Control
const LINKS=preload("res://build/adventure_world_20261031f_system01/world_links.gd")
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	var rect: Rect2=get_parent().get("_map_rect")
	if rect.size==Vector2.ZERO:return
	for row: Dictionary in LINKS.portal_rows():
		var p: Vector2=rect.position+row.world_foot/LINKS.WORLD_SIZE*rect.size
		draw_circle(p,3.6,Color(.05,.08,.06,.95))
		draw_circle(p,2.4,Color(.60,.90,.55,1))
func get_debug_state() -> Dictionary:return {"portals":LINKS.portal_rows(),"added_count":3,"view_only":true}
