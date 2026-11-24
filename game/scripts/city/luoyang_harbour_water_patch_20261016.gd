extends RefCounted
## Same-capture shadow-OFF water only. CPU decode stays in the existing owned worker.
const META="city_harbour_water_patch_20261016"
const CORE=Rect2i(2500,1292,200,280)
const RAW_HALO=Rect2i(4984,2568,432,592)
const SIZE=Vector2i(200,280)
const RGBA_SHA="dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e"
const SELF="res://scripts/city/luoyang_harbour_water_patch_20261016.gd"
const OFF="res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/ground_off_raw.png"
const ON="res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/ground_on_raw.png"
const FLOOR="res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
const CAPTURE="res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/ground_capture.json"
const SOURCES={OFF:"c76fce63dfcfeb463520a01939024445fae024b4a35f127371771b80f0bfd880",ON:"4fe1d5ff80cec55859c1b1db2b1055eeb022536b9534be0d3637e00a90b4f1bd",FLOOR:"494c52dac3edc4d82c8a1cb02691b80c8175e5b25ef351866e3733ff5471aba1",CAPTURE:"aa2aba7052cb289511eb83d68e6135d96e4001c2950763bb9309e2cdbac2e744"}
static func source_paths() -> Dictionary:
	var paths: Dictionary={SELF:true}
	for path: String in SOURCES: paths[path]=true
	return paths
static func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()
static func prepare_packet(cancel: Callable=Callable(),require_pin: bool=true) -> Dictionary:
	for path: String in SOURCES:
		if (cancel.is_valid() and cancel.call()) or FileAccess.get_sha256(path)!=SOURCES[path]: return {}
	var image:=Image.load_from_file(OFF)
	if image==null or image.get_size()!=Vector2i(6144,4096): return {}
	image.convert(Image.FORMAT_RGBA8)
	if cancel.is_valid() and cancel.call(): return {}
	var halo:=image.get_region(RAW_HALO)
	image=null
	halo.resize(216,296,Image.INTERPOLATE_LANCZOS)
	var bytes: PackedByteArray=halo.get_region(Rect2i(8,8,200,280)).get_data()
	if cancel.is_valid() and cancel.call(): return {}
	var packet: Dictionary={"bytes":bytes,"size":SIZE,"roi":CORE,"off_sha256":SOURCES[OFF],"rgba_sha256":sha(bytes)}
	return packet if (not require_pin or packet_valid(packet)) else {}
static func packet_valid(packet: Variant) -> bool:
	if not packet is Dictionary or packet.size()!=5 or not packet.get("bytes") is PackedByteArray: return false
	return RGBA_SHA.length()==64 and packet.get("size")==SIZE and packet.get("roi")==CORE and packet.get("off_sha256")==SOURCES[OFF] and packet.bytes.size()==224000 and packet.get("rgba_sha256")==RGBA_SHA and sha(packet.bytes)==RGBA_SHA
static func install(parent: Node2D,scene: SceneScript,world_size: Vector2) -> Sprite2D:
	if parent==null or scene==null or scene.scene_id!=&"ch4_s2_canal_docks" or world_size!=Vector2(3072,2048): return null
	var packet: Variant=scene.get_meta(META,null)
	if not packet_valid(packet): return null
	var image:=Image.create_from_data(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8,packet.bytes)
	var sprite:=Sprite2D.new()
	sprite.name="HarbourSameCaptureWaterPatch"
	sprite.texture=ImageTexture.create_from_image(image)
	sprite.centered=false; sprite.position=Vector2(CORE.position); sprite.z_index=-999
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(sprite)
	if scene.has_meta("luoyang_docks_workyard_20261019ac"):
		var shore: Dictionary=load("res://scripts/city/luoyang_docks_shore_20261020ae.gd").install(sprite,scene,world_size)
		if shore.get("ok")!=true: sprite.free(); push_error("[HarbourWater] "+String(shore.get("error","AE_INSTALL_REFUSED"))); return null
	return sprite
