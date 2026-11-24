extends RefCounted

const TEXTURE := "res://art/characters/battle_victory_20261108/victory_salute.png"
const SHA256 := "27e98b44aca9bef04bf1e058f6c3356f164ad8257942c4b14d722fbfa386997f"
const CELL_WIDTH := 543
const CELL_HEIGHT := 724
# Cell-local right-hand center, thumb web and weapon pitch.
const SALUTE := [
	[Vector2(356, 279), Vector2(358, 268), 42.0],
	[Vector2(375, 184), Vector2(380, 174), 29.0],
	[Vector2(382, 106), Vector2(388, 95), 13.0],
	[Vector2(362, 216), Vector2(367, 205), 34.0],
]

static func clip() -> Dictionary:
	var frames: Array[Dictionary] = []
	for index in SALUTE.size():
		var hand: Vector2 = SALUTE[index][0]
		var web: Vector2 = SALUTE[index][1]
		frames.append({
			"texture": "victory", "cell_index": index, "cell_width": CELL_WIDTH, "cell_height": CELL_HEIGHT,
			"foot": [271, 717], "hand_center": [hand.x, hand.y],
			"grip": [web.x, web.y], "angle": SALUTE[index][2], "weapon_z": 3,
			"weapon_grips": {"seven_star_sword": [512, 1120], "jinhe_duanyue_blade": [512, 1045]},
		})
	return {"cell": [CELL_WIDTH, CELL_HEIGHT], "frames": frames}
