extends "res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd"

# Producer-only GPU exit fixture: executes the exact exporter cleanup method,
# without building terrain or touching production OUT/player save files.
func _initialize() -> void:
	source_design_only = true
	native_export_root = "res://build/world_map_v14_ninth_cursor_cleanup_fixture/"
	call_deferred("_run_cursor_cleanup_fixture")

func _run_cursor_cleanup_fixture() -> void:
	DirAccess.make_dir_recursive_absolute(native_export_root)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(64, 64)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	await _sync()
	var manager := root.get_node_or_null("CursorManager")
	assert(manager != null)
	for field: String in ["_arrow", "_hand", "_wait"]:
		var texture: Texture2D = manager.get(field)
		assert(texture != null and texture.get_size() == Vector2(48, 48))
	_json(native_export_root + "fixture.json", {
		"scope": "TOOL_CURSOR_EXIT_ONLY_NOT_WORLD_QA",
		"actual_exporter_path": "res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd",
		"actual_exporter_sha256": FileAccess.get_sha256("res://scripts/dev/build_world_map_native_full_v14_ninth_draft.gd"),
		"actual_three_cursor_textures_loaded": true,
		"fixture_sha256": FileAccess.get_sha256(get_script().resource_path)
	})
	print("[V14CursorExitFixture] loaded actual three 48x48 cursor textures; invoking exact exporter exit cleanup")
	await _finish_local_preview(0)
