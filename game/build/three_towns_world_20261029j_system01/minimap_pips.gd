extends Control
const TOWNS=preload("res://build/three_towns_world_20261029j_system01/town_registry.gd")
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	var rect: Rect2=get_parent().get("_map_rect")
	if rect.size==Vector2.ZERO:return
	for row: Dictionary in TOWNS.portal_rows():
		var p: Vector2=rect.position+row.pos*rect.size
		draw_circle(p,3.4,Color(.08,.08,.05,.9))
		draw_circle(p,2.3,Color(.95,.77,.30,1))
func get_debug_state() -> Dictionary:return {"portals":TOWNS.portal_rows(),"added_count":3,"view_only":true}
