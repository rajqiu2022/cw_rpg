extends SceneTree
## Current production sampling unit only. Not a normal Field/visual approval.
const C = preload("res://scripts/world/world_map_v15_contract.gd")
const ROOT := "res://art/maps/world_map_v15_complete_v6/chunks/"
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)

func _expected(point: Vector2, image: Image, cell: Vector2i) -> bool:
	if not point.is_finite() or point.x<0 or point.y<0 or point.x>=C.SIZE.x or point.y>=C.SIZE.y: return false
	var pixel := Vector2i(roundi(point.x),roundi(point.y))
	if pixel.x<0 or pixel.y<0 or pixel.x>=C.SIZE.x or pixel.y>=C.SIZE.y: return false
	if Vector2i(pixel.x/C.TILE_SIZE.x,pixel.y/C.TILE_SIZE.y)!=cell: return false
	var color := image.get_pixelv(pixel-cell*C.TILE_SIZE)
	return color.a>=.5 and maxf(color.r,maxf(color.g,color.b))>=.5

func _run() -> void:
	if "--current-world-direct-sampler-unit" not in OS.get_cmdline_user_args(): quit(2); return
	var layout := WalkableMapLayout.new()
	layout.schema_version=15
	layout.design_size=Vector2i(C.SIZE)
	for row in 8:
		for col in 8:
			var path := ROOT+"r%d_c%d_walk.png"%[row,col]
			_check(FileAccess.file_exists(path),"actual current raw tile exists "+path)
			layout.walkable_mask_tiles.append({"path":path,"logical_rect":Rect2(Vector2(Vector2i(col,row)*C.TILE_SIZE),Vector2(C.TILE_SIZE))})
	if failures>0: quit(1); return
	var scene := SceneScript.new()
	scene.map_layout=layout
	C._prepare(scene)
	for row in 8:
		for col in 8:
			var cell := Vector2i(col,row)
			var path := ROOT+"r%d_c%d_walk.png"%[row,col]
			var image := Image.load_from_file(path)
			_check(image!=null and image.get_size()==C.TILE_SIZE,"actual raw canvas "+path)
			if image==null or image.get_size()!=C.TILE_SIZE: continue
			for local: Vector2 in [Vector2(.51,16),Vector2(975.49,16),Vector2(975.51,16),Vector2(1535.49,512),Vector2(768,512),Vector2(16,1023.49)]:
				var point := Vector2(cell*C.TILE_SIZE)+local
				_check(C._pixel_clear(point)==_expected(point,image,cell),"current production sampler matches independent global rounded raw pixel "+str(point))
	# Literal domain and rounded domain are both checked, never edge-clamped.
	for point: Vector2 in [Vector2(-.01,8),Vector2(8,-.01),Vector2(C.SIZE.x-.01,8),Vector2(8,C.SIZE.y-.01),Vector2(INF,8),Vector2(8,NAN)]:
		_check(not C._pixel_clear(point),"invalid/rounded-outside pixel denied "+str(point))
	print("WORLD_DIRECT_SAMPLER_UNIT_NOT_FIELD: %d checks / %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
