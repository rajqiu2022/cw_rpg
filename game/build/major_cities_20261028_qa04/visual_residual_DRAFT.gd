extends "res://build/major_cities_20261028_qa04/completion_actual_READY.gd"
## Visual suffix only. Original 176 technical checks are not city ART approval.
const VISUAL_FIXTURE := "res://build/major_cities_20261028_qa04/visual_residual_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(VISUAL_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FINAL_VISUAL_SUFFIX_ONLY"): finish(); return
	spec=raw
	if not check(spec.whole_seconds==30 and spec.entry_seconds==20 and spec.max_png==1,"ONE_PUBLIC_SETUP_ONE_NATIVE_ONE_REVIEW"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.inherited_actual))
	check(original.passed==true and original.checks==176 and original.input_ticks==406,"ORIGINAL176_TECHNICAL_COMPONENTS_INHERITED_NOT_ART_PASS")
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	save_before=file_facts(baseline.save15.keys())
	var author: Variant=load(spec.author); var previous: Variant=load(spec.prior_author)
	if not check(author!=null and previous!=null,"FINAL_VISUAL_AUTHOR_AND_FROZEN_PRIOR"): finish(); return
	# One typed identity comparison, not another geometry/projection matrix.
	check(author.building_specs()==previous.building_specs() and author.prop_specs()==previous.prop_specs() and author.completion_occupancy_rows()==previous.completion_occupancy_rows(),"STATIC_OCCUPANCY_TYPED_IDENTICAL_NO_GEOMETRY_RERUN")
	var completion: Dictionary=author.completion_data()
	for contract: Dictionary in spec.farmland_contracts:
		var matching: Array=(completion.ground as Array).filter(func(row: Dictionary) -> bool: return String(row.id)==String(contract.id))
		if not check(matching.size()==1,"ONE_NATIVE_UV_FIELD:"+String(contract.id)): continue
		var row: Dictionary=matching[0]
		check(row.source_uv==spec.farmland_source_uv and point(row.source_foot)==Vector2(253,740) and point(row.world_foot)==point(contract.foot) and float(row.source_scale)==1.5 and not row.has("body"),"EXACT_SOURCE_UV_FOOT_SCALE_NO_NEW_BODY:"+String(contract.id))
		var expected_polygon: Array=[]
		for uv: Array in spec.farmland_source_uv:
			var p: Vector2=point(contract.foot)+(point(uv)-Vector2(253,740))*1.5
			expected_polygon.append([p.x,p.y])
		check(row.polygon==expected_polygon,"NATIVE_UV_UNIFORM_PROJECTION_NOT_STRETCHED_TILE:"+String(contract.id))
	if not errors.is_empty(): finish(); return
	sr=root.get_node_or_null("SceneRouter"); dp=root.get_node_or_null("DialogPlayer"); lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true); state_before=business_state()
	if not check(sr.call("go_field_smart",StringName(spec.city_id),Vector2(1450,1530)/Vector2(6144,6144),"",-1,30)==true,"ONE_EXPLICIT_RESIDENTIAL_SETUP_NOT_DEFAULT_TRAVEL"): finish(); return
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(Vector2(1450,1530))<=1,"SAME_FORMAL_FIELD_PUBLIC_SETUP"): finish(); return
	var world: Node2D=field.get("world_container")
	for contract: Dictionary in spec.runtime_ground:
		var node: Polygon2D=world.get_node_or_null("BianzhouPaving_"+String(contract.id)) as Polygon2D
		if not check(node!=null and node.texture!=null and node.texture.resource_path==contract.texture,"ACTUAL_GROUND_TEXTURE:"+String(contract.id)): continue
		if contract.has("period"): check(node.get_meta("bz_period")==point(contract.period),"ACTUAL_GROUND_PERIOD:"+String(contract.id))
		if contract.has("feather"):
			var material:=node.material as ShaderMaterial
			check(node.get_meta("bz_feather_px")==float(contract.feather) and material!=null and material.get_shader_parameter("feather_px")==float(contract.feather) and int(material.get_shader_parameter("edge_count"))==node.polygon.size(),"ACTUAL_FEATHER_MATERIAL_NOT_META_ONLY:"+String(contract.id))
		if contract.get("native_uv",false):
			var expected_uv:=PackedVector2Array()
			for uv: Array in spec.farmland_source_uv: expected_uv.append(point(uv))
			check(node.uv==expected_uv and node.get_meta("bz_source_uv")==expected_uv and node.texture_repeat==CanvasItem.TEXTURE_REPEAT_DISABLED,"ACTUAL_NATIVE_SOURCE_UV_NO_REPEATED_FIELD_TILE")
	if not await walk_route(field,[[1450,1562]]): finish(); return
	var changed: Dictionary={}
	for npc: Node in field.get("_npc_nodes"):
		if not String(npc.get("npc_id")) in spec.changed_npc_ids: continue
		changed[String(npc.get("npc_id"))]=true
		var texture: Texture2D=npc.get("_idle_texture"); var sprite: Sprite2D=npc.get("sprite")
		check(npc.get("sprite_path")==spec.female_sprite and npc.get("portrait_path")==spec.female_portrait and texture!=null and texture.resource_path==spec.female_sprite,"CHANGED_FEMALE_MATCHED_PAIR:"+String(npc.get("npc_id")))
		check(texture!=null and texture.get_size()==Vector2(640,160) and sprite.texture==texture and sprite.hframes==4,"COMPLETE_SHIPPED_FEMALE_FOUR160_FRAMES:"+String(npc.get("npc_id")))
		var collider: StaticBody2D=npc.get("_body_collider")
		var shape: CollisionShape2D=collider.get_child(0) if collider!=null and collider.get_child_count()==1 else null
		check(shape!=null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size.is_equal_approx(Vector2(20.16,25.92)) and shape.position.is_equal_approx(Vector2(0,17.28)),"SAME_REAL160_FRAME_NPC_BODY:"+String(npc.get("npc_id")))
	check(changed.size()==spec.changed_npc_ids.size() and changed.has(spec.visible_female_id),"EXACT_CHANGED_FEMALE_IDS_AND_RESIDENTIAL_ROLE_PRESENT")
	if not errors.is_empty(): finish(); return
	if not await normal_image("residential_visual_SUFFIX_NATIVE"): finish(); return
	if not await review_overview(field): finish(); return
	check(business_state()==state_before and png_count==1 and overview_count==1 and active(),"VISUAL_SUFFIX_NO_BUSINESS_REPLAY_ONE_NATIVE_ONE_REVIEW")
	records.append({"inherits_actual":spec.inherited_actual,"repeated_176_or_1122_or_38":false,"art_verdict":"ROOT_AND_ART_STILL_MUST_VIEW_IMAGES","physical_geometry_changed":false})
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"VISUAL_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"SAVE15_SAME_ROOT_TICKS_SEPARATE")
	var path: String=ACTUAL_OUTPUT+str(OS.get_process_id())+"/visual_residual_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":overview_count,"records":records,"fixture_sha256":FileAccess.get_sha256(VISUAL_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"art_verdict":"PENDING_ROOT_ART_REVIEW"},"\t")); file.close()
	print("[BianzhouVisualSuffix] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
