extends RefCounted
## One owned, flat native-texture layer per supported field setup. No bodies,
## interactions, ground support or actor ghost; it never changes walkability.
const SELF="res://scripts/city/luoyang_environment_layer_20261022ap.gd"
const INDEX="res://scripts/city/luoyang_environment_index_20261022ap.gd"
const AUTHOR="res://data/maps/luoyang_full_city_20261022ap/environment.json"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const NAME="LuoyangAPGroundAndUseLayer"
const Z=-4
const IDS=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
const SIZE=Vector2(3072,2048)
const SIGN_TEXTURE="res://art/modules/luoyang_full_city_20261022ap/sign.png"
const SIGN_SHA="37c59298f97f640787f7b7cd612c41891c35f3e85ebaa6e7e2a8ce75299711d4"
const PAWN_TEXTURE="res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/north_market_front.png"
const PAWN_SHA="6097a1d45fa5e829a2130ab2d41df988f0c521a3e14ed102ffdabdc99c848209"
static func fail(error: String,detail: Variant=null) -> Dictionary: return {"ok":false,"error":error,"detail":detail}
static func number(raw: Variant) -> bool: return (raw is int or raw is float) and is_finite(float(raw))
static func pair(raw: Variant) -> bool: return raw is Array and raw.size()==2 and number(raw[0]) and number(raw[1])
static func hash_valid(raw: Variant) -> bool:
	if not raw is String or raw.length()!=64: return false
	for i: int in raw.length():
		if raw.unicode_at(i) not in [48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102]: return false
	return true
static func header() -> Dictionary:
	if not FileAccess.file_exists(INDEX): return {}
	var authority: Variant=load(INDEX)
	if not authority is GDScript or authority.resource_path!=INDEX or not authority.formal_enabled(): return {}
	var row: Dictionary=authority.entry()
	if row.size()!=2 or row.get("path")!=AUTHOR or not hash_valid(row.get("sha256")) or FileAccess.get_sha256(AUTHOR)!=row.sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not raw is Dictionary or raw.get("status")!="ROOT_BOUND_AP_EIGHT_FIELD_ENVIRONMENT" or not pair(raw.get("design_size")) or Vector2(raw.design_size[0],raw.design_size[1])!=SIZE or raw.get("no_collision_navigation_or_interaction_delta")!=true or not raw.get("scenes") is Dictionary or raw.scenes.size()!=8 or not raw.get("assets") is Dictionary or not raw.get("source_sha256") is Dictionary or raw.source_sha256.has(INDEX) or raw.source_sha256.has(AUTHOR): return {}
	for id: String in IDS:
		if not raw.scenes.has(id): return {}
	if not raw.get("facade_source_sha256") is Dictionary or raw.get("facade_attachments")!=[{"id":"ap_pawn_dang_sign","parent_id":"market_west_ward_frontage","asset":"pawn_dang_sign","parent_mount":[650,450],"texture_mount":[114,324],"complete_A1_height":156}]: return {}
	if raw.facade_source_sha256.get(SIGN_TEXTURE)!=SIGN_SHA: return {}
	return raw
static func source_paths_for(id: StringName) -> Dictionary:
	if String(id) not in IDS: return {}
	var data: Dictionary=header()
	if data.is_empty(): return {}
	var out: Dictionary={SELF:true,INDEX:true,AUTHOR:true}
	# The small per-release author owns all four shared materials. Each material
	# is loaded only once by a Field setup; there is no per-frame hash or spawn.
	for p: String in data.source_sha256:
		if not p.begins_with("res://") or ".." in p or not hash_valid(data.source_sha256[p]): return {}
		out[p]=true
	if id==&"ch4_s3_luoyang_market":
		for p: String in data.facade_source_sha256:
			if not p.begins_with("res://") or ".." in p or not hash_valid(data.facade_source_sha256[p]): return {}
			out[p]=true
	return out
static func install(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if scene==null or String(scene.scene_id) not in IDS: return {"ok":true,"matched":false}
	if not is_instance_valid(field) or field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or not is_instance_valid(world) or world!=field.get("world_container") or not owner.is_valid() or not owner.call(): return fail("AP_ENVIRONMENT_OWNER_OR_WORLD")
	var design_scale: float=1.0
	if scene.scene_id==&"ch4_s4_ancient_temple":
		var temple: Variant=load("res://scripts/city/luoyang_temple_assembly_20261016.gd")
		var background: TextureRect=field.get("background") as TextureRect
		if not temple.is_scene(scene) or background==null or background.texture==null or scene.map_layout.design_size!=Vector2i(1536,1024) or not scene.map_layout.fill_viewport or world_size!=field.call("_resolve_world_size",scene,background.texture) or background.texture.get_width()*1024!=background.texture.get_height()*1536: return fail("AP_TEMPLE_EXACT_SOURCE_WORLD_MAPPING")
		design_scale=world_size.x/SIZE.x
		if design_scale<=0: return fail("AP_TEMPLE_UNIFORM_SCALE")
	elif world_size!=SIZE: return fail("AP_ENVIRONMENT_FIXED_SEVEN_WORLD_SIZES")
	var data: Dictionary=header()
	if data.is_empty(): return fail("AP_ENVIRONMENT_AUTHORITY_NOT_READY")
	if world.get_node_or_null(NodePath(NAME))!=null: return fail("AP_ENVIRONMENT_DUPLICATE_SETUP")
	var source_first: Dictionary={};var textures: Dictionary={};var source_pins: Dictionary=data.source_sha256.duplicate()
	if scene.scene_id==&"ch4_s3_luoyang_market":
		for p: String in data.facade_source_sha256:
			if source_pins.has(p) and source_pins[p]!=data.facade_source_sha256[p]: return fail("AP_SIGN_CONFLICTING_SOURCE",p)
			source_pins[p]=data.facade_source_sha256[p]
	for p: String in source_pins:
		var actual: String=FileAccess.get_sha256(p)
		if actual!=source_pins[p]: return fail("AP_ENVIRONMENT_SOURCE_CHANGED",p)
		source_first[p]=actual
	var used: Dictionary={}
	for row: Dictionary in data.scenes[String(scene.scene_id)].ground: used[String(row.get("asset",""))]=true
	for key: String in used:
		if not data.assets.has(key): return fail("AP_ENVIRONMENT_UNDECLARED_TEXTURE",key)
		var asset: Dictionary=data.assets[key]
		if not asset.get("texture") is String or not data.source_sha256.has(asset.texture) or not pair(asset.get("source_size")): return fail("AP_ENVIRONMENT_TEXTURE_DECLARATION",key)
		var texture:=ResourceLoader.load(asset.texture) as Texture2D
		if texture==null or texture.get_size()!=Vector2(asset.source_size[0],asset.source_size[1]): return fail("AP_ENVIRONMENT_TEXTURE_SIZE",key)
		textures[key]=texture
	var layer:=Node2D.new();layer.name=NAME;layer.z_index=Z
	var count: int=0;var seen: Dictionary={}
	for row: Dictionary in data.scenes[String(scene.scene_id)].ground:
		if row.size()!=4 or not row.get("id") is String or seen.has(row.id) or not textures.has(row.get("asset")) or not number(row.get("uniform_scale")) or float(row.uniform_scale)<=0: layer.free();return fail("AP_ENVIRONMENT_GROUND_DECLARATION",row.get("id"))
		var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=textures[row.asset];sprite.scale=Vector2.ONE*float(row.uniform_scale)*design_scale
		var area: Rect2
		if row.has("rect"):
			if not row.rect is Array or row.rect.size()!=4: layer.free();return fail("AP_ENVIRONMENT_RECT_DECLARATION",row.id)
			for scalar: Variant in row.rect:
				if not number(scalar): layer.free();return fail("AP_ENVIRONMENT_RECT_NUMBER",row.id)
			area=Rect2(row.rect[0],row.rect[1],row.rect[2],row.rect[3])
			if not area.has_area() or not Rect2(Vector2.ZERO,SIZE).encloses(area): layer.free();return fail("AP_ENVIRONMENT_WORLD_RECT",row.id)
			sprite.centered=false;sprite.position=area.position*design_scale
			# One real repeating source and one uniform scale; no bitmap edit.
			sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,area.size/float(row.uniform_scale));sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		elif row.has("center"):
			var asset: Dictionary=data.assets[row.asset]
			if not pair(row.center) or not asset.get("used_rect") is Array or asset.used_rect.size()!=4: layer.free();return fail("AP_ENVIRONMENT_FULL_ALPHA_STAMP",row.id)
			var source_size:=Vector2(asset.source_size[0],asset.source_size[1]);var full:=Rect2(asset.used_rect[0],asset.used_rect[1],asset.used_rect[2],asset.used_rect[3])
			var center:=Vector2(row.center[0],row.center[1]);area=Rect2(center+(full.position-source_size*.5)*float(row.uniform_scale),full.size*float(row.uniform_scale))
			if not Rect2(Vector2.ZERO,SIZE).encloses(area): layer.free();return fail("AP_ENVIRONMENT_STAMP_A1_OUTSIDE_WORLD",row.id)
			sprite.centered=true;sprite.position=center*design_scale
		else: layer.free();return fail("AP_ENVIRONMENT_RECT_OR_STAMP_ONLY",row.id)
		sprite.set_meta("ap_source_asset",data.assets[row.asset].texture);sprite.set_meta("ap_world_rect",area);sprite.set_meta("ap_no_collision_support_ghost",true)
		layer.add_child(sprite);seen[row.id]=true;count+=1
	if count==0 or not owner.call(): layer.free();return fail("AP_ENVIRONMENT_EMPTY_OR_CANCELLED")
	var source_final: Dictionary={}
	for p: String in source_first:
		source_final[p]=FileAccess.get_sha256(p)
		if source_final[p]!=source_first[p]: layer.free();return fail("AP_ENVIRONMENT_SOURCE_FINAL_CHANGED",p)
	if not owner.call(): layer.free();return fail("AP_ENVIRONMENT_CANCELLED_BEFORE_ATTACH")
	var receipt: Dictionary={"ok":true,"matched":true,"scene_id":String(scene.scene_id),"count":count,"source_first":source_first,"source_final":source_final,"source_hash_passes":2,"z_index":Z,"virtual_design_size":SIZE,"real_world_size":world_size,"source_uniform_design_scale":design_scale,"no_physics_support_ghost_or_interactions":true,"parent_visual_rows_untouched":true,"visible_purpose":data.scenes[String(scene.scene_id)].visible_purpose}
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var attached: Dictionary=attach_pawn_sign(field,scene,data,owner)
		if attached.get("ok")!=true: layer.free();return attached
		receipt["facade_attachment"]=attached
	layer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)
	return receipt


static func attach_pawn_sign(field: Node,scene: SceneScript,data: Dictionary,owner: Callable) -> Dictionary:
	if scene.scene_id!=&"ch4_s3_luoyang_market" or not owner.call(): return fail("AP_SIGN_EXACT_MARKET_OWNER")
	var actor: Node2D=field.get("_actor_layer") as Node2D
	if not is_instance_valid(actor): return fail("AP_SIGN_ACTOR_LAYER")
	var found: Array[Sprite2D]=[]
	for child: Node in actor.get_children():
		if child.name=="SceneObject_market_west_ward_frontage" and child is Sprite2D: found.append(child as Sprite2D)
	if found.size()!=1: return fail("AP_SIGN_UNIQUE_REAL_PAWN")
	var pawn: Sprite2D=found[0]
	var scale_value: float=800.0/1029.0
	# Reproduce the native Vector2 normalization/render-size round trip exactly.
	var expected_scale: Vector2=(Vector2(1039,696)*scale_value)/Vector2(1039,696)
	var expected_center: Vector2=((Vector2(570,1880)+(Vector2(1039,696)*.5-Vector2(529.5,620))*scale_value)/SIZE)*SIZE
	if pawn.texture==null or pawn.texture.resource_path!=PAWN_TEXTURE or pawn.texture.get_size()!=Vector2(1039,696) or FileAccess.get_sha256(PAWN_TEXTURE)!=PAWN_SHA or pawn.scale!=expected_scale or pawn.position!=expected_center or not pawn.centered or pawn.rotation!=0.0 or pawn.get_node_or_null("APExactPawnDangSign")!=null: return fail("AP_SIGN_EXACT_PAWN_SOURCE_TRANSFORM")
	var texture: Texture2D=ResourceLoader.load(SIGN_TEXTURE) as Texture2D
	if texture==null or texture.get_size()!=Vector2(944,1649) or FileAccess.get_sha256(SIGN_TEXTURE)!=SIGN_SHA: return fail("AP_SIGN_EXACT_TEXTURE")
	var image: Image=texture.get_image()
	if image==null or image.get_used_rect()!=Rect2i(109,191,726,1267): return fail("AP_SIGN_COMPLETE_A1")
	var sprite:=Sprite2D.new();sprite.name="APExactPawnDangSign";sprite.texture=texture;sprite.centered=true
	var uniform: float=156.0/1267.0
	var mount: Vector2=Vector2(650,450)-Vector2(1039,696)*.5
	sprite.position=mount+(Vector2(944,1649)*.5-Vector2(114,324))*(Vector2.ONE*uniform/pawn.scale)
	sprite.scale=Vector2.ONE*uniform/pawn.scale;sprite.z_index=1;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.set_meta("ap_pawn_sign",{"parent_id":"market_west_ward_frontage","source_mount":Vector2(650,450),"texture_mount":Vector2(114,324),"source_size":Vector2i(944,1649),"complete_A1_height":156.0,"inherits_parent_depth_fade_and_lifetime":true,"no_body_navigation_support_or_interaction":true})
	if not owner.call(): sprite.free();return fail("AP_SIGN_FINAL_OWNER")
	pawn.add_child(sprite)
	return {"ok":true,"id":"ap_pawn_dang_sign","parent_id":"market_west_ward_frontage","count":1,"native_rows_unchanged":true,"body_mask_support_unchanged":true,"parent_relative_z":1,"no_new_actor_registration":true}
