extends SceneTree
## Pure owned in-memory image unit. No builder, art write, Field, save or GPU.
const SUBJECT_PATH := "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
const EPSILON: float=0.00001
var checks: int=0
var failed: int=0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		push_error("[ALPHA EPSILON UNIT FAIL] "+label)

func _reference(raw: Image,size: Vector2i) -> Dictionary:
	# Independent Color/Image API implementation versus packed-byte subject.
	# The algorithm operation is exact, not a tolerance or a source-image edit.
	var image: Image=raw.duplicate() as Image
	image.convert(Image.FORMAT_RGBAF)
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color=image.get_pixel(x,y)
			image.set_pixel(x,y,Color(pixel.r*pixel.a,pixel.g*pixel.a,pixel.b*pixel.a,pixel.a))
	image.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	var cleared: int=0
	var negative: int=0
	for y in image.get_height():
		for x in image.get_width():
			var pixel: Color=image.get_pixel(x,y)
			if pixel.a>EPSILON:
				image.set_pixel(x,y,Color(pixel.r/pixel.a,pixel.g/pixel.a,pixel.b/pixel.a,pixel.a))
			else:
				cleared+=1
				if pixel.a<0: negative+=1
				image.set_pixel(x,y,Color(0,0,0,0))
	image.convert(Image.FORMAT_RGBA8)
	return {"image":image,"cleared_pixels":cleared,"negative_pixels":negative}

func _run() -> void:
	var script: GDScript=load(SUBJECT_PATH) as GDScript
	_check(script!=null and script.can_instantiate(),"actual current subject compiles in registered autoload context")
	if script==null or not script.can_instantiate(): quit(1); return
	var subject: RefCounted=script.new() as RefCounted
	_check(subject.get_script().resource_path==SUBJECT_PATH,"explicit independent subject path, not Script constant resource_path")
	_check(subject.get_script().get_script_constant_map().get("ALPHA_UNPREMULTIPLY_EPSILON")==EPSILON,"exact declared identity epsilon, no tolerance substitution")
	var rows: Array[Dictionary]=[]
	for value: float in [-.01,0.,.000005,.00001,.00002,.12,1.]:
		var raw:=Image.create(2,2,false,Image.FORMAT_RGBAF)
		raw.fill(Color(.9,.25,.7,value))
		var before: PackedByteArray=raw.get_data()
		var reference: Dictionary=_reference(raw,Vector2i(2,2))
		var actual: Image=subject.call("_alpha_resize",raw,Vector2i(2,2))
		_check(actual.get_data()==reference.image.get_data(),"strict RGBA byte equality for recorded source alpha "+str(value))
		_check(raw.get_data()==before,"subject never mutates source bytes "+str(value))
		if raw.get_pixel(0,0).a<=EPSILON:
			_check(actual.get_data()==PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]),"all four channels clear including low/negative alpha "+str(value))
		else:
			_check(reference.cleared_pixels==0,"above-epsilon colors retain unpremultiplication operation "+str(value))
		rows.append({"source_alpha_requested":value,"actual_float32_alpha":raw.get_pixel(0,0).a,"cleared_pixels":reference.cleared_pixels,"rgba_hex_text_sha256":actual.get_data().hex_encode().sha256_text()})
	for raw_size: Vector2i in [Vector2i(8,4),Vector2i(20,12)]:
		var raw:=Image.create(raw_size.x,raw_size.y,false,Image.FORMAT_RGBA8)
		for y in raw_size.y:
			for x in raw_size.x:
				raw.set_pixel(x,y,Color(.95,.15,.4,1. if x==raw_size.x/2 and y>=1 else 0.))
		var before: PackedByteArray=raw.get_data()
		var low: Vector2i=raw_size/2
		var reference: Dictionary=_reference(raw,low)
		var actual: Image=subject.call("_alpha_resize",raw,low)
		_check(actual.get_size()==low and actual.get_data()==reference.image.get_data(),"actual Lanczos edge/negative-lobe packed reconstruction exact "+str(raw_size))
		_check(raw.get_data()==before,"raw transparent RGB and full bytes unchanged by spatial reconstruction")
		_check(reference.cleared_pixels>0,"spatial example genuinely exercises low-alpha clear operation")
		rows.append({"source_size":[raw_size.x,raw_size.y],"logical_size":[low.x,low.y],"cleared_pixels":reference.cleared_pixels,"actual_negative_lobes":reference.negative_pixels})
	var owned: WeakRef=weakref(subject)
	var geometry: RefCounted=subject.get("geometry") as RefCounted
	geometry.call("release")
	subject.set("geometry",null)
	geometry=null
	subject=null
	script=null
	for frame in 4: await process_frame
	_check(owned.get_ref()==null,"test-owned oracle and geometry references released naturally")
	print(JSON.stringify({"scope":"PURE_ALPHA_IDENTITY_EPSILON_IMAGE_UNIT_NOT_FIELD_GPU_OR_VISUAL_PASS","subject_path":SUBJECT_PATH,"subject_sha256":FileAccess.get_sha256(SUBJECT_PATH),"algorithm_epsilon":EPSILON,"comparison":"EXACT_RGBA_BYTES_NO_TOLERANCE","checks":checks,"failed":failed,"records":rows}))
	quit(0 if failed==0 else 1)
