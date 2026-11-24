extends RefCounted
## Root-only publication transform. Not a new NPC runtime or a global idle fix.
## Select one existing authored pose without producing or editing PNG pixels.
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const HOME := "res://build/luoyang_quality_20261101b_seated01/"
const POSES := {
	"yihongyuan27n_elder_guest": {
		"before": "res://art/characters/npc_inn_tea_guest_left_seated_idle_down_25d_4f_v2_runtime.png",
		"after": HOME + "elder_front_pose.tres"
	},
	"yihongyuan27n_woman_guest": {
		"before": "res://art/characters/npc_inn_tea_guest_right_seated_idle_down_25d_4f_v2_runtime.png",
		"after": HOME + "woman_front_pose.tres"
	}
}

static func apply(source: Dictionary) -> Dictionary:
	if source.get("id") != ROOM or not source.get("npcs") is Array or source.npcs.size() != 6:
		return {"ok": false, "error": "SEATED_EXACT_ROOM_SIX_ACTORS"}
	var room: Dictionary = source.duplicate(true)
	var changed: Array[String] = []
	for id: String in POSES:
		var matches: Array = room.npcs.filter(func(row: Dictionary) -> bool: return row.get("data", {}).get("npc_id") == id)
		if matches.size() != 1:
			return {"ok": false, "error": "SEATED_UNIQUE_ACTOR:" + id}
		var row: Dictionary = matches[0]
		var data: Dictionary = row.data
		var pose: Dictionary = POSES[id]
		if row.get("logical_id") != LOGICAL or row.get("slot_key") != LOGICAL + "/" + id:
			return {"ok": false, "error": "SEATED_EXACT_LOGICAL_SLOT:" + id}
		if data.get("sprite_path") != pose.before or data.get("movement_mode") != "seated" or data.get("conversation_base_facing") != "front":
			return {"ok": false, "error": "SEATED_ORIGINAL_VISUAL_STATE:" + id}
		if not String(data.get("dialog_id", "")).is_empty() or not String(data.get("interaction_action", "")).is_empty() or source.get("yihongyuan_daily", {}).has(id):
			return {"ok": false, "error": "SEATED_AMBIENT_NOT_DIALOG_ACTOR:" + id}
		if source.get("sources", {}).get(pose.before) != FileAccess.get_sha256(pose.before):
			return {"ok": false, "error": "SEATED_ORIGINAL_MEDIA_PIN:" + id}
		if not FileAccess.file_exists(pose.after):
			return {"ok": false, "error": "SEATED_NEW_POSE_RESOURCE:" + id}
		var texture: Texture2D = load(pose.after) as Texture2D
		if not texture is AtlasTexture or texture.get_width() != 160 or texture.get_height() != 160:
			return {"ok": false, "error": "SEATED_POSE_NATIVE_FRAME:" + id}
		var atlas: AtlasTexture = texture as AtlasTexture
		if atlas.atlas == null or atlas.atlas.resource_path != pose.before or atlas.region != Rect2(160, 0, 160, 160) or atlas.margin != Rect2() or not atlas.filter_clip:
			return {"ok": false, "error": "SEATED_POSE_EXACT_ORIGINAL_FRAME:" + id}
		data.sprite_path = pose.after
		room.sources[pose.after] = FileAccess.get_sha256(pose.after)
		changed.append(id)
	# Typed inverse: all other actor data, body sizes/feet/physics, original
	# sources, dialogue, all four speakers and every room field are inherited.
	var inverse: Dictionary = room.duplicate(true)
	for row: Dictionary in inverse.npcs:
		var id: String = String(row.get("data", {}).get("npc_id", ""))
		if POSES.has(id): row.data.sprite_path = POSES[id].before
	inverse.sources = source.sources.duplicate(true)
	if var_to_bytes(inverse) != var_to_bytes(source):
		return {"ok": false, "error": "SEATED_TYPED_INVERSE_ALL_ELSE_IDENTICAL"}
	return {"ok": true, "room": room, "changed_actor_ids": changed, "frame_region": Rect2(160, 0, 160, 160), "new_pngs": 0, "global_npc_writes": 0, "all_else_typed_identical": true}
