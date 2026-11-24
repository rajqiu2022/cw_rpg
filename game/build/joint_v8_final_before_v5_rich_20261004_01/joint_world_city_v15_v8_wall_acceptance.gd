extends RefCounted
## NEW V8/world + wall-street-city joint gate; original approval document schema stays unchanged.
## Independent source authority only; never manufactures approval or QA results.
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
const WORLD_GATE = preload("res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd")
const CITY = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const VISUAL_REVIEW := "res://data/maps/joint_world_city_v15_visual_review.json"
const TECHNICAL_REVIEW := "res://data/maps/joint_world_city_v15_technical_review.json"
const BASELINE := {
	"res://data/scenes/world_map_jianghu.tres": "838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/scenes/ch4_s0_luoyang_gate.tres": "b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/scenes/ch4_s1_luoyang_yamen.tres": "7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/scenes/ch4_s2_canal_docks.tres": "81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
	"res://data/scenes/ch4_s3_luoyang_market.tres": "5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/config/outskirts_native_adoption.json": "203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff",
}
const SYSTEM_PATHS := [
	"res://project.godot",
	"res://scripts/autoload/audio_manager.gd", "res://scripts/autoload/event_bus.gd",
	"res://scripts/autoload/game_state.gd", "res://scripts/autoload/inventory.gd", "res://scripts/autoload/quest_manager.gd",
	"res://scripts/autoload/scene_router.gd", "res://scripts/autoload/save_manager.gd",
	"res://scripts/autoload/dialog_player.gd", "res://scripts/autoload/bounty_manager.gd",
	"res://scripts/field/field_walkable_controller.gd", "res://scripts/field/player.gd", "res://scripts/field/npc_node.gd",
	"res://scripts/field/exit_zone.gd", "res://scripts/field/world_v15_exit_zone.gd", "res://scripts/field/luoyang_v3_exit_zone.gd",
	"res://scripts/world/world_map_v15_contract.gd", "res://scripts/world/world_map_v14_contract.gd",
	"res://scripts/world/outskirts_native_contract.gd", "res://scripts/world/outskirts_modular_overlap.gd",
	"res://scripts/world/v14_modular_overlap.gd", "res://scripts/world/v15_modular_overlap.gd",
	"res://scripts/city/luoyang_layered_v3_contract.gd", "res://scripts/city/luoyang_v3_sprite_alpha.gd",
	"res://scripts/city/luoyang_v3_modular_overlap.gd",
	"res://scripts/dev/world_map_v15_complete_v7_publication_gate_proposal.gd", "res://scripts/dev/publish_world_map_v15_complete_v7_proposal.gd",
	"res://scripts/dev/publish_luoyang_layered_v3.gd", "res://scripts/dev/joint_world_city_v15_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15.gd",
	"res://scripts/battle/battle_controller.gd", "res://scripts/ui/result_victory.gd", "res://scripts/ui/result_defeat.gd",
	"res://scripts/ui/shop_ui.gd", "res://scripts/ui/bounty_board.gd", "res://scripts/ui/world_map_panel.gd", "res://scripts/ui/dialog_box.gd",
	"res://scenes/battle.tscn", "res://scenes/battle_actor.tscn", "res://scenes/result_victory.tscn", "res://scenes/result_defeat.tscn",
	"res://scenes/shop.tscn", "res://scenes/bounty_board.tscn", "res://scenes/field_walkable.tscn",
	"res://tests/test_joint_world_luoyang_v15_20261004.gd",
	"res://tests/helpers/joint_v15_source_context_oracle.gd", "res://tests/helpers/joint_v15_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_world_raw_oracle.gd", "res://tests/helpers/joint_v15_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_world_object_input_probe.gd", "res://tests/helpers/joint_v15_world_saved_context_probe.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd",
	"res://tests/helpers/joint_v15_overview_input_probe.gd", "res://tests/helpers/joint_v15_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_normal_npc_depth_probe.gd", "res://tests/helpers/joint_v15_battle_return_probe.gd",
	"res://tests/helpers/joint_v15_city_prepared_phase.gd", "res://tests/helpers/joint_v15_city_physical_alpha_probe.gd",
	"res://tests/helpers/joint_v15_city_sprite_alpha_probe.gd", "res://tests/helpers/joint_v15_existing_battle_ui_probe.gd",
	"res://tests/helpers/joint_v15_city_migration_load_probe.gd", "res://tests/helpers/joint_v15_city_interaction_negative_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_prepared_phase.gd", "res://tests/helpers/joint_v15_outskirts_field_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_material_probe.gd", "res://tests/helpers/joint_v15_outskirts_encounter_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_saved_geometry_probe.gd",
	"res://scripts/city/luoyang_layered_v3_street_detail_candidate_contract.gd",
	"res://scripts/dev/luoyang_v3_street_detail_material_checker.gd",
	"res://scripts/dev/publish_luoyang_v3_street_detail_candidate.gd",
	"res://tests/helpers/joint_v15_v7_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_v7_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_v7_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_v7_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_v7_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_v7_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v7_probe.gd",
	"res://tests/helpers/joint_v15_v7_plane_caster_semantic_probe.gd",
	"res://tests/helpers/joint_v15_street_detail_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_street_detail_city_physical_alpha_probe.gd",
	"res://tests/helpers/joint_v15_street_detail_city_prepared_phase.gd",
	"res://tests/helpers/joint_v15_street_detail_city_gameplay_lifecycle_grace_phase.gd",
	"res://tests/helpers/joint_v15_looped_bgm_continuity.gd",
	# Keep all83 original roots; append actual V8 capture/system/city/FULL QA roots.
	"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
	"res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd",
	"res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd",
	"res://scripts/world/world_map_v15_complete_v8_candidate_contract.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v8_candidate.gd",
	"res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd",
	"res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd",
	"res://scripts/dev/publish_luoyang_v3_wall_street_candidate.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd",
	"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd",
	"res://scripts/dev/joint_world_city_v15_v8_wall_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15_v8_wall.gd",
	"res://tests/helpers/joint_v15_v8_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_v8_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_v8_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_v8_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_v8_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_v8_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_v8_plane_caster_semantic_probe.gd",
	"res://tests/helpers/joint_v15_v8_city_prepared_phase.gd",
	"res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v8_probe.gd",
	"res://tests/test_joint_world_luoyang_v15_v8_full_20261004.gd",
]

static func candidate_error() -> String:
	if WORLD.SOURCE_PATH != WORLD_GATE.SOURCE_PATH or WORLD.MANIFEST_PATH != WORLD_GATE.MANIFEST_PATH or WORLD.CAPTURE_PROTOCOL != WORLD_GATE.PROTOCOL: return "World runtime/approval artifact authority mismatch"
	var source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	var manifest: Dictionary = WORLD.read_json(WORLD.MANIFEST_PATH)
	var capture: Variant = source.get("capture")
	if not capture is Dictionary or capture.get("capture_protocol") != WORLD.CAPTURE_PROTOCOL or manifest.get("capture_protocol") != WORLD.CAPTURE_PROTOCOL: return "Joint approval requires actual FULL whole v8, not old local-frustum/pilot artifacts"
	var world_error: String = WORLD_GATE.validate(source, manifest)
	if not world_error.is_empty(): return world_error
	var world: SceneScript = ResourceLoader.load(WORLD.CANDIDATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not WORLD.is_v15(world) or world.scene_id != WORLD.CANDIDATE_ID or not WORLD.safe_foot(world, world.player_spawn): return "Missing/unbound safe full world candidate"
	for id: String in CITY.LEGACY_SHAS:
		var scene: SceneScript = ResourceLoader.load(CITY.candidate_path(StringName(id)), "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not CITY.is_v3(scene) or scene.scene_id != StringName(id) or not CITY.runtime_fidelity(scene): return "Missing/unbound normal city candidate " + id
	if OUTSKIRTS.active_root() != OUTSKIRTS.COMPLETE_V5_ROOT: return "New outskirts root must be explicitly selected; old/v4 cannot inherit joint acceptance"
	for biome: String in OUTSKIRTS.ENTRIES:
		if OUTSKIRTS.authoring_contract(biome).is_empty(): return "New independent outskirts NOT_READY " + biome
	return ""

static func snapshot() -> Dictionary:
	# Every actual byte in all eight art graphs and all candidate resources is
	# bound. Approval files themselves are excluded to avoid a circular hash.
	if WORLD.SOURCE_PATH != WORLD_GATE.SOURCE_PATH or WORLD.MANIFEST_PATH != WORLD_GATE.MANIFEST_PATH or WORLD.CAPTURE_PROTOCOL != WORLD_GATE.PROTOCOL: return {}
	var result: Dictionary = {}
	for path: String in SYSTEM_PATHS:
		if not _append(result, path): return {}
	for path: String in [WORLD.SOURCE_PATH, WORLD.MANIFEST_PATH, WORLD.CANDIDATE_PATH, WORLD.LAYOUT_PATH, WORLD.STREAM_PATH, WORLD_GATE.REVIEW]:
		if not _append(result, path): return {}
	if not _catalog(result, WORLD.read_json(WORLD.MANIFEST_PATH).get("asset_sha256", {})): return {}
	var source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	if source.has("asset_sha256") and not _catalog(result, source.asset_sha256): return {}
	for id: String in CITY.LEGACY_SHAS:
		for path: String in [CITY.ROOT + id + "/art_contract.json", CITY.candidate_path(StringName(id)), CITY.layout_path(StringName(id)), CITY.LEGACY_ROOT + id + "_scene.tres", CITY.LEGACY_ROOT + id + "_layout.tres"]:
			if not _append(result, path): return {}
		if not _catalog(result, WORLD.read_json(CITY.ROOT + id + "/art_contract.json").get("asset_sha256", {})): return {}
	for biome: String in OUTSKIRTS.ENTRIES:
		var path: String = OUTSKIRTS.COMPLETE_V5_ROOT + biome + "/art_contract.json"
		if not _append(result, path) or not _catalog(result, WORLD.read_json(path).get("asset_sha256", {})): return {}
		if not _append(result, "res://data/scenes/" + String(OUTSKIRTS.ENTRIES[biome].scene) + ".tres"): return {}
	# Bind original gameplay leaves too, including nested dialogues, encounters,
	# shops, quests and generated item/skill references used by normal actions.
	for directory: String in ["res://data/dialogs", "res://data/enemies", "res://data/shops", "res://data/quests", "res://data/items", "res://data/equipment", "res://data/skills"]:
		if not _data_tree(result, directory): return {}
	# Bind the actual literal dependency closure of these gameplay and QA roots,
	# including reused helpers, resource-domain scripts, UI scenes and real audio.
	# This is byte protection, NOT a claim that every bound dialogue was played.
	var visited: Dictionary = {}
	for path: String in result.keys():
		if not _dependency_tree(result, path, visited): return {}
	if not _actor_frame_dependencies(result): return {}
	return result

static func approval_error() -> String:
	for path: String in BASELINE:
		if FileAccess.get_sha256(path).to_lower() != BASELINE[path]: return "Formal activation baseline changed; no writes allowed: " + path
	var error: String = candidate_error()
	if not error.is_empty(): return error
	var current: Dictionary = snapshot()
	if current.is_empty(): return "Incomplete actual joint byte snapshot"
	var visual: Dictionary = WORLD.read_json(VISUAL_REVIEW)
	var technical: Dictionary = WORLD.read_json(TECHNICAL_REVIEW)
	for review: Dictionary in [visual, technical]:
		if review.get("schema_version") != 1 or review.get("world_coordinate_version") != 15 or review.get("city_layout_version") != 3 or review.get("reviewer_role") != "producer/root" or String(review.get("reviewer", "")).strip_edges().is_empty() or not matches_snapshot(review.get("asset_sha256"), current): return "Independent joint producer review absent/stale"
	if visual.get("visual_approved") != true or typeof(visual.get("visual_approved")) != TYPE_BOOL or visual.get("review_method") != "actual_world_city_outskirts_png_individual_review": return "Joint actual-image visual approval absent"
	if technical.get("technical_approved") != true or typeof(technical.get("technical_approved")) != TYPE_BOOL or technical.get("review_method") != "independent_full_normal_gameplay_field_input": return "Joint normal-gameplay technical approval absent"
	var runs: Variant = technical.get("actual_runs")
	if not runs is Dictionary or runs.size() != 2: return "Separate actual headless/GPU run wrappers required"
	for mode: String in ["headless", "gpu"]:
		var run: Variant = runs.get(mode)
		if not run is Dictionary or not _number(run.get("actual_os_exit_code"), 0): return "Actual process wrapper did not confirm exit0: " + mode
		for role: String in ["result", "stdout", "stderr"]:
			var evidence: Variant = run.get(role)
			if not evidence is Dictionary or not _bound_evidence(evidence): return "Missing/stale independently retained actual log: " + mode + "/" + role
		var report: Dictionary = WORLD.read_json(String(run.result.path))
		if report.get("phase") != "JOINT_FULL_ACTUAL_FIELD_INPUT" or not _number(report.get("failed"), 0) or report.get("mode") != mode or report.get("source_complete") != true or report.get("dry_run") != false or not matches_snapshot(report.get("source_sha256"), current): return "Source/unit/limited/stale evidence cannot approve normal joint gameplay: " + mode
		var coverage: Variant = report.get("coverage")
		if not coverage is Dictionary or not _complete_coverage(coverage, current): return "Joint actual coverage incomplete: " + mode
	return ""

static func _complete_coverage(coverage: Dictionary, actual_snapshot: Dictionary = {}) -> bool:
	for key: String in ["world", "city", "outskirts", "migration"]:
		if not coverage.get(key) is Dictionary or coverage[key].get("complete") != true: return false
	if not _exact_ids(coverage.world.get("portal_ids"), WORLD.PORTAL_IDS) or not _exact_ids(coverage.world.get("core_ids"), WORLD_GATE.CORE_IDS) or coverage.world.get("chunk_count") != 64 or coverage.world.get("seam_count") != 112: return false
	if not _exact_ids(coverage.city.get("region_ids"), CITY.LEGACY_SHAS.keys()) or coverage.city.get("normal_gameplay") != true: return false
	var identities := {"npcs": [], "interactions": [], "portals": []}
	for id: String in CITY.LEGACY_SHAS:
		var original: SceneScript = CITY.legacy_scene(StringName(id))
		if original == null: return false
		for npc: Dictionary in original.npcs: identities.npcs.append(id + "/" + String(npc.npc_id))
		for entry: Dictionary in original.map_layout.interactions: identities.interactions.append(id + "/" + String(entry.id))
		for entry: Dictionary in original.map_layout.portals: identities.portals.append(id + "/" + String(entry.id))
	for key: String in identities:
		if not _exact_ids(coverage.city.get(key + "_ids"), identities[key]): return false
	if not _water_absence_proofs(coverage.city.get("water_decoration_absence_proofs"), actual_snapshot): return false
	if not _exact_ids(coverage.outskirts.get("scene_ids"), ["openworld_v15_bamboo_outskirts", "openworld_v15_forest_outskirts", "openworld_v15_marsh_outskirts"]) or coverage.outskirts.get("normal_encounter_rewards_returns") != true: return false
	return _exact_ids(coverage.migration.get("world_source_versions"), [12, 13, 14, 15]) and _exact_ids(coverage.migration.get("local_source_versions"), [1, 3]) and coverage.migration.get("repeat_no_remap") == true and coverage.migration.get("unknown_rejected_zero_mutation") == true

static func _water_absence_proofs(value: Variant, actual_snapshot: Dictionary) -> bool:
	# Exact object exception only. Source role never certifies a missed station;
	# the actual complete continuous-domain QA proof is an approval prerequisite.
	if not value is Array or value.size() != 1 or actual_snapshot.is_empty(): return false
	var summary: Variant = value[0]
	if not summary is Dictionary or summary.get("region_id") != "ch4_s2_canal_docks" or summary.get("object_id") != "moored_canal_boat" or summary.get("method") != "continuous_full_drawrect_axis_separation" or summary.get("complete") != true: return false
	var id := &"ch4_s2_canal_docks"
	var manifest_path: String = CITY.ROOT + String(id) + "/art_contract.json"
	var manifest: Dictionary = WORLD.read_json(manifest_path)
	var boat: Dictionary = {}
	for object: Variant in manifest.get("objects", []):
		if object is Dictionary and object.get("id") == "moored_canal_boat": boat = object
	if boat.is_empty() or boat.get("role") != "water_decoration" or not CITY._object_role_error(id, boat).is_empty(): return false
	var nav_path: String = String(manifest.get("walk_path", ""))
	var source_path: String = String(boat.get("texture", ""))
	for binding: Array in [["manifest_sha256", manifest_path], ["nav_sha256", nav_path], ["source_sha256", source_path]]:
		if not actual_snapshot.has(binding[1]) or not _hash(summary.get(binding[0])) or String(summary[binding[0]]).to_lower() != actual_snapshot[binding[1]]: return false
	for key: String in ["source_frame_count", "source_alpha_pixels", "legal_nav_cells"]:
		if not _positive_integer(summary.get(key)): return false
	if not _number(summary.get("intersection_count"), 0) or not _positive(summary.get("minimum_gap_px")) or not summary.get("evidence") is Dictionary or not _bound_evidence(summary.evidence): return false
	var evidence: Dictionary = WORLD.read_json(String(summary.evidence.path))
	if evidence.get("scope") != "CONTINUOUS_ALL_NORMAL_PLAYER_WEAPONS_AND_ALL_GATED_NPC_FAMILIES" or evidence.get("complete") != true or not evidence.get("families") is Array or evidence.families.is_empty(): return false
	var original: SceneScript = CITY.legacy_scene(id)
	if original == null: return false
	var expected: Array = []
	for npc: Dictionary in original.npcs: expected.append(String(npc.npc_id))
	if not _exact_ids(evidence.get("normal_npc_ids"), expected): return false
	var seen: Dictionary = {}
	var frames := 0
	var gap := INF
	for family: Variant in evidence.families:
		if not family is Dictionary or not _water_family(family, summary, boat, actual_snapshot): return false
		frames += int(family.source_frame_count)
		gap = minf(gap, float(family.minimum_gap_px))
		for actor: Dictionary in family.actor_domains:
			if not String(actor.actor).begins_with("normal_player_"): seen[String(actor.actor)] = true
	if not _exact_ids(seen.keys(), expected) or not _number(summary.source_frame_count, frames) or absf(float(summary.minimum_gap_px) - gap) > .00001: return false
	return true

static func _water_family(row: Dictionary, summary: Dictionary, boat: Dictionary, actual_snapshot: Dictionary) -> bool:
	if row.get("complete") != true or row.get("method") != "continuous_full_drawrect_axis_separation" or row.get("region_id") != summary.region_id or row.get("object_id") != summary.object_id: return false
	for key: String in ["manifest_sha256", "nav_sha256", "source_sha256", "source_alpha_pixels", "legal_nav_cells"]:
		if row.get(key) != summary.get(key): return false
	if row.get("source_path") != boat.get("texture") or not _number(row.get("all_nav_cells_read"), 3072 * 2048) or not _number(row.get("linear_filter_margin_world_px"), 1) or not _number(row.get("intersection_count"), 0) or not _positive_integer(row.get("source_frame_count")): return false
	var bounds: Variant = row.get("prop_actual_world_rect_with_linear_margin")
	if not bounds is Array or bounds.size() != 4: return false
	var render: Vector2 = CITY._vec(boat.render_size_px)
	var origin: Vector2 = CITY._vec(boat.world_foot_px) - CITY._vec(boat.foot_uv) * render - Vector2.ONE
	for index in 4:
		var expected: float = [origin.x, origin.y, render.x + 2, render.y + 2][index]
		if typeof(bounds[index]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(bounds[index])) or absf(float(bounds[index]) - expected) > .01: return false
	if not row.get("actor_domains") is Array or row.actor_domains.is_empty(): return false
	var rightmost := -INF
	var frames := 0
	var player_count := 0
	for actor: Variant in row.actor_domains:
		if not actor is Dictionary: return false
		var is_player: bool = actor.get("actor") == "normal_player_all_five_weapon_families"
		if is_player: player_count += 1
		var sources: Variant = actor.get("sources")
		var source_rows: Variant = sources.get("sources") if is_player and sources is Dictionary else sources
		var script_key: String = "Player_script_sha256" if is_player else "NPC_script_sha256"
		var script_path: String = "res://scripts/field/player.gd" if is_player else "res://scripts/field/npc_node.gd"
		var family_data: Dictionary = sources if is_player and sources is Dictionary else actor
		if family_data.get("valid") != true or not _positive_integer(family_data.get("frame_count")) or family_data.get(script_key) != actual_snapshot.get(script_path) or not source_rows is Array or source_rows.is_empty(): return false
		if is_player and source_rows.size() != 40: return false
		var source_frames := 0
		var right_extent := 0.0
		var unique: Dictionary = {}
		for source: Variant in source_rows:
			if not source is Dictionary or source.get("valid") != true or not _positive_integer(source.get("frames")) or not _positive_integer(source.get("cell_px")) or not _positive(source.get("right_extent_px")): return false
			var path: String = String(source.get("path", ""))
			if unique.has(path) or not actual_snapshot.has(path) or not _hash(source.get("sha256")) or String(source.sha256).to_lower() != actual_snapshot[path]: return false
			unique[path] = true
			if not CITY._png_size(path, Vector2i(int(source.cell_px) * int(source.frames), int(source.cell_px))): return false
			if is_player:
				var weapon: Variant = source.get("weapon")
				var state: Variant = source.get("state")
				var direction: Variant = source.get("direction")
				if weapon not in ["sword", "dao", "staff", "palm", "hidden"] or state not in ["idle", "walk"] or direction not in ["down", "up", "left", "right"]: return false
				var count: int = 4 if state == "idle" else 8
				if not _number(source.frames, count) or path != "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png" % [weapon, weapon, state, direction, count]: return false
			var scale_value: Variant = source.get("actual_normal_scale" if is_player else "scale")
			if not _positive(scale_value) or float(source.right_extent_px) < float(source.cell_px) * .5 * float(scale_value) + 1: return false
			if is_player and not _number(scale_value, .945 * .91): return false
			source_frames += int(source.frames)
			right_extent = maxf(right_extent, float(source.right_extent_px))
		if not _number(family_data.frame_count, source_frames): return false
		frames += source_frames
		if typeof(actor.get("rightmost_draw_x")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(actor.rightmost_draw_x)): return false
		if typeof(actor.get("root_upper_x")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(actor.root_upper_x)) or float(actor.rightmost_draw_x) < float(actor.root_upper_x) + right_extent: return false
		if is_player:
			if not _positive_integer(row.get("nav_max_white_x")) or float(row.nav_max_white_x) >= CITY.SIZE.x or float(actor.root_upper_x) < float(row.nav_max_white_x) + .5 - CITY.BODY_SIZE.x * .5: return false
		rightmost = maxf(rightmost, float(actor.rightmost_draw_x))
	if player_count != 1 or not _number(row.source_frame_count, frames) or not _positive(row.get("minimum_gap_px")) or absf(float(row.minimum_gap_px) - (origin.x - rightmost)) > .00001: return false
	var negatives: Variant = row.get("negative_stations")
	if not negatives is Array or negatives.size() != 4: return false
	var directions: Array = []
	for negative: Variant in negatives:
		if not negative is Dictionary or not _number(negative.get("prop_ghost_pixels"), 0) or not negative.get("current_alpha") is Dictionary or not _number(negative.current_alpha.get("hits"), 0) or not negative.get("actual_input") is Dictionary or negative.actual_input.get("ok") != true: return false
		var direction: Vector2 = CITY._vec(negative.get("direction"))
		if direction not in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT] or direction in directions: return false
		directions.append(direction)
	return true

static func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0

static func _positive_integer(value: Variant) -> bool:
	return _positive(value) and float(value) == floor(float(value))

static func _actor_frame_dependencies(result: Dictionary) -> bool:
	# Player switches weapon/direction dynamically; literal resource closure
	# cannot find these paths. Bind every permitted current full-frame family.
	for weapon: String in ["sword", "dao", "staff", "palm", "hidden"]:
		for state: String in ["idle", "walk"]:
			for direction: String in ["down", "up", "left", "right"]:
				var count: int = 4 if state == "idle" else 8
				var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png" % [weapon, weapon, state, direction, count]
				if not _append(result, path): return false
	var catalog: NPCCatalog = ResourceLoader.load("res://data/npcs/npc_catalog.tres") as NPCCatalog
	if catalog == null or not _append(result, "res://data/npcs/npc_catalog.tres"): return false
	for id: String in CITY.LEGACY_SHAS:
		var scene: SceneScript = CITY.legacy_scene(StringName(id))
		if scene == null: return false
		for npc: Dictionary in scene.npcs:
			var paths: Array = [String(npc.get("sprite_path", "")), String(npc.get("walk_sprite_path", ""))]
			var conversations: Variant = npc.get("conversation_sprite_paths", {})
			if conversations is Dictionary: paths.append_array(conversations.values())
			var profile: NPCProfile = catalog.find(StringName(npc.npc_id), scene.scene_id)
			if profile != null: paths.append_array([profile.sprite_path, profile.walk_sprite_path])
			for path: String in paths:
				if path.is_empty(): continue
				if not _append(result, path): return false
				# Exact same permitted direction/state/version fallbacks as NPCNode.
				for old_direction: String in ["down", "up", "left", "right"]:
					if not path.contains("_" + old_direction + "_"): continue
					for direction: String in ["down", "up", "left", "right"]:
						var directional: String = path.replace("_" + old_direction + "_", "_" + direction + "_")
						var variants: Array[String] = [directional]
						for version in range(2, 10): variants.append(directional.replace("_v%d_" % version, "_"))
						for variant_path: String in variants:
							for state: String in ["idle", "walk"]:
								var candidate: String = variant_path.replace("_idle_", "_" + state + "_").replace("_walk_", "_" + state + "_")
								if FileAccess.file_exists(candidate) and not _append(result, candidate): return false
	return true

static func matches_snapshot(value: Variant, actual: Dictionary) -> bool:
	if not value is Dictionary or value.size() != actual.size(): return false
	for path: String in actual:
		if not _hash(value.get(path)) or String(value[path]).to_lower() != actual[path]: return false
	return true

static func _exact_ids(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size(): return false
	var found: Array = []
	for id: Variant in value:
		if id not in expected or id in found: return false
		found.append(id)
	return true

static func _bound_evidence(value: Dictionary) -> bool:
	var path: Variant = value.get("path")
	return path is String and path.begins_with("res://build/") and not ".." in path and FileAccess.file_exists(path) and _hash(value.get("sha256")) and FileAccess.get_sha256(path).to_lower() == String(value.sha256).to_lower()

static func _append(result: Dictionary, path: String) -> bool:
	if not path.begins_with("res://") or ".." in path or not FileAccess.file_exists(path): return false
	var sha: String = FileAccess.get_sha256(path).to_lower()
	if not _hash(sha): return false
	result[path] = sha
	return true

static func _catalog(result: Dictionary, value: Variant) -> bool:
	if not value is Dictionary or value.is_empty(): return false
	for path: Variant in value:
		if not path is String or not _hash(value[path]) or not _append(result, path) or result[path] != String(value[path]).to_lower(): return false
	return true

static func _data_tree(result: Dictionary, path: String) -> bool:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null: return false
	for name: String in directory.get_files():
		if name.ends_with(".tres") and not _append(result, path.path_join(name)): return false
	for name: String in directory.get_directories():
		if not _data_tree(result, path.path_join(name)): return false
	return true

static func _dependency_tree(result: Dictionary, path: String, visited: Dictionary) -> bool:
	if visited.has(path): return true
	visited[path] = true
	if path.get_extension() not in ["gd", "tscn", "tres", "godot", "gdshader"]: return true
	var regex := RegEx.new()
	if regex.compile("[\"'](res://[^\"']+)[\"']") != OK: return false
	for reference: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
		var dependency: String = reference.get_string(1)
		# These two independent approval documents certify this snapshot; hashing
		# them into it would make their own asset_sha256 bindings circular.
		# The world visual review and every mandatory art/source root remain bound.
		if dependency in [VISUAL_REVIEW, TECHNICAL_REVIEW]: continue
		# Dynamic path templates and intentionally missing negative fixtures are
		# not executable dependencies. Mandatory roots/graphs above remain strict.
		if ".." in dependency or not FileAccess.file_exists(dependency): continue
		if not _append(result, dependency) or not _dependency_tree(result, dependency, visited): return false
	return true

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

static func _number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected
