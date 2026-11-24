extends RefCounted
## Independent in-memory texture/current-frame test of production hit subject.
## The owned Sprite is NOT Player/NPC; no actual facing/frame is forced.
const SUBJECT := preload("res://scripts/city/luoyang_v3_sprite_alpha.gd")
var tree: SceneTree
var check: Callable

func run(owner: SceneTree,checker: Callable,output: String) -> Dictionary:
	tree=owner
	check=checker
	var subject: RefCounted=SUBJECT.new()
	var original:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	original.fill(Color(0,0,0,0))
	# Each 8x8 cell has independently known head/shoe alpha and padding. The
	# full atlas has different colors, so wrong frame selection is observable.
	for y in 32:
		for x in 32:
			var local:=Vector2i(x%8,y%8)
			if local.x in [3,4] and local.y>=1 and local.y<=6:
				original.set_pixel(x,y,Color(float(x/8+1)/4,float(y/8+1)/4,.25,1))
	var texture: ImageTexture=ImageTexture.create_from_image(original)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(64,64)
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	viewport.msaa_2d=Viewport.MSAA_DISABLED
	tree.root.add_child(viewport)
	var sprite:=Sprite2D.new()
	sprite.texture=texture
	sprite.position=Vector2(32,32)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(sprite)
	var records: Array[Dictionary]=[]
	var gpu: bool=DisplayServer.get_name()!="headless"
	if gpu: check.call("--qa-gpu-approved" in OS.get_cmdline_user_args(),"synthetic render only under root GPU authorization")
	for region_enabled: bool in [false,true]:
		sprite.region_enabled=region_enabled
		sprite.region_rect=Rect2(8,8,16,16)
		sprite.hframes=2
		sprite.vframes=2
		for frame in 4:
			sprite.frame=frame
			for flip_h: bool in [false,true]:
				for flip_v: bool in [false,true]:
					sprite.flip_h=flip_h
					sprite.flip_v=flip_v
					var region:=Rect2i(8,8,16,16) if region_enabled else Rect2i(0,0,32,32)
					var cell:=Vector2i(region.size.x/2,region.size.y/2)
					var source_rect:=Rect2i(region.position+Vector2i(frame%2,frame/2)*cell,cell)
					var mismatches: int=0
					var positive: int=0
					var negative: int=0
					var rendered: Image
					if gpu:
						viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
						await RenderingServer.frame_post_draw
						rendered=viewport.get_texture().get_image()
						check.call(rendered!=null and rendered.get_size()==Vector2i(64,64),"actual current atlas/region render readback")
					for y in cell.y:
						for x in cell.x:
							var source: Vector2i=source_rect.position+Vector2i(x,y)
							var expected: bool=original.get_pixelv(source).a>.1
							var uv:=Vector2((x+.5)/cell.x,(y+.5)/cell.y)
							if flip_h: uv.x=1-uv.x
							if flip_v: uv.y=1-uv.y
							var viewport_point: Vector2=sprite.get_global_transform_with_canvas()*(sprite.get_rect().position+uv*sprite.get_rect().size)
							var actual: bool=subject.call("hits",sprite,viewport_point)
							if actual!=expected: mismatches+=1
							if expected: positive+=1
							else: negative+=1
							if rendered!=null:
								var pixel:=Vector2i(floori(viewport_point.x),floori(viewport_point.y))
								if (rendered.get_pixelv(pixel).a>.1)!=expected: mismatches+=1
					check.call(mismatches==0 and positive>0 and negative>0,"all current source head/shoe/padding texels exactly hit/render under actual frame/region/flips")
					var row: Dictionary={"hframes":2,"vframes":2,"frame":frame,"region_enabled":region_enabled,"region_rect":[8,8,16,16],"flip_h":flip_h,"flip_v":flip_v,"source_rect":[source_rect.position.x,source_rect.position.y,source_rect.size.x,source_rect.size.y],"positive_source_pixels":positive,"transparent_source_pixels":negative,"mismatches":mismatches,"actual_GPU_render":rendered!=null}
					if rendered!=null:
						var path: String=output+"synthetic_alpha_"+str(records.size())+".png"
						check.call(not FileAccess.file_exists(path) and rendered.save_png(path)==OK,"current synthetic render saved without overwrite")
						row["path"]=path
						row["sha256"]=FileAccess.get_sha256(path)
					records.append(row)
	var viewport_ref: WeakRef=weakref(viewport)
	var texture_ref: WeakRef=weakref(texture)
	sprite.texture=null
	texture=null
	original=null
	sprite=null
	viewport.queue_free()
	viewport=null
	subject=null
	for tick in 8: await tree.process_frame
	check.call(viewport_ref.get_ref()==null and texture_ref.get_ref()==null,"owned synthetic viewport/texture and hit cache naturally release")
	tree=null
	check=Callable()
	return {"scope":"OWNED_SYNTHETIC_CURRENT_FRAME_TEXTURE_AND_RENDER_NOT_GAMEPLAY_CREDIT","cases":records,"actual_gpu":gpu,"source_sha256":FileAccess.get_sha256("res://scripts/city/luoyang_v3_sprite_alpha.gd")}
