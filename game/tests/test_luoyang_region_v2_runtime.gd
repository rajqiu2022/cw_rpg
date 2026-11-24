extends SceneTree

const IDS := ["ch4_s1_luoyang_yamen", "ch4_s3_luoyang_market", "ch4_s2_canal_docks", "openworld_huashan_forecourt"]
const DISTINCT_ART := {
	"ch4_s1_luoyang_yamen": "bg_luoyang_yamen_courtyard_v1.png",
	"ch4_s3_luoyang_market": "bg_luoyang_south_market_v1.png",
	"ch4_s2_canal_docks": "bg_luoyang_canal_docks_v1.png",
	"openworld_huashan_forecourt": "bg_huashan_region_composite_v2_2304.png",
}
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var router := root.get_node("SceneRouter")
	_check_huashan_lesson()
	for id: String in IDS:
		var scene := load("res://data/scenes/%s.tres" % id) as SceneScript
		var layout := scene.map_layout
		_check(scene.background_path.ends_with(DISTINCT_ART[id]), id + " owns its reviewed district art")
		_check(scene.hotspots.is_empty(), id + " has no invisible legacy hotspots")
		_check(scene.is_settlement, id + " is safe to visit before main story")
		_check(layout.design_size == Vector2i(2304,1536), id + " owns native art coordinates")
		if id == "ch4_s1_luoyang_yamen":
			var water: Dictionary = layout.interactions[1]
			var rubbing: Dictionary = layout.interactions[2]
			_check(water.pos == rubbing.pos, "water-rule deduction and rubbing share one stone carving")
			_check(water.hide_flag == rubbing.require_flag, "stone carving exposes only one investigation stage at a time")
			for entry in layout.interactions:
				_check(bool(entry.get("visual_baked", false)), "yamen investigation belongs to existing stonework or doorway, not loose inventory art")
		_check(_walkable(layout,scene.player_spawn), id + " default arrival is on road")
		for probe in layout.walkable_probes:
			_check(_walkable(layout,probe.pos), id + " road probe " + probe.id)
		for probe in layout.blocked_probes:
			_check(not _walkable(layout,probe.pos), id + " blocked probe " + probe.id)
		for npc in scene.npcs:
			_check(_walkable(layout,npc.pos), id + " NPC feet on road " + npc.npc_id)
			_check(ResourceLoader.exists(npc.sprite_path) and not "/portraits/" in npc.sprite_path, id + " real field sprite " + npc.npc_id)
		for interaction in layout.interactions:
			_check(_walkable(layout,interaction.pos), id + " interactive object reachable " + interaction.id)
			var has_sprite := not String(interaction.get("interaction_visual_kind", "")).is_empty()
			var has_baked_feature := bool(interaction.get("visual_baked", false)) and not String(interaction.get("baked_feature", "")).is_empty()
			_check(has_sprite or has_baked_feature, id + " visible object or identified scene feature " + interaction.id)
		for portal in layout.portals:
			_check(_walkable(layout,portal.pos), id + " exit on road " + portal.id)
			_check(String(portal.get("require_flag", "")).is_empty(), id + " district exit is not story locked")
			var target := String(portal.get("target_scene", ""))
			if target in IDS:
				var other := load("res://data/scenes/%s.tres" % target) as SceneScript
				_check(_walkable(other.map_layout,portal.target_pos), id + " paired arrival " + target)
		# Exercise actual scene setup, navigation and rendered visuals.
		router.set("_field_payload", {"scene_id":StringName(id),"player_spawn":scene.player_spawn})
		router.set("_current_field_id", StringName(id))
		var field := load("res://scenes/field_walkable.tscn").instantiate() as Node
		root.add_child(field)
		await process_frame
		await process_frame
		_check(field.get("_world_size") == Vector2(2304,1536), id + " runtime world matches art")
		var live_player: Player = field.get("_player")
		_check(is_equal_approx(live_player.get_depth_sort_y(), live_player.global_position.y), id + " player root is foot on reviewed road")
		for live_npc: NPCNode in field.get("_npc_nodes"):
			_check(is_equal_approx(live_npc.get_depth_sort_y(), live_npc.global_position.y), id + " NPC root is foot " + live_npc.npc_id)
		if "--capture-luoyang" in OS.get_cmdline_user_args():
			await create_timer(1.0).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/%s_region_v2.png" % id)
			if id == "openworld_huashan_forecourt":
				var player: Node2D = field.get("_player")
				player.position = Vector2(0.15,0.35) * Vector2(2304,1536)
				await create_timer(1.0).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://screenshots/huashan_waterfall_elder_region_v2.png")
		field.queue_free()
		await process_frame
	print("[LuoyangRegionV2] failures=%d" % failures)
	quit(1 if failures > 0 else 0)

func _check_huashan_lesson() -> void:
	var state := root.get_node("GameState")
	state.reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	var lesson := load("res://data/dialogs/openworld_huashan_lanhui_lesson.tres") as DialogScript
	var revisit := load("res://data/dialogs/openworld_huashan_lanhui_revisit.tres") as DialogScript
	_check(lesson.required_story_flag == &"" and lesson.required_completed_quest == &"", "Huashan meeting independent of main story")
	_check(lesson.get_entry_node().learn_skills.is_empty(), "declining the lesson gives no skill")
	state.player.insight = 1
	root.get_node("DialogPlayer")._apply_node_side_effects(lesson.find_node_by_id(&"lesson"))
	_check(not &"huashan_lanhui_sandie" in state.player.skills, "Huashan lesson respects insufficient insight")
	_check(&"huashan_lanhui_sandie" in state.pending_skill_unlocks, "insufficient insight retains discovered lesson")
	state.player.insight = 6
	state._reconcile_pending_skills()
	_check(&"huashan_lanhui_sandie" in state.player.skills, "discovered lesson learned when insight meets requirement")
	var count: int = state.player.skills.size()
	root.get_node("DialogPlayer")._apply_node_side_effects(lesson.find_node_by_id(&"lesson"))
	_check(state.player.skills.size() == count, "repeated lesson does not duplicate skill")
	_check(revisit.get_entry_node().learn_skills.is_empty(), "revisit has no new reward")
	state.reset_for_new_game()

func _walkable(layout: WalkableMapLayout, pos: Vector2) -> bool:
	for polygon in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(pos,polygon):
			return true
	return false

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("[FAIL] " + label)
