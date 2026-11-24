extends Node2D
## Isolated prototype: input is authored pixels + per-frame sockets, not a save or Inventory.
## Both weapons reuse the SAME body/hand assets. No baked-weapon fallback is drawn here.

var clips: Dictionary = {}
var weapons: Dictionary = {}
var textures: Dictionary = {}
var rigs: Array[Dictionary] = []
var weapon_id := "seven_star_sword"
var action := "idle"
var frame_index := 0
var facing := 1
var direction := "right"
var finished := false
var elapsed := 0.0
var fx_clock := 0.0
var paused := false
var fx_enabled := true
var body_enabled := true
var weapon_enabled := true
var hands_enabled := true
var ghost_material: ShaderMaterial
var body_frames: Dictionary = {}
var hand_frames: Dictionary = {}


func configure(data: Dictionary, loaded_textures: Dictionary) -> void:
	clips = data.clips
	weapons = data.weapons
	textures = loaded_textures
	# Frame views are cached once. Changing a pose never copies pixels or allocates an atlas per tick.
	for clip_id in clips:
		var clip_data: Dictionary = clips[clip_id]
		body_frames[clip_id] = []
		hand_frames[clip_id] = []
		for i in range(clip_data.frames.size()):
			var pose: Dictionary = clip_data.frames[i]
			var cell := Vector2(clip_data.cell[0],clip_data.cell[1])
			var body_view := AtlasTexture.new()
			body_view.atlas = textures[clip_data.texture]
			body_view.region = Rect2(Vector2(i*cell.x,0),cell)
			body_frames[clip_id].append(body_view)
			var hand_view := AtlasTexture.new()
			hand_view.atlas = textures[clip_data.texture]
			var hand_center: Array = pose.get("hand_center",pose.grip)
			hand_view.region = Rect2(Vector2(i*cell.x+hand_center[0]-23,hand_center[1]-23),Vector2(46,46))
			hand_frames[clip_id].append(hand_view)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec4 mask_rect; varying vec2 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;} void fragment(){if(world.x<mask_rect.x||world.y<mask_rect.y||world.x>mask_rect.z||world.y>mask_rect.w) discard;}"
	ghost_material = ShaderMaterial.new()
	ghost_material.shader = shader
	ghost_material.set_shader_parameter("mask_rect", Vector4(-1,-1,-1,-1))
	rigs.append(_make_rig(false))
	rigs.append(_make_rig(true))
	apply_pose()


func _make_rig(ghost: bool) -> Dictionary:
	var root := Node2D.new()
	root.name = "OccludedSilhouette" if ghost else "NormalLayers"
	root.z_index = 50 if ghost else 0
	root.visible = not ghost
	root.modulate.a = 0.42 if ghost else 1.0
	add_child(root)
	var body := Sprite2D.new()
	body.name = "WeaponlessBody"
	body.centered = false
	body.z_index = 1
	root.add_child(body)
	var socket := Node2D.new()
	socket.name = "GripSocket"
	root.add_child(socket)
	var weapon := Sprite2D.new()
	weapon.name = "IndependentWeapon"
	weapon.centered = false
	socket.add_child(weapon)
	var tip := Marker2D.new()
	tip.name = "WeaponTip"
	socket.add_child(tip)
	var hand := Sprite2D.new()
	hand.name = "ForegroundGrip"
	hand.centered = false
	hand.z_index = 5
	root.add_child(hand)
	var effects: Array[Sprite2D] = []
	for i in range(7):
		var spark := Sprite2D.new()
		spark.name = "Enchantment%d" % i
		spark.hframes = 4
		spark.z_index = 1
		socket.add_child(spark)
		effects.append(spark)
	if ghost:
		for sprite in [body, weapon, hand] + effects:
			sprite.material = ghost_material
	return {"root":root,"body":body,"socket":socket,"weapon":weapon,"tip":tip,"hand":hand,"effects":effects}


func set_occluder(rect: Rect2, active: bool) -> void:
	rigs[1].root.visible = active
	ghost_material.set_shader_parameter("mask_rect", Vector4(rect.position.x,rect.position.y,rect.end.x,rect.end.y))


func equip(id: String) -> bool:
	if not weapons.has(id):
		return false
	weapon_id = id
	fx_clock = 0.0
	# No orphan particles or tweens: all effects belong to this socket and switch atomically.
	apply_pose()
	return true


func play(clip: String) -> bool:
	if not clips.has(clip):
		return false
	action = clip
	frame_index = 0
	elapsed = 0.0
	finished = false
	apply_pose()
	return true


func play_action(value: String) -> bool:
	var suffix := "_"+direction if direction in ["up","down"] else ""
	return play(value+suffix)


func set_direction(value: String) -> bool:
	if value not in ["right","left","up","down"]:
		return false
	var base_action: String = action.split("_")[0]
	var next_clip := base_action+("_"+value if value in ["up","down"] else "")
	if not clips.has(next_clip):
		return false
	direction = value
	facing = -1 if value=="left" else 1
	return play(next_clip)


func set_facing(value: int) -> void:
	facing = -1 if value < 0 else 1
	apply_pose()


func _process(delta: float) -> void:
	if rigs.is_empty() or paused:
		return
	fx_clock += delta
	if finished:
		apply_pose()
		return
	elapsed += delta
	var seconds := float(clips[action].seconds)
	while elapsed >= seconds:
		elapsed -= seconds
		if frame_index+1 >= clips[action].frames.size() and not clips[action].get("loop",true):
			finished = true
			elapsed = 0.0
			break
		frame_index = (frame_index + 1) % clips[action].frames.size()
	apply_pose()


func apply_pose() -> void:
	if rigs.is_empty():
		return
	var clip: Dictionary = clips[action]
	var pose: Dictionary = clip.frames[frame_index]
	var spec: Dictionary = weapons[weapon_id]
	var anchor := Vector2(pose.foot[0],pose.foot[1])
	var grip := Vector2(pose.grip[0],pose.grip[1])
	var weapon_anchor: Array = pose.get("weapon_grips",{}).get(weapon_id,spec.grip)
	var weapon_grip := Vector2(weapon_anchor[0],weapon_anchor[1])
	var hand_center: Array = pose.get("hand_center",pose.grip)
	var hand_rect := Rect2(Vector2(hand_center[0],hand_center[1]) - Vector2(23,23),Vector2(46,46))
	for rig in rigs:
		rig.root.scale = Vector2(facing,1)
		rig.body.texture = body_frames[action][frame_index]
		rig.body.position = -anchor
		rig.body.visible = body_enabled
		rig.hand.texture = hand_frames[action][frame_index]
		rig.hand.position = hand_rect.position-anchor
		rig.hand.visible = body_enabled and hands_enabled
		rig.socket.position = grip-anchor
		rig.socket.rotation = deg_to_rad(float(pose.angle))
		rig.socket.scale = Vector2.ONE * float(spec.scale)
		rig.socket.z_index = int(pose.get("weapon_z",3))
		rig.socket.visible = weapon_enabled
		rig.weapon.texture = textures[spec.texture]
		rig.weapon.position = -weapon_grip
		rig.tip.position = Vector2(spec.tip[0],spec.tip[1])-weapon_grip
		for i in range(rig.effects.size()):
			var effect: Sprite2D = rig.effects[i]
			effect.visible = fx_enabled and i < spec.accents.size()
			if not effect.visible:
				continue
			var point: Array = spec.accents[i]
			effect.texture = textures[spec.effect]
			effect.position = Vector2(point[0],point[1])-weapon_grip
			effect.scale = Vector2.ONE * float(spec.effect_scale)
			effect.frame = int(fx_clock*7.0 + i) % 4
			effect.modulate.a = (0.85 if action.begins_with("attack") else 0.62) * (0.6+0.4*sin(fx_clock*2.0+i))


func snapshot() -> Dictionary:
	var rig: Dictionary = rigs[0]
	return {"weapon":weapon_id,"clip":action,"frame":frame_index,"facing":facing,
		"grip":rig.socket.global_position,"tip":rig.tip.global_position,
		"body_texture":String(clips[action].texture),"fx_clock":fx_clock}
