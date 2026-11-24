extends SceneTree

var router: Node
var field: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	field=load("res://scripts/field/field_walkable_controller.gd").new()
	var result := {"scenes":{}, "quests":{}, "plans":{}, "dialogs":{}}
	for chapter in range(1,9):
		var plan := load("res://data/chapters/chapter_%d_content_plan.tres" % chapter) as ChapterContentPlan
		result.plans[chapter]={"entry":router.get_chapter_entry(chapter),"main":plan.main_quest_ids,"side":plan.side_quest_ids,"maps":plan.main_scene_ids}
	for file in DirAccess.get_files_at("res://data/scenes"):
		if file.ends_with(".tres"):
			var id := StringName(file.trim_suffix(".tres"))
			_read_scene(id,result.scenes)
	for plan: Dictionary in result.plans.values():
		for id: StringName in plan.maps:
			if not result.scenes.has(id): _read_scene(id,result.scenes)
	for file in DirAccess.get_files_at("res://data/quests"):
		if not file.ends_with(".tres"): continue
		var quest := load("res://data/quests/"+file) as QuestDef
		if quest:
			result.quests[quest.quest_id]={"title":quest.title,"kind":quest.kind,"auto":quest.auto_accept_triggers,"complete":quest.completion_triggers,"all":quest.require_all_completion_triggers,"independent":quest.chapter_independent}
	for file in DirAccess.get_files_at("res://data/dialogs"):
		if not file.ends_with(".tres"): continue
		var dialog := load("res://data/dialogs/"+file) as DialogScript
		if not dialog: continue
		var rows: Array=[]
		for node in dialog.nodes:
			rows.append({"id":node.node_id,"action":node.on_end,"choices":node.choices,"flags":node.set_flags,"accept":node.accept_quest,"complete":node.complete_quest})
		result.dialogs[file.trim_suffix(".tres")]={"entry":dialog.entry_node_id,"nodes":rows}
	field.free()
	FileAccess.open("res://build/quest_map_audit_20261108/runtime_inventory.json",FileAccess.WRITE).store_string(JSON.stringify(result))
	print("QUEST_MAP_AUDIT scenes=",result.scenes.size()," quests=",result.quests.size()," dialogues=",result.dialogs.size())
	quit()

func _read_scene(id: StringName, scenes: Dictionary) -> void:
	var path: String=router.field_scene_resource_path(id)
	var scene: SceneScript=router._load_field_scene_def(id)
	var resolved := scene!=null
	if scene==null and ResourceLoader.exists(path): scene=load(path) as SceneScript
	if scene==null:
		scenes[id]={"path":path,"missing":true}
		return
	var portals: Array=scene.exits
	var interactions: Array=scene.trigger_zones
	var objects: Array=scene.scene_objects
	if scene.is_walkable:
		if scene.map_layout!=null:
			portals=scene.map_layout.portals
			interactions=scene.map_layout.interactions
			objects=scene.map_layout.visual_objects
			if portals.is_empty() and interactions.is_empty():
				portals=field._legacy_hotspots_to_portals(scene.hotspots)
				interactions=field._legacy_hotspots_to_interactions(scene.hotspots)
		elif not scene.hotspots.is_empty():
			portals=field._legacy_hotspots_to_portals(scene.hotspots)
			interactions=field._legacy_hotspots_to_interactions(scene.hotspots)
	else:
		interactions=scene.hotspots
	var object_actions: Array=[]
	for row: Dictionary in objects:
		if row.has("interaction_action"): object_actions.append(row)
	scenes[id]={"path":path,"resolved":resolved,"id":scene.scene_id,"walkable":scene.is_walkable,"intro":scene.on_enter_dialog.dialog_id if scene.on_enter_dialog else "","npcs":scene.npcs,"portals":portals,"interactions":interactions,"objects":object_actions,"shadow_exits":scene.exits,"hotspots":scene.hotspots}
