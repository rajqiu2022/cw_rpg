extends Node2D
## Standalone native-node editor draft. No autoload, save, task or route access.

const START := Vector2(2650,1550)
@export var show_ground := false
var view_mode := 0
var controls_enabled := true


func _ready() -> void:
	update_view()


func _physics_process(_delta: float) -> void:
	if controls_enabled:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		$SurveyActor.velocity = direction.normalized() * 320.0
		$SurveyActor.move_and_slide()
	update_view()


func update_view() -> void:
	var actor: CharacterBody2D = $SurveyActor
	$Ground.visible = show_ground
	match view_mode:
		0:
			$Camera.position = Vector2(2800,1250)
			$Camera.zoom = Vector2.ONE * 0.37
		1:
			$Camera.position = actor.position - Vector2(0,220)
			$Camera.zoom = Vector2.ONE * 0.90
		2:
			$Camera.position = Vector2(1550,1120)
			$Camera.zoom = Vector2.ONE * 1.45
		3:
			$Camera.position = Vector2(3500,1260)
			$Camera.zoom = Vector2.ONE * 1.45
		4:
			$Camera.position = Vector2(2650,1130)
			$Camera.zoom = Vector2.ONE * 1.0
	actor.z_index = 2 if actor.position.y > 1325 else -1
	var in_portal: bool = actor.position.x > 2460 and actor.position.x < 2840 and actor.position.y > 980 and actor.position.y < 1340
	$Structure/Core.modulate.a = 0.55 if in_portal else 1.0


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			view_mode = 1 if view_mode == 0 else 0
		KEY_1:
			view_mode = 2
		KEY_2:
			view_mode = 3
		KEY_3:
			view_mode = 4
		KEY_R:
			$SurveyActor.position = START
		KEY_F2:
			show_ground = not show_ground
	update_view()
	get_viewport().set_input_as_handled()
