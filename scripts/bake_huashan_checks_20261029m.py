from huashan_map_20261029m import *
old=json.loads((STAGE/'layout-before-visual02.json').read_text('utf-8'));new=json.loads((PROJECT/ART/'huashan.json').read_text('utf-8'))
assert old['terrain']==new['terrain'] and old['blockers']==new['blockers'] and old['roads']==new['roads'] and old['spawn']==new['spawn']
save(STAGE/'visual02-physical-inheritance.json',{'terrain_exact':True,'blockers_exact':True,'roads_exact':True,'spawn_exact':True,'removed_objects_only': [r['name'] for r in old['objects'] if r['name'] not in {x['name'] for x in new['objects']}],'previous_36_checks_inherited':True})
src='''extends SceneTree
var checks: Array=[]
func check(ok: bool,label: String) -> void:
\tchecks.append({"pass":ok,"label":label})
\tif not ok:print("FAIL ",label)
func own_branch(node: Node,scene: Node) -> void:
\tnode.owner=scene
\tfor child: Node in node.get_children():own_branch(child,scene)
func shot(name: String) -> void:
\tawait process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://artifacts-m/"+name+".png")
func key(code: Key,pressed: bool) -> void:
\tvar e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
\tvar path: String="res://scenes/drafts/huashan_map_20261029m/huashan.tscn"
\tvar town: Node2D=load(path).instantiate();root.add_child(town);await physics_frame;town.controls_enabled=false
\tvar count: int=town.terrain.get_child_count();var hall_y: float=town.get_node("Town/MainHall/Art").position.y
\tcheck(town.terrain.find_children("RidgeFace*","Polygon2D",true,false).size()>20,"continuous native granite perimeter faces")
\tcheck(town.terrain.find_children("RidgeEdge*","StaticBody2D",true,false).size()==25,"physical ridge boundary retained")
\town_branch(town.terrain,town);town.set_meta("terrain_baked",true)
\tvar packed:=PackedScene.new();check(packed.pack(town)==OK and ResourceSaver.save(packed,path)==OK,"saved native scene")
\ttown.queue_free();await process_frame;await process_frame
\tvar reload: PackedScene=ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE)
\ttown=reload.instantiate();root.add_child(town);await physics_frame
\tcheck(town.terrain.get_child_count()==count,"saved terrain not duplicated")
\tcheck(absf(town.get_node("Town/MainHall/Art").position.y-hall_y)<.001,"saved visual height not doubled")
\tcheck(town.terrain.actor_level==0 and town.actor.collision_mask==24,"saved protagonist ground layer")
\ttown.view_mode=0;town.update_view();await shot("overview_final")
\ttown.view_mode=1;town.actor.position=Vector2(2770,1270);town.terrain.reset_actor(2);town.update_view();await shot("hall_final")
\ttown.actor.position=Vector2(1480,2410);town.terrain.reset_actor(1);town.update_view();await shot("domestic_final")
\ttown.actor.position=Vector2(4850,1910);town.terrain.reset_actor(1);town.update_view();await shot("debate_final")
\ttown.actor.position=Vector2(2770,4210);town.terrain.reset_actor(0);town.update_view();await shot("gate_final")
\ttown.actor.position=Vector2(2700,3039);town.terrain.reset_actor(0);town.controls_enabled=true
\tawait key(KEY_W,true)
\tfor i in range(115):await physics_frame
\tawait key(KEY_W,false)
\tcheck(town.terrain.actor_level==1,"saved main stair actual ascent")
\tawait key(KEY_S,true)
\tfor i in range(115):await physics_frame
\tawait key(KEY_S,false)
\tcheck(town.terrain.actor_level==0,"saved main stair actual descent")
\tvar fails:=0
\tfor row: Dictionary in checks:
\t\tif not row.pass:fails+=1
\tvar f:=FileAccess.open("res://artifacts-m/baked02.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":fails,"input_ticks":230},"\\t"));f.close()
\tprint("BAKED ",checks.size()," FAILURES ",fails)
\ttown.queue_free();await process_frame;await process_frame;quit(0 if fails==0 else 1)
'''
(PROJECT/'bake_huashan.gd').write_text(src,'utf-8')
