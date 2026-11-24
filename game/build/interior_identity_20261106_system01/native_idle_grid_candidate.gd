extends RefCounted
## Candidate for one RegionField call after add_child (and before first frame).
## Existing NPCNode and all old identities are outside this hook's ownership.
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const ART := "res://art/characters/yihongyuan_identity_20261106/"
const GRID := {
	"yihongyuan27n_musician": ["musician",Vector2i(523,951),Vector2(342,889),"1f3b2ba9af09ea00d4b3a21ab40f0133f2e0e00b6a01be1f6797733ce47c1974","seated",96.0/763.0,1.8],
	"yihongyuan27n_singer": ["singer",Vector2i(509,951),Vector2(250,901),"ac7963048c966f770e98f5cdad3dd70520af6519c7b1af1f4c5bc61df1ecb923","idle",121.0/840.0,1.4],
	"yihongyuan27n_tea_attendant": ["tea_attendant",Vector2i(508,952),Vector2(262,893),"bed8ec3aeae16d735a98bfde8e4801fa8fbe51bed214d3510df09d5d0cad9559","idle",116.0/827.0,1.4],
	"yihongyuan27n_receptionist": ["receptionist",Vector2i(508,951),Vector2(254,888),"2cccdcdaf499b90a0d1ffef33c22f948e545a8d9e304a0963081d3ecc74b2d55","idle",122.0/817.0,1.4],
}

static func prepare(field: Node, owner: RefCounted, source: Dictionary, actor: NPCNode) -> Dictionary:
	var actor_id: String = String(source.get("data",{}).get("npc_id",""))
	if not GRID.has(actor_id):
		return {"ok": true, "adopt": false}
	var room: Dictionary = field.get("_region")
	var scene: SceneScript = field.get("_current_scene")
	if room.get("id") != ROOM or scene == null or String(scene.scene_id) != ROOM or owner == null or owner.call("matches",field,scene) != true:
		return {"ok":false,"error":"YIHONG_IDLE_GRID_ROOM_OWNER"}
	if source.get("logical_id") != LOGICAL or source.get("slot_key") != LOGICAL+"/"+actor_id or source.get("ground_anchored") != true or source.get("body_offset_px") != Vector2.ZERO or source.get("node_origin_offset_px",Vector2.ZERO) != Vector2.ZERO:
		return {"ok":false,"error":"YIHONG_IDLE_GRID_SOURCE_ID"}
	var spec: Array = GRID[actor_id]
	var path: String = ART + String(spec[0]) + "_idle_native.png"
	var half: Vector2 = source.get("half_body",Vector2.ZERO)
	var cell: Vector2i = spec[1]
	var expected_half := Vector2(cell)*Vector2(0.07,0.09)*float(spec[5])
	if half.distance_to(expected_half) > 0.001 or actor.npc_id != actor_id or actor.sprite_path != path or actor.movement_mode != spec[4] or not is_equal_approx(actor.sprite_scale,float(spec[5])) or not is_equal_approx(actor.idle_frame_seconds,float(spec[6])):
		return {"ok":false,"error":"YIHONG_IDLE_GRID_ACTOR_FIELDS"}
	if not actor.dialog_id.is_empty() or not actor.interaction_action.is_empty() or not actor.walk_sprite_path.is_empty() or not actor.conversation_sprite_paths.is_empty():
		return {"ok":false,"error":"YIHONG_IDLE_GRID_AMBIENT_ONLY"}
	var first: Dictionary = owner.call("receipt").get("source_first",{})
	if first.get(path) != spec[3] or not first.has(path+".import"):
		return {"ok":false,"error":"YIHONG_IDLE_GRID_EXACT_MEDIA"}
	var texture := load(path) as Texture2D
	if texture == null or texture.resource_path != path or Vector2i(texture.get_size()) != Vector2i(cell.x*4,cell.y):
		return {"ok":false,"error":"YIHONG_IDLE_GRID_ATLAS_SIZE"}
	return {"ok":true,"adopt":true,"texture":texture,"cell":Vector2(cell),"anchor":spec[2],"half_body":half}

static func finish(actor: NPCNode, plan: Dictionary) -> bool:
	if plan.get("ok") != true: return false
	if plan.get("adopt") != true: return true
	var body := actor.get("_body_collider") as StaticBody2D
	if body == null or body.get_child_count() != 1 or actor.sprite == null or actor.sprite.texture != plan.texture or actor.get("_idle_texture") != plan.texture or actor.get("_calibrate_adult_body") == true:
		return false
	var collider := body.get_child(0) as CollisionShape2D
	var rectangle := collider.shape as RectangleShape2D if collider != null else null
	if rectangle == null or not (body.position+collider.position).is_zero_approx():
		return false
	# Correct the width computed from generic square-frame inference. This is
	# a newly added actor only, before any physics frame; authored half-body is
	# shared with the room validator and leaves the original foot unchanged.
	rectangle.size = plan.half_body*2.0
	actor.set("_hframes",4)
	actor.sprite.hframes = 4
	actor.sprite.vframes = 1
	actor.sprite.frame = 0
	actor.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var cell: Vector2 = plan.cell
	var anchor: Vector2 = plan.anchor
	actor.sprite.offset = cell*0.5-anchor-actor.sprite.position/actor.sprite.scale
	var painted_foot := actor.sprite.position + (anchor+actor.sprite.offset-cell*0.5)*actor.sprite.scale
	return painted_foot.length() < 0.001 and actor.sprite.hframes == 4
