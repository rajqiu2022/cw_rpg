extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Only the two existing craftsmen's display; inherit the 1213 street checks.
const VISUAL_FIXTURE := "res://build/major_cities_20261028_qa03/craftsman_visual_READY.json"
const VISUAL_OUTPUT := "res://build/major_cities_20261028_qa03/actual/"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(VISUAL_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_VISUAL_RESIDUAL"):finish();return
	spec=raw
	if not check(spec.whole_seconds==30 and spec.max_png==1,"ONLY_30S_ONE_PNG"):finish();return
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(baseline.save15.keys())
	for path: String in spec.fixed_sources:check(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	check(FileAccess.get_sha256(spec.inherited_actual.path)==spec.inherited_actual.sha256,"PRIOR_1213_ACTUAL_PRESERVED_NOT_REPLAYED")
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true);check(platform.call("is_checkpoint_saves_suspended")==true,"SUSPENDED_TO_QUIT")
	state_before=business_state()
	if not errors.is_empty():finish();return
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.setup)/point(spec.get("size")),"",-1,29)==true,"EXPLICIT_PUBLIC_VIEW_SETUP_NOT_DEFAULT_TRAVEL"):finish();return
	var field: Node=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(field.get_script().resource_path==spec.field and (field.get("_player") as Node2D).position.distance_to(point(spec.setup))<=1.0,"FROZEN_FIELD_AND_EXPLICIT_SETUP"):finish();return
	var player_shape: CollisionShape2D=(field.get("_player") as Node).get_node("CollisionShape2D")
	check(player_shape.shape is RectangleShape2D and (player_shape.shape as RectangleShape2D).size==Vector2(34,24),"ORIGINAL_PLAYER_FULL34X24_BODY")
	for expected: Dictionary in spec.craftsmen:
		var found: Array=[]
		for actor: Node in field.get("_npc_nodes"):
			if actor.get("npc_id")==expected.id:found.append(actor)
		if not check(found.size()==1,"EXACT_ORIGINAL_CRAFTSMAN:"+String(expected.id)):finish();return
		var actor: Node2D=found[0]
		check(actor.position==point(expected.foot) and actor.get("npc_name")=="修车匠人" and actor.get("interaction_action")=="bianzhou_ambient:修车匠人","ORIGINAL_CRAFTSMAN_FOOT_ROLE_ACTION")
		var sprite: Sprite2D=actor.get("sprite")
		check(actor.get("sprite_path")==expected.sprite and sprite.texture.resource_path==expected.sprite and sprite.hframes==4 and sprite.texture.get_width()==640 and sprite.texture.get_height()==160,"MATCHING_REAL_FOUR_FRAME_TEXTURE_NOT_PLACEHOLDER")
		check(actor.get("portrait_path")==expected.portrait and actor.get("_calibrate_adult_body")==true and is_equal_approx(float(actor.get("sprite_scale")),.8),"MATCHING_PORTRAIT_AND_ADULT_CALIBRATION")
		var bounds: Rect2i=actor.call("_visible_bounds",sprite.texture)
		check(absf(float(bounds.size.y)*sprite.scale.y-112.0)<.001,"CALIBRATED_ADULT_VISIBLE_HEIGHT112_NOT_DEBUG_SIZE")
		var body: Node2D=actor.get("_body_collider")
		var collider: CollisionShape2D=body.get_child(0)
		var actual_body: Vector2=(collider.shape as RectangleShape2D).size
		if expected.get("replaced_placeholder")==true:check(actual_body.distance_to(Vector2(20.16,25.92))<.0001,"NORMAL_SHARED_NPC_BODY_NOT_OVERSIZED_PLACEHOLDER_BODY")
		records.append({"craftsman_id":expected.id,"foot":actor.position,"sprite":sprite.texture.resource_path,"hframes":sprite.hframes,"portrait":actor.get("portrait_path"),"visible_height":float(bounds.size.y)*sprite.scale.y,"actual_npc_body":actual_body,"npc_body_unchanged_claim":false})
	if not errors.is_empty():finish();return
	if not await walk(field,point(spec.short_walk_end)):finish();return
	check(business_state()==state_before and dp.call("is_playing")==false,"NO_DIALOG_OR_BUSINESS_MUTATION")
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=VISUAL_OUTPUT+str(OS.get_process_id())+"/craftsman_after_short_input.png"
	if not check(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_NATIVE_IMAGE_NO_QA_CAMERA_WRITE"):finish();return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());check(image.save_png(path)==OK,"ONE_NATIVE_PNG_SAVED")
	png_count=1;records.append({"png":path,"sha256":FileAccess.get_sha256(path)})
	check(active(),"ONLY_30_SECONDS")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty():check(source_before==file_facts(source_before.keys()),"SMALL_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():check(save_before==file_facts(save_before.keys()),"SAVE15_FACTS_UNCHANGED_ROOT_EXACTTICKS_SEPARATE")
	var path: String=VISUAL_OUTPUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"png_count":png_count,"records":records,"fixture_sha256":FileAccess.get_sha256(VISUAL_FIXTURE),"save_writes":0,"qa_actor_or_camera_writes":0,"repeated_1213_street_probe":false},"\t"));file.close()
	print("[BianzhouCraftsmanVisual] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
