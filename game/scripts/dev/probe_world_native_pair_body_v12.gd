extends "res://scripts/dev/build_world_map_native_pair_ortho_v12.gd"

# Synthetic runtime API gate only: no viewport, model preparation, capture or
# inherited initialize/build/save hooks. Calls the actual production helper.
func _initialize() -> void:
	call_deferred("_body_preflight")


func _body_preflight() -> void:
	var local := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	local.fill_rect(Rect2i(900,600,80,90),Color.WHITE)
	var blended := local.duplicate() as Image
	blended.fill_rect(Rect2i(900,600,80,90),Color(1,1,1,0.4))
	var opaque := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	opaque.fill(Color.WHITE)
	var empty := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var nonlocal := empty.duplicate() as Image
	nonlocal.set_pixel(1,1,Color.WHITE)
	nonlocal.set_pixel(SIZE.x-1,SIZE.y-1,Color.WHITE)
	var wrong_size := Image.create(20,20,false,Image.FORMAT_RGBA8)
	wrong_size.set_pixel(5,5,Color.WHITE)
	var rgb := local.duplicate() as Image
	rgb.convert(Image.FORMAT_RGB8)
	var results: Array=[]
	var failed := false
	for spec in [{"id":"local_transparent","image":local,"expected":true},{"id":"local_blended","image":blended,"expected":true},{"id":"all_opaque","image":opaque,"expected":false},{"id":"all_empty","image":empty,"expected":false},{"id":"nonlocal_full_extent","image":nonlocal,"expected":false},{"id":"wrong_canvas","image":wrong_size,"expected":false},{"id":"RGB_no_alpha_channel","image":rgb,"expected":false},{"id":"null","image":null,"expected":false}]:
		var actual := _body_valid(spec["image"])
		var passed: bool=actual==spec["expected"]
		failed=failed or not passed
		results.append({"id":spec["id"],"expected":spec["expected"],"actual":actual,"passed":passed})
	_json(V12.PREFIX+"body_api_preflight.json",{"cases":results,"all_passed":not failed,"GPU_capture":false,"body_method":"RGBA8_format_local_nonempty_usedrect_transparent_corner","capture_art_not_rewritten":true})
	print("[V12 BodyPreflight] synthetic Image cases=8 failed=",int(failed))
	quit(1 if failed else 0)
