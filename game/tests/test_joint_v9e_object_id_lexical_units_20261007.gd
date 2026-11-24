extends SceneTree
## Independent QA ObjectID lexical units only. No image decoding, material
## building, Field, renderer, approval, save mutation or publication is invoked.
const ARTIFACT = preload("res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd")
const ARTIFACT_PATH := "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const ARTIFACT_SHA := "1c0cfd43dc1f63787b30882d81b35684967e772559701ce3388094bec6c6b4a3"
const REPORT := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const KEYS: Array[String] = ["world_node_instance_id", "viewport_instance_id", "world_3d_instance_id"]
const EXPECTED := {
	"primary":{"world_node_instance_id":"928182701131", "viewport_instance_id":"928115591784", "world_3d_instance_id":"-9223371108688851939"},
	"reference":{"world_node_instance_id":"2258850810955", "viewport_instance_id":"2258783702186", "world_3d_instance_id":"-9223369778020742319"},
}
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _fixture(a: String = "-9223371108688851939", b: String = "-9223369778020742319") -> String:
	return '{"worlds":{"primary":{"world_node_instance_id":11,"viewport_instance_id":12,"world_3d_instance_id":%s},"reference":{"world_node_instance_id":21,"viewport_instance_id":22,"world_3d_instance_id":%s}}}' % [a,b]

func _read(text: String, worlds_override: Dictionary = {}) -> Dictionary:
	var decoder: JSON = JSON.new()
	if decoder.parse(text) != OK: return {}
	var parsed: Variant = decoder.data
	if not parsed is Dictionary or not parsed.get("worlds") is Dictionary: return {}
	var worlds: Dictionary = worlds_override if not worlds_override.is_empty() else parsed.worlds
	return ARTIFACT.ActualObjectIDTokens.new().read(worlds,text)

func _run() -> void:
	_check(FileAccess.get_sha256(ARTIFACT_PATH).to_lower() == ARTIFACT_SHA, "literal NEW E QA implementation SHA")
	var fixture: String = _fixture()
	var good: Dictionary = _read(fixture)
	_check(good.size() == 2 and good.primary.world_3d_instance_id == EXPECTED.primary.world_3d_instance_id and good.reference.world_3d_instance_id == EXPECTED.reference.world_3d_instance_id, "both actual negative RefCounted IDs retain exact decimal tokens")
	_check(_read(_fixture("9223372036854775807","-9223372036854775808")).size() == 2, "exact signed int64 inclusive endpoints legal only as World3D")
	_check(_read(_fixture("1","-1")).size() == 2, "positive and negative nonzero World3D IDs accepted")
	for token: String in ["0","-0","0.0","-0.0","1.0","-1.0","1e3","-1E3",'"1"','"-1"',"true","false","null","+1","01","-01","9223372036854775808","-9223372036854775809","999999999999999999999999","-999999999999999999999999"]:
		_check(_read(_fixture(token)).is_empty(), "malformed/noncanonical/zero/overflow World3D refused: " + token)
	for identity: String in ["primary","reference"]:
		for key: String in KEYS:
			var parsed: Dictionary = JSON.parse_string(fixture)
			parsed.worlds[identity].erase(key)
			_check(_read(JSON.stringify(parsed)).is_empty(), "missing ID refused: " + identity + "/" + key)
			for bad: Variant in ["11",true,null,INF,NAN]:
				var changed: Dictionary = JSON.parse_string(fixture).worlds.duplicate(true)
				changed[identity][key] = bad
				_check(_read(fixture,changed).is_empty(), "parsed ID token type/binding refused: " + identity + "/" + key + "/" + str(bad))
			var mismatched: Dictionary = JSON.parse_string(fixture).worlds.duplicate(true)
			mismatched[identity][key] = 123.0
			_check(_read(fixture,mismatched).is_empty(), "parsed number not associated with own exact token refused: " + identity + "/" + key)
	for key: String in KEYS:
		var duplicated: String = fixture.replace('"'+key+'":', '"'+key+'":42,"'+key+'":')
		_check(_read(duplicated).is_empty(), "duplicate raw ID property refused despite JSON last-key-wins: " + key)
		var escaped_key: String = key.replace("world","wor\\u006cd").replace("viewport","view\\u0070ort")
		var escaped: String = fixture.replace('"'+key+'":', '"'+escaped_key+'":')
		_check(_read(escaped).size() == 2, "escaped property spelling decoded at exact scope: " + key)
		_check(_read(fixture.replace('"'+key+'":', '"'+escaped_key+'":42,"'+key+'":')).is_empty(), "escaped duplicate property refused: " + key)
	for pair: Array in [["world_node_instance_id",11],["viewport_instance_id",12]]:
		for token: String in ["-1","0","1.0","1e2",'"1"',"9223372036854775808"]:
			_check(_read(fixture.replace('"%s":%d'%pair,'"%s":%s'%[pair[0],token])).is_empty(), "Node/Viewport still positive canonical int64: " + pair[0] + "/" + token)
		_check(_read(fixture.replace('"%s":%d'%[pair[0],int(pair[1])+10], '"%s":%d'%pair)).is_empty(), "duplicate exact Node/Viewport identity refused: " + pair[0])
	_check(_read(fixture.replace('"primary":', '"primary":{},"primary":')).is_empty(), "duplicate raw primary object refused")
	_check(_read(fixture.replace('"reference":', '"reference":{},"reference":')).is_empty(), "duplicate raw reference object refused")
	_check(_read('{"worlds":{},'+fixture.substr(1)).is_empty(), "duplicate raw root worlds object refused")
	_check(_read(fixture.replace('"worlds":', '"nested":{"worlds":')).is_empty(), "wrong nested worlds path does not supply root identity")
	var noise: String = fixture.replace('"worlds":', '"noise":{"worlds":{"primary":{"world_3d_instance_id":0}}},"message":"quoted \\"worlds\\" { [] }","worlds":')
	_check(_read(noise).size() == 2, "nested decoy and escaped quoted braces do not confuse direct-member scope")
	var near: String = _fixture("-9223372036854775808","-9223372036854775807")
	var near_parsed: Dictionary = JSON.parse_string(near)
	_check(near_parsed.worlds.primary.world_3d_instance_id == near_parsed.worlds.reference.world_3d_instance_id, "fixture actually reproduces Float64 adjacent-ID merge")
	var exact_near: Dictionary = _read(near)
	_check(exact_near.size() == 2 and exact_near.primary.world_3d_instance_id != exact_near.reference.world_3d_instance_id, "exact distinct adjacent64 tokens accepted despite merged doubles")
	_check(_read(_fixture("-9223372036854775808","-9223372036854775808")).is_empty(), "same exact64 token refused, never str(parsedFloat64) uniqueness")
	_check(FileAccess.get_sha256(REPORT).to_lower() == REPORT_SHA, "literal actual CDD74 capture report unchanged before read")
	if errors.is_empty():
		var raw: String = FileAccess.get_file_as_string(REPORT)
		var parsed: Variant = JSON.parse_string(raw)
		_check(parsed is Dictionary and parsed.get("worlds") is Dictionary, "actual complete capture report parses")
		if parsed is Dictionary and parsed.get("worlds") is Dictionary:
			var exact: Dictionary = ARTIFACT.ActualObjectIDTokens.new().read(parsed.worlds,raw)
			_check(exact == EXPECTED, "all six actual ObjectIDs exactly bound to immutable original tokens")
			for identity: String in ["primary","reference"]:
				for key: String in KEYS: _check(exact.get(identity,{}).get(key) == EXPECTED[identity][key], "actual token " + identity + "/" + key)
	_check(FileAccess.get_sha256(REPORT).to_lower() == REPORT_SHA, "actual capture bytes unchanged after read")
	print("V9E_QA_OBJECT_ID_LEXICAL_UNITS ",JSON.stringify({"scope":"CPU_RAW_OBJECT_ID_UNITS_NOT_ARTIFACT_RENDER_FIELD_OR_RELEASE_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"Field_executed":false,"GPU_executed":false,"production_written":false,"actual_capture_sha256":REPORT_SHA}))
	quit(0 if errors.is_empty() else 1)
