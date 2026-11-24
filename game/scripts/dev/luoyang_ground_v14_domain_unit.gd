extends SceneTree
const DOMAIN = preload("res://scripts/dev/luoyang_ground_v14_serialized_domain.gd")
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("_domain_run")
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)
func _domain_run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	var original := {"scene_id":"ch4_s0_luoyang_gate","logical_size_px":[3072.,2048.],"extra_source_key":{"value":[1.,2.]},"objects":[{"id":"keep","world_foot_px":[120.,240.]}]}
	var before: PackedByteArray = var_to_bytes(original)
	for size: Array in [[3072,2048],[3072.,2048.],[3072,2048.]]:
		var sample: Dictionary = original.duplicate(true); sample.logical_size_px = size
		var prepared: Dictionary = DOMAIN.snapshot(sample)
		_check(not prepared.has("error"),"Valid int/JSONfloat size rejected")
		_check(typeof(prepared.value.logical_size_px[0]) == TYPE_INT and typeof(prepared.value.logical_size_px[1]) == TYPE_INT,"Only dimensions must normalize to native ints")
		_check(BASE._equal_value(prepared.value.extra_source_key,sample.extra_source_key) and BASE._equal_value(prepared.value.objects,sample.objects),"Extra fields/geometry changed")
		prepared.value.extra_source_key.value.append(3.)
		_check(sample.extra_source_key.value.size() == 2,"Prepared snapshot shares source nested values")
	for size: Variant in [null,{},[],[3072],[3072,2048,0],[3071,2048],[3072,2049],[3072.0001,2048.],["3072",2048],[true,2048],[NAN,2048],[INF,2048]]:
		var sample: Dictionary = original.duplicate(true); sample.logical_size_px = size
		_check(DOMAIN.snapshot(sample).has("error"),"Wrong shape/value/type/nonfinite dimension accepted")
	_check(var_to_bytes(original) == before,"Original source record mutated")
	var camera := {"projection":0,"raw_canvas_px":[6144,4096],"logical_canvas_px":[3072,2048],"position_m":[0.,32.,55.4256258422],"basis_columns":[[1.,0.,0.],[0.,.866025388240814,.5],[0.,-.5,.866025388240814]],"near":.1,"far":160.,"extra_camera_key":"must_keep"}
	var stored: Variant = DOMAIN.stored(camera)
	_check(stored is Dictionary and BASE._equal_value(DOMAIN.stored(camera),stored),"Exact full writer/read camera domain failed")
	for mutation: Dictionary in [{"projection":1},{"projection":"0"},{"logical_canvas_px":[3072,2049]},{"near":.1001},{"position_m":[0.,32.,55.4]},{"extra_camera_key":"lost"},{"new_camera_key":true}]:
		var changed: Dictionary = camera.duplicate(true); changed.merge(mutation,true)
		_check(not BASE._equal_value(DOMAIN.stored(changed),stored),"Camera mismatch/type/extra-key bypassed")
	var missing: Dictionary = camera.duplicate(true); missing.erase("extra_camera_key")
	_check(not BASE._equal_value(DOMAIN.stored(missing),stored),"Missing stored camera field accepted")
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"Checkpoint suspension lost")
	print("LUOYANG_GROUND_V14_DOMAIN_ONLY checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
