extends "res://build/scene_quality_20261102c_qa01/NEW_DOMAIN_ROOT_ONLY.gd"
## Root-only residual of failed 128212. The two setup points are in MARKET,
## not YAMEN: actual immutable Civic district boundary is y=2200.
## Keep all coordinates, true inputs, body/route oracle and assertions inherited.
## No source guard, scene payload, object, actor, camera or save changes.
func near_region(id: String, logical: String, point: Vector2) -> Node:
	if id == CIVIC and logical == "ch4_s1_luoyang_yamen" and point in [Vector2(2500,2240), Vector2(1300,2225)]:
		return await super.near_region(id, "ch4_s3_luoyang_market", point)
	return await super.near_region(id, logical, point)
