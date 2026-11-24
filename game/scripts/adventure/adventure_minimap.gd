extends Control
## Static native terrain / building thumbnails, not an abstract schematic.
const IDS: Array[String]=["adventure_zhuwei_hunting_ground","adventure_xiangzhou_deep_mine","adventure_luoyang_riverside_route"]
var _chart := preload("res://scripts/ui/minimap_exploration.gd").new()
var _scene_id: String
var _field: Node
var _size: Vector2
var _viewport: SubViewport
var _map_surface: ColorRect
var _portrait: Control
var _capture_frames: int=0

func configure(field: Node) -> void:
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	if scene==null or String(scene.scene_id) not in IDS:queue_free();return
	_scene_id = String(scene.scene_id)
	_field=field;_size=field.get("_world_size")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	position=Vector2(1540,230);size=Vector2(352,268);mouse_filter=Control.MOUSE_FILTER_IGNORE
	var background:=ColorRect.new();background.color=Color(.015,.03,.04,.55)
	background.size=size;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(background)
	_viewport=SubViewport.new();_viewport.size=Vector2i((_size * minf(1.0, 2560.0 / maxf(_size.x, _size.y))).round()).maxi(1)
	_viewport.disable_3d=true;_viewport.transparent_bg=false;_viewport.world_2d=World2D.new()
	_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;add_child(_viewport)
	var world:=Node2D.new();world.scale=Vector2(_viewport.size) / _size;_viewport.add_child(world)
	if scene.streamed_background!=null:
		for chunk: Dictionary in scene.streamed_background.get_chunks(true):
			var floor:=Sprite2D.new();floor.texture=load(String(chunk.path));floor.centered=false
			floor.position=chunk.get("draw_position",chunk.logical_rect.position);floor.z_index=-1000
			floor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;world.add_child(floor)
	var riverside_ground: bool=false
	if String(scene.scene_id) in ["adventure_luoyang_riverside_route", "adventure_zhuwei_hunting_ground"]:
		riverside_ground=bool(load("res://build/riverside_visual_20261101a_system01/natural_ground.gd").add_ground(world,scene,_size))
	for row: Dictionary in scene.map_layout.travel_routes:
		if riverside_ground:continue
		var line:=Line2D.new();line.width=float(row.width_px);line.texture=load(String(row.texture))
		line.texture_mode=Line2D.LINE_TEXTURE_TILE;line.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		line.begin_cap_mode=Line2D.LINE_CAP_ROUND;line.end_cap_mode=Line2D.LINE_CAP_ROUND;line.joint_mode=Line2D.LINE_JOINT_ROUND
		line.z_index=-900
		var material:=ShaderMaterial.new();material.shader=load("res://scripts/adventure/soft_trail.gdshader");line.material=material
		for point: Vector2 in row.points:line.add_point(point*_size)
		world.add_child(line)
	for row: Dictionary in scene.map_layout.visual_objects:
		if String(row.get("texture","")).is_empty():continue
		var sprite:=Sprite2D.new();sprite.texture=load(String(row.texture));sprite.centered=bool(row.get("centered",true))
		sprite.position=row.get("pos",Vector2.ZERO)*_size;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var render: Variant=row.get("render_size_px")
		if render is Vector2:sprite.scale=render/sprite.texture.get_size()
		else:
			var scale_value: Variant=row.get("scale",Vector2.ONE)
			sprite.scale=Vector2.ONE*float(scale_value) if scale_value is float or scale_value is int else scale_value
		sprite.rotation_degrees=float(row.get("rotation",0))
		sprite.z_index=int(row.get("z_index",0))
		if row.get("sort_by_feet",false):sprite.z_index=clampi(int(float(row.get("depth_sort_foot_y",0))*_size.y/8),0,1024)
		world.add_child(sprite)
	_map_surface = background
	background.draw.connect(_draw_chart.bind(background))
	_portrait=load("res://scripts/ui/minimap_portrait.gd").new()
	add_child(_portrait)

func _process(_delta: float) -> void:
	if not is_instance_valid(_field) or _field!=get_tree().current_scene or not is_instance_valid(_portrait):return
	if _capture_frames<3:
		_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;_capture_frames+=1
	else:_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	var actor: Player=_field.get("_player") as Player
	if actor==null:return
	var world: Node2D=_field.get("world_container") as Node2D
	var uv: Vector2=world.to_local(actor.global_position)/_size
	var panel := Rect2(Vector2.ZERO, size).grow(-8)
	_chart.follow(_scene_id, uv, _size, panel.size)
	_portrait.call("sync_marker", _chart.project(uv, panel))
	_map_surface.queue_redraw()

func _draw_chart(surface: ColorRect) -> void:
	var panel := Rect2(Vector2.ZERO, size).grow(-8)
	_chart.draw_layer(surface, _viewport.get_texture(), panel)
	_chart.draw_layer(surface, _chart.texture, panel)
