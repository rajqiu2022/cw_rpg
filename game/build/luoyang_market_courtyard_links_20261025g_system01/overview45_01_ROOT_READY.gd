extends "res://build/luoyang_city_revision_20261025f_qa01/overview02_ROOT_REVIEW/test_ROOT_REVIEW.gd"
## Authoring-only45 overview: same25f .5 world, six purpose materials; not Field.
const COURTYARD_OVERVIEW_READY = true
const HEADER25G = "res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/overlay_header_NOTREADY.json"
const HEADER_SHA25G = "8a1064f33f5c6303e237c4ecb6e6fb31318e926edb58811a09def30d7c059d6e"
const PROJECTION25G = "res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/projection.bin"
const PROJECTION_SHA25G = "01cf6f89964473c4f0383c66e52492e6affc96c6f741ac066bf8a298c1868daa"
const RAW_NEW25G = {
	"res://art/modules/luoyang_estate_components_20261021am/corridor.png":"a335bb05e3155a1933314525824b90eba098bbd878f1f85d1db60889a549388d",
	"res://art/modules/luoyang_assembled_interiors_20261016g/cloth_roll_rack_v1.png":"078b1086cd2003916e73bb9c9f7a5f98d52286eabd765c609cb928e9ea84fc0e",
	"res://art/modules/luoyang_assembled_interiors_20261016g/medicine_worktable_v1.png":"0e2cd37e803a79c1f51ae2b62f700664e841feef183f51c3ce0bc3355432b05d"
}
func precheck() -> bool:
	if not check(COURTYARD_OVERVIEW_READY,"ROOT_SINGLE45_AUTHORING_OVERVIEW_READY"):
		return false
	if not super.precheck():
		return false
	if not track(HEADER25G,HEADER_SHA25G) or not track(PROJECTION25G,PROJECTION_SHA25G):
		return false
	var header: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HEADER25G))
	var projection: Variant = bytes_to_var(FileAccess.get_file_as_bytes(PROJECTION25G))
	if not check(header.get("child_count")==45 and header.get("parent_count")==43 and header.artifacts["projection.bin"].path==PROJECTION25G and String(header.artifacts["projection.bin"].sha256).to_lower()==PROJECTION_SHA25G.to_lower(),"FIXED_ACTUAL43_TO45_PUBLICATION"):
		return false
	if not check(projection is Dictionary and projection.get("ok")==true and projection.get("render",[]).size()==45,"ONLY_ACTUAL45_ROWS_NO_GEOMETRY_REPLAY"):
		return false
	overview_rows=projection.render
	for path: String in RAW_NEW25G:
		if not track(path,RAW_NEW25G[path]):
			return false
	return true

func _texture(path: String) -> Texture2D:
	if not RAW_NEW25G.has(path):
		return super._texture(path)
	if textures.has(path):
		return textures[path]
	if not track(path,RAW_NEW25G[path]):
		return null
	var pixels: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if not check(pixels!=null and not pixels.is_empty(),"UNCHANGED_DONOR_PNG_DIRECT_PREVIEW_ONLY:"+path):
		return null
	var texture: Texture2D = ImageTexture.create_from_image(pixels)
	textures[path]=texture
	return texture

func _build_props() -> bool:
	view=SubViewport.new();view.name="MarketAuthoringHalfScaleOverview";view.size=Vector2i(1536,1024)
	view.disable_3d=true;view.world_2d=World2D.new();view.transparent_bg=false
	view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(view)
	world=Node2D.new();world.name="World3072x2048AtUniformHalfScale";world.scale=Vector2.ONE*.5;view.add_child(world)
	var floor_texture: Texture2D=_texture(FLOOR24E)
	if floor_texture==null: return false
	var floor_sprite:=Sprite2D.new();floor_sprite.name="OriginalUneditedFormalFloor";floor_sprite.texture=floor_texture;floor_sprite.centered=false;floor_sprite.scale=SIZE/Vector2(floor_texture.get_size());floor_sprite.z_index=-1000;world.add_child(floor_sprite)
	var layer:=Node2D.new();layer.name="SameFivePurposeGround";layer.z_index=-4;world.add_child(layer)
	var ground_textures: Dictionary={}
	for key: String in ["road_stone","court_stone","road_earth","road_gravel"]:
		var path: String=environment24e.assets[key].texture
		var texture: Texture2D=_texture(path)
		if texture==null: return false
		ground_textures[key]=texture
	native_scene=SceneScript.new();native_scene.scene_id=&"ch4_s3_luoyang_market"
	var helper: Script=load(PURPOSE24E) as Script
	# Authoring identity input ONLY: NOT a C/Field/district finite receipt.
	var author_binding: Dictionary={"ok":true,"ready":true,"author_path":use_spec.space_author.path,"author_sha256":use_spec.space_author.sha256}
	purpose_receipt24e=helper.append_to(layer,native_scene,ground_textures,author_binding,func() -> bool: return is_instance_valid(world) and Time.get_ticks_msec()<deadline)
	if not check(purpose_receipt24e.get("ok")==true and purpose_receipt24e.count==6 and purpose_receipt24e.get("clean_base")==true and purpose_receipt24e.get("five_purpose_count")==5,"One clean base + same5 shader unions under original world coordinates; authoring input not runtime lease"): return false
	var seen: Dictionary={}
	for data: Dictionary in overview_rows:
		var id: String=String(data.get("id",""))
		if not check(not id.is_empty() and not seen.has(id) and data.get("pos") is Vector2 and data.get("render_size_px") is Vector2,"Fixed actual45 entity identity/typed position/render size"): return false
		seen[id]=true
		var texture: Texture2D=_texture(String(data.texture))
		if texture==null: return false
		var sprite:=Sprite2D.new();sprite.name="SceneObject_"+id;sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered=bool(data.get("centered",true));sprite.position=data.pos*SIZE;sprite.scale=data.render_size_px/Vector2(texture.get_size());sprite.rotation_degrees=float(data.get("rotation",0.0));sprite.z_index=int(data.get("z_index",0))
		if data.get("modulate") is Color: sprite.modulate=data.modulate
		if data.get("sort_by_feet",false):
			if not check(data.has("depth_sort_foot_y"),"Original world sort foot retained "+id): return false
			sprite.z_index=clampi(int(floor(clampf(float(data.depth_sort_foot_y),0.0,1.0)*SIZE.y/8.0)),0,255)
		world.add_child(sprite)
		rendered.append({"id":id,"position":sprite.position,"render_size_px":data.render_size_px,"scale":sprite.scale,"z_index":sprite.z_index,"texture":String(data.texture)})
	return check(rendered.size()==45 and world.scale==Vector2.ONE*.5,"Exactly45 same projected entities; uniform .5 overview, no synthetic new building")


func _run() -> void:
	var began: int=Time.get_ticks_msec()
	deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before=saves()
	folder="res://build/luoyang_market_courtyard_links_20261025g_system01/overview01_output/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		complete=await _probe()
	if is_instance_valid(view):
		view.queue_free()
	await process_frame
	await process_frame
	world=null
	view=null
	textures.clear()
	native_scene=null
	overview_rows.clear()
	rendered.clear()
	finish(folder,began,complete,"25G_ONE45_COURTYARD_AUTHORING_OVERVIEW_NO_FIELD_OR_FORMAL_CREDIT")
