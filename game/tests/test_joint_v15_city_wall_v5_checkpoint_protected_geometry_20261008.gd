extends "res://tests/test_joint_v15_city_wall_v5_note_fine_geometry_limited_20261004.gd"
## All inherited geometry/input/cleanup/player predicates remain unchanged.
## This process never restores automatic checkpoint saves after creating fixtures.
const CHECKPOINT_BRIDGE_PATH := "res://scripts/autoload/platform_bridge.gd"
const CHECKPOINT_BRIDGE_SHA := "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
const CHECKPOINT_PARENT_PATH := "res://tests/test_joint_v15_city_wall_v5_note_fine_geometry_limited_20261004.gd"
const CHECKPOINT_PARENT_SHA := "2d5ee85613c0114d60e0edfafc348cc6cfdc162411fb78471d2542e68ec82eee"
var checkpoint_start: Dictionary = {}

func _run() -> void:
	# Before any await, preflight, fixture reset or actual Field creation.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("[PROTECTED CITY GEOMETRY FAIL] public checkpoint contract unavailable")
		quit(1)
		return
	var default_suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended", true)
	checkpoint_start = {"default_suspended":default_suspended,"suspended_before_any_await_or_fixture":bridge.call("is_checkpoint_saves_suspended"),"bridge_sha256":FileAccess.get_sha256(CHECKPOINT_BRIDGE_PATH)}
	if typeof(default_suspended) != TYPE_BOOL or default_suspended or bridge.call("is_checkpoint_saves_suspended") != true or FileAccess.get_sha256(CHECKPOINT_BRIDGE_PATH).to_lower() != CHECKPOINT_BRIDGE_SHA or FileAccess.get_sha256(CHECKPOINT_PARENT_PATH).to_lower() != CHECKPOINT_PARENT_SHA:
		push_error("[PROTECTED CITY GEOMETRY FAIL] default/public suspension/exact source binding")
		quit(1)
		return
	await super._run()

func _source_snapshot(ready: Dictionary) -> Dictionary:
	var snapshot: Dictionary = super._source_snapshot(ready)
	for path: String in [CHECKPOINT_BRIDGE_PATH,CHECKPOINT_PARENT_PATH]:
		snapshot[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return snapshot

func _write(name: String,value: Dictionary) -> bool:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true: return false
	var owned: Dictionary = value.duplicate(true)
	owned["checkpoint_suspension"] = {
		"scope":"PROCESS_FIXTURE_AUTOMATIC_CHECKPOINTS_NOT_EXECUTED",
		"start":checkpoint_start.duplicate(true),
		"suspended_at_write":true,
		"automatic_checkpoint_saves_tested":false,
		"automatic_checkpoint_saves_restored_before_exit":false,
		"manual_save_load_tested":false,
		"original_geometry_and_player_guards_preserved":true,
		"parent_entry_path":CHECKPOINT_PARENT_PATH,"parent_entry_sha256":CHECKPOINT_PARENT_SHA
	}
	return super._write(name,owned)
