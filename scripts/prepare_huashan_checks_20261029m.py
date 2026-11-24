from huashan_map_20261029m import *
import re,hashlib
# The initial build precedes explicit imports. These descriptors are new private files only.
for target in (PROJECT/ART).glob('*.png'):
    template=(ROOT/'game/art/modules/sect_maps_20261029k/wudang_hall.png.import').read_text('utf-8')
    rel='res://'+ART+'/'+target.name;cache=target.name+'-'+hashlib.md5(rel.encode()).hexdigest()+'.ctex'
    template=re.sub(r'uid="[^"]+"\n','',template).replace('res://art/modules/sect_maps_20261029k/wudang_hall.png',rel).replace('wudang_hall.png-eaf1a97e8ff5fcf5c60c2264aff64c20.ctex',cache)
    Path(str(target)+'.import').write_text(template,'utf-8')
src=(ROOT/'scripts/templates/sect_maps_20261029k/verify_routes.gd').read_text('utf-8')
src=src[:src.index('func run()')].replace('artifacts-k/','artifacts-m/')
src+='''func own_branch(node: Node,scene: Node) -> void:
\tnode.owner=scene
\tfor child: Node in node.get_children():own_branch(child,scene)
func place(p: Vector2,level: int) -> void:
\ttown.actor.position=p;town.terrain.reset_actor(level);town.update_view();await ticks(2)
func run() -> void:
\ttown=load("res://scenes/drafts/huashan_map_20261029m/huashan.tscn").instantiate();root.add_child(town);await ticks(4)
\tcheck(town.actor.get_script().resource_path.ends_with("preview_player.gd"),"canonical protagonist")
\tcheck(empty_at(town.actor.position,0),"spawn clear")
\tmake_graph()
\ttown.view_mode=0;town.update_view();await shot("overview01");town.view_mode=1
\tcheck(await stairs("MainRise",true),"continuous spawn-gate-court")
\tawait shot("court01")
\tcheck(await stairs("HallRise",true),"continuous court-hall stair")
\tcheck(await walk_to(Vector2(2770,1270),2),"continuous arrival main hall")
\tawait shot("hall01")
\tcheck(await stairs("HallSideRise",false),"east hall side descent")
\tcheck(await walk_to(Vector2(4850,1910),1),"east discussion platform reachable")
\tawait shot("debate01")
\tcheck(await stairs("CliffRise",false),"east reflection stair descent")
\tcheck(await walk_to(Vector2(4630,3450),0),"reflection ledge reachable")
\tawait shot("reflection01")
\tcheck(await stairs("WestRise",true),"west service return ascent")
\tcheck(await walk_to(Vector2(1480,2410),1),"domestic courtyard reachable")
\tawait shot("domestic01")
\tcheck(await stairs("MainRise",false),"continuous return down main stair")
\tcheck(await walk_to(Vector2(town.layout.spawn[0],town.layout.spawn[1]),0),"continuous return spawn")
\tfor r: Dictionary in town.terrain.ramps:
\t\tvar top:=Vector2(r.top[0],r.top[1]);var bottom:=Vector2(r.bottom[0],r.bottom[1])
\t\tcheck(empty_at(top-Vector2(0,55),int(r.high)) and empty_at(bottom+Vector2(0,55),int(r.low)),r.id+" both landings clear")
\t\tawait place((top+bottom)*.5,int(r.low));town.terrain.active_ramp=town.terrain.ramps.find(r);town.terrain.apply_actor_mask();town.terrain.after_move();town.update_view()
\t\tif r.id=="MainRise":await shot("stair_mid01")
\t\tawait key(KEY_D,true);await ticks(55);await key(KEY_D,false)
\t\tcheck(town.actor.position.x<top.x+float(town.terrain.data.portal_half_width),r.id+" side wall blocks")
\tawait place(Vector2(2200,2870),0);await key(KEY_W,true);await ticks(35);await key(KEY_W,false)
\tcheck(town.actor.position.y>2800,"cliff cannot bypass stairs")
\tawait place(Vector2(2780,4420),0)
\tawait key(KEY_TAB,true);await key(KEY_TAB,false);check(town.view_mode==0,"Tab overview")
\tawait key(KEY_TAB,true);await key(KEY_TAB,false);check(town.view_mode==1,"Tab follow")
\tawait key(KEY_SPACE,true);await key(KEY_SPACE,false);check(town.show_details,"Space details")
\tawait key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false);check(not town.show_details,"Esc details closes")
\tvar dir:=DirAccess.open("res://art/modules/huashan_map_20261029m")
\tfor file: String in dir.get_files():
\t\tif not file.ends_with(".png"):continue
\t\tvar path: String="res://art/modules/huashan_map_20261029m/"+file
\t\tvar native:=Image.load_from_file(path);native.convert(Image.FORMAT_RGBA8)
\t\tvar texture: Texture2D=load(path);var imported:=texture.get_image();imported.convert(Image.FORMAT_RGBA8)
\t\tcheck(native.get_size()==imported.get_size() and native.get_data()==imported.get_data(),"import RGBA exact "+file)
\tvar failures:=0
\tfor row: Dictionary in checks:
\t\tif not row.pass:failures+=1
\tvar f:=FileAccess.open("res://artifacts-m/verify01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"input_ticks":input_ticks,"traces":traces},"\\t"));f.close()
\tprint("HUASHAN ",checks.size()," FAILURES ",failures," INPUT ",input_ticks)
\ttown.queue_free();await process_frame;await process_frame;quit(0 if failures==0 else 1)
'''
(PROJECT/'verify_huashan.gd').write_text(src,'utf-8')
