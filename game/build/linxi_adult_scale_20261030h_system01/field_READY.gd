extends "res://build/sect_completion_20261030a_system01/sect_field.gd"
const LOC=preload("res://build/four_settlements_20261030e_system01/locations.gd")
const ADULT_VISUAL=preload("res://build/linxi_adult_scale_20261030h_system01/adult_visual.gd")
var _adult_visual_receipts: Array[Dictionary]=[]
func _load_scene(id:StringName)->SceneScript:
	if not LOC.IDS.has(id):return null
	var scene:SceneScript=load("res://data/scenes/"+String(id)+".tres").duplicate(false)
	scene.actor_positions_are_feet=true
	return scene
func _setup_scene(scene:SceneScript,spawn:Variant=null,progressive:bool=false)->void:
	super._setup_scene(scene,spawn,progressive)
	if _field_loading_failed:return
	_setup_world_travel_minimap(scene)
func get_world_town_debug()->Dictionary:
	return {"id":_current_scene.scene_id,"source_scene":row.scene}
func _setup_world_travel_minimap(scene:SceneScript)->void:
	if not is_instance_valid(_primary_hud):return
	var map:Control=load("res://build/four_settlements_20261030e_system01/minimap.gd").new()
	map.name="CityLocalMinimap";_primary_hud.add_child(map)
	if map.configure(self,scene,_player,_world_camera,world_container):_world_travel_minimap=map
	else:map.queue_free()
func prepare_rows(scene:SceneScript)->void:
	var layout:Dictionary=native_town.layout.business
	npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true);interaction_rows=scene.map_layout.interactions.duplicate(true)
	for d:Dictionary in npc_rows:
		var a:Array=layout.npcs.get(d.npc_id,[])
		if a.is_empty():
			for prefix in layout.get("npc_prefixes",{}):
				if String(d.npc_id).begins_with(prefix):a=layout.npc_prefixes[prefix];break
		assert(not a.is_empty());d.pos=Vector2(a[0],a[1])/_world_size
	for d:Dictionary in portal_rows:
		var target:String=String(d.get("target_scene","world_map_jianghu" if d.get("action","")=="world_map" else ""))
		var a:Array=layout.portal_targets.get(target,layout.portals.get(d.id,[]));assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(110,86)/_world_size;d.marker_offset=Vector2.ZERO;d.show_destination_label=true
	for d:Dictionary in interaction_rows:
		var a:Array=layout.interactions.get(d.id,[]);assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(125,100)/_world_size;d.sect_floor=native_town.terrain.level_at(Vector2(a[0],a[1]));d.visual_baked=true


func _spawn_npcs(npc_data: Array) -> void:
	var first: int=_npc_nodes.size()
	super._spawn_npcs(npc_data)
	if _field_loading_failed or _current_scene==null or not ADULT_VISUAL.SCENES.has(_current_scene.scene_id):return
	if first==0:_adult_visual_receipts.clear()
	for i: int in range(first,_npc_nodes.size()):
		var receipt: Dictionary=ADULT_VISUAL.apply(_npc_nodes[i])
		_adult_visual_receipts.append(receipt)
		if receipt.get("ok")!=true:
			_field_loading_failed=true
			push_error("LINXI_ADULT_VISUAL_PROTECTION_FAILED:"+String(receipt.get("npc_id",""))+":"+String(receipt.get("reason","body/business/foot changed")))
			return

func get_linxi_adult_visual_debug() -> Dictionary:
	return {"scene_id":String(_current_scene.scene_id) if _current_scene!=null else "","scope":ADULT_VISUAL.SCENES,"records":_adult_visual_receipts.duplicate(true),"original_scene_and_NPCNode_sources_changed":false}
