extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const FIELD_ROOT := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable"
const BATTLE_ROOT := "res://art/sprites/battle/weapon_variants_v3/lengguyun"
const FIELD_SCALE := 0.945
const STYLE_CASES := {
	&"sword": &"sword",
	&"blade": &"dao",
	&"staff": &"staff",
	&"palm": &"palm",
	&"hidden": &"hidden",
}
const DIRECTIONS := {
	"down": Vector2.DOWN,
	"up": Vector2.UP,
	"left": Vector2.LEFT,
	"right": Vector2.RIGHT,
}
const BATTLE_STATES := ["ready", "move", "attack", "hit", "defeat"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var player := PLAYER_SCENE.instantiate() as Player
	root.add_child(player)
	await process_frame
	player.set_visual_scale_multiplier(1.0)

	# Several full swap cycles catch accidental `sprite.scale *= ...` regressions.
	for _cycle in range(6):
		for input_style: StringName in STYLE_CASES:
			var expected_style: StringName = STYLE_CASES[input_style]
			player.set_weapon_style(input_style)
			for direction_name: String in DIRECTIONS:
				var direction: Vector2 = DIRECTIONS[direction_name]
				player.set_walk_direction(direction, false)
				_validate_field_texture(player, expected_style, direction_name, false, failures)
				player.set_walk_direction(direction, true)
				_validate_field_texture(player, expected_style, direction_name, true, failures)
			_validate_scale(player, FIELD_SCALE, failures)

	player.set_visual_scale_multiplier(1.12)
	var expected_scaled := FIELD_SCALE * 1.12
	for input_style: StringName in STYLE_CASES:
		player.set_weapon_style(input_style)
		_validate_scale(player, expected_scaled, failures)

	_validate_battle_assets(failures)
	_validate_runtime_switch_hooks(failures)
	player.queue_free()

	if failures.is_empty():
		print("[PlayerWeaponVariantsV7Idle] PASS: planted idle feet, five field styles, two-hand staff battle frames")
		quit(0)
		return
	for failure in failures:
		push_error("[PlayerWeaponVariantsV7Idle] %s" % failure)
	quit(1)


func _validate_field_texture(
	player: Player,
	expected_style: StringName,
	direction_name: String,
	moving: bool,
	failures: Array[String]
) -> void:
	var sprite := player.get_node("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		failures.append("missing field texture for %s/%s" % [expected_style, direction_name])
		return
	var state := "walk" if moving else "idle"
	var frames := 8 if moving else 4
	var expected_path := "%s/%s/lengguyun_%s_%s_%s_25d_%df.png" % [
		FIELD_ROOT,
		expected_style,
		expected_style,
		state,
		direction_name,
		frames,
	]
	if sprite.texture.resource_path != expected_path:
		failures.append("wrong field texture: got %s expected %s" % [sprite.texture.resource_path, expected_path])
	if sprite.hframes != frames or sprite.vframes != 1:
		failures.append("wrong field grid for %s: %dx%d" % [expected_path, sprite.hframes, sprite.vframes])
	if sprite.flip_h:
		failures.append("field direction must use authored row, not runtime mirroring: %s" % expected_path)


func _validate_scale(player: Player, expected: float, failures: Array[String]) -> void:
	var sprite := player.get_node("Sprite2D") as Sprite2D
	if sprite == null:
		failures.append("missing player Sprite2D")
		return
	if not is_equal_approx(sprite.scale.x, expected) or not is_equal_approx(sprite.scale.y, expected):
		failures.append("cumulative scale drift: got %s expected %.5f" % [sprite.scale, expected])


func _validate_battle_assets(failures: Array[String]) -> void:
	for style: StringName in [&"sword", &"dao", &"staff", &"palm", &"hidden"]:
		var battle_root := "res://art/sprites/battle/weapon_variants_v4/lengguyun" if style in [&"sword", &"dao"] else BATTLE_ROOT
		for state_name: String in BATTLE_STATES:
			for frame_index in range(1, 5):
				var path := "%s/%s/lengguyun_%s_%s_%02d.png" % [
					battle_root,
					style,
					style,
					state_name,
					frame_index,
				]
				if not ResourceLoader.exists(path):
					failures.append("missing battle frame: %s" % path)
					continue
				var texture := load(path) as Texture2D
				if texture == null or texture.get_width() != 512 or texture.get_height() != 384:
					failures.append("battle frame must be 512x384: %s" % path)


func _validate_runtime_switch_hooks(failures: Array[String]) -> void:
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	if not field_source.contains("EventBus.equipment_changed.connect(_on_field_equipment_changed)"):
		failures.append("field controller must listen for equipment changes")
	if not field_source.contains("_player.set_weapon_style(_current_player_weapon_type())"):
		failures.append("field controller must refresh the player weapon style")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	if not battle_source.contains("EventBus.equipment_changed.connect(_on_battle_equipment_changed)"):
		failures.append("battle controller must listen for in-battle equipment changes")
	if not battle_source.contains("_refresh_player_battle_weapon_actor(formation_view.get_actor(&\"player\"))"):
		failures.append("formation actor must refresh immediately after a battle weapon swap")
