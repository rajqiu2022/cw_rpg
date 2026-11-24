extends SceneTree
## ROOT-only dynamic source/storage check. No Field node or map transitions.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	for path: String in ["res://scripts/city/luoyang_assembled_rooms_20261016b.gd","res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd","res://scripts/city/luoyang_assembled_interiors_20261016g.gd","res://scripts/field/field_walkable_controller.gd"]:
		var script: Script=load(path) as Script
		if script==null or not script.can_instantiate(): printerr("CANDIDATE_ROOM_SCRIPT_REFUSED ",path); quit(1); return
	var rooms: Script=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd") as Script
	var config: Dictionary=rooms.catalogue()
	if config.get("rooms",{}).size()!=11: quit(1); return
	var loaded: int=0; var known: int=0; var disabled: int=0
	for row: Dictionary in config.rooms.values():
		if row.get("reuse_existing_accepted")==true: continue
		var scene: SceneScript=load(String(row.scene_path)) as SceneScript
		if scene==null or not scene.actor_positions_are_feet or scene.scene_id!=StringName(row.scene_id): quit(1); return
		loaded+=1
		if rooms.known(scene.scene_id):
			if not rooms.matches(scene,scene.scene_id): printerr("CANDIDATE_ROOM_STORAGE_REFUSED ",scene.scene_id); quit(1); return
			known+=1
		else: disabled+=1
	var active: bool=rooms.enabled()
	print("CANDIDATE_ROOM_SOURCES ",JSON.stringify({"can_instantiate":true,"new_scenes":loaded,"flag_enabled":active,"new_known":known,"new_disabled":disabled,"formal":rooms.FORMAL_ENABLED,"no_field_instance_or_transitions":true}))
	quit(0 if loaded==10 and ((active and known==7 and disabled==3) or (not active and known==0 and disabled==10)) else 1)
