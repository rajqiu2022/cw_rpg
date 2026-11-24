extends "res://tests/helpers/luoyang_enclosure_v11_toast_native_npc_band_probe_20261012.gd"
## All full run_objects behavior is inherited from frozen B3. Only six-roof
## source/display proof dispatch differs; the focused NPC tail is exact B3.
const DISPLAY = preload("res://tests/helpers/luoyang_roof_source_display_toast_adapter_20261012.gd")
const DISPLAY_PATH := "res://tests/helpers/luoyang_roof_source_display_toast_adapter_20261012.gd"
const DISPLAY_SHA := "3a7e68037fa6f1d1889d23f0e9d4cad73ef6d6e891b3786a69aa32966054c9cd"
const B3_PATH := "res://tests/helpers/luoyang_enclosure_v11_toast_native_npc_band_probe_20261012.gd"
const B3_SHA := "b1bacb485d2b35acf26696e1afcbe5fe1f1f5b9612fe891d26463a6708fb410a"

func configure(tree: SceneTree,actual_field: Control,original: Dictionary,checker: Callable,screenshot: Callable) -> bool:
	if FileAccess.get_sha256(DISPLAY_PATH)!=DISPLAY_SHA or FileAccess.get_sha256(B3_PATH)!=B3_SHA: return false
	if roof_proof!=null: roof_proof.call("release")
	roof_proof=DISPLAY.new()
	return super.configure(tree,actual_field,original,checker,screenshot)

func _front_proof(object: Dictionary) -> Dictionary:
	if not roof_ready or String(manifest.get("canonical_scene_id",""))!="ch4_s1_luoyang_yamen" or _current_identity().is_empty(): return {}
	var player: Node2D=field.get("_player") as Node2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var container: Node2D=field.get("world_container") as Node2D
	if definition==null or not definition.actor_positions_are_feet or player.get("_ground_anchored")!=true: return {}
	var result: Dictionary=roof_proof.call("prove_actual_display",String(object.id),prop(String(object.id)),player.get("sprite") as Sprite2D,float(player.call("get_depth_sort_y")),container.to_global(point(object.world_foot_px)).y,definition.player_visual_scale,true,field)
	data["source_display_bindings"]=(roof_proof.get("display_receipts") as Array).duplicate(true)
	return result

func run_six_roofs() -> void:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(shape != null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size == BODY and shape.position == Vector2.ZERO, "ordinary actor keeps real enabled centered 34x24 Rectangle, never travel circle")
	_check(absf(actor.scale.y - .945 * .91) < .000001 and absf(float(player.call("get_depth_sort_y")) - player.global_position.y) < .01, "normal adult .91 visual scale and grounded foot; no tiny-world identity")
	var source: Image = alpha.image_for(actor)
	var current: Rect2i = alpha.frame(actor, source)
	var top := current.size.y
	var bottom := -1
	for y in current.size.y:
		for x in current.size.x:
			if source.get_pixelv(current.position + Vector2i(x, y)).a > .12:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	# 113.5134 is DOWN reference, not a blanket current-facing height.
	var facing := ""
	for direction: String in IDLE_REFERENCES:
		var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_%s_25d_4f.png" % direction
		if actor.texture.resource_path == path: facing = direction
	_check(not facing.is_empty() and String(player.get("_direction")) == facing, "actual idle texture/facing identity matches one precise independently measured adult source")
	if not facing.is_empty():
		var expected: Dictionary = IDLE_REFERENCES[facing]
		_check(FileAccess.get_sha256(actor.texture.resource_path).to_lower() == String(expected.sha256), "actual facing original PNG exact SHA, not mutable self-reference")
		_check(bottom >= top and bottom - top + 1 == int(expected.height), "current idle-frame alpha height equals its exact facing reference (DOWN132/UP131/LR130), never widened tolerance")
		_check(absf((bottom - top + 1) * actor.scale.y - float(expected.height) * .945 * .91) < .0001, "actual current-frame effective alpha height uses actual Sprite scale and precise facing reference")
		_check(absf(float(manifest.ordinary_actor_effective_height_px) - 132 * .945 * .91) < .000001, "manifest adult height is explicitly DOWN132 reference, not all facing equality")
		data["adult_current_frame_height"] = {"facing": facing, "frame": actor.frame, "path": actor.texture.resource_path, "sha256": FileAccess.get_sha256(actor.texture.resource_path), "source_alpha_height_px": bottom - top + 1, "source_reference_height_px": expected.height, "actual_scale": actor.scale.y, "effective_height_px": (bottom - top + 1) * actor.scale.y, "down_reference_px": manifest.ordinary_actor_effective_height_px}
	_runtime_collision_inventory()
	for object: Dictionary in manifest.objects:
		if String(object.id) not in ROOF_PROOF.IDS: continue
		var id: String = String(object.id)
		var sprite: Sprite2D = prop(id)
		_check(sprite != null and sprite.texture.resource_path == String(object.texture), "independent runtime PNG binding: " + id)
		if sprite == null: continue
		_check((sprite.get_rect().size * sprite.scale.abs()).distance_to(point(object.render_size_px)) < .01 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual rendered dimensions/filter: " + id)
		_check(_physical_binding(id), "actual StaticBody geometry exactly matches original world solids: " + id)
		var collision: Dictionary = await _collision_trial(id) if blocking_ids.has(id) else {"blocking": false, "actual_static_body_absent": _physical_binding(id), "scope": "nonblocking; no fictional solid stop"}
		var alpha_record: Dictionary
		if object.get("role","")=="ground_overlay":
			var global_alpha_depth: int = alpha.effective_z(sprite)
			_check(not blocking_ids.has(id) and sprite.z_index==-2 and object.get("ghost_occlusion")==false,"ground-only mud overlay is neither solid nor occluding foreground: "+id)
			alpha_record={"scope":"GROUND_OVERLAY_NEGATIVE_NOT_STRONG_FOREGROUND_CREDIT","effective_z":global_alpha_depth,"ghost_occlusion":false}
		elif object.get("role","")=="water_decoration":
			alpha_record=await _water_decoration_domain_trial(object)
		else: alpha_record=await _alpha_trial(object)
		var record: Dictionary = {"id": id, "blocking": blocking_ids.has(id), "collision": collision, "alpha": alpha_record}
		data.objects.append(record)
	_check(data.objects.size() == 6, "limited six-roof focus complete; full manifest/collision inventory retained, not full-city coverage")
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var rows: Array = []
		for tick in 8:
			await driver.completed_actor_stage()
			var definition: SceneScript=field.get("_current_scene") as SceneScript
			if definition!=null and definition.has_meta("city_enclosure_manifest_sha"):
				var observed: Dictionary=_enclosure_npc_band(npc as NPCNode)
				_check(observed.get("complete")==true, "normally spawned original enclosure NPC independent native foot band and same-stage identity: " + String(npc.npc_id))
				rows.append(observed)
			else:
				var foot: float = npc.get_depth_sort_y()
				_check(npc.z_index == clampi(floori(foot / 8), 0, 255), "normally spawned original NPC ordinary foot band: " + String(npc.npc_id))
				rows.append({"foot": foot, "band": npc.z_index, "frame": npc.sprite.frame})
		data.npcs.append({"id": npc.npc_id, "rows": rows})
	_check(data.npcs.size() == (field.get("_npc_nodes") as Array).size(), "all normally spawned current gate-visible NPCs observed; other gated identities tested in normal action phase")

