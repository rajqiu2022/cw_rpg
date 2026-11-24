class_name BattleSpriteFacing
extends RefCounted

## Authored direction belongs to each source frame, never to ally/enemy side.
## Legacy atlases contain mixed-facing reaction rows; keep corrections here so
## ready, movement, strike and recoil all use the same presentation contract.
static func faces_right(texture: Texture2D, fallback: bool) -> bool:
	if texture == null:
		return fallback
	if texture.has_meta(&"authored_faces_right"):
		return bool(texture.get_meta(&"authored_faces_right"))
	var path := texture.resource_path
	# This legacy masked-boss set was painted facing right, unlike the
	# standard_v2 masked killer. Its enemy definitions mostly use flip=false.
	if path == "res://art/characters/battle_masked_killer_boss_v2.png" or path in [
		"res://art/sprites/battle/masked_killer_boss_attack_f01_v2.png",
		"res://art/sprites/battle/masked_killer_boss_attack_f02_v2.png",
		"res://art/sprites/battle/masked_killer_boss_attack_f03_v2.png",
	]:
		return true
	if path.contains("/dojo_senior/") and path.contains("_hit_"):
		return true
	if path.contains("/dojo_disciple/") and path.ends_with("_hit_01.png"):
		return true
	if path.contains("/weapon_variants_") or path.contains("/companions_") or path.contains("/bandit_mountain/") or path.contains("/lengguyun/"):
		return true
	if path.contains("/standard_v2/") or path.contains("/standard_v3/zhuwei_bandit/") or path.contains("/battle/ch5/") or path.contains("/battle/ch8/"):
		return false
	return fallback
