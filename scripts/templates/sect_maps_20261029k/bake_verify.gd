extends SceneTree
var checks: Array=[]
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"label":label})
	if not ok:print("FAIL ",label)
func own_branch(node: Node,scene: Node) -> void:
	node.owner=scene
	for child: Node in node.get_children():own_branch(child,scene)
func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-k/"+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var dir:=DirAccess.open("res://art/modules/sect_maps_20261029k")
	for file: String in dir.get_files():
		if not file.ends_with(".png"):continue
		var path: String="res://art/modules/sect_maps_20261029k/"+file
		var native:=Image.load_from_file(path);native.convert(Image.FORMAT_RGBA8)
		var texture: Texture2D=load(path);var imported:=texture.get_image();imported.convert(Image.FORMAT_RGBA8)
		check(native.get_size()==imported.get_size() and native.get_data()==imported.get_data(),"imported RGBA exact "+file)
	for key: String in ["wudang","mingwu"]:
		var path: String="res://scenes/drafts/sect_maps_20261029k/"+key+".tscn"
		var town: Node2D=load(path).instantiate();root.add_child(town);town.controls_enabled=false
		var count: int=town.terrain.get_child_count()
		var hall: Node2D=town.get_node("Town/MainHall" if key=="wudang" else "Town/ManorHall")
		var visual_y: float=hall.get_node("Art").position.y
		own_branch(town.terrain,town);town.set_meta("terrain_baked",true)
		var packed:=PackedScene.new();check(packed.pack(town)==OK and ResourceSaver.save(packed,path)==OK,key+" saved native scene")
		town.queue_free();await process_frame;await process_frame
		var reloaded: PackedScene=ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE)
		town=reloaded.instantiate();root.add_child(town);await process_frame;await physics_frame
		check(town.terrain.get_child_count()==count,key+" geometry not duplicated after reload")
		hall=town.get_node("Town/MainHall" if key=="wudang" else "Town/ManorHall")
		check(absf(hall.get_node("Art").position.y-visual_y)<.001,key+" visual height not applied twice")
		check(town.terrain.actor_level==0 and town.actor.collision_mask==24,key+" reload actor floor correct")
		town.view_mode=0;town.update_view();await shot(key+"_overview_final")
		town.view_mode=1;town.actor.position=Vector2(2700,1190) if key=="wudang" else Vector2(4080,1350);town.terrain.reset_actor(2);town.update_view();await shot(key+"_hall_final")
		town.queue_free();await process_frame;await process_frame
	var failures:=0
	for row: Dictionary in checks:
		if not row.pass:failures+=1
	var f:=FileAccess.open("res://artifacts-k/baked03.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));f.close()
	print("BAKED ",checks.size()," FAILURES ",failures);quit(0 if failures==0 else 1)
