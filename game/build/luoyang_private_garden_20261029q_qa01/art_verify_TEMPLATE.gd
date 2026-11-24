extends SceneTree
const FILE := "res://art/modules/luoyang_estate_garden_20261029q/lotus_pond_v1.png"
const PNG_SHA := "__PNG_SHA__"
const RGBA_SHA := "__RGBA_SHA__"
const SIZE := Vector2i(__WIDTH__,__HEIGHT__)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	if FileAccess.get_sha256(FILE)!=PNG_SHA:push_error("ART_IMPORT_SOURCE_CHANGED");quit(1);return
	var texture: Texture2D=load(FILE)
	if texture==null:push_error("ART_IMPORT_TEXTURE_NULL");quit(1);return
	var image: Image=texture.get_image()
	if image==null or image.get_size()!=SIZE or image.has_mipmaps():push_error("ART_IMPORT_DIMENSIONS_OR_MIPS");quit(1);return
	image.convert(Image.FORMAT_RGBA8)
	var source: Image=Image.load_from_file(FILE)
	if source==null or source.get_size()!=SIZE:push_error("ART_IMPORT_SOURCE_DIMENSIONS");quit(1);return
	source.convert(Image.FORMAT_RGBA8)
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(image.get_data())
	var actual:=h.finish().hex_encode()
	if actual!=RGBA_SHA or image.get_data()!=source.get_data():push_error("ART_IMPORT_RGBA_NOT_EXACT");quit(1);return
	print("ART_IMPORT_LOSSLESS_RGBA ",actual," size=",SIZE.x,"x",SIZE.y," old_art_changes=0")
	quit(0)


