extends SceneTree

## Read-only representation diagnostic, not Field/material acceptance.
const SOURCE := preload("res://scripts/dev/luoyang_modular_v3_source.gd")
const SURFACE := preload("res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd")
const SAVED := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v1/ch4_s0_luoyang_gate/paving_material.res"
var failures: Array[Dictionary]=[]
var owner: SURFACE
var fresh: ShaderMaterial
var stored: ShaderMaterial
var subject: SOURCE

func _initialize() -> void:
	call_deferred("_run")

func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256)!=OK: return "ERROR"
	if not bytes.is_empty() and hash.update(bytes)!=OK: return "ERROR"
	return hash.finish().hex_encode()

func _variant(value: Variant) -> Dictionary:
	var result: Dictionary={"type":typeof(value),"variant_sha256":_sha(var_to_bytes(value))}
	if value is Array:
		result["size"]=value.size()
		result["typed"]=value.is_typed()
		result["typed_builtin"]=value.get_typed_builtin()
		result["typed_class_name"]=String(value.get_typed_class_name())
	elif value is Resource:
		result["class"]=value.get_class()
		result["path"]=value.resource_path
	else: result["value"]=str(value)
	return result

func _compare(name: String,a: Variant,b: Variant) -> void:
	var same: bool=var_to_bytes(a)==var_to_bytes(b)
	var record: Dictionary={"uniform":name,"byte_exact":same,"actual":_variant(a),"saved":_variant(b)}
	if a is Array and b is Array:
		record["element_count_equal"]=a.size()==b.size()
		var different: Array=[]
		for index in range(mini(a.size(),b.size())):
			if var_to_bytes(a[index])!=var_to_bytes(b[index]): different.append({"index":index,"actual":_variant(a[index]),"saved":_variant(b[index])})
		record["element_byte_differences"]=different
		record["elements_byte_exact"]=a.size()==b.size() and different.is_empty()
	print("PAVING_UNIFORM ",JSON.stringify(record))
	if not same: failures.append(record)

func _texture(name: String,a: Texture2D,b: Variant) -> void:
	if not b is Texture2D:
		_compare(name+"_texture_type",a,b)
		return
	var ai: Image=a.get_image()
	var bi: Image=b.get_image()
	if ai==null or bi==null:
		failures.append({"uniform":name,"null_image":true})
		return
	var x: Dictionary={"size":[ai.get_width(),ai.get_height()],"format":ai.get_format(),"mips":ai.get_mipmap_count(),"bytes":ai.get_data().size(),"sha256":_sha(ai.get_data())}
	var y: Dictionary={"size":[bi.get_width(),bi.get_height()],"format":bi.get_format(),"mips":bi.get_mipmap_count(),"bytes":bi.get_data().size(),"sha256":_sha(bi.get_data())}
	print("PAVING_SAMPLER ",JSON.stringify({"uniform":name,"actual":x,"saved":y,"source_evidence":owner.evidence,"byte_exact":ai.get_data()==bi.get_data()}))
	if x!=y or ai.get_data()!=bi.get_data(): failures.append({"uniform":name,"actual":x,"saved":y})

func _run() -> void:
	subject=SOURCE.new()
	subject.prepare("ch4_s0_luoyang_gate")
	owner=SURFACE.new()
	if subject.preparation_error!="" or not owner.configure(subject.snapshot()) or not owner.load_sources():
		failures.append({"preparation_error":subject.preparation_error,"surface_error":owner.error})
		await _finish()
		return
	fresh=owner.paving()
	stored=ResourceLoader.load(SAVED,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if fresh==null or stored==null or fresh.shader==null or stored.shader==null:
		failures.append({"material_null":true,"saved_path":SAVED})
		await _finish()
		return
	_compare("shader_code",fresh.shader.code,stored.shader.code)
	_compare("uniform_schema",fresh.shader.get_shader_uniform_list(),stored.shader.get_shader_uniform_list())
	for declaration: Dictionary in fresh.shader.get_shader_uniform_list():
		var name: String=declaration["name"]
		var a: Variant=fresh.get_shader_parameter(name)
		var b: Variant=stored.get_shader_parameter(name)
		if a is Texture2D: _texture(name,a,b)
		else: _compare(name,a,b)
	print("PAVING_DIAGNOSTIC ",JSON.stringify({"scope":"READ_ONLY_FRESH_VS_ROOT143_SAVED_REPRESENTATION_NOT_ACCEPTANCE","saved_path":SAVED,"saved_sha256":FileAccess.get_sha256(SAVED),"failures":failures,"tolerance":0,"asset_writes":false}))
	await _finish()

func _finish() -> void:
	fresh=null
	stored=null
	if owner!=null: owner.release()
	owner=null
	subject=null
	# Natural autoload lifecycle, no private caches or canceled timers.
	var until: int=Time.get_ticks_msec()+9000
	while Time.get_ticks_msec()<until: await process_frame
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_WAIT)
	quit(0 if failures.is_empty() else 1)
