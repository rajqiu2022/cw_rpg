extends Node
## System/art adapter. Native actors retain textures, frames, transforms and all gameplay.
## One GPU composite per live hero keeps every body/weapon layer in the same depth band.
const Manifest=preload("res://art/characters/layered_actor_adoption_20261106/appearance_data.gd")
const Pose=preload("res://scripts/appearance/layered_pose.gd")
const Carry=preload("res://scripts/appearance/weapon_carry_data.gd")
const Legendary=preload("res://scripts/appearance/legendary_weapon_data.gd")
const LegendaryPicker=preload("res://scripts/appearance/legendary_gm_picker.gd")
const VictoryPose=preload("res://art/characters/battle_victory_20261108/victory_pose_data.gd")
const CombatPose=preload("res://art/characters/battle_stances_20261109/combat_pose_data.gd")
const FastCombat=preload("res://art/characters/hero_combat_20261111/combat_data.gd")
const CombatForms=preload("res://art/characters/combat_forms_20261112/hero_frames.gd")
const ORIGIN=Vector2(768,1100)
const CANVAS=Vector2i(1536,1280)
const LOCAL_STANDING_HEIGHT := 144.0
const WORLD_STANDING_HEIGHT := 136.0
const SOURCE_STANDING_HEIGHT := 690.0
const READY_CYCLE := [0, 1, 0, 2, 3]
var manifest: Dictionary={}
var textures: Dictionary={}
var actors: Dictionary={}
var clock:=0.0
var load_failed:=false
var ghost_shader: Shader

func _ready() -> void:
	process_priority=300
	add_child(LegendaryPicker.new())
	get_tree().node_added.connect(_node_added)
	for n in get_tree().get_nodes_in_group("player"): _node_added(n)
	ghost_shader=Shader.new()
	ghost_shader.code="""shader_type canvas_item;
uniform sampler2D overlap_mask: filter_linear;
uniform sampler2D frame_mask: filter_nearest;
uniform int mode=0;
uniform vec2 mask_world_size=vec2(1.0);
uniform vec4 actor_local_rect=vec4(0.0,0.0,160.0,160.0);
uniform vec2 mask_flip=vec2(0.0);
uniform vec2 view_scale=vec2(1.0);
uniform vec2 view_offset=vec2(0.0);
varying vec2 world_position;
varying vec2 frame_uv;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; frame_uv=((VERTEX*view_scale+view_offset)-actor_local_rect.xy)/actor_local_rect.zw; frame_uv=mix(frame_uv,vec2(1.0)-frame_uv,mask_flip);}
void fragment(){vec2 uv=mode==1?world_position/mask_world_size:frame_uv; float inside=step(0.0,uv.x)*step(0.0,uv.y)*step(uv.x,1.0)*step(uv.y,1.0); float a=mode==0?1.0:(mode==1?texture(overlap_mask,clamp(uv,vec2(0.0),vec2(1.0))).a:texture(frame_mask,clamp(uv,vec2(0.0),vec2(1.0))).a)*inside; COLOR.a*=a;}
"""

func _node_added(n: Node) -> void:
	if n is Player or n is BattleActor: _register.call_deferred(n.get_instance_id())
	elif n is TextureRect and n.texture!=null and n.mouse_filter==Control.MOUSE_FILTER_IGNORE and n.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		_afterimage.call_deferred(n.get_instance_id())

func _register(id: int) -> void:
	var n=instance_from_id(id)
	if (n is Player or (n is BattleActor and (n.unit_id==&"player" or n.name==&"PlayerActor"))) and not actors.has(id):
		actors[id]={"ref":weakref(n),"active":false}

func _load_assets() -> bool:
	if not textures.is_empty(): return true
	if load_failed: return false
	manifest=Manifest.DATA.duplicate(true)
	manifest.textures["carry_atlas"]=Carry.ATLAS_PATH
	manifest.sha256["carry_atlas"]=Carry.ATLAS_SHA
	manifest.textures["field_sheaths"]=Carry.SHEATHS_PATH
	manifest.sha256["field_sheaths"]=Carry.SHEATHS_SHA
	for id: String in Legendary.SOURCES:
		manifest.textures[id]=Legendary.ART+id+".png"
		manifest.sha256[id]=Legendary.SOURCES[id]
	var pending: Dictionary={}
	for key: String in manifest.textures:
		var path: String=manifest.textures[key]
		var source: Image
		if FileAccess.file_exists(path):
			if FileAccess.get_sha256(path)!=manifest.sha256[key]:
				push_error("Layered appearance source rejected: "+path)
				load_failed=true
				return false
			source=Image.load_from_file(path)
		elif ResourceLoader.exists(path):
			var imported:=load(path) as Texture2D
			if imported!=null:
				source=imported.get_image()
		if source==null or source.is_empty() or (source.is_compressed() and source.decompress()!=OK):
			load_failed=true
			return false
		if not source.has_mipmaps():
			source.generate_mipmaps()
		pending[key]=ImageTexture.create_from_image(source)
	textures=pending
	# The new clip is optional so a missing victory asset cannot disable the hero.
	var victory := load(VictoryPose.TEXTURE) as Texture2D if ResourceLoader.exists(VictoryPose.TEXTURE) else null
	if victory!=null and victory.get_size()==Vector2(4*VictoryPose.CELL_WIDTH,VictoryPose.CELL_HEIGHT) and (not FileAccess.file_exists(VictoryPose.TEXTURE) or FileAccess.get_sha256(VictoryPose.TEXTURE)==VictoryPose.SHA256):
		textures["victory"]=victory
		manifest.clips["victory"]=VictoryPose.clip()
	CombatPose.install(manifest.clips, textures)
	FastCombat.install(manifest.clips, textures)
	FastCombat.install_rows(CombatForms.ROOT, CombatForms.DATA, manifest.clips, textures, true)
	return true

func _process(delta: float) -> void:
	clock+=delta
	var inventory:=get_node_or_null("/root/Inventory")
	var equipped: Equipment=inventory.get_equipped(Equipment.Slot.WEAPON) if inventory!=null else null
	for id in actors.keys():
		var r: Dictionary=actors[id]; var actor=r.ref.get_ref()
		if not is_instance_valid(actor):
			actors.erase(id); continue
		var field: bool=actor is Player
		var source: CanvasItem=actor.sprite if field else actor.artwork
		var eligible: bool=source!=null and (field or actor.unit_id==&"player" or actor.victory_frame>=0)
		if eligible and field:
			eligible=source.texture!=null and source.texture.resource_path.begins_with(Player.FIELD_VARIANT_ROOT) and source.hframes in [4,8] and not source.region_enabled and source.material==null
		if not eligible or not _load_assets(): _release(r); continue
		if not r.has("view"): _create(r,actor,source)
		var fallback: StringName=actor._weapon_style if field else &""
		var appearance:=Carry.equipment_appearance(equipped,fallback)
		if field: _field_pose(r,actor,appearance)
		else: _battle_pose(r,actor,appearance)

func _create(r: Dictionary, actor: Node, source: CanvasItem) -> void:
	var vp:=SubViewport.new(); vp.name="LayeredAppearanceCanvas"; vp.size=CANVAS; vp.transparent_bg=true; vp.disable_3d=true; vp.world_2d=World2D.new()
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS; actor.add_child(vp)
	var pose:=Pose.new(); vp.add_child(pose); pose.position=ORIGIN; pose.configure(manifest,textures)
	var view:=Sprite2D.new(); view.name="LayeredNamedWeapon"; view.centered=false; view.texture=vp.get_texture(); view.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	source.add_child(view)
	r.merge({"viewport":vp,"pose":pose,"view":view,"source":source,"base_color":source.self_modulate,"active":false})
	if actor is Player:
		var ghost: Sprite2D=actor._overlap_ghost
		var gv:=Sprite2D.new(); gv.name="LayeredNamedWeaponGhost"; gv.centered=false; gv.texture=view.texture; gv.texture_filter=view.texture_filter
		ghost.add_child(gv)
		var mat:=ShaderMaterial.new(); mat.shader=ghost_shader; gv.material=mat
		r.merge({"ghost":ghost,"ghost_view":gv,"ghost_color":ghost.self_modulate,"ghost_material":mat})
		var town := actor.get_parent().get_parent()
		if town != null and "ghost" in town and is_instance_valid(town.ghost):
			var overlay := town.ghost.get("overlay") as Sprite2D
			if overlay != null:
				var town_view := Sprite2D.new()
				town_view.name = "LayeredTownOverlap"
				town_view.centered = false
				town_view.texture = view.texture
				town_view.texture_filter = view.texture_filter
				town_view.hide()
				overlay.add_child(town_view)
				r.merge({"town_overlay": overlay, "town_view": town_view, "town_color": overlay.self_modulate})

func _activate(r: Dictionary, foot: Vector2, ratio: float) -> void:
	if not r.active:
		r.base_color=r.source.self_modulate
		if r.has("ghost"): r.ghost_color=r.ghost.self_modulate
	r.active=true; r.view.visible=true; r.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	r.source.self_modulate=Color(r.base_color.r,r.base_color.g,r.base_color.b,0)
	r.view.scale=Vector2.ONE*ratio; r.view.position=foot-ORIGIN*ratio

func _release(r: Dictionary) -> void:
	if not r.get("active",false): return
	r.active=false
	r.erase("ready_clip")
	if is_instance_valid(r.view): r.view.visible=false
	if is_instance_valid(r.viewport): r.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	if is_instance_valid(r.source) and r.source.self_modulate.a==0: r.source.self_modulate=r.base_color
	if r.has("ghost") and is_instance_valid(r.ghost):
		r.ghost_view.visible=false
		if r.ghost.self_modulate.a==0: r.ghost.self_modulate=r.ghost_color
	if r.has("town_overlay") and is_instance_valid(r.town_overlay):
		r.town_view.hide()
		r.town_overlay.self_modulate = r.town_color

func _field_pose(r: Dictionary, actor: Player, id: String) -> void:
	var sprite: Sprite2D=actor.sprite
	var dir: String=actor._direction
	var clip:= "walk" if sprite.hframes==8 else "idle"
	if dir in ["up","down"]: clip+="_"+dir
	r.pose.show_pose(id,clip,sprite.frame,-1 if dir=="left" else 1,clock,not Carry.sheath_for(id).is_empty(),Carry.carries_on_back(id))
	var router := get_node_or_null("/root/SceneRouter")
	var world_travel: bool = router!=null and router.is_world_map_scene(router.get_current_field_id())
	var standing_height := WORLD_STANDING_HEIGHT if world_travel else LOCAL_STANDING_HEIGHT
	_activate(r,Vector2(0,sprite.texture.get_height()*0.45),standing_height/SOURCE_STANDING_HEIGHT)
	r.ghost.self_modulate=Color(r.ghost_color.r,r.ghost_color.g,r.ghost_color.b,0)
	if r.has("town_overlay") and is_instance_valid(r.town_overlay):
		var town_blocked: bool = r.town_overlay.is_visible_in_tree()
		r.town_overlay.self_modulate.a = 0
		r.town_view.visible = town_blocked
		if town_blocked:
			# The town requests a whole translucent silhouette. Use the same
			# layered pose there and hide the duplicate normal pass.
			r.town_view.global_transform = r.view.global_transform
			r.view.hide()
			r.ghost_view.hide()
			return
	r.ghost_view.visible = r.ghost.visible
	if not r.ghost.visible:
		return
	r.ghost_view.global_transform = r.view.global_transform
	var mat: ShaderMaterial=r.ghost_material
	mat.set_shader_parameter("view_scale",r.view.scale); mat.set_shader_parameter("view_offset",r.view.position)
	var old: ShaderMaterial=r.ghost.material as ShaderMaterial
	if old == null:
		r.view.hide()
	var mode:=0
	if old!=null:
		if old.shader.code.contains("actor_local_rect"):
			mode=2
			for key in ["frame_mask","actor_local_rect","mask_flip"]: mat.set_shader_parameter(key,old.get_shader_parameter(key))
		else:
			mode=1
			for key in ["overlap_mask","mask_world_size"]: mat.set_shader_parameter(key,old.get_shader_parameter(key))
	mat.set_shader_parameter("mode",mode)

func _battle_pose(r: Dictionary, actor: BattleActor, id: String) -> void:
	var clip: String=""
	var frame:=0
	if actor.victory_frame>=0 and manifest.clips.has("victory"):
		clip="victory"
		frame=actor.victory_frame
	elif actor.unit_id==&"player" and not actor.combat_clip.is_empty() and manifest.clips.has(actor.combat_clip):
		clip=actor.combat_clip
		frame=actor.combat_frame
	elif actor.unit_id==&"player":
		for pair in [["idle",actor.ready_frames],["walk",actor.move_frames],["attack",actor.attack_frames],["hit",actor.hit_frames],["defeat",actor.defeat_frames]]:
			var found: int=pair[1].find(actor.artwork.texture)
			if found>=0: clip=pair[0]; frame=found; break
	if clip.is_empty(): _release(r); return
	if clip=="idle":
		var ready_clip := CombatPose.ready_clip(id)
		if manifest.clips.has(ready_clip):
			clip = ready_clip
			if manifest.clips[clip].frames.size() == 4:
				if r.get("ready_clip", "") != clip:
					r.ready_clip = clip
					r.ready_started = clock
				frame = READY_CYCLE[int((clock - float(r.ready_started)) * 6.0) % READY_CYCLE.size()]
	elif clip=="walk":
		frame=frame*2+int(actor._visual_clock>=actor._visual_frame_duration*0.5)
	elif clip=="attack":
		if manifest.clips.has(actor.action_pose):
			clip = actor.action_pose
			var authored_count: int = manifest.clips[clip].frames.size()
			# Preserve the native strike tick (floor of half the source sequence).
			var native_impact := actor.attack_frames.size() / 2
			var authored_impact := authored_count / 2
			if frame < native_impact:
				frame = int(float(frame * authored_impact) / native_impact)
			elif frame == native_impact:
				frame = authored_impact
			else:
				frame = authored_count - 1
		# Preserve explicitly authored non-palm special-skill art.
		elif not actor.default_attack_frames.has(actor.artwork.texture):
			_release(r)
			return
		elif id in ["jinhe_duanyue_blade","plain_blade"] or Legendary.WEAPONS.get(id,{}).get("heavy",false):
			clip="attack_dao"
	if not clip.begins_with("ready_"):
		r.erase("ready_clip")
	frame=clampi(frame,0,manifest.clips[clip].frames.size()-1)
	r.pose.show_pose(id,clip,frame,-1 if actor._visual_direction<0 else 1,clock)
	var fit:=minf(actor.artwork.size.x/512.0,actor.artwork.size.y/384.0)
	_activate(r,actor.artwork.size*0.5+Vector2(0,180)*fit,300.0/690.0*fit)

func _afterimage(id: int) -> void:
	var node=instance_from_id(id)
	if not node is TextureRect or node.name=="Artwork" or node.texture==null: return
	# Exact native afterimage consumer: sibling in the same formation + same hero texture.
	for r: Dictionary in actors.values():
		var actor=r.ref.get_ref()
		if not actor is BattleActor or not r.get("active",false) or actor.get_parent()!=node.get_parent() or node.texture!=actor.artwork.texture: continue
		if node.size!=actor.artwork.size or node.z_index!=actor.z_index-1: continue
		var vp:=SubViewport.new(); vp.size=CANVAS; vp.transparent_bg=true; vp.disable_3d=true; vp.world_2d=World2D.new(); vp.render_target_update_mode=SubViewport.UPDATE_ONCE; node.add_child(vp)
		var pose:=Pose.new(); vp.add_child(pose); pose.position=ORIGIN; pose.configure(manifest,textures)
		pose.show_pose(r.pose.current_weapon,r.pose.current_clip,r.pose.current_frame,r.pose.current_facing,r.pose.fx_clock,r.pose.current_sheathed,r.pose.current_back_carried)
		var view:=Sprite2D.new(); view.centered=false; view.texture=vp.get_texture(); view.scale=r.view.scale; view.position=r.view.position; node.add_child(view)
		node.self_modulate.a=0
		return

func debug_state() -> Dictionary:
	var result: Dictionary={"textures":textures.size(),"failed":load_failed,"actors":[]}
	for r: Dictionary in actors.values():
		var actor=r.ref.get_ref()
		if not is_instance_valid(actor): continue
		var info: Dictionary={"path":str(actor.get_path()),"active":r.active}
		if r.active: info.merge({"weapon":r.pose.current_weapon,"clip":r.pose.current_clip,"frame":r.pose.current_frame,"facing":r.pose.current_facing,"foot":r.view.position+ORIGIN*r.view.scale})
		result.actors.append(info)
	return result
