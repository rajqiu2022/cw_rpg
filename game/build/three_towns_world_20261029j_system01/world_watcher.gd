extends Node
## Installs the three independently guarded additions on each real v15 owner.
const TOWNS=preload("res://build/three_towns_world_20261029j_system01/town_registry.gd")
const DOOR=preload("res://scripts/field/world_v15_exit_zone.gd")
const WORLD31C=preload("res://build/world_landmarks_20261031c/refinement.gd")
const DEPTH31D=preload("res://build/environment_residual_20261031d_system01/landmark_depth.gd")
var world_owner: Node
var overlay_root: Node2D
var world_nodes: Array[ExitZone]=[]
var owner_validated:=false

func _process(_delta: float) -> void:
	var field: Node=get_tree().current_scene
	if not is_instance_valid(field):return
	_update_map(field)
	if not TOWNS.is_v15_world(field) or not bool(field.get("_field_loading_complete")):return
	if field!=world_owner:
		world_owner=field
		world_nodes.clear()
		owner_validated=TOWNS.source_valid()
		if owner_validated:_attach_world(field)
	if owner_validated:_update_minimap(field)

func _attach_world(field: Node) -> void:
	var world: Node2D=field.get("world_container")
	var actor: Player=field.get("_player")
	if not is_instance_valid(world) or not is_instance_valid(actor):return
	overlay_root=Node2D.new()
	overlay_root.name="ThreeTownWorldAdditions"
	overlay_root.set_meta("registry_source",TOWNS.ROOT+"native_sources.json")
	world.add_child(overlay_root)
	# The visual groups / authored feet come from an independent, pinned source packet.
	var spec: Dictionary=_world_spec()
	if spec.is_empty():
		owner_validated=false
		overlay_root.queue_free()
		return
	_add_world_visuals(spec)
	for row: Dictionary in TOWNS.portal_rows():
		var zone: ExitZone=(load("res://scenes/exit_zone.tscn") as PackedScene).instantiate()
		zone.set_script(DOOR)
		zone.name=String(row.id)
		zone.position=row.world_foot
		zone.exit_label="进入"+String(row.label)
		zone.destination_name=String(row.label)
		zone.target_scene_id=String(row.target_scene)
		zone.target_spawn_pos=row.target_pos
		zone.always_show_destination=true
		zone.set_meta("portal_id",row.id)
		zone.set_meta("source_spawn_pos",row.source_spawn_pos)
		zone.set_meta("three_town_registry",TOWNS.ROOT+"town_registry.gd")
		zone.set_meta("source_scene",row.source_scene)
		overlay_root.add_child(zone)
		var foot: Vector2=row.world_foot
		var polygon:=PackedVector2Array([foot+Vector2(-44,-35),foot+Vector2(44,-35),foot+Vector2(44,60),foot+Vector2(-44,60)])
		zone.call("configure_doorway",polygon,actor,Callable(self,"_world_door_safe").bind(field,row,spec))
		zone.configure_marker(foot,TOWNS.WORLD_SIZE)
		zone.exit_triggered.connect(func(_target: String,_spawn: Vector2) -> void:TOWNS.enter_from_world(field,row))
		var live: Array=field.get("_exit_nodes")
		live.append(zone)
		world_nodes.append(zone)
	overlay_root.set_meta("portal_count",3)
	overlay_root.set_meta("foreground_name_count",WORLD31C.raise_names(field))

func _world_door_safe(global_foot: Vector2,field: Node,row: Dictionary,spec: Dictionary) -> bool:
	if field!=world_owner or not is_instance_valid(field) or not owner_validated:return false
	if not bool(field.get("_field_loading_complete")) or bool(field.get("_system_panel_open")) or DialogPlayer.is_playing():return false
	if not TOWNS.is_v15_world(field):return false
	var world: Node2D=field.get("world_container")
	var foot: Vector2=world.to_local(global_foot)
	var contract: Variant=SceneRouter.layered_world_contract(field.get("_current_scene"))
	if not contract.safe_foot(field.get("_current_scene"),foot/TOWNS.WORLD_SIZE):return false
	var stream: Variant=field.get("_world_v15_stream")
	if not is_instance_valid(stream) or not stream.visual_ready_for_motion(foot):return false
	var actor: Player=field.get("_player")
	if not TOWNS.actor_shape_clear(actor):return false
	var contact: CollisionShape2D=actor.get_node("CollisionShape2D")
	var radius: float=contact.shape.radius if contact.shape is CircleShape2D else 17.5
	var own: Dictionary=spec.towns.get(String(row.target_scene),{})
	if own.is_empty():return false
	var declared: Array=own.door_foot
	if Vector2(declared[0],declared[1])!=row.world_foot:return false
	# Added landmark collisions use the same source as their render geometry.
	for city: Dictionary in spec.towns.values():
		for raw: Array in city.get("blockers",[]):
			var polygon:=PackedVector2Array()
			for p: Array in raw:polygon.append(Vector2(p[0],p[1]))
			if Geometry2D.is_point_in_polygon(foot,polygon):return false
			for i: int in range(16):
				var angle:=TAU*float(i)/16.0
				if Geometry2D.is_point_in_polygon(foot+Vector2(cos(angle),sin(angle))*radius,polygon):return false
	return true

func _world_spec() -> Dictionary:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(TOWNS.ROOT+"world_spec.json"))
	if not data is Dictionary or data.get("landmarks",[]).size()!=3:return {}
	var result: Dictionary={"towns":{},"roads":[]}
	for raw: Dictionary in data.routes:
		result.roads.append({"width":raw.width_px,"points":raw.points_px,"source_id":raw.id})
	var ids: Dictionary={"redrock_town":"openworld_redrock_town","desert_town":"openworld_desert_city","lanxi_zhai":"openworld_lanxi_zhai"}
	for raw: Dictionary in data.landmarks:
		if not ids.has(String(raw.id)):return {}
		var city: Dictionary={"door_foot":raw.door_foot_px,"blockers":raw.solid_polygons_px,"sprites":[]}
		for sprite: Dictionary in WORLD31C.sprites(raw):
			city.sprites.append({"path":sprite.texture,"position":sprite.origin_px,"scale":sprite.scale,"foot":sprite.foot_px})
		result.towns[ids[String(raw.id)]]=city
	return result

func _add_world_visuals(spec: Dictionary) -> void:
	for raw: Dictionary in spec.get("roads",[]):
		var path: PackedVector2Array=WORLD31C.route(raw)
		for polygon: PackedVector2Array in Geometry2D.offset_polyline(path,float(raw.width)*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			var ground:=Polygon2D.new()
			ground.polygon=polygon
			var uv:=PackedVector2Array()
			for point: Vector2 in polygon:uv.append(point*2.0)
			ground.uv=uv
			ground.texture=load("res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg")
			ground.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
			ground.z_index=-9
			WORLD31C.blend_path(ground,raw,path)
			overlay_root.add_child(ground)
	for id: String in spec.towns:
		var city: Dictionary=spec.towns[id]
		var group:=Node2D.new()
		group.name=id
		group.set_meta("source_foot",city.door_foot)
		overlay_root.add_child(group)
		for raw: Dictionary in city.get("sprites",[]):
			var sprite:=Sprite2D.new()
			sprite.texture=WORLD31C.texture(raw.path)
			sprite.centered=false
			sprite.position=Vector2(raw.position[0],raw.position[1])
			sprite.scale=Vector2.ONE*float(raw.scale)
			sprite.z_as_relative=false
			sprite.z_index=clampi(roundi(float(raw.foot[1])/8.0),-4096,4095)
			DEPTH31D.align(sprite,world_owner.get("_actor_layer") as Node2D)
			group.add_child(sprite)
		for raw: Array in city.get("blockers",[]):
			var body:=StaticBody2D.new()
			body.collision_layer=1
			body.collision_mask=0
			var shape:=CollisionPolygon2D.new()
			var points:=PackedVector2Array()
			for p: Array in raw:points.append(Vector2(p[0],p[1]))
			shape.polygon=points
			body.add_child(shape)
			group.add_child(body)

func _update_map(field: Node) -> void:
	# Map UI gets a read-only view, never a replacement map_layout or navigation cache.
	if not _has_property(field,"_world_map_panel"):return
	var panel: Variant=field.get("_world_map_panel")
	if not is_instance_valid(panel) or not panel.visible:return
	if not TOWNS.WORLDS.has(SceneRouter.get_active_world_map_scene()):return
	var rect: Control=panel.map_rect
	for row: Dictionary in TOWNS.portal_rows():
		var found:=false
		for child: Node in rect.get_children():
			if not child.is_queued_for_deletion() and child.get_meta("three_town_map_id","")==row.id:found=true;break
		if found:continue
		panel.call("_build_location_label",row)
		var label: Node=rect.get_child(rect.get_child_count()-1)
		label.set_meta("three_town_map_id",row.id)

func _update_minimap(field: Node) -> void:
	var mini: Variant=field.get("_world_travel_minimap")
	if not is_instance_valid(mini) or mini.has_node("ThreeTownPips"):return
	var pips: Control=load(TOWNS.ROOT+"minimap_pips.gd").new()
	pips.name="ThreeTownPips"
	mini.add_child(pips)

func _has_property(node: Object,key: String) -> bool:
	for prop: Dictionary in node.get_property_list():
		if prop.name==key:return true
	return false

func get_debug_state() -> Dictionary:
	return {"owner":world_owner,"source_valid":owner_validated,"added_door_count":world_nodes.size(),"total_door_count":world_owner.get("_exit_nodes").size() if is_instance_valid(world_owner) else 0,"portals":TOWNS.portal_rows()}
