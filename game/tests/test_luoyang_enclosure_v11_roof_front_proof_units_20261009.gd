extends SceneTree
## Source/import + owned Sprite mathematical fixtures, NOT actual Field credit.
## Root wrapper additionally guards all15 player exact UTC ticks and stderr.
const PROOF_PATH := "res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd"
const PROOF_SHA := "8a82284236fe033f770fc4ff803106abd04c23c64728d713d157c0e11a66b891"
const PROOF = preload("res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd")
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
var proof: RefCounted=PROOF.new()
var first: Dictionary={}
var players: Dictionary={}
var slot: Variant
var checks:=0
var failures:=0
var output:=""
var positives: Array[Dictionary]=[]
var negatives: Array[String]=[]

static func fixture_sources() -> Array[String]:
	return ["res://tests/test_luoyang_enclosure_v11_roof_front_proof_units_20261009.gd",PROOF_PATH,PROOF.PATCH,PROOF.PLAYER,"res://scripts/autoload/platform_bridge.gd","res://scripts/autoload/save_manager.gd","res://data/scenes/world_map_jianghu.tres","res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres","res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres","res://data/config/outskirts_native_adoption.json"]
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1; push_error("[ROOF PROOF UNIT FAIL] "+label)
	return ok
func _file(path: String) -> Dictionary:
	var f:=FileAccess.open(path,FileAccess.READ)
	return {"exists":f!=null,"bytes":f.get_length() if f!=null else 0,"sha256":FileAccess.get_sha256(path) if f!=null else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if f!=null else 0}
func _players() -> Dictionary:
	var value: Dictionary={}
	for i: int in 5:
		for suffix: String in ["",".bak",".tmp"]: value["user://save_%d.json%s"%[i,suffix]]=_file("user://save_%d.json%s"%[i,suffix])
	return value
func _negative(value: Dictionary,label: String) -> void:
	_check(value.is_empty() or value.get("proved")==false,label)
	negatives.append(label)
func _core(image: Image,foot: float=6.,minimum: float=-1.,flip_v: bool=false,t: Transform2D=Transform2D.IDENTITY) -> Dictionary:
	return proof.call("support_gap",image,Rect2(0,0,8,8),t,false,flip_v,minimum,foot)

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_players(); slot=root.get_node("SaveManager").get("active_slot")
	if not _check(bridge.call("is_checkpoint_saves_suspended")==true,"public checkpoint suspension before any await"): quit(1); return
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not _check("--luoyang-roof-front-proof-units" in args and not "--activate" in args,"explicit limited noField/no publication scope"): quit(1); return
	output="res://build/joint_world_luoyang_20261003_qa/roof_front_proof_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique evidence output"): quit(1); return
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual ordinary WASAPI/executable")
	if not _check(FileAccess.get_sha256(PROOF_PATH)==PROOF_SHA,"exact reviewed independent proof source"): await _finish(); return
	for path: String in fixture_sources(): first[path]=_file(path); _check(first[path].exists,"source exists "+path)
	if not _check(proof.call("prepare")==true,"independent fixed six PNGs/40 strips240frames import/source inventory"): await _finish(); return
	for path: String in proof.get("sources"): first[path]=proof.get("sources")[path].duplicate(true)
	var layer:=Node2D.new(); root.add_child(layer)
	var actor_root:=Node2D.new(); layer.add_child(actor_root); actor_root.position=Vector2(1000,1000)
	var actor:=Sprite2D.new(); actor_root.add_child(actor)
	actor.texture=ResourceLoader.load(PROOF.ROOT+"sword/lengguyun_sword_idle_down_25d_4f.png") as Texture2D
	actor.hframes=4; actor.vframes=1; actor.scale=Vector2.ONE*(.945*.91); actor.position=Vector2(0,-160.*actor.scale.y*.45)
	var actor_foot: float=actor_root.global_position.y+actor.position.y+actor.texture.get_height()*actor.scale.y*.45
	for id: String in PROOF.IDS:
		var row: Dictionary=proof.get("records")[id]
		var prop:=Sprite2D.new(); layer.add_child(prop)
		prop.texture=ResourceLoader.load(row.texture,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		prop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var render:=Vector2(row.render_size_px[0],row.render_size_px[1]); var foot:=Vector2(row.world_foot_px[0],row.world_foot_px[1]); var uv:=Vector2(row.foot_uv[0],row.foot_uv[1])
		var center: Vector2=(foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048)
		prop.position=center*Vector2(3072,2048)
		var value: Dictionary=proof.call("prove_actual",id,prop,actor,actor_foot,foot.y,.91,true)
		_check(not value.is_empty() and value.get("proved")==true and value.get("source_import_all_RGBA_exact")==true,"six actual source/import sprites independent proof "+id)
		positives.append(value)
		_negative(proof.call("prove_actual","unknown_roof",prop,actor,actor_foot,foot.y,.91,true),"unknown identity refuses "+id)
		_negative(proof.call("prove_actual",id,prop,actor,actor_foot,foot.y+1.,.91,true),"wrong prop depth foot refuses "+id)
		_negative(proof.call("prove_actual",id,prop,actor,actor_foot,foot.y,.91,false),"wrong ground anchor refuses "+id)
		prop.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		_negative(proof.call("prove_actual",id,prop,actor,actor_foot,foot.y,.91,true),"wrong sampler domain refuses "+id)
		prop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var original: Image=Image.load_from_file(row.texture); original.convert(Image.FORMAT_RGBA8)
		var weak: Image=original.duplicate() as Image
		weak.set_pixel(int(weak.get_width()/2),weak.get_height()-1,Color(1,1,1,1./255.))
		_check(proof.call("rgba_pair_exact",original,original.duplicate())==true,"actual byte predicate original owned equality "+id)
		_check(proof.call("rgba_pair_exact",original,weak)==false,"actual byte predicate weak alpha corruption refuses "+id)
		var bound: Dictionary=proof.call("actor_bound",actor,actor_foot,.91,true)
		_negative(proof.call("support_gap",weak,prop.get_rect(),prop.global_transform,false,false,bound.get("minimum_relative_y",-INF),foot.y),"owned weak alpha outside metadata bbox defeats gap "+id)
		prop.free()
	var rows: Array=proof.get("inventory").duplicate(true)
	_check(proof.call("inventory_valid",rows)==true,"complete independent inventory accepts")
	var missing: Array=rows.duplicate(true); missing.pop_back()
	_check(proof.call("inventory_valid",missing)==false,"missing noncurrent strip refuses")
	var duplicate: Array=rows.duplicate(true); duplicate[39]=duplicate[0].duplicate(true)
	_check(proof.call("inventory_valid",duplicate)==false,"duplicate strip refuses")
	var changed: Array=rows.duplicate(true); changed[39].full_drawrect=Rect2(-80,-100,160,180)
	_check(proof.call("inventory_valid",changed)==false,"noncurrent walk frame geometry alteration refuses")
	changed=rows.duplicate(true); changed[39].hframes=4
	_check(proof.call("inventory_valid",changed)==false,"noncurrent animation frame count refuses")
	actor.offset=Vector2(0,1)
	_check(proof.call("actor_bound",actor,actor_foot,.91,true).is_empty(),"actual offset alteration refuses")
	actor.offset=Vector2.ZERO; actor.scale*=2.
	_check(proof.call("actor_bound",actor,actor_foot,.91,true).is_empty(),"actual scale alteration refuses")
	actor.scale=Vector2.ONE*(.945*.91); actor.rotation=.1
	_check(proof.call("actor_bound",actor,actor_foot,.91,true).is_empty(),"actual rotation alteration refuses")
	actor.rotation=0.; actor.texture=ImageTexture.create_from_image(Image.create(640,160,false,Image.FORMAT_RGBA8))
	_check(proof.call("actor_bound",actor,actor_foot,.91,true).is_empty(),"unowned fallback texture refuses")
	layer.free()
	var image:=Image.create(8,8,false,Image.FORMAT_RGBA8); image.fill(Color(0,0,0,0)); image.set_pixel(3,3,Color.WHITE)
	var positive: Dictionary=_core(image)
	_check(positive.get("proved")==true and positive.get("prop_positive_pixels")==1 and positive.get("source_positive_max_row")==3 and positive.get("metadata_used")==false,"owned actual core positive allalpha scan")
	_negative(_core(image,5.),"bilinear halo-only overlap refuses despite positive nearest-centre gap")
	_negative(_core(image,5.5),"closed-domain zero gap refuses")
	_negative(_core(image,4.),"negative gap refuses")
	_negative(_core(image,6.,-8.),"later full-frame support reaching roof refuses")
	for bad: float in [NAN,INF,-INF]:
		_negative(_core(image,bad),"nonfinite foot refuses "+str(bad))
		_negative(_core(image,6.,bad),"nonfinite full-frame bound refuses "+str(bad))
	_negative(_core(image,6.,0.),"invalid actor minimum refuses")
	_negative(_core(image,6.,-1.,false,Transform2D(Vector2.ZERO,Vector2.DOWN,Vector2.ZERO)),"singular transform refuses")
	_negative(_core(image,6.,-1.,false,Transform2D(Vector2(INF,0),Vector2.DOWN,Vector2.ZERO)),"overflow transform refuses")
	var flipped:=Image.create(8,8,false,Image.FORMAT_RGBA8); flipped.fill(Color(0,0,0,0)); flipped.set_pixel(3,0,Color.WHITE)
	_check(_core(flipped,4.).get("proved")==true,"top alpha positive without flip")
	_negative(_core(flipped,4.,-1.,true),"flipped source bottom support refuses")
	var empty:=Image.create(8,8,false,Image.FORMAT_RGBA8); empty.fill(Color(0,0,0,0))
	_negative(_core(empty),"empty support is insufficient not searchmiss approval")
	var rgb:=Image.create(8,8,false,Image.FORMAT_RGB8)
	_negative(_core(rgb),"wrong decoded format refuses")
	_check(proof.call("rgba_pair_exact",image,rgb)==false,"actual byte predicate rejects wrong format")
	_check(proof.call("rgba_pair_exact",image,Image.create(9,8,false,Image.FORMAT_RGBA8))==false,"actual byte predicate rejects wrong canvas")
	var wrong_rgb: Image=image.duplicate() as Image; wrong_rgb.set_pixel(3,3,Color(0,1,1,1))
	_check(proof.call("rgba_pair_exact",image,wrong_rgb)==false,"actual byte predicate rejects RGB-only source/import mutation")
	_check(proof.call("unchanged")==true,"all helper consumed source/import/compiled inputs final exact")
	await _finish()

func _finish() -> void:
	root.get_node("AudioManager").call("stop_bgm",.1)
	for tick: int in 8: await process_frame
	_check(proof.call("unchanged")==true,"all consumed source/import/compiled inputs unchanged after final await")
	var source_same:=true
	for path: String in first:
		if first[path]!=_file(path): source_same=false
	_check(source_same,"all first/last source identity SHA bytes mtime unchanged")
	_check(players==_players() and slot==root.get_node("SaveManager").get("active_slot"),"15 normal files and active slot unchanged")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"checkpoint remains publicly suspended through exit")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"end actual driver/executable/time unchanged")
	var result: Dictionary={"scope":"SIX_ROOF_CONTINUOUS_FRONT_PROOF_SOURCE_IMPORT_AND_OWNED_FIXTURES_NOT_FIELD","complete":failures==0,"checks":checks,"failures":failures,"positive_six":positives,"negative_function_cases":negatives,"source_before":first,"source_unchanged":source_same,"players_before":players,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"actual_engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"all40strips240frames":proof.get("inventory").duplicate(true),"Field_input_executed":false,"behind_Physics_Y_union_approved":false,"original_ROOT412_FAIL_preserved":true,"formal_approved":false}
	proof.call("release"); proof=null
	var encoded: String=JSON.stringify(result,"\t",false)
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(encoded+"\n"); file.flush(); var wrote: bool=file.get_error()==OK; file.close()
	var parser:=JSON.new(); var expected:=JSON.new()
	_check(wrote and parser.parse(FileAccess.get_file_as_string(output+"result.json"))==OK and expected.parse(encoded)==OK and parser.data==expected.data,"unique result exact native JSON readback")
	print("LUOYANG_ROOF_FRONT_PROOF_UNITS "+output+"result.json "+str(checks)+"/"+str(failures))
	quit(0 if failures==0 else 1)
