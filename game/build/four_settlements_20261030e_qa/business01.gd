extends SceneTree
func _initialize()->void:run.call_deferred()
func serial(v:Variant)->Variant:
	if v is Vector2 or v is Vector2i:return [v.x,v.y]
	if v is Dictionary:
		var d:Dictionary={}
		for k in v:d[String(k)]=serial(v[k])
		return d
	if v is Array:
		var a:Array=[]
		for x in v:a.append(serial(x))
		return a
	if v is Resource:return v.resource_path
	return v
func run()->void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var out:Dictionary={}
	for id in ["openworld_bailu_ferry","openworld_east_sea_port","linxi_tutorial","linxi_village_center","linxi_village_scrollmap","ch1_s2_qingfeng","ch2_s1_zhuwei_market"]:
		var s:Resource=load("res://data/scenes/"+id+".tres");var r:Dictionary={"npcs":s.npcs,"portals":s.map_layout.portals,"interactions":s.map_layout.interactions,"hotspots":s.hotspots,"exits":s.exits,"triggers":s.trigger_zones,"spawn":s.player_spawn,"on_enter":s.on_enter_dialog}
		out[id]=serial(r)
	var f:=FileAccess.open("res://build/four_settlements_20261030e_qa/business01.json",FileAccess.WRITE);f.store_string(JSON.stringify(out,"\t"));f.close();quit()
