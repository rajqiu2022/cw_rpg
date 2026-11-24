"""Numeric-leaf sufficient-condition proof and unique typed-pair key scope."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def pin(row):
    b=res(row['path']).read_bytes();assert sha(b)==row['sha256'];return b
hp=SF/'performance19_typed_pair_key01/handoff_PENDING_ROOT_NOT_RUN.json';hb=hp.read_bytes();assert sha(hb)=='c4d5b2c53330ebe7348989d00ef23d7c5e2509193c08cc218a96018e9462f1d0';h=json.loads(hb)
proof=json.loads(pin(h['candidate_inverse_and_design']));before=pin(proof['parent']);candidate=pin(h['candidate']);assert candidate==pin(proof['candidate'])
text=candidate.decode();back=text
for row in reversed(proof['hunks']):assert back.count(row['new'])==1;back=back.replace(row['new'],row['old'],1)
assert back.encode()==before and proof['parent']['sha256']=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
forward=before.decode()
for row in proof['hunks']:assert forward.count(row['old'])==1;forward=forward.replace(row['old'],row['new'],1)
assert forward.encode()==candidate
def func(t,name):
    a=t.index('static func '+name+'(');b=t.find('\nstatic func ',a+1);return t[a:b if b>=0 else len(t)]
assert func(text,'_strict_record_json_equal')==func(before.decode(),'_strict_record_json_equal')
helper=func(text,'_numeric_leaf_record_wire_success');wrapper=func(text,'_symmetric_record_wire_equal')
assert 'if depth>=64: return false'in helper
assert 'left_type in [TYPE_INT,TYPE_FLOAT] and right_type in [TYPE_INT,TYPE_FLOAT]'in helper
assert '(left_type==TYPE_FLOAT and not is_finite(left)) or (right_type==TYPE_FLOAT and not is_finite(right))'in helper
assert 'if left_type==right_type and left==right: return true'in helper and 'return equal(_wire(left),_wire(right))'in helper
assert 'if left_type!=right_type: return false'in helper and 'if typeof(key)!=TYPE_STRING: return false'in helper
assert 'typeof(key)!=TYPE_STRING or not right.has(key)'in helper and 'TYPE_NIL,TYPE_BOOL,TYPE_STRING: return left==right'in helper
assert '_numeric_leaf_record_wire_success(left[key],right[key],depth+1)'in helper and '_numeric_leaf_record_wire_success(left[index],right[index],depth+1)'in helper
assert 'if _numeric_leaf_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))'in wrapper
for bad in ['await ','FileAccess','ResourceLoader','load(','.erase(','.append(','.duplicate(','_scene_sessions','_transition_validation']:assert bad not in helper
assert text.count('_numeric_leaf_record_wire_success(')==4
key=pin(h['pending_key']);fixture_raw=pin(h['pending_fixture']);f=json.loads(fixture_raw);keytext=key.decode()
oldkey=pin(h['key_parent']);backkey=keytext
for row in reversed(h['hunks']):assert backkey.count(row['new'])==1;backkey=backkey.replace(row['new'],row['old'],1)
assert backkey.encode()==oldkey
assert f['ready']is False and f['allowed_binary_decode_count']==1 and f['large_pairs']==2 and len(f['source_sha256'])==4
assert f['source_sha256'][f['T_packet_path']]=='04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'
assert f['source_sha256'][f['JSON_parent_path']]=='b606f4913456fc967a7a650c979d3f20ced97bb41a4f8bd3da4a6a445670aee3'
assert f['source_sha256'][f['candidate_path']]==sha(candidate) and f['source_sha256'][f['old_bundle_path']]==sha(before)
assert keytext.count('bytes_to_var(')==1 and 'bytes_to_var(FileAccess.get_file_as_bytes(fixture.T_packet_path))'in keytext
assert 'old._plain(packet)'in keytext and 'packet.get("scene_id")=="ch4_s1_luoyang_yamen"'in keytext
assert 'var current_t: Dictionary=packet.record.duplicate(true)'in keytext and 'var child_t: Dictionary=packet.record.duplicate(true)'in keytext
assert 'var prior: Dictionary=packet.t_parent_record.duplicate(true)'in keytext and 'var expected: Dictionary=publication.record.duplicate(true)'in keytext
receipts='["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]'
assert keytext.count(receipts)==2 and 'if not current_t.has(k): child_t.erase(k)'in keytext and 'if not expected.has(k): prior.erase(k)'in keytext
assert 'for k: String in ["annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:\n\t\tcurrent_t.erase(k)'in keytext
assert 'if label.begins_with("actual pair"):\n\t\tcheck(baseline,label+": independently reconstructed old complete inverse must accept")'in keytext
assert 'check(baseline==deployed and baseline==proposed'in keytext and 'check(strict==failure.is_empty()'in keytext
assert keytext.count('compare_case(old,candidate,')==9 and 'nested(64),nested(64)'in keytext
for bad in ['ResourceLoader','SceneScript','go_field','bytes_to_var_with_objects','instantiate(','.restore_parent_record(','.materialize(','.source_paths(','.get_image(','.compile(']:assert bad not in keytext
assert 'Fixed source before 'in keytext and 'Fixed source after 'in keytext and 'fixture.get("ready")==true'in keytext
pin(h['candidate_complete_diff']);pin(h['key_diff'])
out=QA/'numeric_leaf3F00_typedkeyC716_independent_static_review_READY.json'
r={'status':'NUMERIC_LEAF_ONLY_CANDIDATE_AND_TYPED_PAIR_DRAFT_NO_STATIC_BLOCKER_NOT_RUN','candidate_sha256':sha(candidate),'candidate_whole_byte_forward_inverse7123':True,'old_strict_helper_byte_unchanged':True,'only_numeric_leaf_unequal_or_crosstype_uses_exact_old_two_wire':True,'shape_Stringkeys_Array_order_recursion_and_depth64_fullfallback':True,'nonfinite_unknown_Vector_Packed_Object_not_fast_domain':True,'no_mutation_cache_alias_owner_or_FIRSTFINAL_delta':True,'mathematical_boundary':'For accepted finite JSON trees, equal parsed scalar leaves imply equal whole parsed structures under the same writer/parser; unlike epsilon/coercion the numeric leaf itself uses original equal(_wire(left),_wire(right)). Unsupported/mismatch returns false to unchanged original whole fallback. Signed zero does not need JSON byte identity.','typed_key_sha256':sha(key),'fixture_sha256':sha(fixture_raw),'pending_ready':False,'fixed_native_packet_SHA':'04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df','allowed_future_packet_decode':1,'binary_objects_decode_enabled':False,'actual_pairs':2,'independent_record_deepcopies_and_exact_B_DT_receipt_stripping':True,'actual_old_complete_wire_baseline_must_accept':True,'first_strict_rejection_diagnostic_tracks_path_type_depth':True,'numeric_and_strict_results_not_filled_before_actual':True,'Root_external_wall_bound_required':True,'QA_engine_parse_packet_decode_JSONparent_parse_collector_canonical_writes':0,'blocking_findings':[],'scope_limits':['This is a NEW typed-packet representation diagnostic, not a rerun of stopped JSON-only21760 or public Field05.','Timing order old-wire then deployed7123 then numeric candidate is fixed and biased, not loading speed or performance pass evidence.','18 design proof points to its original historical draft; final actual-baseline assertion is in the separately pinned19 successor audited here.','Root must freeze NEW ready key/fixture after this static review; no deployment or runtime pass is inferred.']}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
