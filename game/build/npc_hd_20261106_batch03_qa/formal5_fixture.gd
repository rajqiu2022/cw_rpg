extends SceneTree
## ROOT ONLY after formal adoption. No candidate injection, travel or save content.
const PREFIX := "res://art/characters/street_expansion_v1/npc_street_merchant_"
const SUFFIXES: Array[String] = ["idle_down_4f", "down_walk_8f", "up_walk_8f", "left_walk_8f", "right_walk_8f"]
const COUNTS: Array[int] = [4, 8, 8, 8, 8]
var suspended := false
var failures := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	call_deferred("_run")

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _run() -> void:
	if not suspended:
		printerr("FORMAL_B03 EARLY_SUSPEND_MISSING")
		quit(1)
		return
	var adapter := root.get_node("PCSpriteViewRuntime")
	adapter.set_process(false)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/pc_hd_20261102c/source.json"))
	if not bool(manifest.get("approved", false)) or manifest.mappings.size() != 23 or adapter._mappings.size() != 24 or not adapter._map_errors.is_empty():
		printerr("FORMAL_B03 MAP_ERROR ", adapter._mappings.size(), " ", adapter._map_errors)
		quit(1)
		return
	var count := 0
	for suffix: String in SUFFIXES:
		var source := PREFIX + suffix + "_v3_runtime.png"
		if not adapter._mappings.has(source):
			printerr("FORMAL_B03 MISSING_SOURCE ", source)
			quit(1)
			return
		var mapping: Dictionary = adapter._mappings[source]
		var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		if npc == null:
			quit(1)
			return
		npc.sprite_path = source
		root.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		adapter._adopt_actor(npc)
		if not adapter._actors.has(npc.get_instance_id()):
			printerr("FORMAL_B03 NOT_ADOPTED ", source)
			quit(1)
			return
		var entry: Dictionary = adapter._actors[npc.get_instance_id()]
		adapter._sync_entry(entry)
		var view := entry.view.get_ref() as Sprite2D
		var fields: Dictionary = {
			"reason_ok": entry.reason == "AUTHORED_NATIVE_HD_VIEW",
			"view_exists": view != null,
			"source_retained": npc.sprite.texture.resource_path == source,
			"frame_count": npc.sprite.hframes * npc.sprite.vframes == COUNTS[count] and mapping.frames.size() == COUNTS[count],
		}
		if view != null:
			fields["hd_filter"] = view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var frame_texture := view.texture as AtlasTexture
			fields["frame_is_atlas"] = frame_texture != null
			if frame_texture != null:
				fields["atlas_identity"] = frame_texture.atlas == mapping.atlas
				fields["formal_atlas_path"] = frame_texture.atlas.resource_path == String(manifest.mappings[source].atlas)
				fields["base_mipmaps"] = frame_texture.atlas.get_image().has_mipmaps()
				fields["all_regions_valid"] = true
				for mapped_frame: AtlasTexture in mapping.frames:
					if mapped_frame.atlas != mapping.atlas or not mapped_frame.region.has_area(): fields["all_regions_valid"] = false
		var ok := true
		for field: String in fields:
			if not bool(fields[field]): ok = false
		if not ok: failures += 1
		print("FORMAL_B03 CONSUMER ", JSON.stringify({"source": source, "adopted": ok, "fields": fields}))
		count += 1
		adapter._release_entry(npc.get_instance_id())
		npc.queue_free()
		await process_frame
	await process_frame
	print("FORMAL_B03_RESULT ", JSON.stringify({"formal_mapping_count": adapter._mappings.size(), "manifest_mapping_count": manifest.mappings.size(), "new_consumer_count": count, "failures": failures, "candidate_injection": false, "real_field": false, "real_save_content_access": false}))
	quit(0 if failures == 0 and count == 5 else 1)
