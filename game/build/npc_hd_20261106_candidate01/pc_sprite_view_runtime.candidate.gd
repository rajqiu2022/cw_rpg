extends Node
## PC-only display adapter. Native actors retain textures, frames and gameplay.
## LINEAR is sampling improvement, not newly generated high-resolution artwork.

const OPTIONAL_MANIFEST := "res://art/characters/pc_hd_20261102c/source.json"
const MANIFEST_SCHEMA := "PC_HD_SPRITE_VIEW_20261102C_V1"
const VIEW_NAME := "PCNativeHDView"
const FARMER_SOURCE := "res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png"
const FARMER_ATLAS := "res://art/characters/pc_hd_20261102c/farmer_idle_down.png"

var _actors: Dictionary = {}
var _mappings: Dictionary = {}
var _map_errors: Array[String] = []
var _enabled := false
const OUTLINE_PATH := "res://shaders/interaction_outline.gdshader"
const OUTLINE_SHA := "e7dfbe9bae6b04a78a8fe78917806fe0baaedd8b44438c1a7a6fdd99bbcb3f39"
var _outline_verified := false
var _suppression_material: ShaderMaterial


func _ready() -> void:
	_enabled = not OS.has_feature("web") and not OS.has_feature("mobile")
	if not _enabled:
		set_process(false)
		return
	# Native NPC animation runs at 0, the existing gait addon runs at 100.
	process_priority = 200
	_outline_verified = FileAccess.get_sha256(OUTLINE_PATH) == OUTLINE_SHA
	var suppression_shader := Shader.new()
	suppression_shader.code = "shader_type canvas_item; void fragment() { discard; }"
	_suppression_material = ShaderMaterial.new()
	_suppression_material.shader = suppression_shader
	_install_mapping(FARMER_SOURCE, {
		"atlas": FARMER_ATLAS,
		"source_sha256": "904ff9885d7c7f7a3337b4db964141c6c1b4a8411cfc31a7b4b888723fd43900",
		"atlas_sha256": "68b2c05fdd44ab36c241987233ae8ddc0f75956e31dbf4e23b3df0f53ee83fa5",
		"cols": 4, "rows": 1, "row": 0, "framecount": 4,
		"source_hframes": 4, "source_vframes": 1,
		"source_cell": [160, 160], "atlas_size": [1536, 1024],
		"source_body_height": 140, "body_height": 808,
		"minimum_native_body_height": 320,
		"source_anchors": [[76.5, 160], [76.5, 160], [76.5, 160], [76.5, 160]],
		"body_anchors": [[191.5, 909], [167.5, 909], [150.5, 909], [134.5, 909]],
	})
	_load_optional_manifest()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_adopt_existing")


func _load_optional_manifest() -> void:
	if not FileAccess.file_exists(OPTIONAL_MANIFEST):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPTIONAL_MANIFEST))
	if not parsed is Dictionary or parsed.get("schema") != MANIFEST_SCHEMA or parsed.get("approved") != true or not parsed.get("mappings") is Dictionary:
		_map_errors.append("OPTIONAL_MANIFEST_NOT_APPROVED_OR_SCHEMA")
		return
	for source_path: String in parsed.mappings:
		if source_path == FARMER_SOURCE:
			_map_errors.append("OPTIONAL_MANIFEST_CANNOT_OVERRIDE_FARMER")
			continue
		if parsed.mappings[source_path] is Dictionary:
			_install_mapping(source_path, parsed.mappings[source_path])


func _install_mapping(source_path: String, declaration: Dictionary) -> void:
	var atlas_path := String(declaration.get("atlas", ""))
	# A missing newly authored resource is an honest low-resolution fallback.
	if not ResourceLoader.exists(source_path) or not ResourceLoader.exists(atlas_path):
		return
	if not source_path.begins_with("res://art/characters/") or not atlas_path.begins_with("res://art/characters/pc_hd_20261102c/") or ".." in source_path or ".." in atlas_path:
		_map_errors.append("MAPPING_PATH_SCOPE:" + source_path)
		return
	for pair: Array in [[source_path, "source_sha256"], [atlas_path, "atlas_sha256"]]:
		var expected := String(declaration.get(pair[1], ""))
		if expected.length() != 64 or FileAccess.get_sha256(pair[0]) != expected:
			_map_errors.append("MAPPING_SHA:" + source_path)
			return
	var source := load(source_path) as Texture2D
	var atlas := load(atlas_path) as Texture2D
	var mapping := prepare_mapping(source, atlas, declaration)
	if mapping.is_empty():
		_map_errors.append("MAPPING_GEOMETRY:" + source_path)
		return
	_mappings[source_path] = mapping


static func _numeric_pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))


static func prepare_mapping(source: Texture2D, atlas: Texture2D, declaration: Dictionary) -> Dictionary:
	# Pure preparation hook for Root's small isolated structure check. All pixel
	# coordinates are audited metadata; no CPU image scan occurs in _process.
	if source == null or atlas == null:
		return {}
	var cols := int(declaration.get("cols", 0))
	var rows := int(declaration.get("rows", 0))
	var row := int(declaration.get("row", -1))
	var count := int(declaration.get("framecount", 0))
	var source_hframes := int(declaration.get("source_hframes", 0))
	var source_vframes := int(declaration.get("source_vframes", 0))
	var source_cell_raw: Variant = declaration.get("source_cell")
	var atlas_size_raw: Variant = declaration.get("atlas_size")
	var source_height := float(declaration.get("source_body_height", 0))
	var height := float(declaration.get("body_height", 0))
	var minimum := float(declaration.get("minimum_native_body_height", 320))
	if cols <= 0 or rows <= 0 or count <= 0 or count > cols or row < 0 or row >= rows or source_hframes <= 0 or source_vframes <= 0 or count != source_hframes * source_vframes:
		return {}
	if not _numeric_pair(source_cell_raw) or not _numeric_pair(atlas_size_raw):
		return {}
	var source_cell := Vector2(float(source_cell_raw[0]), float(source_cell_raw[1]))
	var atlas_size := Vector2(float(atlas_size_raw[0]), float(atlas_size_raw[1]))
	if source_cell.x <= 0 or source_cell.y <= 0 or source.get_size() != source_cell * Vector2(source_hframes, source_vframes) or atlas.get_size() != atlas_size or atlas.get_width() % cols != 0 or atlas.get_height() % rows != 0:
		return {}
	if not is_finite(source_height) or not is_finite(height) or not is_finite(minimum) or source_height <= 0 or height < maxf(320, minimum):
		return {}
	var source_anchors: Variant = declaration.get("source_anchors")
	var body_anchors: Variant = declaration.get("body_anchors")
	if not source_anchors is Array or not body_anchors is Array or source_anchors.size() != count or body_anchors.size() != count:
		return {}
	var cell := atlas_size / Vector2(cols, rows)
	if source_height > source_cell.y or height > cell.y:
		return {}
	var frames: Array[AtlasTexture] = []
	var source_points: Array[Vector2] = []
	var body_points: Array[Vector2] = []
	for frame: int in range(count):
		if not _numeric_pair(source_anchors[frame]) or not _numeric_pair(body_anchors[frame]):
			return {}
		var source_point := Vector2(float(source_anchors[frame][0]), float(source_anchors[frame][1]))
		var body_point := Vector2(float(body_anchors[frame][0]), float(body_anchors[frame][1]))
		if source_point.x < 0 or source_point.y < 0 or source_point.x > source_cell.x or source_point.y > source_cell.y or body_point.x < 0 or body_point.y < 0 or body_point.x > cell.x or body_point.y > cell.y:
			return {}
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = atlas
		frame_texture.region = Rect2(Vector2(frame, row) * cell, cell)
		frame_texture.filter_clip = true
		frames.append(frame_texture)
		source_points.append(source_point)
		body_points.append(body_point)
	return {"source": source, "atlas": atlas, "frames": frames,
		"source_hframes": source_hframes, "source_vframes": source_vframes,
		"source_cell": source_cell, "cell": cell,
		"source_anchors": source_points, "body_anchors": body_points,
		"ratio": source_height / height, "source_body_height": source_height,
		"body_height": height}


func _adopt_existing() -> void:
	for group_name: String in ["player", "npc"]:
		for actor: Node in get_tree().get_nodes_in_group(group_name):
			_adopt_actor(actor)


func _on_node_added(node: Node) -> void:
	if node is Player or node is NPCNode:
		call_deferred("_adopt_weak_actor", weakref(node))
	elif node is Sprite2D and (node.get_parent() is Player or node.get_parent() is NPCNode) and node.name == &"Sprite2D":
		call_deferred("_adopt_weak_actor", weakref(node.get_parent()))


func _adopt_weak_actor(reference: WeakRef) -> void:
	var actor := reference.get_ref() as Node
	if is_instance_valid(actor) and actor.is_inside_tree() and not actor.is_queued_for_deletion():
		_adopt_actor(actor)


func _adopt_actor(actor: Node) -> void:
	if not (actor is Player or actor is NPCNode) or not actor.is_node_ready():
		return
	var sprite := actor.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	if _actors.has(actor.get_instance_id()):
		var previous: Sprite2D = _actors[actor.get_instance_id()].sprite.get_ref() as Sprite2D
		if previous == sprite:
			return
		_release_entry(actor.get_instance_id())
	var entry := {"actor": weakref(actor), "sprite": weakref(sprite),
		"original_filter": sprite.texture_filter, "view": null,
		"leased": false, "original_color": Color.WHITE, "applied_color": Color.WHITE,
		"material_leased": false, "original_material": null, "outline_copy": null,
		"outline_source": null,
		"reason": "REGISTERED", "path": ""}
	_actors[actor.get_instance_id()] = entry
	_sync_entry(entry)


func _release_hd(entry: Dictionary, reason: String) -> void:
	var sprite: Sprite2D = entry.sprite.get_ref() as Sprite2D
	_release_material(entry, sprite)
	if is_instance_valid(sprite) and entry.leased and sprite.self_modulate == entry.applied_color:
		sprite.self_modulate = entry.original_color
	entry.leased = false
	var view: Sprite2D = entry.view.get_ref() as Sprite2D if entry.view is WeakRef else null
	if is_instance_valid(view):
		view.hide()
	entry.reason = reason


func _release_material(entry: Dictionary, sprite: Sprite2D) -> void:
	if is_instance_valid(sprite) and entry.material_leased and sprite.material == _suppression_material:
		var actor: Node = entry.actor.get_ref() as Node
		# NPC's exit callback cannot clear our replacement by native identity.
		# Honor the owner's real range state instead of resurrecting its outline.
		if actor is NPCNode and entry.original_material == actor.get("_interaction_outline_material") and not bool(actor.get("_in_range")):
			sprite.material = null
		else:
			sprite.material = entry.original_material
	entry.material_leased = false
	entry.original_material = null


func _known_outline(material: Material) -> bool:
	return _outline_verified and material is ShaderMaterial and material.shader != null and material.shader.resource_path == OUTLINE_PATH


func _sync_entry(entry: Dictionary) -> void:
	var sprite: Sprite2D = entry.sprite.get_ref() as Sprite2D
	if not is_instance_valid(sprite) or sprite.is_queued_for_deletion():
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	entry.path = sprite.texture.resource_path if sprite.texture != null else ""
	if sprite.texture == null or not _mappings.has(entry.path):
		_release_hd(entry, "NO_AUTHORED_HD_FOR_CURRENT_TEXTURE")
		return
	var mapping: Dictionary = _mappings[entry.path]
	var actor: Node = entry.actor.get_ref() as Node
	if entry.material_leased and actor is NPCNode and entry.original_material == actor.get("_interaction_outline_material") and not bool(actor.get("_in_range")):
		_release_material(entry, sprite)
	# Only the byte-verified native outline is supported; foreign effects retain
	# their original display. External material changes are observed, never undone.
	if entry.material_leased and sprite.material != _suppression_material:
		entry.material_leased = false
		entry.original_material = null
	var native_material: Material = entry.original_material if entry.material_leased else sprite.material
	if sprite.use_parent_material or (native_material != null and not _known_outline(native_material)):
		_release_hd(entry, "NATIVE_MATERIAL_FALLBACK")
		return
	if sprite.texture != mapping.source or sprite.hframes != int(mapping.source_hframes) or sprite.vframes != int(mapping.source_vframes) or sprite.region_enabled or sprite.frame < 0 or sprite.frame >= mapping.frames.size():
		_release_hd(entry, "NATIVE_LAYOUT_NOT_DECLARED")
		return
	var view: Sprite2D = entry.view.get_ref() as Sprite2D if entry.view is WeakRef else null
	if not is_instance_valid(view):
		view = Sprite2D.new()
		view.name = VIEW_NAME
		view.centered = false
		view.use_parent_material = false
		view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.add_child(view)
		entry.view = weakref(view)
	if native_material != null:
		if not entry.material_leased:
			entry.original_material = native_material
			# Cache by native material identity. Another owner may reapply the same
			# outline each frame; that must not allocate one duplicate per frame.
			if entry.outline_source != native_material or entry.outline_copy == null:
				entry.outline_copy = native_material.duplicate() as ShaderMaterial
				entry.outline_source = native_material
			entry.material_leased = true
		var copied: ShaderMaterial = entry.outline_copy
		for parameter: String in ["outline_color", "pulse", "base_strength"]:
			copied.set_shader_parameter(parameter, native_material.get_shader_parameter(parameter))
		copied.set_shader_parameter("outline_width", float(native_material.get_shader_parameter("outline_width")) / float(mapping.ratio))
		view.material = copied
		sprite.material = _suppression_material
	else:
		view.material = null
	if not entry.leased or sprite.self_modulate != entry.applied_color:
		entry.original_color = sprite.self_modulate
	entry.leased = true
	entry.applied_color = Color(entry.original_color.r, entry.original_color.g, entry.original_color.b, 0)
	view.self_modulate = entry.original_color
	sprite.self_modulate = entry.applied_color
	var frame := sprite.frame
	var source_point: Vector2 = mapping.source_anchors[frame]
	var body_point: Vector2 = mapping.body_anchors[frame]
	if sprite.flip_h:
		source_point.x = mapping.source_cell.x - source_point.x
		body_point.x = mapping.cell.x - body_point.x
	if sprite.flip_v:
		source_point.y = mapping.source_cell.y - source_point.y
		body_point.y = mapping.cell.y - body_point.y
	view.texture = mapping.frames[frame]
	view.scale = Vector2.ONE * float(mapping.ratio)
	view.position = sprite.get_rect().position + source_point - body_point * float(mapping.ratio)
	view.flip_h = sprite.flip_h
	view.flip_v = sprite.flip_v
	view.show()
	entry.reason = "AUTHORED_NATIVE_HD_VIEW"


func _process(_delta: float) -> void:
	# Registered actors only. No recurring scene/group or alpha-pixel scan.
	for key: int in _actors.keys():
		var entry: Dictionary = _actors[key]
		var actor: Node = entry.actor.get_ref() as Node
		var sprite: Sprite2D = entry.sprite.get_ref() as Sprite2D
		if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.is_queued_for_deletion() or not is_instance_valid(sprite) or sprite.get_parent() != actor:
			_release_entry(key)
			continue
		_sync_entry(entry)


func _release_entry(key: int) -> void:
	var entry: Dictionary = _actors[key]
	_release_hd(entry, "ADAPTER_RELEASE")
	var sprite: Sprite2D = entry.sprite.get_ref() as Sprite2D
	if is_instance_valid(sprite) and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR:
		sprite.texture_filter = entry.original_filter
	var view: Sprite2D = entry.view.get_ref() as Sprite2D if entry.view is WeakRef else null
	if is_instance_valid(view) and not view.is_queued_for_deletion():
		view.queue_free()
	_actors.erase(key)


func _exit_tree() -> void:
	for key: int in _actors.keys():
		_release_entry(key)


func get_debug_state() -> Dictionary:
	var actors: Array[Dictionary] = []
	for key: int in _actors:
		var entry: Dictionary = _actors[key]
		actors.append({"instance_id": key, "texture_path": entry.path,
			"hd_visible": entry.leased, "reason": entry.reason})
	return {"enabled_pc": _enabled, "registered_actors": _actors.size(),
		"mapping_count": _mappings.size(), "map_errors": _map_errors.duplicate(),
		"actors": actors, "native_body_or_texture_writes": false,
		"ghost_contract_unchanged": true, "ghost_stays_original_resolution": true,
		"linear_sampling_is_not_hd": true, "per_frame_pixel_scans": 0}
