extends RefCounted
## Pure native visual constructor. It never grants a Family or Field lease.
const AUTHOR="res://build/luoyang_garden_river_20261025h_source01/author_river_bridge03_NOTREADY.json"
const AUTHOR_SHA="06d873797e954a4f7b874a85b421a1b1dda87b2072170d7749eeaaf3ddc77cb6"
const SHADER="res://build/luoyang_garden_river_20261025h_source01/river_shore_native16.gdshader"
const B="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const SHORE="res://art/modules/ground/road_stone_grass_edge.png"
const SHORE_SHA="527d8babc86461c7f37c49bbed9f6d7c348df827b483bfedd1f1e1b8117cacd3"
const ID=&"luoyang_riverside_garden_20261022ap"
const SIZE=Vector2(3072,2048)
static func fail(error: String) -> Dictionary: return {"ok":false,"error":error,"bodies":[]}
static func source_paths() -> Array[String]: return [AUTHOR,SHADER]
static func make_water_visual(scene: SceneScript,entries: Array) -> Dictionary:
	if scene==null or scene.scene_id!=ID or scene.map_layout==null or FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA or scene.get_meta("luoyang_full_city_AP","")!=AUTHOR_SHA: return fail("RIVER_EXACT_NEW_NATIVE_AUTHOR")
	var bundle: Variant=load(B)
	if not bundle.equal(entries,scene.map_layout.blockers): return fail("RIVER_WHOLE_NATIVE_BLOCKERS")
	var author: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	var raw: Variant=scene.get_meta("ap_garden_river25h",null)
	if not author is Dictionary or not raw is Dictionary or raw.size()!=15 or not raw.get("polygon") is PackedVector2Array or raw.polygon.size()!=16 or not raw.get("physics_pieces") is Array or raw.physics_pieces.size()!=2 or not raw.get("deck") is Rect2 or raw.get("whole_bridge_below_actors")!=true or raw.get("physics_is_visual_water_minus_visible_deck")!=true: return fail("RIVER_NATIVE_METADATA")
	for i: int in range(16):
		var point: Array=author.scenes[0].water_polygons[0][i]
		if raw.polygon[i]!=Vector2(float(point[0]),float(point[1])): return fail("RIVER_EXACT_SOURCE_POLYGON")
	var count: int=0
	for row: Dictionary in entries:
		if String(row.id).begins_with("garden_river_minus_deck_"):
			if count>=2 or not bundle.equal(row.get("ground_polygon_world"),raw.physics_pieces[count]): return fail("RIVER_PHYSICS_MATCHES_NATIVE_DECK_SUBTRACTION")
			count+=1
	if count!=2 or raw.deck.size.y-24.0<128.0: return fail("RIVER_TWO_CLOSED_PIECES_AND_VISIBLE_BODY_DECK")
	var front: AtlasTexture=load(raw.front_texture) as AtlasTexture
	if front==null or front.atlas==null or front.atlas.resource_path!=raw.front_source or front.region!=raw.front_region or front.margin!=Rect2() or not front.filter_clip: return fail("RIVER_NATIVE_FRONT_ORIGINAL_UV")
	if raw.texture!="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/deepwater.res" or raw.texture_size!=Vector2i(200,280) or raw.uniform_texture_scale!=1.0 or raw.z_index!=-18 or raw.rgba_sha256!="dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e": return fail("RIVER_UNCHANGED_DOCKS_WATER_RESOURCE")
	var texture: Texture2D=load(raw.texture) as Texture2D
	if texture==null or texture.get_size()!=Vector2(200,280): return fail("RIVER_WATER_TEXTURE_SIZE")
	var image: Image=texture.get_image()
	if image==null: return fail("RIVER_WATER_IMAGE")
	image.convert(Image.FORMAT_RGBA8)
	if bundle.bytes_sha(image.get_data())!=raw.rgba_sha256: return fail("RIVER_WHOLE_WATER_RGBA")
	var water: Polygon2D=Polygon2D.new();water.name="APGardenSameCaptureRiver25h"
	water.polygon=raw.polygon.duplicate();water.uv=raw.polygon.duplicate();water.texture=texture
	water.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;water.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;water.z_index=-18
	var shore: Dictionary=make_shore(water,raw.polygon)
	if shore.get("ok")!=true: water.free();return shore
	water.set_meta("garden_river_visual_receipt",{"full_visual_water_beneath_bridge":true,"same_native_water_minus_deck_physics_and_mask":true,"two_closed_physics_pieces":2,"deck":raw.deck,"front_native_Atlas_region":raw.front_region,"whole_bridge_below_actors":true,"no_image_edit":true,"shore_tiles":shore.count})
	return {"ok":true,"node":water,"river_visual_polygons":1,"river_physical_water_pieces":2,"real_bridge_deck":raw.deck}
static func make_shore(water: Polygon2D,polygon: PackedVector2Array) -> Dictionary:
	if water==null or polygon.size()!=16 or FileAccess.get_sha256(SHORE)!=SHORE_SHA: return fail("RIVER_EXISTING_SHORE_SOURCE")
	var texture: Texture2D=load(SHORE) as Texture2D
	var shader: Shader=load(SHADER) as Shader
	if texture==null or texture.get_size()!=Vector2(317,109) or shader==null: return fail("RIVER_SHORE_TEXTURE_OR_FRAGMENT_SHADER")
	var material: ShaderMaterial=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("native_water_polygon",polygon.duplicate())
	var group: Node2D=Node2D.new();group.name="GardenRiver16ShoreEdges"
	var count: int=0
	for i: int in range(polygon.size()):
		var from: Vector2=polygon[i];var to: Vector2=polygon[(i+1)%polygon.size()]
		var edge: Vector2=to-from;var length: float=edge.length()
		if length<=0: group.free();return fail("RIVER_ZERO_SHORE_EDGE")
		var pieces: int=maxi(1,ceili(length/158.5))
		var scale: float=(length/float(pieces)+2.0)/317.0
		for n: int in range(pieces):
			var sprite: Sprite2D=Sprite2D.new();sprite.name="RiverShore_%02d_%02d"%[i,n]
			sprite.texture=texture;sprite.centered=false;sprite.offset=Vector2(-158.5,-75)
			sprite.position=from.lerp(to,(float(n)+.5)/float(pieces));sprite.rotation=edge.angle();sprite.scale=Vector2.ONE*scale
			sprite.material=material;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.z_index=0
			group.add_child(sprite);count+=1
	water.add_child(group)
	return {"ok":true,"count":count,"exact_source_edges":16,"no_support_or_collision_from_shore":true}
