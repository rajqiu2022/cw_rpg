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
	return out
static func install(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if scene==null or String(scene.scene_id) not in IDS: return {"ok":true,"matched":false}
	if not is_instance_valid(field) or field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or not is_instance_valid(world) or world!=field.get("world_container") or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("AP_ENVIRONMENT_OWNER_OR_WORLD")
	var data: Dictionary=header()
	if data.is_empty(): return fail("AP_ENVIRONMENT_AUTHORITY_NOT_READY")
	if world.get_node_or_null(NodePath(NAME))!=null: return fail("AP_ENVIRONMENT_DUPLICATE_SETUP")
	var source_first: Dictionary={};var textures: Dictionary={}
	for p: String in data.source_sha256:
		var actual: String=FileAccess.get_sha256(p)
		if actual!=data.source_sha256[p]: return fail("AP_ENVIRONMENT_SOURCE_CHANGED",p)
		source_first[p]=actual
	for key: String in data.assets:
		var asset: Dictionary=data.assets[key]
		if not asset.get("texture") is String or not data.source_sha256.has(asset.texture) or not pair(asset.get("source_size")): return fail("AP_ENVIRONMENT_TEXTURE_DECLARATION",key)
		var texture:=ResourceLoader.load(asset.texture) as Texture2D
		if texture==null or texture.get_size()!=Vector2(asset.source_size[0],asset.source_size[1]): return fail("AP_ENVIRONMENT_TEXTURE_SIZE",key)
		textures[key]=texture
	var layer:=Node2D.new();layer.name=NAME;layer.z_index=Z
	var count: int=0;var seen: Dictionary={}
	for row: Dictionary in data.scenes[String(scene.scene_id)].ground:
		if not row.get("id") is String or seen.has(row.id) or not textures.has(row.get("asset")) or not row.get("rect") is Array or row.rect.size()!=4 or not number(row.get("uniform_scale")) or float(row.uniform_scale)<=0: layer.free();return fail("AP_ENVIRONMENT_GROUND_DECLARATION",row.get("id"))
		for scalar: Variant in row.rect:
			if not number(scalar): layer.free();return fail("AP_ENVIRONMENT_RECT_NUMBER",row.id)
		var area:=Rect2(row.rect[0],row.rect[1],row.rect[2],row.rect[3])
		if not area.has_area() or not Rect2(Vector2.ZERO,SIZE).encloses(area): layer.free();return fail("AP_ENVIRONMENT_WORLD_RECT",row.id)
		var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=textures[row.asset];sprite.centered=false;sprite.position=area.position;sprite.scale=Vector2.ONE*float(row.uniform_scale)
		# Native repeating source, one uniform scale. Cropping occurs on the
		# Sprite region, never by painting, resizing or editing the source PNG.
		sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,area.size/float(row.uniform_scale));sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.set_meta("ap_source_asset",data.assets[row.asset].texture);sprite.set_meta("ap_world_rect",area);sprite.set_meta("ap_no_collision_support_ghost",true)
		layer.add_child(sprite);seen[row.id]=true;count+=1
	if count==0 or not owner.call(): layer.free();return fail("AP_ENVIRONMENT_EMPTY_OR_CANCELLED")
	var source_final: Dictionary={}
	for p: String in source_first:
		source_final[p]=FileAccess.get_sha256(p)
		if source_final[p]!=source_first[p]: layer.free();return fail("AP_ENVIRONMENT_SOURCE_FINAL_CHANGED",p)
	if not owner.call(): layer.free();return fail("AP_ENVIRONMENT_CANCELLED_BEFORE_ATTACH")
	var receipt: Dictionary={"ok":true,"matched":true,"scene_id":String(scene.scene_id),"count":count,"source_first":source_first,"source_final":source_final,"source_hash_passes":2,"z_index":Z,"no_physics_support_ghost_or_interactions":true,"parent_visual_rows_untouched":true,"visible_purpose":data.scenes[String(scene.scene_id)].visible_purpose}
	layer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)
	return receipt
