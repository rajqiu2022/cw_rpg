"""Independent B-only success-path proof and pending pure-key scope review."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def get(p,h):
    b=p.read_bytes();assert sha(b)==h;return b
proof=json.loads(get(D/'whole_byte_inverse_and_design_READY.json','2d84e87ef942a910f07aa5c416bf01bbbda9e74097af1a9674d6ede977ebe0e4'))
parent=get(res(proof['parent']['path']),proof['parent']['sha256']);candidate=get(res(proof['candidate']['path']),proof['candidate']['sha256']);text=candidate.decode()
assert proof['parent']['sha256']=='77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16' and len(proof['hunks'])==2
forward=parent.decode()
for h in proof['hunks']:assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'],1)
assert forward.encode()==candidate
back=text
for h in reversed(proof['hunks']):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent
start=text.index('static func _strict_record_json_equal(');end=text.index('static func restore_parent_record(',start);helpers=text[start:end]
assert helpers.count('static func ')==2
assert 'if depth>=64 or typeof(left)!=typeof(right): return false'in helpers
assert 'for key: Variant in right:\n\t\t\tif typeof(key)!=TYPE_STRING: return false'in helpers
assert 'if typeof(key)!=TYPE_STRING or not right.has(key) or not _strict_record_json_equal(left[key],right[key],depth+1): return false'in helpers
assert 'if left.size()!=right.size(): return false'in helpers and '_strict_record_json_equal(left[index],right[index],depth+1)'in helpers
assert 'TYPE_NIL,TYPE_BOOL,TYPE_STRING,TYPE_INT: return left==right'in helpers
assert 'TYPE_FLOAT: return is_finite(left) and is_finite(right) and left==right'in helpers
assert '\n\treturn false\nstatic func _symmetric_record_wire_equal'in helpers
assert '\tif _strict_record_json_equal(left,right): return true\n\treturn equal(_wire(left),_wire(right))'in helpers
for bad in ['await ','FileAccess','ResourceLoader','load(','.erase(','.append(','.clear(','.duplicate(','_scene_sessions','_transition_validation'] :assert bad not in helpers
assert text.count('_symmetric_record_wire_equal(')==3
assert proof['hunks'][1]['old']=='if not equal(_wire(current),_wire(child)) or not equal(_wire(prior),_wire(expected)): return {}'
get(res(proof['diff']['path']),proof['diff']['sha256'])
kp=D/'test_pure_record_comparison_PENDING_ROOT.gd';key=get(kp,'c25f6c5dcf8474999e9de4e2388dec94f0767b07724eabf10cb2aebe4df85123').decode()
fp=D/'pure_record_comparison_fixture_PENDING_ROOT.json';fixture=json.loads(get(fp,'621ca879dafc115c1f1b7d6029b7543dd5bfe0b2d1816cdf8fc79a7005f63321'))
assert fixture['ready'] is False and fixture['large_pair_passes']==1 and fixture['depth_boundary']==64
assert len(fixture['source_sha256'])==3 and fixture['source_sha256'][proof['parent']['path']]==proof['parent']['sha256']and fixture['source_sha256'][proof['candidate']['path']]==proof['candidate']['sha256']
assert fixture['parent_manifest_path']=='res://build/luoyang_yamen_annex_publication_20261016/84632_1726/manifest.json'
assert fixture['source_sha256'][fixture['parent_manifest_path']]=='b606f4913456fc967a7a650c979d3f20ced97bb41a4f8bd3da4a6a445670aee3'
assert key.count('compare_case(old,candidate,')==9 and 'nested(63),nested(63)'in key and 'nested(64),nested(64)'in key
assert 'var right: Dictionary=left.duplicate(true)'in key and key.count('JSON.parse_string(FileAccess.get_file_as_string(fixture.parent_manifest_path))')==1
assert key.index('var old_result: bool=old.equal(old._wire(left),old._wire(right))')<key.index('var new_result: bool=candidate._symmetric_record_wire_equal(left,right)')
assert 'check(new_result==old_result'in key and 'check(strict_result==strict_expected'in key
for bad in ['go_field','source_paths(','.instantiate(','.new(','.restore_parent_record(','.materialize(','.get_image(','.compile(','.validation_'] :assert bad not in key
assert 'raw.get("ready")==true'in key and 'Fixed source before 'in key and 'Fixed source after 'in key
out=QA/'symmetric_wire7123_and_pending_purekey_C25F_independent_static_review_READY.json'
r={'status':'B_ONLY_SYMMETRIC_FAST_SUCCESS_NO_STATIC_BLOCKER_PENDING_ROOT_TEST_FREEZE','candidate_sha256':sha(candidate),'parent_sha256':sha(parent),'whole_byte_forward_inverse':True,'only_added_private_functions':2,'only_replaced_symmetric_predicate_pairs':2,'strict_success_domain':['both String-key Dictionaries with exact sizes/keysets recursively','same-size Arrays recursively','null/bool/String/int strict typeof and equal value','finite float strict typeof and equal value'],'failure_exact_old_fallback':True,'depth64_or_unknown_or_nonfinite_false_to_original_fallback':True,'mutation_alias_cache_IO_or_owner_proof_changes':False,'negative_tiny_cases':8,'strict_depth_boundaries':[63,64],'large_fixed_manifest_pair_count':1,'large_pair_independent_deepcopy':True,'test_order':'old first then candidate; record-only observation biased, not Field loading evidence','pending_fixture_ready':False,'deterministic_json_proof_note':'Same finite strict tree gives equivalent parsed JSON on both sides. Signed zero may stringify differently but parses to numerically equal same-type floats; literal JSON byte identity is not required for old equal(_wire,left/right) truth.','test_scope_limits':['No engine run or parse by QA. Root must freeze NEW ready key/fixture before one execution.','Key has no internal wall timeout; Root external bounded process timeout is necessary if a process stalls.','Unknown types/cycles/depth rejection enters the unchanged old serializer behavior, not an expanded accepted strict domain.','No whole_bound, record-copy, asymmetric DT, adapter/G/T/FIRST/FINAL changes.','No measured performance saving or production/deployment approval.'],'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
