extends RefCounted
## Authored source-space footprints and hand occlusion for the battle-only art.
const Carry = preload("res://scripts/appearance/weapon_carry_data.gd")
const Legendary = preload("res://scripts/appearance/legendary_weapon_data.gd")
const Frames = preload("res://art/characters/battle_stances_20261109/combat_pose_frames.gd")
const ReadyLoops = preload("res://art/characters/battle_ready_loops_20261109/ready_loop_frames.gd")
const ROOT := "res://art/characters/battle_stances_20261109/"
const READY_ROOT := "res://art/characters/battle_ready_loops_20261109/"

static func ready_clip(appearance: String) -> String:
	if appearance in ["unarmed", "immortal_gauntlets"] or Legendary.WEAPONS.get(appearance, {}).get("concealed", false):
		return "ready_palm"
	if appearance in ["plain_blade", "jinhe_duanyue_blade", "tiger_roar_blade", "buddha_subduing_staff"]:
		return "ready_blade"
	return "ready_staff" if Carry.carries_on_back(appearance) else "ready_sword"

static func staff_near_grip_y(appearance: String) -> float:
	if appearance == "plain_staff":
		return 735.0
	return 1110.0

static func install(clips: Dictionary, textures: Dictionary) -> void:
	_install_rows(Frames.DATA, ROOT, clips, textures)
	_install_rows(ReadyLoops.DATA, READY_ROOT, clips, textures)

static func _install_rows(rows: Dictionary, directory: String, clips: Dictionary, textures: Dictionary) -> void:
	for key: String in rows:
		var row: Dictionary = rows[key]
		var path: String = directory + String(row.file)
		if not ResourceLoader.exists(path) or (FileAccess.file_exists(path) and FileAccess.get_sha256(path) != row.sha):
			continue
		var texture := load(path) as Texture2D
		if texture == null or texture.get_size() != _point(row.size):
			continue
		var frames: Array = []
		for spec: Dictionary in row.frames:
			var ratio: float = spec.source_scale
			var foot := _point(spec.foot) * ratio
			var near := _point(spec.near) * ratio
			var grip := _point(spec.get("grip", spec.near)) * ratio
			var far := _point(spec.far) * ratio
			var region: Array = spec.region
			frames.append({
				"texture": key, "cell_index": frames.size(),
				"region": Rect2(region[0],region[1],region[2],region[3]),
				"source_scale": ratio, "foot": [foot.x,foot.y],
				"hand_center": [near.x,near.y], "far_hand": far,
				"grip": [grip.x,grip.y], "angle": float(spec.get("angle",0.0)), "weapon_z": 3,
				"fingers": _outline(spec.get("fingers",[])), "far_fingers": _outline(spec.get("far_fingers",[])),
				"weapon_grips": {"seven_star_sword":[512,1120], "jinhe_duanyue_blade":[512,1045]},
			})
		textures[key] = texture
		clips[key] = {"cell": row.size, "frames": frames}

static func _point(pair: Array) -> Vector2:
	return Vector2(pair[0],pair[1])

static func _outline(raw: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for pair: Array in raw:
		points.append(_point(pair))
	return points
