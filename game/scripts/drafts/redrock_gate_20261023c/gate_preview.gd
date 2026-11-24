extends Node2D
## Standalone editor draft. Does not access autoloads, routes, tasks, or saves.

const START := Vector2(680, 1510)
const OVERVIEW := Vector2(1280, 880)
const OVERVIEW_ZOOM := Vector2(0.58, 0.58)
const FOLLOW_ZOOM := Vector2(1.0, 1.0)
const MOVE_SPEED := 290.0

@onready var actor: CharacterBody2D = $Depth/SurveyActor
@onready var camera: Camera2D = $Camera
@onready var gate_art: Sprite2D = $Depth/Gate/Art
var follow := false
var controls_enabled := true


func _physics_process(_delta: float) -> void:
	if controls_enabled:
		var direction := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity = direction.normalized() * MOVE_SPEED
		actor.move_and_slide()
	update_view()


func update_view() -> void:
	if follow:
		camera.position = actor.position - Vector2(0, 120)
		camera.zoom = FOLLOW_ZOOM
	else:
		camera.position = OVERVIEW
		camera.zoom = OVERVIEW_ZOOM
	# The complete original gate texture stays intact. Fade only while the adult
	# passes beneath/behind its lintel; the two pier bodies remain fully solid.
	var beneath_lintel: bool = absf(actor.position.x - 1280.0) < 230.0 and actor.position.y < 1036.0 and actor.position.y > 465.0
	gate_art.modulate.a = 0.36 if beneath_lintel else 1.0
	$MakingNotes/ActorLabel.position = actor.position - START


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			follow = not follow
		KEY_R:
			actor.position = START
		KEY_F1:
			$MakingNotes.visible = not $MakingNotes.visible
	update_view()
	get_viewport().set_input_as_handled()
