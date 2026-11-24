extends "res://scripts/world/v14_modular_overlap.gd"

# Ground contact along the granite sprite, sampled in its own source pixels.
const EDGE := [
	Vector2(249,526),Vector2(350,876),Vector2(450,918),Vector2(550,891),
	Vector2(650,911),Vector2(750,912),Vector2(850,873),Vector2(950,890),
	Vector2(1050,901),Vector2(1150,877),Vector2(1250,894),Vector2(1350,885),
	Vector2(1450,904),Vector2(1550,938),Vector2(1650,934),Vector2(1750,959),
	Vector2(1850,974),Vector2(1965,889)
]

func refresh(player: Player, force: bool = false) -> void:
	for prop: Dictionary in _props:
		if not String(prop.id).begins_with("granite_ridge_") or not is_instance_valid(prop.sprite):continue
		var sprite: Sprite2D=prop.sprite
		var local_x: float=sprite.to_local(player.global_position).x
		var front:=Vector2(1107,976)
		if local_x>=EDGE[0].x and local_x<=EDGE[-1].x:
			for i in range(1,EDGE.size()):
				if local_x<=EDGE[i].x:
					var y:=lerpf(EDGE[i-1].y,EDGE[i].y,inverse_lerp(EDGE[i-1].x,EDGE[i].x,local_x))
					front=Vector2(local_x,y)
					break
		prop.foot_local=front
		for entry: Dictionary in _depth_entries:
			if entry.node==sprite:
				entry.foot_local=front
				break
	super.refresh(player,force)
