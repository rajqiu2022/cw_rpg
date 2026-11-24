extends SceneTree
## ROOT ONLY: formal consumer residual, no candidate injection or travel/save.
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
		printerr("FORMAL16 EARLY_SUSPEND_MISSING")
		quit(1)
		return
	var adapter := root.get_node("PCSpriteViewRuntime")
	adapter.set_process(false)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/pc_hd_20261102c/source.json"))
	if not manifest.approved or manifest.mappings.size() != 15 or adapter._mappings.size() != 16 or not adapter._map_errors.is_empty():
		printerr("FORMAL16 MAP_ERROR ",adapter._mappings.size()," ",adapter._map_errors)
		quit(1)
		return
	var adopted := 0
	for source: String in adapter._mappings:
		var mapping: Dictionary = adapter._mappings[source]
		var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		npc.sprite_path = source
		root.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		adapter._adopt_actor(npc)
		adapter._sync_entry(adapter._actors[npc.get_instance_id()])
		var entry: Dictionary = adapter._actors[npc.get_instance_id()]
		var view := entry.view.get_ref() as Sprite2D
		var fields: Dictionary = {"reason_ok":entry.reason == "AUTHORED_NATIVE_HD_VIEW", "view_exists":view != null, "source_retained":npc.sprite.texture.resource_path == source}
		if view != null:
			fields["hd_filter"] = view.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var frame_texture := view.texture as AtlasTexture
			fields["frame_is_atlas"] = frame_texture != null
			if frame_texture != null:
				fields["atlas_identity"] = frame_texture.atlas == mapping.atlas
				fields["active_region_nonempty"] = frame_texture.region.has_area()
				fields["all_regions_valid"] = true
				for mapped_frame: AtlasTexture in mapping.frames:
					if mapped_frame.atlas != mapping.atlas or not mapped_frame.region.has_area():
						fields["all_regions_valid"] = false
			if manifest.mappings.has(source):
				fields["formal_atlas_path"] = frame_texture != null and frame_texture.atlas.resource_path == String(manifest.mappings[source].atlas)
				fields["base_atlas_mipmaps"] = frame_texture != null and frame_texture.atlas.get_image().has_mipmaps()
		var ok: bool = true
		for field: String in fields:
			if not bool(fields[field]): ok = false
		if not ok: failures += 1
		print("FORMAL16 CONSUMER ",JSON.stringify({"source":source,"formal":true,"adopted":ok,"reason":entry.reason,"fields":fields,"frames":npc.sprite.hframes*npc.sprite.vframes}))
		adopted += 1
		npc.queue_free()
		await process_frame
	print("FORMAL16_RESULT ",JSON.stringify({"formal_mapping_count":adapter._mappings.size(),"manifest_mapping_count":manifest.mappings.size(),"consumer_count":adopted,"failures":failures,"real_field":false,"real_save_content_access":false,"candidate_injection":false}))
	quit(0 if failures == 0 else 1)
