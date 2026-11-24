extends "res://tests/test_world_map_v14_production_20261002.gd"

## Source-only until producer grants a bounded CPU slot. This proves the
## explicit 1px integer-foot / current idle-frame0 domain, NOT every subpixel
## position, walking frame, or continuous-world absence. New output only.
const CASES := {"original_grove_11": true, "native_rock_foothill": false, "native_cliff_south": false}

func _actor_offsets() -> Array:
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	var result: Array = []
	for facing: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_set_idle(facing)
		var actor: Sprite2D = player.get("sprite")
		var image := actor.texture.get_image()
		if image.is_compressed(): image.decompress()
		var frame := _sprite_frame(actor, image)
		var rect := actor.get_rect()
		var map := container.global_transform.affine_inverse() * actor.global_transform
		var offsets := PackedVector2Array()
		var solid := PackedByteArray()
		for y in frame.size.y:
			for x in frame.size.x:
				var alpha := image.get_pixelv(frame.position + Vector2i(x, y)).a
				if alpha <= .01: continue
				var uv := (Vector2(x, y) + Vector2(.5, .5)) / Vector2(frame.size)
				if actor.flip_h: uv.x = 1.0 - uv.x
				if actor.flip_v: uv.y = 1.0 - uv.y
				offsets.append(map * (rect.position + uv * rect.size) - player.position)
				solid.append(1 if alpha > .12 else 0)
		var bounds := _alpha_bounds_world_local(actor)
		bounds.position -= player.position
		# Independent reconstruction of the real visual footline. Even a
		# ground-anchored sprite can have a tiny scale/position residual at an
		# exact 8px boundary; do not silently use physical body Y or +/-1 bands.
		var visual_offset := actor.position.y + float(image.get_height()) * actor.scale.y * .45
		result.append({"facing": facing, "frame": actor.frame, "bounds": bounds, "offsets": offsets, "solid": solid, "visual_offset_y": visual_offset})
	return result

func _proof_case(id: String, front: bool, actor_faces: Array) -> Dictionary:
	var prop: Sprite2D = runtime_props[id]
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	var definition: Dictionary
	for d: Dictionary in world.map_layout.visual_objects:
		if String(d.get("id")) == id: definition = d; break
	var base_y := float(definition.get("depth_sort_foot_y")) * WORLD_SIZE.y
	var source := prop.texture.get_image()
	if source.is_compressed(): source.decompress()
	var prop_rect := prop.get_rect()
	var prop_frame := _sprite_frame(prop, source)
	# Used-rect bounds plus one SOURCE texel on each side conservatively retain
	# LINEAR interpolation. This is not the generated overlap-mask bbox.
	var prop_bounds := _alpha_bounds_world_local(prop)
	var source_texel := prop_rect.size / Vector2(prop_frame.size)
	var local_map := container.global_transform.affine_inverse() * prop.global_transform
	var texel_extent := local_map.basis_xform(source_texel)
	prop_bounds = prop_bounds.grow(maxf(absf(texel_extent.x), absf(texel_extent.y)))
	var relative: Rect2 = actor_faces[0].bounds
	for actor_face: Dictionary in actor_faces: relative = relative.merge(actor_face.bounds)
	var domain := Rect2(prop_bounds.position - relative.end, prop_bounds.size + relative.size)
	var lo := Vector2i(maxi(0, ceili(domain.position.x)), maxi(0, ceili(domain.position.y)))
	var hi := Vector2i(mini(int(WORLD_SIZE.x)-1, floori(domain.end.x)), mini(int(WORLD_SIZE.y)-1, floori(domain.end.y)))
	if front: lo.y = maxi(lo.y, floori(base_y) + 1)
	else: hi.y = mini(hi.y, ceili(base_y) - 1)
	var report := {"id": id, "front": front, "scope": "ALL_INTEGER_1PX_FEET_CURRENT_IDLE_FRAME0_FOUR_FACING_NOT_CONTINUOUS_SUBPIXEL_PROOF", "base_y": base_y,
		"domain": [domain.position.x, domain.position.y, domain.size.x, domain.size.y], "integer_min": [lo.x,lo.y], "integer_max": [hi.x,hi.y],
		"tested_centers": 0, "legal_centers": 0, "depth_eligible_centers": 0, "direction_tests": 0, "reason_counts": {}, "first_rejections": {},
		"solid_alpha_positive_stations": 0, "soft_alpha_positive_stations": 0, "max_solid_hits": 0, "max_soft_hits": 0, "depth_runtime_mismatches": 0, "first_hit": {}, "best_hit": {}, "best_soft": {}, "boundary_stations": [], "visual_offset_y": actor_faces[0].visual_offset_y}
	for face: Dictionary in actor_faces:
		_check(face.visual_offset_y == report.visual_offset_y,"four current idle directions retain exactly the independently reconstructed visual foot offset: "+id)
	var target_map := prop.global_transform.affine_inverse() * container.global_transform
	var prepared: Array = []
	for face: Dictionary in actor_faces:
		var delta_target := PackedVector2Array()
		for delta: Vector2 in face.offsets: delta_target.append(target_map.basis_xform(delta))
		prepared.append({"facing": face.facing, "bounds": face.bounds, "offsets": delta_target, "solid": face.solid})
	for y in range(lo.y, hi.y+1):
		for x in range(lo.x, hi.x+1):
			var point := Vector2(x,y)
			report.tested_centers += 1
			var reason := _raw_foot_reason(world, point / WORLD_SIZE)
			if not reason.is_empty():
				var kind := String(reason.get("kind", "unknown")) + ":" + String(reason.get("object_id", ""))
				report.reason_counts[kind] = int(report.reason_counts.get(kind,0))+1
				if not report.first_rejections.has(kind): report.first_rejections[kind] = {"point": [x,y], "reason": reason}
				continue
			report.legal_centers += 1
			var expected_z := clampi(floori((container.to_global(point).y + float(report.visual_offset_y)) / 8.0),0,512)
			var expected_front := expected_z > prop.z_index or (expected_z == prop.z_index and player.get_parent() == prop.get_parent() and player.get_index() > prop.get_index())
			if expected_front != front: continue
			report.depth_eligible_centers += 1
			player.position = point
			player.call("refresh_depth_sort")
			if player.z_index != expected_z or not _depth_order(player,prop,front): report.depth_runtime_mismatches += 1
			var target_origin := target_map * point
			for face: Dictionary in prepared:
				report.direction_tests += 1
				var actor_bounds: Rect2 = face.bounds
				actor_bounds.position += point
				if not actor_bounds.intersects(prop_bounds): continue
				var hits := 0
				var soft := 0
				for index in face.offsets.size():
					var local: Vector2 = target_origin + face.offsets[index]
					if not prop_rect.has_point(local): continue
					var alpha := _prop_sample_alpha(prop,source,(local-prop_rect.position)/prop_rect.size)
					if alpha > .01: soft += 1
					if alpha > .12 and face.solid[index] == 1: hits += 1
				report.max_solid_hits = maxi(report.max_solid_hits,hits)
				report.max_soft_hits = maxi(report.max_soft_hits,soft)
				if soft > 0:
					report.soft_alpha_positive_stations += 1
					if report.best_soft.is_empty() or soft > int(report.best_soft.soft_hits): report.best_soft = {"point": [x,y],"facing":[face.facing.x,face.facing.y],"solid_hits":hits,"soft_hits":soft}
				if hits > 0:
					report.solid_alpha_positive_stations += 1
					if report.first_hit.is_empty(): report.first_hit = {"point": [x,y], "facing": [face.facing.x,face.facing.y], "solid_hits": hits,"soft_hits":soft}
					if report.best_hit.is_empty() or hits > int(report.best_hit.solid_hits): report.best_hit = {"point": [x,y], "facing": [face.facing.x,face.facing.y], "solid_hits": hits,"soft_hits":soft}
				if report.boundary_stations.size() < 4: report.boundary_stations.append({"point": [x,y],"facing":[face.facing.x,face.facing.y],"solid_hits":hits,"soft_hits":soft})
	_check(report.depth_runtime_mismatches == 0,"every independent integer-depth eligible station matches actual runtime order: "+id)
	_check(report.tested_centers == maxi(0,hi.x-lo.x+1)*maxi(0,hi.y-lo.y+1),"entire bounded 1px lattice visited, not a coarse scan: "+id)
	if not report.best_hit.is_empty(): report.boundary_stations.append(report.best_hit)
	if not report.best_soft.is_empty() and report.best_soft != report.best_hit: report.boundary_stations.append(report.best_soft)
	if id == "original_grove_11" and front:
		# Exact nearest-neighbour center-cell preimages cover every continuous
		# candidate foot in this bounded current-frame Minkowski domain. A
		# rejected center suffices to reject the complete foot (center is sample0).
		# Unlike the integer scan this includes the fractional row below3065.
		var oracle := _raw_oracle(world)
		var raw: Image = oracle.mask
		var region := domain.intersection(Rect2(Vector2.ZERO,WORLD_SIZE))
		var lower_y := maxf(region.position.y,base_y-float(report.visual_offset_y))
		var pixel_lo := Vector2i(roundi(region.position.x/WORLD_SIZE.x*(raw.get_width()-1)),roundi(lower_y/WORLD_SIZE.y*(raw.get_height()-1)))
		var pixel_hi := Vector2i(roundi(region.end.x/WORLD_SIZE.x*(raw.get_width()-1)),mini(raw.get_height()-1,roundi(region.end.y/WORLD_SIZE.y*(raw.get_height()-1))))
		var covered := 0
		var open := 0
		for py in range(pixel_lo.y,pixel_hi.y+1):
			for px in range(pixel_lo.x,pixel_hi.x+1):
				covered += 1
				var color := raw.get_pixel(px,py)
				if color.a >= .5 and maxf(color.r,maxf(color.g,color.b)) >= .5: open += 1
		report.continuous_center_cell_cover = {"scope":"CONTINUOUS_CURRENT_FRAME0_FOUR_DIRECTION_BOUNDING_DOMAIN_CENTER_NAV_REJECTION_NOT_ALL_ANIMATIONS","world_x":[region.position.x,region.end.x],"world_y":[lower_y,region.end.y],"raw_pixel_min":[pixel_lo.x,pixel_lo.y],"raw_pixel_max":[pixel_hi.x,pixel_hi.y],"pixel_count":covered,"open_pixels":open,"sampling":"nearest raw round(normalized*(image_size-1)); every overlapping cell preimage conservatively included"}
		# The fractional first center row is partly white: retain that fact.
		# Complete feet include the +6px southern cardinal sample. Centers
		# >= WORLD_SIZE.y-6 are outside at that sample; for all remaining
		# centers conservatively cover every possible raw south-sample cell.
		var safe_upper_y := minf(region.end.y,WORLD_SIZE.y-6.0)
		var south_lo := Vector2i(maxi(0,pixel_lo.x-1),roundi((lower_y+6.0)/WORLD_SIZE.y*(raw.get_height()-1)))
		var south_hi := Vector2i(mini(raw.get_width()-1,pixel_hi.x+1),mini(raw.get_height()-1,roundi((safe_upper_y+6.0)/WORLD_SIZE.y*(raw.get_height()-1))))
		var south_covered := 0
		var south_open := 0
		for py in range(south_lo.y,south_hi.y+1):
			for px in range(south_lo.x,south_hi.x+1):
				south_covered += 1
				var color := raw.get_pixel(px,py)
				if color.a>=.5 and maxf(color.r,maxf(color.g,color.b))>=.5: south_open+=1
		report.continuous_complete_foot_cover = {"scope":"CONTINUOUS_BOUNDED_CURRENT_FRAME0_FRONT_DOMAIN_CARDINAL_SOUTH_SAMPLE_REJECTION_NOT_ALL_ANIMATIONS","center_white_pixels_retained":open,"candidate_center_y":[lower_y,safe_upper_y],"south_sample_y":[lower_y+6.0,safe_upper_y+6.0],"raw_pixel_min":[south_lo.x,south_lo.y],"raw_pixel_max":[south_hi.x,south_hi.y],"pixel_count":south_covered,"open_pixels":south_open,"higher_center_y_canvas_denied_from":WORLD_SIZE.y-6.0,"x_padding_pixels":1,"source":"original imported walk.png; source raw alpha/RGB sampled, not generated proof mask"}
		_check(covered>0 and south_covered>0 and south_open==0,"continuous meaningful front-domain COMPLETE south foot is raw-denied or outside, even when center is white: "+id)
	# An absence is an observation, not an automatic acceptance waiver.
	# Positive stations must become real main-suite evidence after review.
	for station: Dictionary in report.boundary_stations:
		var point := _point(station.point)
		_check(await _place_fixture(point),"strict proof boundary remains complete-foot legal: "+id)
		_set_idle(_point(station.facing))
		var actual_hits := _actual_actor_alpha_intersection(prop)
		_check(actual_hits == int(station.solid_hits),"cached independent original-current-frame count equals live source-alpha count: "+id)
		var soft_hits := _live_soft_hits(prop)
		_check(soft_hits == int(station.soft_hits),"soft original current-frame intersection is separately reproduced, not lowered solid threshold: "+id)
		var ghost := await _ghost_mask_check("bounded alpha proof "+id)
		station.actual_union_pixels = int(ghost.pixels)
	var center := _point(definition.get("pos"))*WORLD_SIZE + _point(definition.get("collision_offset",Vector2.ZERO))*WORLD_SIZE
	_check(not _raw_foot_reason(world,center/WORLD_SIZE).is_empty(),"no-station classification never permits standing inside solid footprint: "+id)
	print("[AlphaDomainProof] ",JSON.stringify(report))
	return report

func _live_soft_hits(prop: Sprite2D) -> int:
	var actor: Sprite2D = field.get("_player").get("sprite")
	var original := actor.texture.get_image()
	var target := prop.texture.get_image()
	if original.is_compressed(): original.decompress()
	if target.is_compressed(): target.decompress()
	var frame := _sprite_frame(actor,original)
	var rect := actor.get_rect()
	var target_rect := prop.get_rect()
	var result := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if original.get_pixelv(frame.position+Vector2i(x,y)).a<=.01: continue
			var uv := (Vector2(x,y)+Vector2(.5,.5))/Vector2(frame.size)
			if actor.flip_h: uv.x=1.0-uv.x
			if actor.flip_v: uv.y=1.0-uv.y
			var local := prop.to_local(actor.to_global(rect.position+uv*rect.size))
			if target_rect.has_point(local) and _prop_sample_alpha(prop,target,(local-target_rect.position)/target_rect.size)>.01: result+=1
	return result

func _run() -> void:
	candidate_stage = true; active_id = CANDIDATE_ID; active_path = CANDIDATE_PATH
	qa_scope = "FOCUSED_INTEGER_ALPHA_DOMAIN_PROOF_NOT_FULL_MAP_NOT_CONTINUOUS"
	phase_output = OUTPUT_DIR + "alpha_domain_proof_"+str(int(Time.get_unix_time_from_system()))+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	manifest = _json(MANIFEST_PATH); source_contract = _json(SOURCE_PATH)
	world = load(active_path) as SceneScript
	_check(DisplayServer.get_name()=="headless","bounded original-alpha proof requires separately approved CPU-only slot")
	if failed>0 or world==null: _finish(); return
	_fixture_new_game()
	if not await _open_world(world.player_spawn): _finish(); return
	_collect_runtime()
	var faces := _actor_offsets()
	var reports: Array = []
	for id: String in CASES:
		_check(runtime_props.has(id),"real frozen fifth runtime entity exists for exhaustive proof: "+id)
		if runtime_props.has(id): reports.append(await _proof_case(id,bool(CASES[id]),faces))
	var out := FileAccess.open(phase_output+"domain_evidence.json",FileAccess.WRITE)
	if out!=null: out.store_string(JSON.stringify(reports,"\t")); out.close()
	_finish()
