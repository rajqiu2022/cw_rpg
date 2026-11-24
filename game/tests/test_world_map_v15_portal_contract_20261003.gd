extends "res://tests/test_world_map_v15_production_20261003.gd"
## Limited real-production door category. Never suppresses Field _ready,
## dialogue, collision, story, ExitZone signal, or SceneRouter travel.
## Optional --portal-id=luoyang --portal-mode=space selects one diagnostic case;
## the result remains LIMITED and cannot substitute for FULL acceptance.
func _default_phase() -> String:
	return "portal"
