extends SceneTree
## Prepared for ROOT execution only. Pure index/native Texture/Node lifetime
## checks, not actual Field/physics/loading-time/GPU publication.
const STREAM = preload("res://build/r_world01/candidate/scripts/world/world_v15_visible_stream_20261018r.gd")
const OVERLAP = preload("res://build/r_world01/candidate/scripts/world/world_v15_stream_overlap_20261018r.gd")
var checks:=0
var failures: Array[String]=[]

class Actor:
	extends Node2D
	func get_depth_sort_y() -> float: return global_position.y

func check(label: String, ok: bool) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene:=load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	check("formal world",scene!=null and STREAM.applies(scene))
	if scene==null: quit(1); return
	var objects: Array=scene.map_layout.visual_objects
	var index: Dictionary=STREAM.make_index(objects,Vector2(12288,8192))
	check("index valid",index.ok)
	check("all2687",index.entries.size()==2687)
	check("original2682depth",index.depth_count==2682)
	var polys:=0
	var rects:=0
	for data: Dictionary in objects:
		if data.has("solid_polygons_px"): polys+=1
		if data.has("collision_size"): rects+=1
	check("poly104",polys==104)
	check("rect2218",rects==2218)
	check("portals16",scene.map_layout.portals.size()==16)
	check("nav64",scene.map_layout.walkable_mask_tiles.size()==64)
	var selected: Dictionary=STREAM.initial_selection(scene,scene.player_spawn,Vector2(1920,1080))
	check("initial202",selected.ok and int(selected.selected)==202 and selected.paths.size()==202)
	var rng:=RandomNumberGenerator.new()
	rng.seed=20261018
	for n in range(50):
		var center:=Vector2(rng.randf_range(0,12288),rng.randf_range(0,8192))
		var rect:=STREAM.view_rect(center,Vector2(1920,1080),1.25,Vector2(12288,8192)).grow(STREAM.PREFETCH)
		var expected: Array[int]=[]
		for ordinal in range(index.entries.size()):
			if index.entries[ordinal].bounds.intersects(rect,true): expected.append(ordinal)
		check("native_index_bruteforce_%d"%n,STREAM.query(index,rect)==expected)
	# A tall rotated roof with its foot outside the view must still be selected.
	var fixture: Dictionary={"id":"roof","texture":"res://fixture.png","pos":Vector2(.5,.5),"render_size_px":Vector2(200,900),"centered":false,"rotation":37.0}
	var bounds: Rect2=STREAM.render_bounds(fixture,Vector2(1000,1000))
	check("rotated extent",bounds.size.x>600 and bounds.size.y>700)
	var invalid: Dictionary=fixture.duplicate(true)
	invalid.interaction_action="dialog:unsupported"
	check("no silent interaction loss",not STREAM.make_index([invalid],Vector2(1000,1000)).ok)
	for key: String in ["require_quest_active","require_quest_completed"]:
		var gated: Dictionary=fixture.duplicate(true)
		gated[key]="fixture_quest"
		check("no silent quest loss:"+key,not STREAM.make_index([gated],Vector2(1000,1000)).ok)
	var world:=Node2D.new()
	root.add_child(world)
	var fade: RefCounted=OVERLAP.new()
	fade.call("configure_stream",world,2682)
	var image:=Image.create(8,8,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture:=ImageTexture.create_from_image(image)
	var a:=Sprite2D.new()
	a.texture=texture; a.position=Vector2(20,40); world.add_child(a)
	check("A registered",fade.call("add_stream_prop",a,"A",40.0,10))
	var actor:=Actor.new()
	actor.position=Vector2(20,40); world.add_child(actor)
	fade.call("add_actor",actor)
	var b:=Sprite2D.new()
	b.texture=texture; b.position=Vector2(20,40); world.add_child(b)
	check("B late registered",fade.call("add_stream_prop",b,"B",40.0,2))
	fade.call("_refresh_depth_order")
	check("exact source tie",b.get_index()<a.get_index() and a.get_index()<actor.get_index())
	fade.call("remove_stream_prop",b)
	world.remove_child(b); b.free()
	check("shared image retained",(fade.get("_images") as Dictionary).size()==1)
	fade.call("remove_stream_prop",a)
	world.remove_child(a); a.free()
	check("zero stale prop image",(fade.get("_images") as Dictionary).is_empty() and (fade.get("_props") as Array).is_empty())
	check("actor source ordinal unchanged",int((fade.get("_depth_entries") as Array)[0].ordinal)==2682)
	fade.call("release_stream")
	world.free()
	print(JSON.stringify({"scope":"NATIVE_INDEX_OVERLAP_ONLY_NOT_FIELD_GPU","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
