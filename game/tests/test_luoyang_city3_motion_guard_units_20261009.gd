extends "res://tests/test_luoyang_shop_corner_input_diagnostic_20261009.gd"
## Independent motion-only units, not Field/input or whole-city approval.
const MOTION_PATH := "res://scripts/city/luoyang_city3_motion_guard_20261009.gd"
const MOTION_SHA := "aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93"
const NEW_FIELD_SHA := "93a34013d42a773f0fe82c77b82ed6a2477dbedf25d771137eb1eb455cdcfb93"
const UNIT_PATH := "res://tests/test_luoyang_city3_motion_guard_units_20261009.gd"
const STARTUP: Array[String]=["res://project.godot","res://scenes/player.tscn","res://scenes/npc_node.tscn","res://scenes/exit_zone.tscn","res://scenes/field_walkable.tscn","res://art/fonts/default_theme.tres","res://art/fonts/LXGWWenKaiLite-Regular.ttf","res://scripts/autoload/audio_manager.gd","res://scripts/autoload/cursor_manager.gd"]
var guard_records: Array[Dictionary]=[]
var dynamic_seen: Dictionary={}
var motion_script: Script
var market_record: Dictionary={}
var market_definition: SceneScript
var configure_timings: Array[int]=[]
var motion_timings: Array[int]=[]

func _track(path: String) -> void:
	if path.is_empty() or paths.has(path): return
	if not _check(FileAccess.file_exists(path),"required tracked input exists "+path): return
	paths[path]=true
	if path.get_extension()!="gd": return
	var references:=RegEx.new()
	# Exact .gd token, never the .gd prefix of an actual .gdshader path.
	references.compile("(res://[^\"'\\\\\\r\\n]+[.]gd)(?=[\"'\\r\\n])")
	for item: RegExMatch in references.search_all(FileAccess.get_file_as_string(path)): _track(item.get_string(1))

func _timed_configure(actual: RefCounted,image: Image,objects: Array) -> Variant:
	var start: int=Time.get_ticks_usec()
	var answer: Variant=actual.call("configure",image,objects)
	configure_timings.append(Time.get_ticks_usec()-start)
	return answer

func _timed_motion(actual: RefCounted,from: Vector2,to: Vector2,callback: Callable,margin: float) -> Variant:
	var start: int=Time.get_ticks_usec()
	var answer: Variant=actual.call("safe_motion",from,to,callback,margin)
	motion_timings.append(Time.get_ticks_usec()-start)
	return answer

func _timing_summary(values: Array[int]) -> Dictionary:
	if values.is_empty(): return {"count":0}
	var sorted: Array[int]=values.duplicate(); sorted.sort()
	var total: int=0
	for value: int in values: total+=value
	return {"count":values.size(),"total_usec":total,"maximum_usec":sorted.back(),"p95_usec":sorted[ceili(sorted.size()*.95)-1],"actual_monotonic_measurement":true}

static func fixture_sources() -> Array[String]:
	var result: Array[String]=[UNIT_PATH,MOTION_PATH,OBS_PATH,PHYSICAL_PATH,INPUT_PATH,RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,ACTUAL418,"res://tests/test_luoyang_shop_corner_input_diagnostic_20261009.gd"]
	for path: String in STARTUP: result.append(path)
	for path: String in PINS:
		if not result.has(path): result.append(path)
	for id: String in IDS: result.append("res://data/scenes/"+id+".tres")
	for path: String in PROTECTED: result.append(path)
	return result

func _dynamic(path: String) -> void:
	if path.is_empty() or dynamic_seen.has(path): return
	if not FileAccess.file_exists(path): return
	dynamic_seen[path]=true; _track(path)
	if FileAccess.file_exists(path+".import"):
		_track(path+".import")
		var config:=ConfigFile.new()
		_check(config.load(path+".import")==OK,"current dynamic import "+path)
		var compiled: Variant=config.get_value("remap","path",null)
		if typeof(compiled)==TYPE_STRING: _track(compiled)
		for value: Variant in config.get_value("deps","dest_files",PackedStringArray()):
			if typeof(value)==TYPE_STRING: _track(value)
	var extension: String=path.get_extension()
	if extension not in ["godot","gd","tscn","tres","gdshader","gdshaderinc"]: return
	var text: String=FileAccess.get_file_as_string(path)
	var pattern:=RegEx.new()
	if extension=="gd":
		pattern.compile("(?:preload|load)\\(\"(res://[^\"\\r\\n]+)\"\\)")
	else: pattern.compile("(res://[^\"\\r\\n]+)")
	for item: RegExMatch in pattern.search_all(text): _dynamic(item.get_string(1))
	# Runtime font/cursor/audio/UI constants are actual dynamic startup resources;
	# do not walk world art catalogs merely because their strings exist in code.
	if extension=="gd" and (path.begins_with("res://scripts/ui/") or path.begins_with("res://scripts/autoload/")):
		pattern.compile("(res://[^\"\\r\\n]+[.](?:png|svg|ttf|otf|wav|ogg|mp3|json|cfg|tres|tscn))")
		for item: RegExMatch in pattern.search_all(text): _dynamic(item.get_string(1))

func _motion_startup() -> void:
	for path: String in fixture_sources(): _track(path); _dynamic(path)
	# _track's complete literal script closure is deduplicated; only follow real
	# preload edges/resources from those scripts, not arbitrary world JSON lists.
	var previous: int=-1
	while previous!=paths.size():
		previous=paths.size()
		for path: String in paths.keys():
			if path.get_extension()=="gd": _dynamic(path)
	for path: String in STARTUP: _check(FileAccess.file_exists(path),"explicit startup source exists "+path)

func _market_sources() -> void:
	# Independently read frozen JSON; the serialized scene is an actual input,
	# never the authority used to derive the expected black-pixel slab.
	var raw_script: Script=load(RAW_PATH) as Script
	var contract: Script=load(CONTRACT_PATH) as Script
	if not _check(raw_script!=null and raw_script.can_instantiate() and contract!=null and contract.can_instantiate(),"market source readers compile"): return
	diag_raw=raw_script.new()
	market_record=diag_raw.call("independent_record",StringName(DIAG_ID))
	if not _check(not market_record.is_empty(),"independent full frozen market JSON"): return
	for path: String in market_record.get("asset_sha256",{}): _track(path); _dynamic(path)
	for key: String in ["enclosure_patch_path","enclosure_base_manifest_path","ground_capture_path"]:
		if typeof(market_record.get(key))==TYPE_STRING: _track(market_record[key]); _dynamic(market_record[key])
	var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(market_record.enclosure_patch_path))
	_track(String(patch.export_plan_path)); _dynamic(String(patch.export_plan_path))
	var candidate: String=contract.call("candidate_path",StringName(DIAG_ID))
	_track(candidate); _dynamic(candidate); _track(contract.call("layout_path",StringName(DIAG_ID))); _dynamic(contract.call("layout_path",StringName(DIAG_ID)))
	market_definition=ResourceLoader.load(candidate,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(market_definition!=null and market_definition.map_layout!=null,"actual serialized market source/layout"): return
	_dynamic(market_definition.bgm_path)
	for npc: Dictionary in market_definition.npcs:
		var npc_paths: Array=[]
		for key: String in ["sprite_path","walk_sprite_path","portrait_path"]:
			if typeof(npc.get(key))==TYPE_STRING and not String(npc[key]).is_empty(): npc_paths.append(npc[key])
		for value: Variant in npc.get("conversation_sprite_paths",{}).values():
			if typeof(value)==TYPE_STRING and not String(value).is_empty(): npc_paths.append(value)
		for path: String in npc_paths:
			_dynamic(path)
			for direction: String in ["up","down","left","right"]:
				for state_name: String in ["idle","walk"]:
					_dynamic(path.replace("_down_","_"+direction+"_").replace("_idle_","_"+state_name+"_"))
	for family: String in ["sword","dao","staff","palm","hidden"]:
		for state_name: String in ["idle","walk"]:
			for direction: String in ["up","down","left","right"]:
				_dynamic("res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png"%[family,family,state_name,direction,4 if state_name=="idle" else 8])

func _new_guard(image: Image,objects: Array) -> RefCounted:
	var actual: RefCounted=motion_script.new()
	_check(_timed_configure(actual,image,objects)==true,"actual production guard configured")
	return actual

func _endpoint(image: Image,p: Vector2) -> bool:
	if not p.is_finite(): return false
	var rect:=Rect2(p-Vector2(17,12),Vector2(34,24))
	var low:=Vector2i(roundi(rect.position.x),roundi(rect.position.y))
	var high:=Vector2i(roundi(rect.end.x),roundi(rect.end.y))
	if low.x<0 or low.y<0 or high.x>=image.get_width() or high.y>=image.get_height(): return false
	for y: int in range(low.y,high.y+1):
		for x: int in range(low.x,high.x+1):
			var color: Color=image.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	return true

func _pixel_interval(from: Vector2,to: Vector2,pixel: Vector2i) -> Dictionary:
	# Independent scalar slab intersection, not the production prefix/events.
	# Positive pixel coordinates: round(body right)>=pixel is lower-closed;
	# round(body left)<=pixel is upper-open. Store those boundaries explicitly.
	var enter: float=0.; var leave: float=1.
	for axis: int in 2:
		var half: float=17. if axis==0 else 12.
		var lower: float=float(pixel[axis])-half-.5
		var upper: float=float(pixel[axis])+half+.5
		var start: float=from[axis]; var speed: float=float(to[axis])-start
		if speed==0:
			if start<lower or start>=upper: return {"intersects":false}
			continue
		var first_hit: float=(lower-start)/speed
		var last_hit: float=(upper-start)/speed
		enter=maxf(enter,minf(first_hit,last_hit)); leave=minf(leave,maxf(first_hit,last_hit))
	if enter>=leave: return {"intersects":false,"touch_only":enter==leave}
	return {"intersects":true,"parameter_open_interior":[enter,leave],"midpoint_native":from.lerp(to,(enter+leave)*.5),"pixel":[pixel.x,pixel.y],"lower_closed_upper_open":true}

func _call_case(actual: RefCounted,image: Image,label: String,from: Vector2,to: Vector2,expected: bool,margin: float=.08) -> void:
	var callback: Callable=func(p: Vector2)->bool: return _endpoint(image,p)
	var start: int=Time.get_ticks_usec()
	var answer: Variant=_timed_motion(actual,from,to,callback,margin)
	var elapsed: int=Time.get_ticks_usec()-start
	_check(typeof(answer)==TYPE_BOOL and answer==expected,label)
	guard_records.append({"label":label,"from":[from.x,from.y],"to":[to.x,to.y],"from_native_hex":PackedVector2Array([from]).to_byte_array().hex_encode(),"to_native_hex":PackedVector2Array([to]).to_byte_array().hex_encode(),"start_endpoint":_endpoint(image,from),"end_endpoint":_endpoint(image,to),"actual":answer,"expected":expected,"actual_call_usec":elapsed,"long_segment_not_a_normal_frame":from.distance_to(to)>64,"margin":margin if is_finite(margin) else "NONFINITE"})

func _source_rect_interval(from: Vector2,to: Vector2,minimum: Vector2,maximum: Vector2,margin: float) -> Dictionary:
	# Independent Minkowski/slab for this authored rectangle only. No helper
	# prefix, helper hull, or helper event list is used to derive the answer.
	var enter: float=0.; var leave: float=1.
	for axis: int in 2:
		var half: float=(17. if axis==0 else 12.)+margin
		var lower: float=float(minimum[axis])-half
		var upper: float=float(maximum[axis])+half
		var start: float=from[axis]; var speed: float=float(to[axis])-start
		if speed==0:
			if start<lower or start>upper: return {"intersects":false}
			continue
		var a: float=(lower-start)/speed; var b: float=(upper-start)/speed
		enter=maxf(enter,minf(a,b)); leave=minf(leave,maxf(a,b))
	return {"intersects":enter<=leave,"closed":true,"parameter_interval":[enter,leave]}

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null: quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true,"public checkpoint protection before all awaits")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--luoyang-city3-motion-units" in args and "--fresh-start-only" in args and "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args,"explicit motion unit scope")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual engine/WASAPI/time")
	output="res://build/joint_world_luoyang_20261003_qa/city3_motion_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique motion unit output"): quit(1); return
	_motion_startup()
	_market_sources()
	_check(FileAccess.get_sha256(MOTION_PATH)==MOTION_SHA and FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd")==NEW_FIELD_SHA,"exact NEW motion/Field sources")
	_check(FileAccess.get_sha256(CONTRACT_PATH)==PINS[CONTRACT_PATH] and FileAccess.get_sha256(INPUT_PATH)==PINS[INPUT_PATH] and FileAccess.get_sha256("res://scripts/field/player.gd")==PINS["res://scripts/field/player.gd"],"C/Player/original INPUT unchanged")
	motion_script=load(MOTION_PATH) as Script
	_check(motion_script!=null and motion_script.can_instantiate(),"actual production motion script compiles")
	first=_snapshot(); _check(_write("source_before.json",first),"unique complete startup source guard")
	if failed==0:
		var image:=Image.create(3072,2048,false,Image.FORMAT_RGBA8); image.fill(Color.WHITE)
		image.set_pixel(1915,830,Color.BLACK)
		image.set_pixel(800,1000,Color(.49,1,1,1)); image.set_pixel(850,1000,Color(1,1,1,.49))
		var neutral: Array=[{"blocking":false}]
		var actual: RefCounted=_new_guard(image,neutral)
		var slab: Dictionary=_pixel_interval(Vector2(1888,832),Vector2(1920,864),Vector2i(1915,830))
		_check(slab.get("intersects")==true and _endpoint(image,Vector2(1888,832)) and _endpoint(image,Vector2(1920,864)) and not _endpoint(image,slab.midpoint_native),"independent original blackcorner endpoints-white/interior-black slab")
		evidence["independent_black_corner_slab"]={"pixel":slab.pixel,"parameter_interval":slab.parameter_open_interior,"midpoint":[slab.midpoint_native.x,slab.midpoint_native.y],"lower_closed_upper_open":true}
		_call_case(actual,image,"original14 continuous blackcorner denied",Vector2(1888,832),Vector2(1920,864),false)
		_call_case(actual,image,"reverse blackcorner denied",Vector2(1920,864),Vector2(1888,832),false)
		_call_case(actual,image,"legal vertical fallback",Vector2(1893.6568603515625,837.6568603515625),Vector2(1893.6568603515625,843.313720703125),true)
		_call_case(actual,image,"legal horizontal below corner",Vector2(1888,864),Vector2(1920,864),true)
		_call_case(actual,image,"legal reverse horizontal",Vector2(1920,864),Vector2(1888,864),true)
		_call_case(actual,image,"gray red pixel denied",Vector2(770,1000),Vector2(830,1000),false)
		_call_case(actual,image,"gray alpha pixel denied",Vector2(820,1000),Vector2(880,1000),false)
		_call_case(actual,image,"zero-length legal portal point",Vector2(1000,1400),Vector2(1000,1400),true)
		_call_case(actual,image,"samepoint forbidden callback",Vector2(1915,830),Vector2(1915,830),false)
		_call_case(actual,image,"long legal move has no arbitrary span cap",Vector2(100,1800),Vector2(2900,1800),true)
		_call_case(actual,image,"nonfinite start denied",Vector2(INF,800),Vector2(1200,800),false)
		_call_case(actual,image,"nonfinite end denied",Vector2(1200,800),Vector2(NAN,800),false)
		_call_case(actual,image,"outside endpoint denied",Vector2(-1,800),Vector2(1200,800),false)
		_call_case(actual,image,"body outside pixel domain denied",Vector2(10,800),Vector2(100,800),false)
		_call_case(actual,image,"nonzero nonfinite margin denied",Vector2(1000,1400),Vector2(1100,1400),false,INF)
		_call_case(actual,image,"negative margin denied",Vector2(1000,1400),Vector2(1100,1400),false,-.01)
		var false_type: Callable=func(_p: Vector2)->int: return 1
		_check(_timed_motion(actual,Vector2(1000,1400),Vector2(1100,1400),false_type,.08)==false,"strict callback bool, no numeric coercion")
		var call_count: Array=[0]
		var count_callback: Callable=func(_p: Vector2)->bool:
			call_count[0]+=1
			return true
		_check(_timed_motion(actual,Vector2(1000,1400),Vector2(1000,1400),count_callback,.08)==true and call_count[0]==1,"samepoint calls existing endpoint exactly once")
		for x: float in [1897.4998779296875,1897.5,1897.5001220703125]:
			var a:=Vector2(x,841.5); var b:=Vector2(1899,843)
			_call_case(actual,image,"half-grid adjacent native state denied "+str(x),a,b,false)
		actual.call("release"); actual=null
		var thin: Array=[{"blocking":true,"city_v3_solid_polygons_px":[[[1500,1199],[1501,1199],[1501,1201],[1500,1201]]],"collision_size_px":[0,0]}]
		actual=_new_guard(image,thin)
		# Source rectangle Minkowski support gives closed expanded rectangle:
		# x=[1482.92,1518.08], y=[1186.92,1213.08], independently of prefix.
		var solid_slab: Dictionary=_source_rect_interval(Vector2(1450,1200),Vector2(1550,1200),Vector2(1500,1199),Vector2(1501,1201),.08)
		_check(solid_slab.intersects==true and _source_rect_interval(Vector2(1450,1186),Vector2(1550,1186),Vector2(1500,1199),Vector2(1501,1201),.08).intersects==false,"independent closed authored rectangle slab crossing versus clear axis")
		evidence["independent_source_closed_slab"]=solid_slab
		_call_case(actual,image,"midpath thin source entity denied",Vector2(1450,1200),Vector2(1550,1200),false)
		_call_case(actual,image,"exact source closed touch denied at margin zero",Vector2(1450,1187),Vector2(1550,1187),false,0.)
		_call_case(actual,image,"closed source touch plus actual recovery margin denied",Vector2(1450,1187),Vector2(1550,1187),false)
		_call_case(actual,image,"source entity clear legal axis",Vector2(1450,1186),Vector2(1550,1186),true)
		_call_case(actual,image,"native subpixel source near-touch remains clear",Vector2(1450,1186.875),Vector2(1550,1186.875),true,0.)
		_call_case(actual,image,"large support margin denies source corridor",Vector2(1450,1186),Vector2(1550,1186),false,2.)
		_call_case(actual,image,"native support overflow denied",Vector2(1450,1186),Vector2(1550,1186),false,1e200)
		actual.call("release"); actual=null
		var invalid: RefCounted=motion_script.new()
		_check(_timed_configure(invalid,null,neutral)==false,"missing mask failclosed")
		_check(_timed_configure(invalid,Image.create(8,8,false,Image.FORMAT_RGBA8),neutral)==false,"wrong mask canvas rejected")
		_check(_timed_configure(invalid,image,[])==false,"missing object provenance rejected")
		_check(_timed_configure(invalid,image,[{"blocking":1}])==false,"blocking wrong type rejected")
		_check(_timed_configure(invalid,image,[{"blocking":true,"city_v3_solid_polygons_px":[[[1500,1200],[1501,1200],[NAN,1201]]]}])==false,"nonfinite source polygon rejected")
		invalid.call("release"); invalid=null
		for format: int in [Image.FORMAT_RF,Image.FORMAT_RGF,Image.FORMAT_RGBF,Image.FORMAT_RGBAF]:
			var float_mask:=Image.create(3072,2048,false,format); float_mask.fill(Color(.4999,1,1,1))
			invalid=motion_script.new()
			_check(_timed_configure(invalid,float_mask,neutral)==false,"float mask cannot quantize subthreshold white: "+str(format))
			invalid.call("release"); invalid=null
		var corridor:=Image.create(3072,2048,false,Image.FORMAT_RGBA8); corridor.fill(Color.BLACK)
		for y: int in range(1479,1522):
			for x: int in range(60,2941): corridor.set_pixel(x,y,Color.WHITE)
		actual=_new_guard(corridor,neutral)
		_call_case(actual,corridor,"legal narrow axis corridor remains open",Vector2(100,1500),Vector2(2900,1500),true)
		_call_case(actual,corridor,"reverse narrow axis corridor remains open",Vector2(2900,1500),Vector2(100,1500),true)
		actual.call("release"); actual=null
		var thresholds:=image.duplicate() as Image
		thresholds.set_pixel(1200,1400,Color(127./255.,1,1,1)); thresholds.set_pixel(1300,1400,Color(128./255.,1,1,1))
		thresholds.set_pixel(1400,1400,Color(1,1,1,127./255.)); thresholds.set_pixel(1500,1400,Color(1,1,1,128./255.))
		actual=_new_guard(thresholds,neutral)
		for item: Array in [[1200,false],[1300,true],[1400,false],[1500,true]]:
			var center:=Vector2(item[0],1400)
			_call_case(actual,thresholds,"exact 8bit red/alpha 127 versus 128 "+str(item[0]),center,center,item[1])
			_call_case(actual,thresholds,"nonzero prefix 8bit red/alpha threshold "+str(item[0]),center-Vector2(40,0),center+Vector2(40,0),item[1])
		actual.call("release"); actual=null
		for format: int in [Image.FORMAT_L8,Image.FORMAT_LA8,Image.FORMAT_RGB8]:
			var integer_mask:=Image.create(3072,2048,false,format); integer_mask.fill(Color.WHITE)
			actual=_new_guard(integer_mask,neutral)
			_call_case(actual,integer_mask,"supported 8bit format nonzero motion "+str(format),Vector2(1000,1600),Vector2(1040,1600),true)
			actual.call("release"); actual=null
		var native_mask:=Image.new()
		_check(native_mask.load(String(market_record.walk_path))==OK,"actual market PNG loaded independently")
		var native_objects: Array=market_definition.map_layout.visual_objects
		actual=_new_guard(native_mask,native_objects)
		var native_slab: Dictionary=_pixel_interval(Vector2(1888,832),Vector2(1920,864),Vector2i(1915,830))
		_check(_endpoint(native_mask,Vector2(1888,832)) and _endpoint(native_mask,Vector2(1920,864)) and not _endpoint(native_mask,native_slab.midpoint_native),"actual frozen market endpoints white but independently slab black")
		_call_case(actual,native_mask,"actual market original14 sweep denied",Vector2(1888,832),Vector2(1920,864),false)
		actual.call("release"); actual=null
		evidence["actual_helper_cases"]=guard_records.duplicate(true)
		evidence["configure_timing"]=_timing_summary(configure_timings)
		evidence["safe_motion_timing_all_calls"]=_timing_summary(motion_timings)
		var short_times: Array[int]=[]; var long_times: Array[int]=[]
		for row: Dictionary in guard_records:
			if row.long_segment_not_a_normal_frame: long_times.append(row.actual_call_usec)
			else: short_times.append(row.actual_call_usec)
		evidence["short_motion_timing"]=_timing_summary(short_times)
		evidence["long_segments_timing_not_frame_cost"]=_timing_summary(long_times)
	await _finish_motion_units()

func _finish_motion_units() -> void:
	if diag_raw!=null: _check(diag_raw.call("verify_sources")==true,"independent market sources final exact"); diag_raw.call("release"); diag_raw=null
	market_definition=null
	for tick: int in 10: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick: int in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all startup/consumed inputs first-last unchanged")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"15 players/slot unchanged; outer exact UTC ticks required")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"actual audio/engine/checkpoint remains protected")
	var result: Dictionary={"scope":"CITY3_CONTINUOUS_MOTION_INDEPENDENT_PIXEL_SLAB_AND_SOURCE_SUPPORT_UNITS","complete":failed==0,"checks":checks+1,"failures":failed,"evidence":evidence,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"checkpoint":checkpoint,"actual_Field_tested":false,"input_roundtrip_tested":false,"formal_approved":false,"original418_419_FAIL_preserved":true}
	_check(_write("result.json",result),"motion units report exact readback")
	print("CITY3_MOTION_UNITS_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)
