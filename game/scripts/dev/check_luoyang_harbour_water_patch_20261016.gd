extends SceneTree
## ROOT-only bounded CPU proof. No resource imports, PNG outputs or gameplay.
const W=preload("res://scripts/city/luoyang_harbour_water_patch_20261016.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var started: int=Time.get_ticks_msec()
	var packet: Dictionary=W.prepare_packet(Callable(),false)
	var result: Dictionary={"passed":false,"packet_nonempty":not packet.is_empty(),"helper_sha256":FileAccess.get_sha256(W.SELF),"source_sha256":W.SOURCES,"no_png_or_import_written":true}
	if not packet.is_empty():
		var whole:=Image.load_from_file(W.OFF)
		whole.convert(Image.FORMAT_RGBA8); whole.resize(3072,2048,Image.INTERPOLATE_LANCZOS)
		var full_core: PackedByteArray=whole.get_region(W.CORE).get_data()
		var floor_image:=Image.load_from_file(W.FLOOR)
		floor_image.convert(Image.FORMAT_RGBA8)
		var patch:=Image.create_from_data(200,280,false,Image.FORMAT_RGBA8,packet.bytes)
		var border_changed: int=0
		var border_samples: int=0
		for y: int in range(280):
			for x: int in range(200):
				if x>=4 and x<196 and y>=4 and y<276: continue
				border_samples+=1
				if patch.get_pixel(x,y)!=floor_image.get_pixel(2500+x,1292+y): border_changed+=1
		result.merge({"rgba_sha256":packet.rgba_sha256,"local_equals_full_lanczos_core":packet.bytes==full_core,"border_changed":border_changed,"border_samples":border_samples,"size":[200,280],"world_roi":[2500,1292,200,280],"raw_halo":[4984,2568,432,592],"bytes":packet.bytes.size()})
		result.passed=packet.bytes==full_core and border_changed==0 and packet.bytes.size()==224000
	result["elapsed_ms"]=Time.get_ticks_msec()-started
	var directory: String="res://build/luoyang_harbour_life_20261016_system01"
	var path: String=directory+"/water_patch_cpu_"+str(OS.get_process_id())+"_"+str(Time.get_ticks_msec())+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(result,"\t",true,true)); file.close()
	print(JSON.stringify({"result":path,"passed":result.passed,"rgba_sha256":result.get("rgba_sha256","")}))
	quit(0 if result.passed else 1)
