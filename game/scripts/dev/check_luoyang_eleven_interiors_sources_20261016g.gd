extends SceneTree
## ROOT-only compile/storage probe. No Field, transition, game actions or saves.
const MODULE="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const FADE="res://scripts/city/luoyang_assembled_interiors_fade_20261016g.gd"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	var module: Script=load(MODULE) as Script
	var fade: Script=load(FADE) as Script
	if module==null or fade==null or not module.can_instantiate() or not fade.can_instantiate(): quit(1); return
	var config: Dictionary=module.catalogue()
	var count: int=0
	for row: Dictionary in config.get("rooms",{}).values():
		if row.get("reuse_existing_accepted")==true: continue
		var scene: SceneScript=load(String(row.scene_path)) as SceneScript
		var layout: WalkableMapLayout=load(String(row.layout_path)) as WalkableMapLayout
		if scene==null or layout==null or scene.scene_id!=StringName(row.scene_id) or scene.map_layout!=layout or not scene.actor_positions_are_feet: quit(1); return
		count+=1
	print("ELEVEN_ROOM_SOURCES_COMPILE ",JSON.stringify({"scripts_can_instantiate":true,"catalogue":config.get("rooms",{}).size(),"new_scenes_loaded":count,"smith_reused_unchanged":config.get("rooms",{}).get("luoyang_market_shop_interior_20261015",{}).get("reuse_existing_accepted")==true,"production_hooks":false}))
	quit(0 if count==10 and config.get("rooms",{}).size()==11 else 1)
