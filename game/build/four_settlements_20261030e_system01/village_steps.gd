extends "res://scripts/drafts/sect_maps_20261029k/terrain.gd"

# The visible treads flare toward the bottom. The old fixed 45 px test let
# feet enter the flared part without ever changing floor.
func before_move(velocity: Vector2) -> Vector2:
	if active_ramp < 0:
		var p: Vector2 = town.actor.global_position
		for i in ramps.size():
			var ramp: Dictionary = ramps[i]
			var top: float = ramp.top[1]
			var bottom: float = ramp.bottom[1]
			var ascending := actor_level == int(ramp.low) and velocity.y < 0.0 and p.y >= top and p.y <= bottom + 34.0
			var descending := actor_level == int(ramp.high) and velocity.y > 0.0 and p.y <= bottom and p.y >= top - 34.0
			var half_width := 123.0 if ascending else float(data.portal_half_width)
			if (ascending or descending) and absf(p.x - float(ramp.top[0])) < half_width:
				active_ramp = i
				apply_actor_mask()
				break
	return super.before_move(velocity)
