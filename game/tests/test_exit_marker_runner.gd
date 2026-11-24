extends Node2D

var _failures: int = 0


func _ready() -> void:
	var zone: ExitZone = preload("res://scenes/exit_zone.tscn").instantiate()
	zone.destination_name = "林西村外山道"
	zone.position = Vector2(1510.0, 80.0)
	add_child(zone)
	zone.configure_marker(zone.position, Vector2(1536.0, 1024.0), Vector2(-69.0, 46.0))

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	zone._on_body_entered(player)

	var marker: Sprite2D = zone.get_node("MarkerVisual")
	var prompt: Label = zone.get_node("Prompt")
	_expect(marker.global_position.x <= 1386.0, "upper-right marker respects safe right margin")
	_expect(marker.global_position.y >= 90.0, "upper-right marker respects safe top margin")
	_expect(prompt.visible, "destination tip appears near exit")
	_expect(prompt.text == "林西村外山道", "destination tip shows place name")

	if _failures == 0:
		print("[PASS] exit marker and destination tip regression")
	else:
		push_error("[FAIL] exit marker regression: %d failure(s)" % _failures)
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("[ExitMarkerTest] %s" % message)
