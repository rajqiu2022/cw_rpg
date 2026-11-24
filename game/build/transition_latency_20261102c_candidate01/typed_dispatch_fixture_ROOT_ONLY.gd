extends "res://scripts/ui/loading_screen.gd"
## A hidden same-PackedScene instance, not the actual manager's screen.
var override_calls := 0

func hide_screen() -> void:
	override_calls += 1
	await super.hide_screen()
