extends RefCounted
## Non-walkable complete mountain backdrop and whole-source rock variation.
const BACKDROP=preload("res://build/environment_residual_20261031d_system01/mountain_backdrop.gd")
static var mountain_texture: Texture2D

static func install(town: Node2D,source: String,expected_sha: String,size: Vector2i) -> Dictionary:
	if source.is_empty() or expected_sha.length()!=64:return {"ready":false,"reason":"UNFROZEN_NATIVE_BACKGROUND"}
	if FileAccess.get_sha256(source)!=expected_sha:return {"ready":false,"reason":"BACKGROUND_SOURCE_CHANGED"}
	if mountain_texture==null:
		var image:=Image.load_from_file(source)
		if image==null or image.is_empty() or image.get_size()!=size:return {"ready":false,"reason":"BACKGROUND_NATIVE_SIZE"}
		mountain_texture=ImageTexture.create_from_image(image)
	var layer:=CanvasLayer.new();layer.name="HuashanFarMountains31d";layer.layer=-10;town.add_child(layer)
	var art:=Sprite2D.new();art.set_script(BACKDROP);art.name="WholeNativeMountainBackdrop";art.texture=mountain_texture;art.centered=true;layer.add_child(art)
	var mirrored: Array[String]=[]
	for id: String in ["CliffNative1","CliffNative3"]:
		var cliff:=town.get_node_or_null("Terrain/NativeSectRepair31c/"+id) as Sprite2D
		if cliff==null:continue
		# Whole 1536px source mirrors around its x=768 registration column.
		# No vertex/position/scale/z/physics/stair-slot changes, no PNG processing.
		cliff.flip_h=true;mirrored.append(id)
	var fact: Dictionary={"ready":true,"source":source,"source_sha256":expected_sha,"source_size":size,"complete_image_uniform_cover":true,"canvas_layer":-10,"static_nonwalkable_background":true,"mirrored_whole_cliffs":mirrored,"physical_nodes_created":0,"old_floor_and_collision_untouched":true}
	town.set_meta("environment_refinement31d",fact)
	return fact
