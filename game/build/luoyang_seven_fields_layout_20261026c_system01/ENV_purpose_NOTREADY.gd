extends RefCounted
const FINISH25I_ENABLED: bool=true
const FINISH25I_RUNTIME: String="res://build/luoyang_city_finish_20261025i_source01/market_living_street_repair01/closure_READY01/finish8_runtime_READY.gd"
const FINISH25I_RUNTIME_SHA: String="13d1c28a078d4124b52fefc2c611282f17e6417841a26d2434022b6d9df023e6"
const FINISH25I_PURPOSE_SPEC: String="res://build/luoyang_seven_fields_layout_20261026c_system01/purpose_seven_fields_NOTREADY.json"
const FINISH25I_PURPOSE_PINS: Dictionary={"res://build/luoyang_seven_fields_layout_20261026c_system01/purpose_seven_fields_NOTREADY.json":"fca9653407812ff7c07ba19a9f60af8e16ef2e06ad6237d3f09bc4ef25701a93","res://build/luoyang_city_finish_20261025i_source01/city_purpose_surface04_explicit_repeat_NOTREADY.gd":"28fcbf648affc0e867126a88e71286a69d82e44e0c505eb72202cea63a66b5d3","res://build/luoyang_city_finish_20261025i_source01/city_purpose_surface04_explicit_repeat_NOTREADY.gdshader":"13c1a3181570845460c624fa909232d06fb5dec5677d04dd484f14dea9388e86","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png":"39c898f7ac8c409b7b244077dd30016c398b21313156c8fc36911ddc859a5c0e","res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d","res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg":"57a87dae26769677578ab53b8829fe9b1e4dfec1ae1726f2942ce99fc73f400b","res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/forest_ground_04_diff_2k.jpg":"24b8aaf4c8547305d80b0e029ec365219ab1b90748d4ca5651bdc9e75bfde5e6"}
static func _finish25i_purpose_spec() -> Dictionary:
	if not FINISH25I_ENABLED or FileAccess.get_sha256(FINISH25I_PURPOSE_SPEC)!=FINISH25I_PURPOSE_PINS[FINISH25I_PURPOSE_SPEC]: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FINISH25I_PURPOSE_SPEC))
	if not value is Dictionary or not value.get("textures") is Dictionary or value.textures.size()!=4 or not value.get("scenes") is Dictionary or value.scenes.size()!=8: return {}
	if value.get("factory",{}).get("path")!="res://build/luoyang_city_finish_20261025i_source01/city_purpose_surface04_explicit_repeat_NOTREADY.gd" or value.factory.get("sha256")!=FINISH25I_PURPOSE_PINS[value.factory.path] or value.get("shader",{}).get("path")!="res://build/luoyang_city_finish_20261025i_source01/city_purpose_surface04_explicit_repeat_NOTREADY.gdshader" or value.shader.get("sha256")!=FINISH25I_PURPOSE_PINS[value.shader.path]: return {}
	for role: String in value.textures:
		var row: Dictionary=value.textures[role]
		if FINISH25I_PURPOSE_PINS.get(row.get("path"))!=row.get("sha256"): return {}
	return value
static func _finish25i_purpose_node(scene: SceneScript,spec: Dictionary,owner: Callable) -> Node2D:
	if not FINISH25I_ENABLED or scene==null or spec.is_empty() or not owner.is_valid() or not owner.call() or FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var runtime: Variant=load(FINISH25I_RUNTIME)
	if not runtime is GDScript or runtime.resource_path!=FINISH25I_RUNTIME or runtime.state_for(scene).is_empty(): return null
	var textures: Dictionary={}
	for role: String in spec.textures:
		var row: Dictionary=spec.textures[role]
		var texture: Texture2D=ResourceLoader.load(row.path) as Texture2D
		if texture==null or texture.resource_path!=row.path: return null
		if row.has("source_size") and texture.get_size()!=Vector2(float(row.source_size[0]),float(row.source_size[1])): return null
		textures[role]=texture
	var factory: Variant=load(spec.factory.path)
	var shader: Shader=ResourceLoader.load(spec.shader.path) as Shader
	if not factory is GDScript or factory.resource_path!=spec.factory.path or shader==null or shader.resource_path!=spec.shader.path or not owner.call(): return null
	return factory.create(spec.scenes[String(scene.scene_id)],textures,shader)
## One owned, flat native-texture layer per supported field setup. No bodies,
## interactions, ground support or actor ghost; it never changes walkability.
const SELF="res://scripts/city/luoyang_environment_layer_20261022ap.gd"
const INDEX="res://scripts/city/luoyang_environment_index_20261022ap.gd"
const AUTHOR="res://data/maps/luoyang_full_city_20261022ap/environment.json"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const NAME="LuoyangAPGroundAndUseLayer"
const MARKET_SPACE_READY=true # Native/spec admission and runtime SHA are pending Root actuals.
const MARKET_SPACE_RUNTIME="res://build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/market_courtyard_session_READY.gd"
const MARKET_SPACE_RUNTIME_SHA="4922879a8734c95ec308b6cb7ff4b026695f07bb2c48a86928a7fea07a46fc6d"
const MARKET_USE_HELPER="res://build/luoyang_market_workcourts_20261026b_system01/market_purpose_layer_street02_CANDIDATE.gd"
const MARKET_USE_HELPER_SHA="b5dc92f52434ef84b1fed33eeb8cb2e3fac37062ab207c53e557727a4adb24a6"
const MARKET_USE_SPEC="res://build/luoyang_market_workcourts_20261026b_system01/market_five_use_spec_street02_NOTREADY.json"
const MARKET_USE_SPEC_SHA="1c158b15dd87128346231e008a128ce13dc7f3e9094f8872458da37348633c86"
const MARKET_USE_SHADER="res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_use_materials_BUILD.gdshader"
const MARKET_USE_SHADER_SHA="84befe183f06894ee45c608c1ff49367b22d14cd2ddef38d84f81bdd58c7bbb0"
const MARKET_SPACE_AUTHOR="res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json"
const MARKET_SPACE_AUTHOR_SHA="de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95"
const Z=-4
const RECT_TRANSITION_SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/visual_transition_successor02_retry2/environment_rect_color_once_READY.gdshader"
const RECT_TRANSITION_SHADER_SHA="8dab8ea0515d4cc94ff89595c287d2513cb3a8d47dcd36edb1d7ed74a796ae53"
const PURPOSE_RECT_SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_visual_epoch01/rect_ground_purpose_candidate.gdshader"
const PURPOSE_RECT_SHADER_SHA="e80916d7fa99218e3dc36ee1a83efd49f544ed426739941499c8500f23da14f1"
const MARKET_L_SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/market_L_continuous_material_epoch01/market_L_continuous_candidate.gdshader"
const MARKET_L_SHADER_SHA="f1d01c7d63ba62b5c9883f4976f3b73da96e5b54243e4431d5ba5b61787c4d06"
const MARKET_L_SOURCE="res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const MARKET_L_SEGMENTS=[Vector4(1472,800,1600,800),Vector4(1600,800,1600,2024),Vector4(1600,2024,220,2024),Vector4(220,2024,220,1928),Vector4(220,1928,1472,1928),Vector4(1472,1928,1472,800)]
const ARTISAN_UNION_SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/visual_transition_successor02_retry2/artisan_ground_union_exterior_READY.gdshader"
const ARTISAN_UNION_SHADER_SHA="411bceeec31d10025ff17e21e36b416054425e916e04ee39e91038b709acda83"
const A2_MATERIAL_READY=true
const A2_FINISH_MATERIAL_HELPER="res://build/luoyang_city_finish_20261025i_source01/market_living_street_repair01/closure_READY01/material_runtime_finish139_READY.gd"
const A2_FINISH_MATERIAL_HELPER_SHA="3b29de089aed5c107cf47451f359f763f0fdaee88f171a733ee25b2259d99eef"
const A2_MATERIAL_HELPER="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/life_production100_READY/material_runtime_life_READY.gd"
const A2_MATERIAL_HELPER_SHA="7bd26f666035fc45a2f3161cc8df323da5ef6756f758ba16a6ffc1814ee5836a"
const A2_MATERIAL_CONTRACT="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_contract_READY.json"
const A2_MATERIAL_CONTRACT_SHA="87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af"
const A2_MATERIAL_SHADER="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_use_candidate.gdshader"
const A2_MATERIAL_SHADER_SHA="11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e"
const EXAMINER_SOURCES={"res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png.import":"284ed8f2af70e4b9d499fb561cb0ab88f299394690f6c9baf1b99149d85ee2b1","res://.godot/imported/examiner_mature_v1.png-25f2af75a741a5e611494715946e4a2e.ctex":"b3140dfd0ebea21c80bab0f310802ffc2e85907a386ea4c614879442f2436cac","res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png":"4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc"}
const SCHOLAR_SOURCES={"res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png.import":"b0b43881897d0c5d776993940d03ff4112abf93bf5f4bf10496efae0c05a4c6a","res://.godot/imported/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png-20c042a9774f2c6ac7ad1dfff49d229e.ctex":"257f7af837370bd7723fba1ef9760d7fd0f25b4f0259ce4a571ee61b4be2ca2f","res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png":"b1a4df81e9519bb02537a90ca683d67ffea60feb64e348e1f22ccc4a274b0fa7"}
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
	if not raw.get("facade_source_sha256") is Dictionary or not raw.get("facade_attachments") is Array or raw.facade_attachments.size()!=1: return {}
	var facade: Variant=raw.facade_attachments[0]
	if not facade is Dictionary or facade.size()!=6 or facade.get("id")!="ap_pawn_dang_sign" or facade.get("parent_id")!="market_west_ward_frontage" or facade.get("asset")!="pawn_dang_sign" or not pair(facade.get("parent_mount")) or Vector2(facade.parent_mount[0],facade.parent_mount[1])!=Vector2(650,450) or not pair(facade.get("texture_mount")) or Vector2(facade.texture_mount[0],facade.texture_mount[1])!=Vector2(114,324) or not number(facade.get("complete_A1_height")) or float(facade.complete_A1_height)!=156.0: return {}
	if raw.facade_source_sha256.get(SIGN_TEXTURE)!=SIGN_SHA: return {}
	return raw
static func source_paths_for(id: StringName) -> Dictionary:
	if String(id) not in IDS: return {}
	var data: Dictionary=header()
	if data.is_empty(): return {}
	var out: Dictionary={SELF:true,INDEX:true,AUTHOR:true,RECT_TRANSITION_SHADER:true}
	if id==&"luoyang_artisan_residential_20261022ap":
		if A2_MATERIAL_READY:
			for p: String in [A2_MATERIAL_HELPER,A2_MATERIAL_CONTRACT,A2_MATERIAL_SHADER,A2_FINISH_MATERIAL_HELPER]: out[p]=true
		else: out[ARTISAN_UNION_SHADER]=true
	if id in [&"ch4_s1_luoyang_yamen",&"ch4_s3_luoyang_market"]: out[PURPOSE_RECT_SHADER]=true
	# The small per-release author owns all four shared materials. Each material
	# is loaded only once by a Field setup; there is no per-frame hash or spawn.
	for p: String in data.source_sha256:
		if not p.begins_with("res://") or ".." in p or not hash_valid(data.source_sha256[p]): return {}
		out[p]=true
	if id==&"ch4_s3_luoyang_market":
		out[MARKET_L_SHADER]=true # Historical source retained;new layout never draws old L.
		for p: String in [MARKET_SPACE_RUNTIME,MARKET_USE_HELPER,MARKET_USE_SPEC,MARKET_USE_SHADER,MARKET_SPACE_AUTHOR]: out[p]=true
		for p: String in EXAMINER_SOURCES: out[p]=true
		for p: String in SCHOLAR_SOURCES: out[p]=true
		for p: String in data.facade_source_sha256:
			if not p.begins_with("res://") or ".." in p or not hash_valid(data.facade_source_sha256[p]): return {}
			out[p]=true
	if FINISH25I_ENABLED:
		for p: String in FINISH25I_PURPOSE_PINS: out[p]=true
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
	if scene.scene_id==&"ch4_s3_luoyang_market" and not MARKET_SPACE_READY: return fail("MARKET_SPACE_PURPOSE_NATIVE_PENDING")
	if world.get_node_or_null(NodePath(NAME))!=null: return fail("AP_ENVIRONMENT_DUPLICATE_SETUP")
	var source_first: Dictionary={};var textures: Dictionary={};var source_pins: Dictionary=data.source_sha256.duplicate()
	source_pins[RECT_TRANSITION_SHADER]=RECT_TRANSITION_SHADER_SHA
	if scene.scene_id in [&"ch4_s1_luoyang_yamen",&"ch4_s3_luoyang_market"]: source_pins[PURPOSE_RECT_SHADER]=PURPOSE_RECT_SHADER_SHA
	if scene.scene_id==&"luoyang_artisan_residential_20261022ap":
		if A2_MATERIAL_READY:
			source_pins[A2_MATERIAL_HELPER]=A2_MATERIAL_HELPER_SHA
			source_pins[A2_MATERIAL_CONTRACT]=A2_MATERIAL_CONTRACT_SHA
			source_pins[A2_MATERIAL_SHADER]=A2_MATERIAL_SHADER_SHA
			source_pins[A2_FINISH_MATERIAL_HELPER]=A2_FINISH_MATERIAL_HELPER_SHA
		else: source_pins[ARTISAN_UNION_SHADER]=ARTISAN_UNION_SHADER_SHA
	if scene.scene_id==&"ch4_s3_luoyang_market":
		source_pins[MARKET_L_SHADER]=MARKET_L_SHADER_SHA
		var use_pins: Dictionary={MARKET_SPACE_RUNTIME:MARKET_SPACE_RUNTIME_SHA,MARKET_USE_HELPER:MARKET_USE_HELPER_SHA,MARKET_USE_SPEC:MARKET_USE_SPEC_SHA,MARKET_USE_SHADER:MARKET_USE_SHADER_SHA,MARKET_SPACE_AUTHOR:MARKET_SPACE_AUTHOR_SHA}
		for p: String in use_pins: source_pins[p]=use_pins[p]
		for p: String in EXAMINER_SOURCES: source_pins[p]=EXAMINER_SOURCES[p]
		for p: String in SCHOLAR_SOURCES: source_pins[p]=SCHOLAR_SOURCES[p]
		for p: String in data.facade_source_sha256:
			if source_pins.has(p) and source_pins[p]!=data.facade_source_sha256[p]: return fail("AP_SIGN_CONFLICTING_SOURCE",p)
			source_pins[p]=data.facade_source_sha256[p]
	var finish_spec: Dictionary={}
	if FINISH25I_ENABLED:
		finish_spec=_finish25i_purpose_spec()
		if finish_spec.is_empty(): return fail("FINISH25I_PURPOSE_FIXED_SPEC")
		for p: String in FINISH25I_PURPOSE_PINS:
			if source_pins.has(p) and source_pins[p]!=FINISH25I_PURPOSE_PINS[p]: return fail("FINISH25I_PURPOSE_CONFLICTING_SOURCE",p)
			source_pins[p]=FINISH25I_PURPOSE_PINS[p]
	for p: String in source_pins:
		var actual: String=FileAccess.get_sha256(p)
		if actual!=source_pins[p]: return fail("AP_ENVIRONMENT_SOURCE_CHANGED",p)
		source_first[p]=actual
	var used: Dictionary={}
	for row: Dictionary in data.scenes[String(scene.scene_id)].ground: used[String(row.get("asset",""))]=true
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var use_spec: Variant=JSON.parse_string(FileAccess.get_file_as_string(MARKET_USE_SPEC))
		if not use_spec is Dictionary or not use_spec.get("groups") is Array or use_spec.groups.size()!=5: return fail("MARKET_USE_FIXED_FIVE")
		for use_group: Variant in use_spec.groups:
			if not use_group is Dictionary or not use_group.get("asset") is String: return fail("MARKET_USE_EXACT_GROUP")
			used[String(use_group.asset)]=true
	for key: String in used:
		if not data.assets.has(key): return fail("AP_ENVIRONMENT_UNDECLARED_TEXTURE",key)
		var asset: Dictionary=data.assets[key]
		if not asset.get("texture") is String or not data.source_sha256.has(asset.texture) or not pair(asset.get("source_size")): return fail("AP_ENVIRONMENT_TEXTURE_DECLARATION",key)
		var texture:=ResourceLoader.load(asset.texture) as Texture2D
		if texture==null or texture.get_size()!=Vector2(asset.source_size[0],asset.source_size[1]): return fail("AP_ENVIRONMENT_TEXTURE_SIZE",key)
		textures[key]=texture
	var rect_transition: Shader=ResourceLoader.load(RECT_TRANSITION_SHADER) as Shader
	if rect_transition==null or rect_transition.resource_path!=RECT_TRANSITION_SHADER: return fail("AP_ENVIRONMENT_EXACT_RECT_SHADER")
	var purpose_shader: Shader=null
	if scene.scene_id in [&"ch4_s1_luoyang_yamen",&"ch4_s3_luoyang_market"]:
		purpose_shader=ResourceLoader.load(PURPOSE_RECT_SHADER) as Shader
		if purpose_shader==null or purpose_shader.resource_path!=PURPOSE_RECT_SHADER: return fail("AP_PURPOSE_EXACT_RECT_SHADER")
	var market_l_shader: Shader=null
	if scene.scene_id==&"ch4_s3_luoyang_market":
		market_l_shader=ResourceLoader.load(MARKET_L_SHADER) as Shader
		if market_l_shader==null or market_l_shader.resource_path!=MARKET_L_SHADER: return fail("AP_MARKET_L_EXACT_SHADER")
	var layer:=Node2D.new();layer.name=NAME;layer.z_index=Z
	var count: int=0;var seen: Dictionary={}
	var market_use: Dictionary={}
	var ground_rows: Array=data.scenes[String(scene.scene_id)].ground
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var space: Variant=load(MARKET_SPACE_RUNTIME)
		if not space is GDScript or space.resource_path!=MARKET_SPACE_RUNTIME or not space.requested(scene) or not space.bound(scene): layer.free();return fail("MARKET_USE_CURRENT_NATIVE25_OWNER")
		var use_helper: Variant=load(MARKET_USE_HELPER)
		if not use_helper is GDScript or use_helper.resource_path!=MARKET_USE_HELPER: layer.free();return fail("MARKET_USE_FIXED_HELPER")
		market_use=use_helper.append_to(layer,scene,textures,space.purpose_binding(scene),owner)
		if market_use.get("ok")!=true: layer.free();return market_use
		count=int(market_use.count);ground_rows=[]
	for row: Dictionary in ground_rows:
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
			# Whole rect coordinates remain independent of repeating UV tiles.
			var transition:=ShaderMaterial.new();transition.shader=rect_transition
			transition.set_shader_parameter("ap_rect_size_world",area.size*design_scale)
			transition.set_shader_parameter("ap_source_to_world",float(row.uniform_scale)*design_scale)
			transition.set_shader_parameter("ap_feather_world",32.0)
			var core_opacity: float=1.0 if scene.scene_id==&"ch4_s3_luoyang_market" and row.id=="market_pawn_clean_paved_forecourt" else 0.66
			transition.set_shader_parameter("ap_core_opacity",core_opacity)
			sprite.modulate=Color(1.10,1.10,1.08,1.0)
			var purpose: Dictionary=purpose_rect_profile(scene.scene_id,String(row.id))
			var market_l: bool=scene.scene_id==&"ch4_s3_luoyang_market" and String(row.id) in ["market_main_street","market_pawn_approach"]
			if market_l:
				var expected_area: Rect2=Rect2(1472,800,128,1224) if row.id=="market_main_street" else Rect2(220,1928,1252,96)
				if area!=expected_area or row.asset!="road_stone" or float(row.uniform_scale)!=.25 or design_scale!=1.0 or sprite.texture.resource_path!=MARKET_L_SOURCE or sprite.texture.get_size()!=Vector2(1536,1024): layer.free();return fail("AP_MARKET_L_EXACT_TWO_ROWS",row.id)
				purpose=purpose_rect_profile(scene.scene_id,"market_main_street")
			if not purpose.is_empty():
				if purpose_shader==null: layer.free();return fail("AP_PURPOSE_SHADER_NOT_LOADED",row.id)
				transition.shader=market_l_shader if market_l else purpose_shader
				transition.set_shader_parameter("ap_rect_size_world",area.size*design_scale)
				transition.set_shader_parameter("ap_source_to_world",float(row.uniform_scale)*design_scale)
				transition.set_shader_parameter("ap_feather_world",32.0)
				transition.set_shader_parameter("ap_edge_widths_world",purpose.edge_widths*design_scale)
				transition.set_shader_parameter("ap_wear_world",purpose.wear*design_scale)
				transition.set_shader_parameter("ap_world_origin",area.position*design_scale)
				transition.set_shader_parameter("ap_material_tone",purpose.tone)
				transition.set_shader_parameter("ap_texture_contrast",purpose.contrast)
				transition.set_shader_parameter("ap_core_opacity",purpose.core)
				if market_l:
					transition.set_shader_parameter("ap_source_size",Vector2(1536,1024))
					transition.set_shader_parameter("ap_union_segments",PackedVector4Array(MARKET_L_SEGMENTS))
				sprite.modulate=Color.WHITE
				sprite.set_meta("ap_purpose_ground_visual_only",purpose.duplicate())
			sprite.material=transition
			if purpose.is_empty():
				sprite.set_meta("ap_rect_transition",{"whole_author_rect":true,"feather_world":32.0,"core_opacity":core_opacity,"no_tile_edge_feather":true})
			elif market_l:
				sprite.set_meta("ap_rect_transition",{"whole_author_rect":true,"per_rect_profile_replaced_by_union_exterior":true,"union_exterior_segments":6,"shared_world_texture_phase":true,"one_texture_sample":true,"core_opacity":purpose.core,"edge_widths_world":purpose.edge_widths,"wear_world":purpose.wear,"no_tile_or_shared_interior_edge_feather":true})
			else:
				sprite.set_meta("ap_rect_transition",{"whole_author_rect":true,"legacy_transition_replaced_by_purpose_profile":true,"core_opacity":purpose.core,"edge_widths_world":purpose.edge_widths*design_scale,"wear_world":purpose.wear*design_scale,"no_tile_edge_feather":true})
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
	if scene.scene_id==&"ch4_s3_luoyang_market" and market_use.get("ok")!=true and (not seen.has("market_main_street") or not seen.has("market_pawn_approach")): layer.free();return fail("AP_MARKET_L_TWO_ROWS_MISSING")
	if count==0 or not owner.call(): layer.free();return fail("AP_ENVIRONMENT_EMPTY_OR_CANCELLED")
	var artisan_union: Dictionary={}
	if scene.scene_id==&"luoyang_artisan_residential_20261022ap":
		if A2_MATERIAL_READY: artisan_union=_attach_a2_exact_material(field,scene,world,world_size,owner)
		else: artisan_union=attach_artisan_union_transition(field,scene,world_size,owner)
		if artisan_union.get("ok")!=true: layer.free();return artisan_union
	var finish_purpose: Node2D=null
	if FINISH25I_ENABLED:
		if world.get_node_or_null("CityPurposeGround25i")!=null: layer.free();return fail("FINISH25I_PURPOSE_DUPLICATE")
		finish_purpose=_finish25i_purpose_node(scene,finish_spec,owner)
		if finish_purpose==null: layer.free();return fail("FINISH25I_PURPOSE_SOURCE_OR_OWNER")
		# Temporary unattached ownership means every later rejection frees this too.
		# At successful commit it becomes a world sibling with factory z=-3 intact.
		layer.add_child(finish_purpose)
	var source_final: Dictionary={}
	for p: String in source_first:
		source_final[p]=FileAccess.get_sha256(p)
		if source_final[p]!=source_first[p]: layer.free();return fail("AP_ENVIRONMENT_SOURCE_FINAL_CHANGED",p)
	if not owner.call(): layer.free();return fail("AP_ENVIRONMENT_CANCELLED_BEFORE_ATTACH")
	var receipt: Dictionary={"ok":true,"matched":true,"scene_id":String(scene.scene_id),"count":count,"source_first":source_first,"source_final":source_final,"source_hash_passes":2,"z_index":Z,"virtual_design_size":SIZE,"real_world_size":world_size,"source_uniform_design_scale":design_scale,"no_physics_support_ghost_or_interactions":true,"parent_visual_rows_untouched":true,"visible_purpose":data.scenes[String(scene.scene_id)].visible_purpose}
	if not market_use.is_empty():
		receipt["market_space_five_uses"]=market_use;receipt["visible_purpose"]="300主街—南北横街—六铺退界—双后勤作业院—144/96服务巷—真实树穴"
	if not artisan_union.is_empty():
		if A2_MATERIAL_READY:
			receipt["a2_exact_runtime_material"]=artisan_union
			receipt["original_complete_alpha_ground_stamps_retained"]=count
		else: receipt["artisan_union_visual_only"]=artisan_union
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var attached: Dictionary=attach_pawn_sign(field,scene,data,owner)
		if attached.get("ok")!=true: layer.free();return attached
		receipt["facade_attachment"]=attached
	if finish_purpose!=null:
		if not owner.call(): layer.free();return fail("FINISH25I_PURPOSE_COMMIT_OWNER")
		layer.remove_child(finish_purpose);world.add_child(finish_purpose)
		receipt["finish25i_purpose_material"]={"count":finish_purpose.get_child_count(),"source_spec":FINISH25I_PURPOSE_SPEC,"world_position":finish_purpose.position,"z_index":finish_purpose.z_index,"visual_only":true,"geometry_mask_NPC_unchanged":true}
	layer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)
	return receipt


static func _attach_a2_exact_material(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if not A2_MATERIAL_READY or scene.scene_id!=&"luoyang_artisan_residential_20261022ap" or not owner.call(): return fail("A2_MATERIAL_NOT_ADMITTED")
	var helper: Variant=load(A2_MATERIAL_HELPER)
	if not helper is GDScript or helper.resource_path!=A2_MATERIAL_HELPER: return fail("A2_EXACT_RUNTIME_MATERIAL_HELPER")
	# Existing install() owns the original stamp layer and source-FIRST/FINAL.
	# Do not replace it with an empty marker or repeat its hash passes here.
	if FINISH25I_ENABLED and field.get("_finish25i")!=null:
		if FileAccess.get_sha256(A2_FINISH_MATERIAL_HELPER)!=A2_FINISH_MATERIAL_HELPER_SHA: return fail("FINISH_A2_EXACT_MATERIAL_HELPER_SOURCE")
		var finish_helper: Variant=load(A2_FINISH_MATERIAL_HELPER)
		if not finish_helper is GDScript or finish_helper.resource_path!=A2_FINISH_MATERIAL_HELPER: return fail("FINISH_A2_EXACT_MATERIAL_HELPER")
		return finish_helper.attach_finish_exact_runtime(field,scene,world,world_size,owner)
	return helper.attach_exact_runtime(field,scene,world,world_size,owner)


static func attach_artisan_union_transition(field: Node,scene: SceneScript,world_size: Vector2,owner: Callable) -> Dictionary:
	if scene.scene_id!=&"luoyang_artisan_residential_20261022ap" or world_size!=SIZE or not owner.call(): return fail("AP_UNION_EXACT_ARTISAN_WORLD")
	var visual: Node2D=field.get("_visual_layer") as Node2D
	if not is_instance_valid(visual): return fail("AP_UNION_VISUAL_LAYER")
	var shader: Shader=ResourceLoader.load(ARTISAN_UNION_SHADER) as Shader
	if shader==null or shader.resource_path!=ARTISAN_UNION_SHADER: return fail("AP_UNION_EXACT_SHADER")
	var specifications: Array=[["SceneObject_ap_main_street_paving_v2_0_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[288.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_1_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[672.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_2_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[1056.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_3_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[1440.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_4_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[1824.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_5_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[2208.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_6_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x768.tres",[2592.0,1664.0],[384,192],-28],["SceneObject_ap_main_street_paving_v2_7_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x768.tres",[2880.0,1664.0],[192,192],-28],["SceneObject_ap_cross_street_paving_v2_0_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x1024.tres",[1520.0,288.0],[192,256],-28],["SceneObject_ap_cross_street_paving_v2_0_1","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x1024.tres",[1520.0,544.0],[192,256],-28],["SceneObject_ap_cross_street_paving_v2_0_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x1024.tres",[1520.0,800.0],[192,256],-28],["SceneObject_ap_cross_street_paving_v2_0_3","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x1024.tres",[1520.0,1056.0],[192,256],-28],["SceneObject_ap_cross_street_paving_v2_0_4","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x1024.tres",[1520.0,1312.0],[192,256],-28],["SceneObject_ap_cross_street_paving_v2_0_5","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_768x512.tres",[1520.0,1504.0],[192,128],-28],["SceneObject_ap_residential_lane_paving_v2_0_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[384.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_1_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[768.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_2_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1152.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_3_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1536.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_4_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1920.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_5_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2304.0,864.0],[384,128],-28],["SceneObject_ap_residential_lane_paving_v2_6_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2688.0,864.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_0_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[384.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_1_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[768.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_2_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1152.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_3_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1536.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_4_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1920.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_5_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2304.0,1336.0],[384,128],-28],["SceneObject_ap_craft_lane_paving_v2_6_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2688.0,1336.0],[384,128],-28],["SceneObject_ap_woodwork_workyard_stone_v3_0_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[448.0,928.0],[384,256],-28],["SceneObject_ap_woodwork_workyard_stone_v3_1_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[832.0,928.0],[384,256],-28],["SceneObject_ap_woodwork_workyard_stone_v3_0_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[448.0,1184.0],[384,256],-28],["SceneObject_ap_woodwork_workyard_stone_v3_1_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[832.0,1184.0],[384,256],-28],["SceneObject_ap_woodwork_workyard_stone_v3_0_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[448.0,1376.0],[384,128],-28],["SceneObject_ap_woodwork_workyard_stone_v3_1_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[832.0,1376.0],[384,128],-28],["SceneObject_ap_shared_well_court_stone_v3_0_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1216.0,928.0],[384,256],-28],["SceneObject_ap_shared_well_court_stone_v3_1_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1600.0,928.0],[384,256],-28],["SceneObject_ap_shared_well_court_stone_v3_2_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_384x1024.tres",[1840.0,928.0],[96,256],-28],["SceneObject_ap_shared_well_court_stone_v3_0_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1216.0,1184.0],[384,256],-28],["SceneObject_ap_shared_well_court_stone_v3_1_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1600.0,1184.0],[384,256],-28],["SceneObject_ap_shared_well_court_stone_v3_2_1","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_384x1024.tres",[1840.0,1184.0],[96,256],-28],["SceneObject_ap_shared_well_court_stone_v3_0_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1216.0,1376.0],[384,128],-28],["SceneObject_ap_shared_well_court_stone_v3_1_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[1600.0,1376.0],[384,128],-28],["SceneObject_ap_shared_well_court_stone_v3_2_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_384x512.tres",[1840.0,1376.0],[96,128],-28],["SceneObject_ap_cloth_workyard_stone_v3_0_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[2080.0,928.0],[384,256],-28],["SceneObject_ap_cloth_workyard_stone_v3_1_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[2464.0,928.0],[384,256],-28],["SceneObject_ap_cloth_workyard_stone_v3_0_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[2080.0,1184.0],[384,256],-28],["SceneObject_ap_cloth_workyard_stone_v3_1_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[2464.0,1184.0],[384,256],-28],["SceneObject_ap_cloth_workyard_stone_v3_0_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2080.0,1376.0],[384,128],-28],["SceneObject_ap_cloth_workyard_stone_v3_1_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x512.tres",[2464.0,1376.0],[384,128],-28],["SceneObject_ap_residential_forecourt_stone_v3_0_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[384.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_1_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[768.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_2_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[1152.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_3_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[1536.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_4_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[1920.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_5_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[2304.0,720.0],[384,160],-28],["SceneObject_ap_residential_forecourt_stone_v3_6_0","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x640.tres",[2688.0,720.0],[384,160],-28],["SceneObject_ap_south_shop_apron_stone_v3_0_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1344.0,1568.0],[384,256],-28],["SceneObject_ap_south_shop_apron_stone_v3_1_0","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1728.0,1568.0],[384,256],-28],["SceneObject_ap_south_shop_apron_stone_v3_0_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1344.0,1824.0],[384,256],-28],["SceneObject_ap_south_shop_apron_stone_v3_1_1","res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png",[1728.0,1824.0],[384,256],-28],["SceneObject_ap_south_shop_apron_stone_v3_0_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x192.tres",[1344.0,1976.0],[384,48],-28],["SceneObject_ap_south_shop_apron_stone_v3_1_2","res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision3/atlases/stone_1536x192.tres",[1728.0,1976.0],[384,48],-28]]
	var prepared: Array[Dictionary]=[]
	var segments:=PackedVector4Array([Vector4(1424,160,1616,160),Vector4(192,640,1424,640),Vector4(1616,640,2880,640),Vector4(192,928,256,928),Vector4(2656,928,2880,928),Vector4(192,1272,256,1272),Vector4(2656,1272,2880,1272),Vector4(192,1400,256,1400),Vector4(2656,1400,2880,1400),Vector4(256,1440,1152,1440),Vector4(1920,1440,2656,1440),Vector4(96,1568,1152,1568),Vector4(1920,1568,2976,1568),Vector4(96,1760,1152,1760),Vector4(1920,1760,2976,1760),Vector4(1152,2000,1920,2000),Vector4(96,1568,96,1760),Vector4(192,640,192,928),Vector4(192,1272,192,1400),Vector4(256,928,256,1272),Vector4(256,1400,256,1440),Vector4(1152,1440,1152,1568),Vector4(1152,1760,1152,2000),Vector4(1424,160,1424,640),Vector4(1616,160,1616,640),Vector4(1920,1440,1920,1568),Vector4(1920,1760,1920,2000),Vector4(2656,928,2656,1272),Vector4(2656,1400,2656,1440),Vector4(2880,640,2880,928),Vector4(2880,1272,2880,1400),Vector4(2976,1568,2976,1760)])
	for row: Array in specifications:
		var found: Array[Sprite2D]=[]
		for child: Node in visual.get_children():
			if child is Sprite2D and String(child.name)==row[0]: found.append(child as Sprite2D)
		if found.size()!=1: return fail("AP_UNION_EXACT_NATIVE_TILE",row[0])
		var sprite: Sprite2D=found[0]
		var source_size: Vector2=sprite.texture.get_size() if sprite.texture!=null else Vector2.ZERO
		var native_pos: Vector2=(Vector2(row[2][0],row[2][1])/SIZE)*SIZE
		var native_size:=Vector2(row[3][0],row[3][1])
		if sprite.texture==null or sprite.texture.resource_path!=row[1] or not sprite.centered or sprite.position!=native_pos or sprite.scale!=native_size/source_size or sprite.rotation!=0.0 or sprite.z_index!=row[4] or sprite.material!=null: return fail("AP_UNION_NATIVE_SOURCE_TRANSFORM",row[0])
		var material:=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("ap_union_segments",segments)
		material.set_shader_parameter("ap_sprite_design_origin",sprite.position)
		material.set_shader_parameter("ap_sprite_source_to_design",sprite.scale)
		prepared.append({"sprite":sprite,"material":material})
	if not owner.call(): return fail("AP_UNION_CANCELLED_BEFORE_ATTACH")
	for row: Dictionary in prepared:
		var sprite: Sprite2D=row.sprite
		sprite.material=row.material
		sprite.set_meta("ap_union_exterior_transition",{"segment_count":32,"feather_world":32.0,"core_opacity":1.0,"native_transform_and_texture_unchanged":true,"no_tile_or_interior_section_seams":true})
	return {"ok":true,"native_tile_count":prepared.size(),"source_sections":9,"exterior_segments":32,"feather_world":32.0,"core_opacity":1.0,"visual_only":true,"no_native_geometry_delta":true}


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
	var block_runtime: Variant=load(MARKET_SPACE_RUNTIME)
	if not block_runtime is GDScript or block_runtime.resource_path!=MARKET_SPACE_RUNTIME or not block_runtime.bound(scene): return fail("MARKET24E_SIGN_CURRENT_FIELD_LEASE")
	var block_pawn: Dictionary=block_runtime.pawn_transform(scene)
	if block_pawn.get("ok")!=true: return fail("MARKET24E_SIGN_EXACT_PAWN_ROW")
	expected_scale=block_pawn.scale;expected_center=block_pawn.center
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

static func purpose_rect_profile(scene_id: StringName,row_id: String) -> Dictionary:
	# Fixed use-oriented settings, not random patches; no author/native mutation.
	if scene_id==&"ch4_s1_luoyang_yamen":
		if row_id=="official_court_axis": return {"purpose":"official_axis","edge_widths":Vector4(44,24,44,24),"wear":8.0,"tone":Color(.56,.57,.54,1),"contrast":.46,"core":.52}
		if row_id=="petition_waiting_court": return {"purpose":"waiting_court","edge_widths":Vector4(64,48,64,48),"wear":18.0,"tone":Color(.55,.555,.525,1),"contrast":.40,"core":.48}
	if scene_id==&"ch4_s3_luoyang_market":
		if row_id=="market_pawn_clean_paved_forecourt": return {"purpose":"pawn_forecourt_opaque_core","edge_widths":Vector4(48,96,64,24),"wear":12.0,"tone":Color(.57,.58,.56,1),"contrast":.34,"core":1.0}
		if row_id=="market_main_street": return {"purpose":"market_spine","edge_widths":Vector4(28,20,28,20),"wear":6.0,"tone":Color(.56,.57,.54,1),"contrast":.46,"core":.50}
		if row_id=="market_pawn_approach": return {"purpose":"pawn_public_approach","edge_widths":Vector4(40,24,40,24),"wear":8.0,"tone":Color(.55,.56,.53,1),"contrast":.42,"core":.56}
	return {}
