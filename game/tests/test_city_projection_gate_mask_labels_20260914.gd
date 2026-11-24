extends SceneTree

const CITY_SCENES := [
	&"openworld_bianzhou_city",
	&"openworld_xiangzhou_city",
	&"openworld_jinling_city",
]

const GATE_SCENES := [
	&"ch4_s0_luoyang_gate",
	&"openworld_wudang_gate",
	&"openworld_huashan_forecourt",
]

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_city_gameplay_projection_contract()
	await _check_gate_mask_contract()
	await _check_world_destination_label_contract()
	print("[CityProjectionGateMaskLabels] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _check_city_gameplay_projection_contract() -> void:
	var contract_text := FileAccess.get_file_as_string("res://data/maps/openworld_city_gameplay_contract_v2.json")
	var contract: Dictionary = JSON.parse_string(contract_text) as Dictionary
	_check(not contract.is_empty(), "city gameplay projection contract parses")
	_check(String(contract.get("projection", "")) == "fixed_parallel_orthographic_2_5d", "city maps require fixed parallel 2.5D projection")
	_check(String(contract.get("legacy_v1_usage", "")) == "loading_or_concept_only", "old panorama maps are loading/concept only")
	for scene_id: StringName in CITY_SCENES:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null, "%s loads" % scene_id)
		if scene == null:
			continue
		_check(scene.background_path.contains("openworld_cities_v2"), "%s uses the equal-scale v2 gameplay artwork" % scene_id)
		_check(scene.map_layout != null and scene.map_layout.resource_path.ends_with("_layout_v2.tres"), "%s uses a reviewed v2 navigation layout" % scene_id)
		_check(scene.map_layout.design_size == Vector2i(3072, 2048), "%s keeps native 3072x2048 gameplay resolution" % scene_id)
		var texture := load(scene.background_path) as Texture2D
		_check(texture != null and texture.get_size() == Vector2(3072, 2048), "%s runtime art is full resolution" % scene_id)


func _check_gate_mask_contract() -> void:
	var mask_samples := {
		&"ch4_s0_luoyang_gate": {"solid": Vector2(0.30, 0.30), "hole": Vector2(0.50, 0.35)},
		&"openworld_wudang_gate": {"solid": Vector2(0.50, 0.20), "hole": Vector2(0.50, 0.55)},
		&"openworld_huashan_forecourt": {"solid": Vector2(0.50, 0.40), "hole": Vector2(0.50, 0.62)},
	}
	for scene_id: StringName in GATE_SCENES:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null and scene.map_layout != null, "%s loads with layout" % scene_id)
		if scene == null or scene.map_layout == null:
			continue
		_check(scene.map_layout.actor_fade_zones.is_empty(), "%s does not fade the whole base actor" % scene_id)
		_check(scene.map_layout.occluders.size() >= 1, "%s owns a true foreground occluder" % scene_id)
		var data: Dictionary = scene.map_layout.occluders[0]
		var mask_path := String(data.get("alpha_mask_texture_path", ""))
		_check(mask_path != "" and ResourceLoader.exists(mask_path), "%s owns a dedicated alpha mask asset" % scene_id)
		var mask := load(mask_path) as Texture2D
		_check(mask != null and mask.get_size() == Vector2(scene.map_layout.design_size), "%s mask aligns 1:1 with the gameplay canvas" % scene_id)
		if mask != null:
			var image := mask.get_image()
			var solid_uv: Vector2 = mask_samples[scene_id].solid
			var hole_uv: Vector2 = mask_samples[scene_id].hole
			var solid := image.get_pixelv(Vector2i(solid_uv * Vector2(image.get_size()))).a
			var hole := image.get_pixelv(Vector2i(hole_uv * Vector2(image.get_size()))).a
			_check(solid > 0.90, "%s mask contains opaque gate architecture" % scene_id)
			_check(hole < 0.10, "%s mask keeps the walk-through opening transparent" % scene_id)
		var background := load(scene.background_path) as Texture2D
		var occluder := DynamicOccluder2D.new()
		root.add_child(occluder)
		_check(occluder.configure(data, background, Vector2(scene.map_layout.design_size)), "%s foreground occluder configures" % scene_id)
		_check(occluder.material is ShaderMaterial, "%s foreground pixels are clipped by the authored mask" % scene_id)
		var payload := occluder.get_actor_overlap_mask_payload()
		_check(payload.get("texture") is Texture2D, "%s exposes the same mask to the actor overlap shader" % scene_id)
		occluder.free()

	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	var luoyang := load("res://data/scenes/ch4_s0_luoyang_gate.tres") as SceneScript
	var luoyang_mask := load(String(luoyang.map_layout.occluders[0].alpha_mask_texture_path)) as Texture2D
	player.set_building_overlap(true, 0.43, true, {"texture": luoyang_mask, "world_size": Vector2(luoyang.map_layout.design_size)})
	var ghost := player.get_node_or_null("BuildingOverlapGhost") as Sprite2D
	_check(ghost != null and ghost.visible and ghost.material is ShaderMaterial, "actor ghost uses a mask-clipped overlap shader")
	_check((ghost.material as ShaderMaterial).shader.code.contains("MODEL_MATRIX"), "overlap mask is sampled in world coordinates")
	player.free()


func _check_world_destination_label_contract() -> void:
	var packed := load("res://scenes/exit_zone.tscn") as PackedScene
	var zone := packed.instantiate() as ExitZone
	zone.always_show_destination = true
	zone.destination_name = "金陵城 · 江南水城"
	root.add_child(zone)
	await process_frame
	zone.configure_destination_render_scale(1.25)
	var prompt := zone.get_node("Prompt") as Label
	_check(is_equal_approx(prompt.scale.x * 1.25, 1.0), "world destination label cancels camera zoom to a 1:1 screen transform")
	_check(prompt.get_theme_font_size("font_size") >= 24, "world destination label uses a high-resolution source size")
	_check(prompt.get_theme_constant("outline_size") >= 3, "world destination label has a crisp dark outline")
	var import_text := FileAccess.get_file_as_string("res://art/fonts/LXGWWenKaiLite-Regular.ttf.import")
	_check(import_text.contains("multichannel_signed_distance_field=true"), "bundled Chinese font enables MSDF for transformed map labels")
	zone.free()


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[CityProjectionGateMaskLabels] " + description)
