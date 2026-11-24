extends "res://build/lanxi_boardwalk_edges_20261031a_system01/boardwalk_controller.gd"
## Four declared paddy moves only; all31a/30l compatibility remains inherited.
const PADDY_MOVES := {
	"Paddy1":{"old":Vector2(6960,1260),"return_foot":Vector2(6600,1440),"old_body":[[-446.6409,-66.6],[446.6409,-66.6],[446.6409,0],[-446.6409,0]]},
	"Paddy2":{"old":Vector2(7110,1660),"return_foot":Vector2(6750,1880),"old_body":[[-410.42676,-61.2],[410.42676,-61.2],[410.42676,0],[-410.42676,0]]},
	"Paddy3":{"old":Vector2(7270,2120),"return_foot":Vector2(6750,2280),"old_body":[[-386.28403,-57.6],[386.28403,-57.6],[386.28403,0],[-386.28403,0]]},
	"Paddy4":{"old":Vector2(7070,2820),"return_foot":Vector2(6500,2880),"old_body":[[-386.28403,-57.6],[386.28403,-57.6],[386.28403,0],[-386.28403,0]]}
}
var paddy_migration: Dictionary={"migrated":false,"reason":"NOT_EVALUATED"}

func _ready() -> void:
	super._ready()
	_restore_paddy_foot.call_deferred()

func _paddy_full_foot_clear(foot: Vector2,old_paddies: bool) -> bool:
	var contact:=actor.get_node("CollisionShape2D") as CollisionShape2D
	var full:=RectangleShape2D.new();full.size=Vector2(35,25)
	var transform:=contact.global_transform;transform.origin+=foot-actor.global_position
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=full;query.transform=transform
	query.collision_mask=actor.collision_mask;query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0.0
	var excluded: Array[RID]=[];excluded.append(actor.get_rid())
	if old_paddies:
		for name: String in PADDY_MOVES:
			excluded.append((get_node("Town/"+name+"/Body") as StaticBody2D).get_rid())
	query.exclude=excluded
	if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():return false
	if old_paddies:
		for name: String in PADDY_MOVES:
			var item:=get_node("Town/"+name) as Node2D
			var body:=item.get_node("Body") as StaticBody2D
			if (body.collision_layer&actor.collision_mask)==0:continue
			var points:=PackedVector2Array()
			for pair: Array in PADDY_MOVES[name].old_body:points.append(Vector2(float(pair[0]),float(pair[1])))
			var previous: Transform2D=(item.get_node("Body/Outline") as CollisionPolygon2D).global_transform
			previous.origin+=get_node("Town").to_global(PADDY_MOVES[name].old)-item.global_position
			if _overlap_points(full,transform,points,previous):return false
	return true

func _restore_paddy_foot() -> void:
	await get_tree().physics_frame
	if not is_inside_tree() or not is_instance_valid(actor) or in_hall or terrain.active_ramp>=0 or terrain.actor_level!=1:
		paddy_migration={"migrated":false,"reason":"UNCHANGED_NOT_OUTDOOR_L1"};return
	var owner_scene: Node=get_tree().current_scene
	if not is_instance_valid(owner_scene) or owner_scene.get("native_town")!=self:
		paddy_migration={"migrated":false,"reason":"UNCHANGED_NOT_CURRENT_OWNER"};return
	var contact:=actor.get_node("CollisionShape2D") as CollisionShape2D
	var before: Vector2=actor.global_position
	for name: String in PADDY_MOVES:
		var item:=get_node("Town/"+name) as Node2D
		var outline:=item.get_node("Body/Outline") as CollisionPolygon2D
		if not outline_overlap(contact.shape,contact.global_transform,outline,outline.global_transform):continue
		paddy_migration={"migrated":false,"paddy":name,"before":before,"reason":"UNCHANGED_OLD_WORLD_NOT_CLEAR"}
		if not _paddy_full_foot_clear(before,true):return
		var destination: Vector2=get_node("Town").to_global(PADDY_MOVES[name].return_foot)
		if terrain.level_at(destination)!=1 or not _paddy_full_foot_clear(destination,false) or not foot_clear(destination):
			paddy_migration.reason="UNCHANGED_DECLARED_BUND_NOT_CLEAR";return
		actor.global_position=destination
		paddy_migration={"migrated":true,"paddy":name,"before":before,"after":destination,"reason":"OLD_LEGAL_NEW_PADDY_BODY_ONLY_DECLARED_BUND"}
		update_view();return
	paddy_migration={"migrated":false,"reason":"UNCHANGED_NOT_NEW_PADDY_BODY"}

func get_paddy_passage_debug() -> Dictionary:
	var rows: Array[Dictionary]=[]
	for name: String in PADDY_MOVES:
		var item:=get_node("Town/"+name) as Node2D
		var art:=item.get_node("Art") as Sprite2D
		rows.append({"name":name,"ground_foot":item.global_position,"projected_foot":item.global_position-Vector2(0,120),"level":item.get_meta("terrain_level",0),"height":item.get_meta("elevation",0),"art_position":art.position,"art_scale":art.scale,"body_polygon":(item.get_node("Body/Outline") as CollisionPolygon2D).polygon,"declared_return":PADDY_MOVES[name].return_foot})
	return {"paddies":rows,"migration":paddy_migration.duplicate(true),"actor_foot":actor.global_position,"actor_level":terrain.actor_level,"actor_height":terrain.actor_height,"active_ramp":terrain.active_ramp,"boardwalk_controller_inherited":true}
