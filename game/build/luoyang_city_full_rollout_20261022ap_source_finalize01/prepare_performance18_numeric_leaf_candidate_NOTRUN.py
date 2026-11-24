"""NEW numeric-leaf-only symmetric success candidate and typed-record key draft."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance18_numeric_leaf_candidate01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
oldpath=S+'performance11_symmetric_wire_candidate01/Bundle_symmetric_record_wire_READY.gd'
oldsha='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
old=fixed(oldpath,oldsha);new=old;hunks=[]
def replace(a,b):
    global new
    aa,bb=a.encode(),b.encode();assert new.count(aa)==1;hunks.append({'old':a,'new':b});new=new.replace(aa,bb,1)
anchor='static func _symmetric_record_wire_equal(left: Variant,right: Variant) -> bool:\n'
helper='''static func _numeric_leaf_record_wire_success(left: Variant,right: Variant,depth: int=0) -> bool:
	# Only a sufficient whole-tree success condition; never replace the fallback.
	if depth>=64: return false
	var left_type: int=typeof(left);var right_type: int=typeof(right)
	if left_type in [TYPE_INT,TYPE_FLOAT] and right_type in [TYPE_INT,TYPE_FLOAT]:
		if (left_type==TYPE_FLOAT and not is_finite(left)) or (right_type==TYPE_FLOAT and not is_finite(right)): return false
		if left_type==right_type and left==right: return true
		# Exact old JSON writer/parser semantics at this finite numeric leaf,
		# not an epsilon, implicit coercion, or native geometry normalization.
		return equal(_wire(left),_wire(right))
	if left_type!=right_type: return false
	if left is Dictionary:
		if left.size()!=right.size(): return false
		for key: Variant in right:
			if typeof(key)!=TYPE_STRING: return false
		for key: Variant in left:
			if typeof(key)!=TYPE_STRING or not right.has(key) or not _numeric_leaf_record_wire_success(left[key],right[key],depth+1): return false
		return true
	if left is Array:
		if left.size()!=right.size(): return false
		for index: int in left.size():
			if not _numeric_leaf_record_wire_success(left[index],right[index],depth+1): return false
		return true
	match left_type:
		TYPE_NIL,TYPE_BOOL,TYPE_STRING: return left==right
	return false
'''
replace(anchor,helper+anchor)
replace('if _strict_record_json_equal(left,right): return true\n\treturn equal(_wire(left),_wire(right))','if _numeric_leaf_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))')
back=new
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
candidate=O+'Bundle_numeric_leaf_wire_CANDIDATE.gd'
fixture={'status':'PENDING_ROOT_ONE_TYPED_T_PACKET_DIAGNOSTIC_NOT_FIELD_OR_FORMAL','ready':False,
 'source_sha256':{oldpath:oldsha,candidate:sha(new),
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/packet.bin':'04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df',
 'res://build/luoyang_yamen_annex_publication_20261016/84632_1726/manifest.json':'b606f4913456fc967a7a650c979d3f20ced97bb41a4f8bd3da4a6a445670aee3'},
 'old_bundle_path':oldpath,'candidate_path':candidate,
 'T_packet_path':'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/packet.bin',
 'JSON_parent_path':'res://build/luoyang_yamen_annex_publication_20261016/84632_1726/manifest.json',
 'allowed_binary_decode_count':1,'ordinary_tiny_cases':True,'large_pairs':2,'source_collector_Field_Scene_ResourceLoader_geometry_image_calls':0,
 'blocker':'Root and QA must read and freeze a NEW ready fixture/key; sole future typed-domain diagnostic, not a rerun of JSON-only21760 or Field05.'}
fp=O+'typed_packet_comparison_fixture_PENDING_ROOT.json';fb=js(fixture)
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
func strict_first_rejection(old: Variant,left: Variant,right: Variant,path: Array=[],depth: int=0) -> Dictionary:
	var fact: Dictionary={"path":path,"depth":depth,"left_type":typeof(left),"right_type":typeof(right)}
	if depth>=64: fact.reason="DEPTH_LIMIT";return fact
	if typeof(left)!=typeof(right):
		fact.reason="TYPE_MISMATCH"
		if typeof(left) in [TYPE_INT,TYPE_FLOAT] and typeof(right) in [TYPE_INT,TYPE_FLOAT]:
			fact.left_value=var_to_str(left);fact.right_value=var_to_str(right);fact.old_numeric_leaf_wire_equal=old.equal(old._wire(left),old._wire(right))
		return fact
	if left is Dictionary:
		if left.size()!=right.size(): fact.reason="DICTIONARY_SIZE";return fact
		for k: Variant in right:
			if typeof(k)!=TYPE_STRING: fact.reason="RIGHT_NONSTRING_KEY";fact.key_type=typeof(k);return fact
		for k: Variant in left:
			if typeof(k)!=TYPE_STRING or not right.has(k): fact.reason="LEFT_KEY_OR_MISSING";fact.key_type=typeof(k);return fact
			var failure: Dictionary=strict_first_rejection(old,left[k],right[k],path+[k],depth+1)
			if not failure.is_empty(): return failure
		return {}
	if left is Array:
		if left.size()!=right.size(): fact.reason="ARRAY_SIZE";return fact
		for index: int in left.size():
			var failure: Dictionary=strict_first_rejection(old,left[index],right[index],path+[index],depth+1)
			if not failure.is_empty(): return failure
		return {}
	match typeof(left):
		TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_INT:
			if left==right: return {}
			fact.reason="STRICT_SCALAR_VALUE"
		TYPE_FLOAT:
			if is_finite(left) and is_finite(right) and left==right: return {}
			fact.reason="FINITE_FLOAT_VALUE_VARIANT" if is_finite(left) and is_finite(right) else "NONFINITE_FLOAT"
			fact.left_value=var_to_str(left);fact.right_value=var_to_str(right);fact.old_numeric_leaf_wire_equal=old.equal(old._wire(left),old._wire(right))
		_: fact.reason="UNSUPPORTED_VARIANT"
	return fact
func compare_case(old: Variant,candidate: Variant,label: String,left: Variant,right: Variant) -> void:
	var before: int=Time.get_ticks_usec()
	var baseline: bool=old.equal(old._wire(left),old._wire(right))
	var baseline_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var deployed: bool=old._symmetric_record_wire_equal(left,right)
	var deployed_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var proposed: bool=candidate._symmetric_record_wire_equal(left,right)
	var proposed_usec: int=Time.get_ticks_usec()-before
	var strict: bool=old._strict_record_json_equal(left,right)
	var numeric: bool=candidate._numeric_leaf_record_wire_success(left,right)
	var failure: Dictionary=strict_first_rejection(old,left,right)
	check(baseline==deployed and baseline==proposed,label+": old-wire/deployed7123/numeric results exactly same")
	check(strict==failure.is_empty(),label+": diagnostic follows deployed strict rejection")
	rows.append({"label":label,"old_wire":baseline,"deployed7123":deployed,"numeric_candidate":proposed,"deployed_strict_success":strict,"numeric_leaf_whole_success":numeric,"first_deployed_strict_rejection":failure,"old_wire_wall_usec":baseline_usec,"deployed_wall_usec":deployed_usec,"numeric_candidate_wall_usec":proposed_usec})
func nested(levels: int) -> Variant:
	var value: Variant="leaf"
	for index: int in levels: value={"next":value}
	return value
func finish() -> void:
	var root: String="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance18_numeric_leaf_candidate01/output/%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root)
	var file: FileAccess=FileAccess.open(root+"/result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify({"status":"ONE_TYPED_T_PACKET_TWO_SYMMETRIC_PAIRS_NOT_FIELD_OR_LOADING_CREDIT","passed":errors.is_empty(),"checks":checks,"errors":errors,"rows":rows,"binary_packet_decodes":1 if not rows.is_empty() else 0,"Field_Scene_ResourceLoader_geometry_image_collector_calls":0,"fixed_order_cache_bias_no_performance_pass_claim":true},"  ",true,true)+"\\n")
	file.close();print("TYPED_PAIR_RESULT "+root+"/result.json");quit(0 if errors.is_empty() else 1)
func _run() -> void:
	if not check(FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"Fixed fixture SHA"): finish();return
	var fixture: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(fixture is Dictionary and fixture.get("ready")==true,"Root frozen ready fixture required"): finish();return
	for path: String in fixture.source_sha256:
		if not check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source before "+path): finish();return
	var old: Variant=load(fixture.old_bundle_path)
	var candidate: Variant=load(fixture.candidate_path)
	if not check(old is GDScript and candidate is GDScript,"Two fixed pure scripts"): finish();return
	compare_case(old,candidate,"tiny integer versus float",{"a":4},{"a":4.0})
	compare_case(old,candidate,"tiny finite float writer variant",{"a":245.75999450683594},{"a":245.7599945068359})
	compare_case(old,candidate,"tiny different finite numbers",{"a":4},{"a":5.0})
	compare_case(old,candidate,"tiny Vector2 excluded",{"a":Vector2(1,2)},{"a":Vector2(1,2)})
	compare_case(old,candidate,"tiny packed excluded",{"a":PackedInt32Array([1,2])},{"a":PackedInt32Array([1,2])})
	compare_case(old,candidate,"tiny nonString key excluded",{4:"x"},{4:"x"})
	compare_case(old,candidate,"tiny nonfinite excluded",{"a":INF},{"a":INF})
	check(not candidate._numeric_leaf_record_wire_success(nested(64),nested(64)),"Depth64 remains old full fallback")
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(fixture.T_packet_path))
	var publication: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture.JSON_parent_path))
	if not check(packet is Dictionary and packet.get("record") is Dictionary and packet.get("t_parent_record") is Dictionary and old._plain(packet) and packet.get("scene_id")=="ch4_s1_luoyang_yamen" and publication is Dictionary and publication.get("record") is Dictionary,"Fixed native T and JSON parent domains"): finish();return
	var current_t: Dictionary=packet.record.duplicate(true)
	var child_t: Dictionary=packet.record.duplicate(true)
	# Actual DT Yamen strips these two runtime receipts before B. Adapter maps
	# both independent copies of frozen T with the same missing-key condition.
	for k: String in ["annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		current_t.erase(k)
	for k: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not current_t.has(k): child_t.erase(k)
	compare_case(old,candidate,"actual pair1 independent native T current/child",current_t,child_t)
	var prior: Dictionary=packet.t_parent_record.duplicate(true)
	var expected: Dictionary=publication.record.duplicate(true)
	for k: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not expected.has(k): prior.erase(k)
	compare_case(old,candidate,"actual pair2 native prior versus JSON expected",prior,expected)
	for path: String in fixture.source_sha256:
		check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source after "+path)
	finish()
'''.replace('@FIXTURE@',fp).replace('@SHA@',sha(fb)).encode()
keypath=O+'test_typed_packet_comparison_PENDING_ROOT.gd'
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldpath,tofile=candidate)).encode()
proof={'status':'BUILD_ONLY_NUMERIC_LEAF_SYMMETRIC_SUCCESS_NOT_PARSED_OR_RUN','parent':{'path':oldpath,'sha256':oldsha},'candidate':{'path':candidate,'sha256':sha(new)},'whole_byte_inverse':back==old,'hunks':hunks,
 'design_boundary':['Only String-key dictionaries with identical keyset and ordinary arrays with identical size/order recurse; depth>=64 refuses success.',
 'Only null/bool/String and finite int/float scalar domains are admitted. Equal typed finite scalars return true; unequal or cross-type finite numbers execute exactly equal(_wire(left),_wire(right)) at that leaf.',
 'Each accepted structure has matching keys and slots and each corresponding parsed JSON leaf is equal under the original two-sided writer/parser. Thus parsed whole JSON trees agree. No one-sided round-trip claim, epsilon or geometry normalization.',
 'Any mismatch, nonString key, Object, Vector, packed array, NaN/INF, unsupported type or depth limit returns false to the unchanged full-tree original fallback. Cycles never gain new success credit.',
 'The existing strict helper is preserved byte-for-byte for deployed7123 diagnostics. Only the symmetric wrapper success predicate changes; DT non-symmetric final wire and all source/owner/whole inverse gates are untouched.',
 'Actual typed packet strict-failure paths and candidate hit counts are not yet observed. The pending test decodes exactly one pinned T packet only after Root approval; no JSON-only replay or Field loading pass is inferred.'],
 'test_draft':{'key':{'path':keypath,'sha256':sha(key)},'fixture':{'path':fp,'sha256':sha(fb)},'ready':False},'diff':{'path':O+'complete_vs_7123.diff','sha256':sha(diff)},'engine_parse_collector_Stage_formal_writes':0}
files={'Bundle_numeric_leaf_wire_CANDIDATE.gd':new,'complete_vs_7123.diff':diff,'typed_packet_comparison_fixture_PENDING_ROOT.json':fb,'test_typed_packet_comparison_PENDING_ROOT.gd':key,'whole_byte_inverse_and_design_READY.json':js(proof)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
