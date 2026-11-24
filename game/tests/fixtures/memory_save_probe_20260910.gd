extends "res://scripts/autoload/save_manager.gd"

## Invoke the actual SaveManager serializer/restorer without touching user slots.
var captured: Dictionary = {}
func _write_slot_atomic(_slot: int, text: String) -> bool:
	captured = JSON.parse_string(text)
	return true
func _read_slot_data(_slot: int) -> Dictionary: return captured.duplicate(true)
func has_save(_slot: int) -> bool: return not captured.is_empty()
