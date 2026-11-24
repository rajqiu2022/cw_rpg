extends Node2D

const ACTOR = preload("res://layered_actor.gd")
var data: Dictionary
var actors: Array[Node2D] = []
var textures: Dictionary = {}
var status: Label
var stopped := false
var show_fx := true
var show_body := true
var show_weapon := true
var show_hand := true
var occluded := false
var clip := "idle"
var background_mode := 0
var blockers: Array[ColorRect] = []
var weapon_labels: Array[Label] = []
var metrics: Dictionary = {"checks":0,"failures":[],"scope":"Isolated layered 2D lab; no main-game, saves, inventory, collision or source-guard adoption."}


func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var base := ProjectSettings.globalize_path("res://").path_join(data.source_root).simplify_path()
	for key in data.textures:
		var img := Image.load_from_file(base.path_join(key+".png"))
		if img == null or img.is_empty():
			push_error("Missing asset: "+key)
			get_tree().quit(1)
			return
		img.generate_mipmaps()
		textures[key] = ImageTexture.create_from_image(img)
	var font_path := ProjectSettings.globalize_path("res://../../art/fonts/LXGWWenKaiLite-Regular.ttf").simplify_path()
	var font := FontFile.new()
	font.load_dynamic_font(font_path)
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 21
	var ui := Control.new()
	ui.theme = theme
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	_label(ui, "名器 · 分层 2D 试验台", Vector2(42,24),32)
	_label(ui, "共用人物底稿 ｜ 独立武器与光效 ｜ 四向待机／行走／挥击样板，尚未替换正式主角",Vector2(42,72),21)
	weapon_labels.append(_label(ui, "七星龙泉剑",Vector2(245,132),26))
	weapon_labels.append(_label(ui, "烬河断岳刀",Vector2(795,132),26))
	_label(ui, "正常人物尺寸",Vector2(1260,132),24)
	for i in range(3):
		var actor := ACTOR.new()
		add_child(actor)
		actor.position = [Vector2(350,755),Vector2(900,755),Vector2(1380,610)][i]
		actor.scale = Vector2.ONE * (0.60 if i<2 else 0.194)
		actor.configure(data,textures)
		actor.equip("jinhe_duanyue_blade" if i==1 else "seven_star_sword")
		actors.append(actor)
		var wall := ColorRect.new()
		wall.position = actor.position+Vector2(-200 if i<2 else -65,-180 if i<2 else -70)
		wall.size = Vector2(400,130) if i<2 else Vector2(130,50)
		wall.color = Color(0.25,0.32,0.36,1)
		wall.z_index = 10
		wall.visible = false
		add_child(wall)
		blockers.append(wall)
	status = _label(ui,"",Vector2(42,805),22)
	_label(ui,"1 待机  2 行走  3 挥击  4 受击(侧向)  5 倒地(侧向)  方向键 转向  Space 暂停",Vector2(42,850),20)
	_label(ui,"N 逐帧  Q 换武器  B 人物  W 武器  H 手部  F 光效  O 遮挡  C 背景  Esc 退出",Vector2(42,886),20)
	_label(ui,"四帧关键姿势；左向为镜像。受击／倒地暂限侧向，刀剑差异动作与正式接入仍待完成。",Vector2(42,921),17)
	_update_status()
	queue_redraw()
	if "--qa" in OS.get_cmdline_user_args():
		call_deferred("_run_qa")
	elif "--grip-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_grip_qa")
	elif "--directions-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_directions_qa")
	elif "--rear-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_rear_qa")
	elif "--defeat-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_defeat_qa")
	elif "--web-qa" in OS.get_cmdline_user_args():
		call_deferred("_run_directions_qa")


func _label(parent: Node, text: String, pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label


func _draw() -> void:
	var bg: Color = [Color("17242d"),Color("c5b28d"),Color("344642")][background_mode]
	draw_rect(Rect2(0,0,1600,960),bg)
	for x in [72,620,1200]:
		draw_rect(Rect2(x,185,500 if x<1200 else 350,595),Color(0,0,0,0.12))
	for p in [Vector2(350,755),Vector2(900,755),Vector2(1380,610)]:
		draw_line(p-Vector2(210,0),p+Vector2(210,0),Color(0.65,0.76,0.78,0.35),1)


func _process(_delta: float) -> void:
	if status != null:
		_update_status()


func _update_status() -> void:
	for i in range(weapon_labels.size()):
		weapon_labels[i].text = data.weapons[actors[i].weapon_id].label
	var names := {"idle":"待机","walk":"行走","attack":"挥击","hit":"受击(侧向)","defeat":"倒地(侧向)"}
	var directions := {"right":"右","left":"左镜像","down":"正面","up":"背面"}
	status.text = "%s · %s · 第 %d/%d 帧 · %s  | 人物 %s / 武器 %s / 手部 %s / 光效 %s" % [names[clip],directions[actors[0].direction],actors[0].frame_index+1,data.clips[actors[0].action].frames.size(),"收尾停留" if actors[0].finished else "暂停" if stopped else "播放",_yn(show_body),_yn(show_weapon),_yn(show_hand),_yn(show_fx)]


func _yn(value: bool) -> String:
	return "开" if value else "关"


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE: get_tree().quit()
		KEY_1: _play("idle")
		KEY_2: _play("walk")
		KEY_3: _play("attack")
		KEY_4: _play("hit")
		KEY_5: _play("defeat")
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			if clip in ["hit","defeat"] and event.keycode in [KEY_UP,KEY_DOWN]:
				_play("idle")
			for actor in actors:
				actor.set_direction({KEY_LEFT:"left",KEY_RIGHT:"right",KEY_UP:"up",KEY_DOWN:"down"}[event.keycode])
		KEY_SPACE:
			stopped = not stopped
			for actor in actors:
				actor.paused = stopped
		KEY_N:
			stopped = true
			for actor in actors:
				actor.paused = true
				actor.frame_index = (actor.frame_index+1)%data.clips[actor.action].frames.size()
				actor.finished = false
				actor.apply_pose()
		KEY_Q:
			for actor in actors:
				actor.equip("jinhe_duanyue_blade" if actor.weapon_id=="seven_star_sword" else "seven_star_sword")
		KEY_F: show_fx = not show_fx
		KEY_B: show_body = not show_body
		KEY_W: show_weapon = not show_weapon
		KEY_H: show_hand = not show_hand
		KEY_C:
			background_mode = (background_mode+1)%3
			queue_redraw()
		KEY_O:
			occluded = not occluded
			for i in range(actors.size()):
				blockers[i].visible = occluded
				actors[i].set_occluder(Rect2(blockers[i].position,blockers[i].size),occluded)
	for actor in actors:
		actor.fx_enabled = show_fx
		actor.body_enabled = show_body
		actor.weapon_enabled = show_weapon
		actor.hands_enabled = show_hand
		actor.apply_pose()


func _play(value: String) -> void:
	clip = value
	for actor in actors:
		if value in ["hit","defeat"] and actor.direction in ["up","down"]:
			actor.play("idle")
			actor.set_direction("right")
		actor.play_action(value)


func _check(condition: bool, label: String) -> void:
	metrics.checks += 1
	if not condition:
		metrics.failures.append(label)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)


func _capture(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://evidence/"+name+".png")


func _run_qa() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://evidence"))
	# Let the root viewport finish registering unhandled-input delivery before the first event.
	await get_tree().process_frame
	await get_tree().process_frame
	_key(KEY_SPACE)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(actors[0].paused,"pause_input")
	for id in data.weapons:
		for state in data.clips:
			for direction in [-1,1]:
				actors[0].equip(id)
				actors[0].play(state)
				actors[0].set_facing(direction)
				for f in range(4):
					actors[0].frame_index = f
					actors[0].apply_pose()
					var pose: Dictionary = data.clips[state].frames[f]
					var expected: Vector2 = actors[0].to_global(Vector2(direction*(pose.grip[0]-pose.foot[0]),pose.grip[1]-pose.foot[1]))
					var snap: Dictionary = actors[0].snapshot()
					_check(snap.grip.distance_to(expected)<0.01,"socket "+id+state+str(direction)+str(f))
					var hilt: Array = pose.weapon_grips[id]
					var actual_web: Vector2 = actors[0].rigs[0].weapon.to_global(Vector2(hilt[0],hilt[1]))
					_check(actual_web.distance_to(expected)<0.01,"upper_hilt_at_web")
					_check(actors[0].rigs[0].hand.texture.atlas==textures[data.clips[state].texture],"original_hand_preserved")
					_check(snap.tip.is_finite(),"finite tip")
					_check(actors[0].rigs[0].hand.z_index>actors[0].rigs[0].socket.z_index,"hand_covers_grip")
	var old_id: String = actors[0].weapon_id
	var old_body: String = actors[0].snapshot().body_texture
	_key(KEY_Q)
	await get_tree().process_frame
	_check(actors[0].weapon_id!=old_id,"equip_input")
	_check(actors[0].snapshot().body_texture==old_body,"equip_reuses_same_body")
	_check(actors[0].fx_clock==0.0,"equip_clears_effect_clock")
	_check(not actors[0].equip("missing_id"),"unknown_equip_rejected")
	_check(not actors[0].play("missing_clip"),"unknown_clip_rejected")
	for i in range(3):
		actors[i].equip("jinhe_duanyue_blade" if i==1 else "seven_star_sword")
		actors[i].set_facing(1)
	_play("idle")
	for actor in actors:
		actor.fx_clock = 0.28
		actor.apply_pose()
	await _capture("01_idle")
	_key(KEY_2)
	await get_tree().process_frame
	_check(actors[0].action=="walk","walk_input")
	_key(KEY_N)
	await get_tree().process_frame
	_check(actors[0].frame_index==1,"step_input")
	await _capture("02_walk")
	_key(KEY_3)
	await get_tree().process_frame
	for f in range(4):
		for actor in actors:
			actor.frame_index = f
			actor.apply_pose()
		await _capture("03_attack_%d"%f)
	_key(KEY_LEFT)
	await get_tree().process_frame
	_check(actors[0].facing==-1,"mirror_input")
	_key(KEY_1)
	_key(KEY_O)
	await get_tree().process_frame
	_check(blockers[0].visible and actors[0].rigs[1].root.visible,"opaque_occlusion_and_ghost")
	await _capture("04_occlusion")
	_key(KEY_B)
	await get_tree().process_frame
	_check(not actors[0].rigs[0].body.visible,"body_layer_toggle")
	_key(KEY_B)
	_key(KEY_F)
	await get_tree().process_frame
	_check(not actors[0].rigs[0].effects[0].visible,"fx_toggle")
	_key(KEY_W)
	await get_tree().process_frame
	_check(not actors[0].rigs[0].socket.visible,"weapon_layer_toggle")
	_key(KEY_W)
	_key(KEY_O)
	_key(KEY_C)
	await _capture("05_light_background")
	_key(KEY_F)
	_key(KEY_2)
	_key(KEY_SPACE)
	await get_tree().process_frame
	var seen_frames: Dictionary = {}
	var before_clock: float = actors[0].fx_clock
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<750:
		await get_tree().process_frame
		seen_frames[actors[0].frame_index] = true
	_check(seen_frames.size()==4,"live_animation_four_frames")
	_check(actors[0].fx_clock>before_clock+0.5,"live_effect_clock")
	_key(KEY_SPACE)
	await get_tree().process_frame
	await _capture("06_live_fx")
	metrics["result"] = "PASS" if metrics.failures.is_empty() else "FAIL"
	var file := FileAccess.open("res://evidence/qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	file.close()
	print(JSON.stringify(metrics))
	get_tree().quit(0 if metrics.failures.is_empty() else 1)


func _run_grip_qa() -> void:
	# Only the user-rejected third attack pose changed. Do not replay the old full matrix.
	metrics.scope = "Original hand/body preserved; third attack pose thumb-index web attachment only."
	await get_tree().process_frame
	stopped = true
	_play("attack")
	for actor in actors:
		actor.paused = true
		actor.frame_index = 2
		actor.apply_pose()
	var pose: Dictionary = data.clips.attack.frames[2]
	for id in data.weapons:
		for direction in [-1,1]:
			var actor: Node2D = actors[0]
			actor.equip(id)
			actor.set_facing(direction)
			var rig: Dictionary = actor.rigs[0]
			var expected: Vector2 = actor.to_global(Vector2(direction*(pose.grip[0]-pose.foot[0]),pose.grip[1]-pose.foot[1]))
			var anchor: Array = pose.weapon_grips[id]
			var anchor_world: Vector2 = rig.weapon.to_global(Vector2(anchor[0],anchor[1]))
			_check(anchor_world.distance_to(expected)<0.01,"upper_hilt_at_thumb_web "+id+str(direction))
			_check(rig.body.texture.atlas==textures.attack,"original_body_and_hand_texture")
			_check(rig.hand.texture.atlas==textures.attack,"original_foreground_hand")
			_check(rig.hand.texture.region==Rect2(1472,315,46,46),"hand_mask_not_moved_with_socket")
			_check(rig.hand.z_index>rig.socket.z_index,"original_fingers_cover_handle")
			_check(rig.tip.global_position.is_finite(),"finite_tip")
	for i in range(3):
		actors[i].equip("jinhe_duanyue_blade" if i==1 else "seven_star_sword")
		actors[i].set_facing(1)
	await _capture("07_grip_fixed")
	metrics["result"] = "PASS" if metrics.failures.is_empty() else "FAIL"
	var file := FileAccess.open("res://evidence/grip_qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	file.close()
	print(JSON.stringify(metrics))
	get_tree().quit(0 if metrics.failures.is_empty() else 1)


func _run_directions_qa() -> void:
	metrics.scope = "New 8 native strips; 4 direction input/2 weapons/per-frame web sockets; side hit/defeat lifecycle. Isolated only."
	await get_tree().process_frame
	await get_tree().process_frame
	_key(KEY_SPACE)
	await get_tree().process_frame
	_check(actors[0].paused,"pause_input")
	var web_only := "--web-qa" in OS.get_cmdline_user_args()
	var states := ["idle_down","idle_up","walk_down","walk_up"] if web_only else ["idle_down","idle_up","walk_down","walk_up","attack_down","attack_up","hit","defeat"]
	for state in states:
		for id in data.weapons:
			var actor: Node2D = actors[0]
			actor.play(state)
			actor.equip(id)
			actor.set_facing(1)
			for f in range(data.clips[state].frames.size()):
				actor.frame_index = f
				actor.apply_pose()
				var pose: Dictionary = data.clips[state].frames[f]
				var rig: Dictionary = actor.rigs[0]
				var anchor: Array = pose.weapon_grips[id]
				var web: Vector2 = actor.to_global(Vector2(pose.grip[0]-pose.foot[0],pose.grip[1]-pose.foot[1])*float(data.clips[state].get("body_scale",1.0)))
				_check(rig.weapon.to_global(Vector2(anchor[0],anchor[1])).distance_to(web)<0.01,"web "+state+id+str(f))
				_check(rig.hand.texture.atlas==rig.body.texture.atlas,"same_original_hand")
				_check(rig.socket.z_index==pose.weapon_z,"direction_depth")
				_check(rig.tip.global_position.is_finite(),"finite_tip")
	for i in range(actors.size()):
		actors[i].equip("jinhe_duanyue_blade" if i==1 else "seven_star_sword")
		actors[i].play("idle")
		actors[i].set_direction("right")
	if web_only:
		metrics.scope = "Residual front/rear idle/walk thumb-web refinement: 4 clips x2 weapons x4 frames; original hands preserved."
		for d in ["down","up"]:
			for actor in actors:
				actor.set_direction(d)
			for a in ["idle","walk"]:
				_play(a)
				await _capture("directions_"+a+"_"+d)
		metrics.result = "PASS" if metrics.failures.is_empty() else "FAIL"
		var file := FileAccess.open("res://evidence/web_qa.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(metrics,"\t")+"\n")
		print(JSON.stringify(metrics))
		get_tree().quit(0 if metrics.failures.is_empty() else 1)
		return
	for pair in [[KEY_DOWN,"down"],[KEY_UP,"up"],[KEY_LEFT,"left"],[KEY_RIGHT,"right"]]:
		_key(pair[0])
		await get_tree().process_frame
		_check(actors[0].direction==pair[1],"direction_input "+pair[1])
		for action_key in [[KEY_1,"idle"],[KEY_2,"walk"],[KEY_3,"attack"]]:
			_key(action_key[0])
			await get_tree().process_frame
			var target: String = action_key[1]+("_"+pair[1] if pair[1] in ["up","down"] else "")
			_check(actors[0].action==target,"direction_action "+target)
			for actor in actors:
				actor.frame_index = 2
				actor.apply_pose()
			if pair[1] in ["up","down"]:
				await _capture("directions_"+target)
	_key(KEY_5)
	await get_tree().process_frame
	_check(actors[0].action=="defeat","defeat_input")
	_key(KEY_SPACE)
	await get_tree().process_frame
	await get_tree().create_timer(1.05).timeout
	_check(actors[0].finished and actors[0].frame_index==3,"defeat_holds_last_frame")
	await _capture("directions_defeat")
	_check(not actors[0].set_direction("up"),"unavailable_defeat_up_rejected")
	_check(actors[0].action=="defeat","rejection_preserves_pose")
	_key(KEY_4)
	await get_tree().process_frame
	_check(not actors[0].finished and actors[0].action=="hit","replay_resets_finished")
	await get_tree().create_timer(.24).timeout
	await _capture("directions_hit")
	_key(KEY_2)
	_key(KEY_UP)
	await get_tree().process_frame
	var seen: Dictionary = {}
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<800:
		await get_tree().process_frame
		seen[actors[0].frame_index]=true
	_check(seen.size()==4 and not actors[0].finished,"rear_walk_live_cycle")
	_key(KEY_Q)
	await get_tree().process_frame
	_check(actors[0].weapon_id=="jinhe_duanyue_blade","swap_weapon_input")
	metrics.result = "PASS" if metrics.failures.is_empty() else "FAIL"
	var file := FileAccess.open("res://evidence/directions_qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	file.close()
	print(JSON.stringify(metrics))
	get_tree().quit(0 if metrics.failures.is_empty() else 1)


func _run_rear_qa() -> void:
	metrics.scope = "Residual rear weapon depth fix: visible above background, below body. GPU on/off comparison."
	await get_tree().process_frame
	stopped = true
	for actor in actors:
		actor.paused = true
		actor.fx_enabled = false
		actor.set_direction("up")
	for state in ["idle","walk","attack"]:
		_play(state)
		for f in range(4):
			for actor in actors:
				actor.frame_index = f
				actor.apply_pose()
			_check(actors[0].rigs[0].socket.z_index==0 and actors[0].rigs[0].body.z_index==1,"rear_depth "+state+str(f))
		_play(state)
		for actor in actors:
			actor.frame_index = 2
			actor.apply_pose()
		await _capture("directions_"+state+"_up")
	_play("idle")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var on := get_viewport().get_texture().get_image()
	for actor in actors:
		actor.weapon_enabled = false
		actor.apply_pose()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var off := get_viewport().get_texture().get_image()
	var changed := 0
	for y in range(200,600):
		for x in range(240,450):
			var a := on.get_pixel(x,y)
			var b := off.get_pixel(x,y)
			if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.04:
				changed += 1
	_check(changed>100,"rear_weapon_visible_pixels")
	metrics.visible_changed_pixels = changed
	for actor in actors:
		actor.weapon_enabled = true
		actor.fx_enabled = true
		actor.apply_pose()
	_play("idle")
	for actor in actors:
		actor.set_direction("down")
	await _capture("directions_idle_down")
	metrics.result = "PASS" if metrics.failures.is_empty() else "FAIL"
	var file := FileAccess.open("res://evidence/rear_qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	print(JSON.stringify(metrics))
	get_tree().quit(0 if metrics.failures.is_empty() else 1)


func _run_defeat_qa() -> void:
	metrics.scope = "Residual replacement defeat_v3 native strip; two weapons, both side facings, four frames, terminal hold."
	await get_tree().process_frame
	stopped = true
	_play("defeat")
	for actor in actors:
		actor.paused = true
	for id in data.weapons:
		for face in ["left","right"]:
			actors[0].equip(id)
			actors[0].set_direction(face)
			for f in range(4):
				var actor: Node2D = actors[0]
				actor.frame_index=f
				actor.apply_pose()
				var pose: Dictionary = data.clips.defeat.frames[f]
				var anchor: Array = pose.weapon_grips[id]
				var expected: Vector2 = actor.to_global(Vector2(actor.facing*(pose.grip[0]-pose.foot[0]),pose.grip[1]-pose.foot[1]))
				_check(actor.rigs[0].weapon.to_global(Vector2(anchor[0],anchor[1])).distance_to(expected)<.01,"defeat web "+id+face+str(f))
				_check(actor.rigs[0].body.texture.atlas==textures.defeat_v3,"native_v3_consumed")
				_check(actor.rigs[0].hand.texture.region==Rect2(f*512+pose.hand_center[0]-23,pose.hand_center[1]-23,46,46),"original_hand_region")
	for i in range(actors.size()):
		actors[i].equip("jinhe_duanyue_blade" if i==1 else "seven_star_sword")
		actors[i].set_direction("right")
	for f in range(4):
		for actor in actors:
			actor.frame_index=f
			actor.apply_pose()
		await _capture("directions_defeat_v3_%d"%f)
	for actor in actors:
		actor.play("defeat")
		actor.paused=false
	stopped=false
	await get_tree().create_timer(1.0).timeout
	_check(actors[0].frame_index==3 and actors[0].finished,"defeat_terminal_hold")
	_check(not actors[0].set_direction("up"),"no_fake_rear_defeat")
	await _capture("directions_defeat")
	metrics.result = "PASS" if metrics.failures.is_empty() else "FAIL"
	var file := FileAccess.open("res://evidence/defeat_qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	print(JSON.stringify(metrics))
	get_tree().quit(0 if metrics.failures.is_empty() else 1)
