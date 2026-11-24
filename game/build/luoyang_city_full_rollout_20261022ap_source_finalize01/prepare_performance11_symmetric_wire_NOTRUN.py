"""NEW B-only symmetric JSON success path and NOTREADY pure-record key; no engine."""
import difflib
import hashlib
import json
from pathlib import Path

H=Path(__file__).resolve().parent
G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance11_symmetric_wire_candidate01/'
def p(v): return G/v.removeprefix('res://')
def sha(v): return hashlib.sha256(v).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN_CHANGED',v);return b
def js(v): return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()

oldpath='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
oldsha='77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16'
old=fixed(oldpath,oldsha)
new=old
hunks=[]
def replace(a,b):
    global new
    assert new.count(a)==1
    hunks.append({'old':a.decode(),'new':b.decode()})
    new=new.replace(a,b,1)

anchor=b'static func restore_parent_record(scene: SceneScript,current: Dictionary,expected: Dictionary) -> Dictionary:\n'
helper='''static func _strict_record_json_equal(left: Variant,right: Variant,depth: int=0) -> bool:
	# Success only: finite JSON-domain whole-tree strict equality. At the
	# conservative depth boundary, leave the original wire predicate in charge.
	if depth>=64 or typeof(left)!=typeof(right): return false
	if left is Dictionary:
		if left.size()!=right.size(): return false
		for key: Variant in right:
			if typeof(key)!=TYPE_STRING: return false
		for key: Variant in left:
			if typeof(key)!=TYPE_STRING or not right.has(key) or not _strict_record_json_equal(left[key],right[key],depth+1): return false
		return true
	if left is Array:
		if left.size()!=right.size(): return false
		for index: int in left.size():
			if not _strict_record_json_equal(left[index],right[index],depth+1): return false
		return true
	match typeof(left):
		TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_INT: return left==right
		TYPE_FLOAT: return is_finite(left) and is_finite(right) and left==right
	return false
static func _symmetric_record_wire_equal(left: Variant,right: Variant) -> bool:
	# Equivalent JSON trees produce the same sorted/full-precision JSON input
	# to both parses. This is NOT a one-sided round-trip stability assertion.
	if _strict_record_json_equal(left,right): return true
	return equal(_wire(left),_wire(right))
'''.encode()
replace(anchor,helper+anchor)
replace(b'if not equal(_wire(current),_wire(child)) or not equal(_wire(prior),_wire(expected)): return {}',
        b'if not _symmetric_record_wire_equal(current,child) or not _symmetric_record_wire_equal(prior,expected): return {}')
back=new
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
candidate=O+'Bundle_symmetric_record_wire_READY.gd'
parent='res://build/luoyang_yamen_annex_publication_20261016/84632_1726/manifest.json'
parentsha='b606f4913456fc967a7a650c979d3f20ced97bb41a4f8bd3da4a6a445670aee3'
parentbytes=fixed(parent,parentsha)
assert len(parentbytes)==23484239 and isinstance(json.loads(parentbytes)['record'],dict)
fixture={'status':'PENDING_ROOT_ONE_PURE_RECORD_COMPARISON_NOT_PARSE_OR_RUNTIME_CREDIT','ready':False,
 'source_sha256':{oldpath:oldsha,candidate:sha(new),parent:parentsha},
 'old_bundle_path':oldpath,'candidate_path':candidate,'parent_manifest_path':parent,
 'scope':{'tiny_record_cases':True,'one_fixed_Yamen_parent_record_pair':True,'Field':False,'collector':False,'geometry':False,'full_city_source_hash':False,'new_native_decode':False},
 'depth_boundary':64,'large_pair_passes':1,'speed_target_or_replay':False,'blocker':'Root must approve and freeze a NEW ready fixture/key before its only execution.'}
fixturepath=O+'pure_record_comparison_fixture_PENDING_ROOT.json';fixturebytes=js(fixture)
key='''extends SceneTree
const FIXTURE="@FIXTURE@"
const FIXTURE_SHA="@SHA@"
var checks: int=0
var errors: Array=[]
var rows: Array=[]
func check(value: bool,label: String) -> bool:
	checks+=1
	if not value: errors.append(label)
	return value
func _initialize() -> void: call_deferred("_run")
func nested(levels: int) -> Variant:
	var value: Variant="leaf"
	for index: int in levels: value={"next":value}
	return value
func compare_case(old: Variant,candidate: Variant,label: String,left: Variant,right: Variant,strict_expected: bool) -> void:
	var before: int=Time.get_ticks_usec()
	var old_result: bool=old.equal(old._wire(left),old._wire(right))
	var old_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var new_result: bool=candidate._symmetric_record_wire_equal(left,right)
	var new_usec: int=Time.get_ticks_usec()-before
	var strict_result: bool=candidate._strict_record_json_equal(left,right)
	check(new_result==old_result,label+": complete old/new result equality")
	check(strict_result==strict_expected,label+": strict domain/match branch")
	rows.append({"label":label,"old":old_result,"new":new_result,"strict_success":strict_result,"old_wall_usec":old_usec,"new_wall_usec":new_usec})
func finish() -> void:
	var root: String="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01/output/%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root)
	var file: FileAccess=FileAccess.open(root+"/result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify({"status":"ONE_PURE_RECORD_OLD_NEW_COMPARISON_NOT_FIELD_OR_LOADING_CREDIT","passed":errors.is_empty(),"checks":checks,"errors":errors,"rows":rows,"Field_requests":0,"collector_calls":0,"geometry_calls":0,"native_decode_calls":0,"order_bias_and_record_only_no_loading_speed_claim":true},"  ",true,true)+"\\n")
	file.close()
	print("PURE_RECORD_RESULT "+root+"/result.json")
	quit(0 if errors.is_empty() else 1)
func _run() -> void:
	if not check(FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"Exact fixture SHA"): finish();return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"Root frozen ready fixture required"): finish();return
	var fixture: Dictionary=raw
	for path: String in fixture.source_sha256:
		if not check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source before "+path): finish();return
	var old: Variant=load(fixture.old_bundle_path)
	var candidate: Variant=load(fixture.candidate_path)
	if not check(old is GDScript and candidate is GDScript,"Two fixed pure scripts loaded"): finish();return
	compare_case(old,candidate,"finite scalar nested exact",{"a":[null,true,"x",4,4.5]},{"a":[null,true,"x",4,4.5]},true)
	compare_case(old,candidate,"strict numeric type mismatch falls back",{"a":4},{"a":4.0},false)
	compare_case(old,candidate,"different value falls back",{"a":4},{"a":5},false)
	compare_case(old,candidate,"Vector2 excluded",{"a":Vector2(1,2)},{"a":Vector2(1,2)},false)
	compare_case(old,candidate,"nonString key excluded",{4:"x"},{4:"x"},false)
	compare_case(old,candidate,"StringName key excluded",{&"x":4},{&"x":4},false)
	compare_case(old,candidate,"nonfinite excluded",{"a":INF},{"a":INF},false)
	compare_case(old,candidate,"packed array excluded",{"a":PackedInt32Array([1,2])},{"a":PackedInt32Array([1,2])},false)
	check(candidate._strict_record_json_equal(nested(63),nested(63)),"63 levels remain in conservative domain")
	check(not candidate._strict_record_json_equal(nested(64),nested(64)),"64 levels fail closed to old fallback")
	var publication: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture.parent_manifest_path))
	if not check(publication is Dictionary and publication.get("record") is Dictionary,"Fixed Yamen publication record only"): finish();return
	var left: Dictionary=publication.record
	var right: Dictionary=left.duplicate(true)
	compare_case(old,candidate,"one fixed Yamen parent whole record",left,right,true)
	for path: String in fixture.source_sha256:
		check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source after "+path)
	finish()
'''.replace('@FIXTURE@',fixturepath).replace('@SHA@',sha(fixturebytes)).encode()
keypath=O+'test_pure_record_comparison_PENDING_ROOT.gd'
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldpath,tofile=candidate)).encode()
proof={'status':'BUILD_ONLY_B_SYMMETRIC_RECORD_SUCCESS_PATH_NOT_PARSED_OR_RUN',
 'parent':{'path':oldpath,'sha256':oldsha},'candidate':{'path':candidate,'sha256':sha(new)},
 'whole_byte_inverse':back==old,'hunks':hunks,'diff':{'path':O+'complete_vs_B77DFC.diff','sha256':sha(diff)},
 'design_proof':[
  'Strict success visits every Dictionary key and Array slot with identical typeof and values, rejects nonString keys on both sides, objects, vectors, packed arrays, nonfinite floats and depth>=64.',
  'Two admitted equal typed JSON trees feed identical sorted full_precision JSON to the two original parses, hence equal(_wire(left),_wire(right)) is true. No one-sided JSON round-trip property is inferred.',
  'If fast predicate fails for any reason, the original equal(_wire(left),_wire(right)) is executed unchanged, including all old accepted/rejected non-domain cases.',
  'Only the two symmetric predicates at final restore_parent_record gate use this helper. Existing short-circuit order, all copies, owner/whole_bound, source-FIRST/FINAL, other APIs and DT asymmetric final comparison remain unchanged.',
  'No cache, receipt, native, geometry or metadata DAG produced; expected benefit is unmeasured until separately Root-approved pure-record comparison.'],
 'comparison_draft':{'key':{'path':keypath,'sha256':sha(key)},'fixture':{'path':fixturepath,'sha256':sha(fixturebytes)},'ready':False},
 'code_runtime_or_parse_executions':0,'formal_writes':0}
files={'Bundle_symmetric_record_wire_READY.gd':new,'complete_vs_B77DFC.diff':diff,
       'pure_record_comparison_fixture_PENDING_ROOT.json':fixturebytes,'test_pure_record_comparison_PENDING_ROOT.gd':key,'whole_byte_inverse_and_design_READY.json':js(proof)}
assert not p(O).exists(),'NEW_OUTPUT_REQUIRED'
p(O).mkdir()
for name,b in files.items(): (p(O)/name).write_bytes(b)
assert fixed(oldpath,oldsha)==old
print(json.dumps({name:sha(b) for name,b in files.items()},indent=2))
