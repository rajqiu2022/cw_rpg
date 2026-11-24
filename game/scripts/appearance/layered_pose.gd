extends Node2D
## Art/system: authored body + independent weapon + original foreground hand.
## Driven by the real actor's frame; never owns movement, strike timing or stats.
const Carry=preload("res://scripts/appearance/weapon_carry_data.gd")
const Legendary=preload("res://scripts/appearance/legendary_weapon_data.gd")
const ENCHANTMENT=preload("res://scripts/appearance/seven_star_enchantment.gdshader")
const StarParticles=preload("res://scripts/appearance/seven_star_particles.gd")
const CombatPose=preload("res://art/characters/battle_stances_20261109/combat_pose_data.gd")
const Gauntlets=preload("res://scripts/appearance/enchanted_gauntlets.gd")
var data: Dictionary
var textures: Dictionary
var body := Sprite2D.new()
var hand := Sprite2D.new()
var carry_arm := Polygon2D.new()
var ready_fingers := Polygon2D.new()
var far_ready_fingers := Polygon2D.new()
var socket := Node2D.new()
var weapon := Sprite2D.new()
var atlases: Dictionary = {}
var current_clip := "idle"
var current_frame := 0
var current_weapon := "seven_star_sword"
var current_facing := 1
var current_sheathed := false
var current_back_carried := false
var fx_clock := 0.0
var prop_textures: Dictionary = {}
var front_hilt_textures: Dictionary = {}
var props: Dictionary = {}
var enchantment: ShaderMaterial
var star_particles: Node2D
var gauntlets: Node2D

func configure(manifest: Dictionary, loaded: Dictionary) -> void:
	data=manifest; textures=loaded
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.centered=false; body.z_index=1; add_child(body)
	add_child(socket); weapon.centered=false; socket.add_child(weapon)
	hand.centered=false; hand.z_index=5; add_child(hand)
	carry_arm.z_index=5
	carry_arm.visible=false
	carry_arm.antialiased=true
	add_child(carry_arm)
	ready_fingers.z_index=5
	ready_fingers.visible=false
	ready_fingers.antialiased=true
	ready_fingers.texture=textures.idle
	add_child(ready_fingers)
	far_ready_fingers.z_index=5
	far_ready_fingers.visible=false
	far_ready_fingers.antialiased=true
	add_child(far_ready_fingers)
	enchantment=ShaderMaterial.new()
	enchantment.shader=ENCHANTMENT
	props=Carry.PROPS.merged(Legendary.PROPS)
	for key: String in props:
		var prop: Dictionary=props[key]
		var region:=AtlasTexture.new()
		region.atlas=textures[prop.get("atlas","carry_atlas")]
		region.region=prop.region
		region.filter_clip=true
		prop_textures[key]=region
		if Carry.FRONT_HILT_CUT.has(key):
			var start: float=Carry.FRONT_HILT_CUT[key]
			var hilt:=AtlasTexture.new()
			hilt.atlas=region.atlas
			hilt.region=Rect2(region.region.position+Vector2(0,start),region.region.size-Vector2(0,start))
			hilt.filter_clip=true
			front_hilt_textures[key]=hilt
	for clip_id: String in data.clips:
		var clip: Dictionary=data.clips[clip_id]
		var frames: Array=[]
		for p: Dictionary in clip.frames:
			var cell:=Vector2(clip.cell[0],clip.cell[1])
			var offset:=Vector2(float(p.cell_index)*cell.x,0)
			var region: Rect2=p.get("region",Rect2(offset,cell))
			var b:=AtlasTexture.new(); b.atlas=textures[p.texture]; b.region=region; b.filter_clip=true
			var h: AtlasTexture
			if not p.has("region"):
				h=AtlasTexture.new(); h.atlas=b.atlas; h.region=Rect2(offset+Vector2(p.hand_center[0]-23,p.hand_center[1]-23),Vector2(46,46)); h.filter_clip=true
			var arm_points := PackedVector2Array()
			if Carry.ARM_COVER.has(p.texture):
				var outline: Array = Carry.ARM_COVER[p.texture][int(p.cell_index)]
				for j in range(0,outline.size(),2):
					arm_points.append(Vector2(outline[j],outline[j+1]))
			var arm_uv := arm_points.duplicate()
			for j in range(arm_uv.size()):
				arm_uv[j]+=offset
			var fingers := PackedVector2Array()
			if clip_id=="idle":
				var skin: Array = Carry.READY_SWORD_GRIPS[int(p.cell_index)].fingers
				for j in range(0,skin.size(),2):
					fingers.append(Vector2(skin[j],skin[j+1]))
			var raw_scale: float=p.get("source_scale",1.0)
			var near_mask: PackedVector2Array=p.get("fingers",fingers)
			var far_mask: PackedVector2Array=p.get("far_fingers",PackedVector2Array())
			frames.append([b,h,arm_points,arm_uv,_grip_polygon(near_mask,region.position,raw_scale),_grip_polygon(far_mask,region.position,raw_scale)])
		atlases[clip_id]=frames

func _grip_polygon(outline: PackedVector2Array, offset: Vector2, raw_scale: float) -> Array:
	var local := PackedVector2Array()
	var uv := PackedVector2Array()
	for point: Vector2 in outline:
		local.append(point * raw_scale)
		uv.append(point + offset)
	return [local,uv]

func _show_grip(fingers: Polygon2D, grip_mask: Array, texture: Texture2D, foot: Vector2, show_mask: bool) -> void:
	fingers.visible=show_mask and not grip_mask[0].is_empty()
	if fingers.visible:
		fingers.texture=texture
		fingers.polygon=grip_mask[0]
		fingers.uv=grip_mask[1]
		fingers.position=-foot

func show_pose(id: String, clip_id: String, index: int, face: int, clock: float, sheathed := false, back_carried := false) -> void:
	current_weapon=id; current_clip=clip_id; current_frame=index; current_facing=face; fx_clock=clock
	current_sheathed=sheathed
	current_back_carried=back_carried
	var p: Dictionary=data.clips[clip_id].frames[index]
	var foot:=Vector2(p.foot[0],p.foot[1])
	scale=Vector2(face,1)
	var layers: Array=atlases[clip_id][index]
	body.texture=layers[0]; body.position=-foot
	body.scale=Vector2.ONE*float(p.get("source_scale",1.0))
	hand.texture=atlases[clip_id][index][1]; hand.position=Vector2(p.hand_center[0]-23,p.hand_center[1]-23)-foot
	var arm_points: PackedVector2Array=atlases[clip_id][index][2]
	carry_arm.visible=sheathed and not arm_points.is_empty()
	if carry_arm.visible:
		carry_arm.texture=textures[p.texture]
		carry_arm.polygon=arm_points
		carry_arm.uv=atlases[clip_id][index][3]
		carry_arm.position=-foot
	var legendary: Dictionary=Legendary.WEAPONS.get(id,{})
	var enchanted := id=="seven_star_sword" or not legendary.is_empty()
	var concealed: bool=legendary.get("concealed",false)
	var direction := "up" if clip_id.ends_with("_up") else ("down" if clip_id.ends_with("_down") else "side")
	var side_back := back_carried and direction=="side"
	var hand_action := clip_id in ["attack_fist","attack_palm","fast_leap"] or clip_id.begins_with("fast_palm")
	var throwing := clip_id.begins_with("fast_hidden")
	var reveal_dart: bool = concealed and p.get("show_concealed", false)
	var ready_stance := clip_id.begins_with("ready_")
	var legacy_ready := clip_id=="idle" and not sheathed and not back_carried and not concealed and id not in ["unarmed","immortal_gauntlets"]
	var wearing_gauntlets:=id=="immortal_gauntlets"
	socket.visible=id!="unarmed" and not wearing_gauntlets and not hand_action and (reveal_dart if throwing else (not concealed or clip_id=="attack"))
	var grip_overlay := socket.visible and (legacy_ready or ready_stance or clip_id.begins_with("fast_"))
	_show_grip(ready_fingers,layers[4],textures[p.texture],foot,grip_overlay)
	_show_grip(far_ready_fingers,layers[5],textures[p.texture],foot,grip_overlay)
	hand.visible=socket.visible and not sheathed and not back_carried and not grip_overlay
	if star_particles != null:
		star_particles.visible=enchanted and socket.visible
	if wearing_gauntlets:
		if gauntlets==null:
			gauntlets=Gauntlets.new()
			add_child(gauntlets)
			gauntlets.setup(textures)
		gauntlets.show_hands(p,foot,clock)
	if gauntlets!=null:
		gauntlets.visible=wearing_gauntlets
	if not socket.visible:
		return

	var prop: String=Carry.sheath_for(id) if sheathed else id
	var front_hilt := sheathed and direction=="down" and front_hilt_textures.has(prop)
	var spec: Dictionary=data.weapons.get(id,{})
	var prop_data: Dictionary=props.get(prop,{})
	var grip: Vector2
	var art_size: Vector2
	var angle:=float(p.angle)
	if concealed:
		angle=clampf(angle-90.0,-22.0,24.0)
	socket.position=Vector2(p.grip[0],p.grip[1])-foot
	socket.z_index=int(p.weapon_z)
	if prop_textures.has(prop):
		grip=prop_data.grip
		weapon.texture=prop_textures[prop]
		socket.scale=Vector2.ONE*float(prop_data.scale)
		art_size=textures[prop_data.get("atlas","carry_atlas")].get_size()
		if sheathed or back_carried:
			var mount: Array=Carry.BACK[direction] if back_carried else Carry.WAIST[direction]
			socket.position=mount[0]-foot
			var swing := 0.0 if side_back else (3.0 if direction=="side" else 1.2)
			angle=float(mount[1])+(sin(index*TAU/8.0)*swing if clip_id.begins_with("walk") else 0.0)
			socket.z_index=int(mount[2])
			if back_carried:
				grip=prop_data.get("back_center",grip)
			elif direction!="side":
				socket.scale*=0.92
				if front_hilt:
					weapon.texture=front_hilt_textures[prop]
					# The cropped atlas starts at the base of the handle, at the belt.
					grip.y=0.0
					socket.scale*=0.76
	elif not spec.is_empty():
		var upper: Array=p.weapon_grips[id]
		grip=Vector2(upper[0],upper[1])
		weapon.texture=textures[spec.texture]
		art_size=weapon.texture.get_size()
		socket.scale=Vector2.ONE*float(spec.scale)
	if legacy_ready:
		socket.position=Carry.READY_SWORD_GRIPS[int(p.cell_index)].web-foot
		angle=float(legendary.get("ready_angle",25.0))
	elif clip_id in ["ready_staff","fast_staff","fast_staff_group"]:
		# Pull the long staff through both authored hand anchors.
		grip.y = CombatPose.staff_near_grip_y(id)
		if clip_id.begins_with("fast_staff"):
			var axis: Vector2=p.far_hand-Vector2(p.grip[0],p.grip[1])
			if axis.length()>1:
				angle=rad_to_deg(axis.angle())+90.0
	elif id=="buddha_subduing_staff" and ready_stance:
		angle = 107.0

	# The exposed cutting edge is on the inner side of the source art.
	# Reflect the whole drawn assembly around the grip before rotating the swing.
	if id=="jinhe_duanyue_blade" and not sheathed:
		var drawn_scale:=socket.scale
		socket.transform=Transform2D(deg_to_rad(angle),Vector2(-drawn_scale.x,drawn_scale.y),0.0,socket.position)
	else:
		socket.rotation=deg_to_rad(angle)
	weapon.position=-grip
	weapon.material=enchantment if enchanted else null
	if enchanted:
		var blade_glow := not Carry.sheath_for(id).is_empty()
		var tip: Vector2
		var heel: Vector2
		if not prop_data.is_empty():
			tip=prop_data.tip
			heel=prop_data.heel
		elif legendary.is_empty():
			tip=Vector2(spec.tip[0],spec.tip[1])
			heel=Vector2(grip.x,982.0)
		else:
			tip=legendary.drawn_tip
			heel=legendary.drawn_heel
		var hilt_span := Vector2.ZERO
		if front_hilt:
			var hilt_region: Rect2=front_hilt_textures[prop].region
			hilt_span=Vector2(hilt_region.position.y,hilt_region.end.y)/art_size.y
			# The handle is a different atlas region: y=0 is now the cut at the belt.
			heel=Vector2(grip.x,8.0)
			tip=Vector2(grip.x,minf(hilt_region.size.y * 0.60,155.0))
		enchantment.set_shader_parameter("hilt_span",hilt_span)
		enchantment.set_shader_parameter("blade_span",Vector2(tip.y,heel.y)/art_size.y if blade_glow and not front_hilt else Vector2.ZERO)
		enchantment.set_shader_parameter("sheathed",sheathed)
		enchantment.set_shader_parameter("intensity",float(legendary.get("intensity",1.0)))
		enchantment.set_shader_parameter("compact_ready_wrap",(legacy_ready or ready_stance) and id=="seven_star_sword")
		enchantment.set_shader_parameter("phase",fmod(clock*3.5,TAU))
		enchantment.set_shader_parameter("texel",Vector2.ONE/art_size)
		enchantment.set_shader_parameter("custom_palette",not legendary.is_empty())
		var tint: Color=legendary.get("tint",Color.WHITE)
		enchantment.set_shader_parameter("tint",Vector3(tint.r,tint.g,tint.b))
		enchantment.set_shader_parameter("glow_end",float(legendary.get("glow_end",0.725)))
		enchantment.set_shader_parameter("paired_tips",legendary.get("paired_tips",false))
		if star_particles==null:
			star_particles=StarParticles.new()
			socket.add_child(star_particles)
			star_particles.setup(textures.starfx)
		star_particles.show()
		star_particles.draw_at(clock,tip-grip,heel-grip,sheathed,legendary,blade_glow,front_hilt or side_back)
