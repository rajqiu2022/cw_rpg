"""Canonical-key sufficient condition and corrected complete-domain probe audit."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def pin(r):
    b=res(r['path']).read_bytes();assert sha(b)==r['sha256'];return b
def reverse_literals(b,rows):
    s=b.decode()
    for r in reversed(rows):assert s.count(r['new'])==1;s=s.replace(r['new'],r['old'],1)
    return s.encode()
def offset_transform(b,rows,reverse=False):
    chunks=[];cursor=0
    for r in rows:
        a='new'if reverse else'old';z='old'if reverse else'new';start=r[a+'_byte_start'];end=r[a+'_byte_end'];assert start>=cursor and b[start:end]==r[a].encode()
        chunks += [b[cursor:start],r[z].encode()];cursor=end
    return b''.join(chunks+[b[cursor:]])
def func(t,name,static=False):
    marker=('static 'if static else'')+'func ';a=t.index(marker+name+'(');b=t.find('\n'+marker,a+1);return t[a:b if b>=0 else len(t)]
hp=SF/'performance22_canonical_probe_retry1/handoff_PENDING_ROOT_NOT_RUN.json';hb=hp.read_bytes();assert sha(hb)=='63de05f7406906539c0189a161c24fb95ec96e0ea3a7d7383b977865220324d9';h=json.loads(hb)
candidate=pin(h['candidate_unchanged']);proof=json.loads(pin(h['candidate_inverse_math']));parent=pin(proof['parent_numeric']);strict=pin(proof['parent_strict'])
assert reverse_literals(candidate,proof['hunks'])==parent
np=json.loads(pin(proof['numeric_parent_inverse']));assert reverse_literals(parent,np['hunks'])==strict
text=candidate.decode();helper=func(text,'_canonical_keys_record_wire_success',True)
assert func(text,'_strict_record_json_equal',True)==func(strict.decode(),'_strict_record_json_equal',True)
assert func(text,'_numeric_leaf_record_wire_success',True)==func(parent.decode(),'_numeric_leaf_record_wire_success',True)
assert 'if depth>=64: return false'in helper and 'TYPE_STRING,TYPE_STRING_NAME'in helper
assert helper.count('return equal(_wire(left),_wire(right))')==2
assert 'if left_index.has(canonical): return false'in helper and 'if right_index.has(canonical): return false'in helper
assert 'left_index[canonical]=left[key]'in helper and 'right_index[canonical]=right[key]'in helper
assert '_canonical_keys_record_wire_success(left_index[key],right_index[key],depth+1)'in helper
assert helper.index('if all_string:')<helper.index('return true',helper.index('if all_string:'))<helper.index('var left_index: Dictionary={};var right_index: Dictionary={}')
for bad in ['await ','FileAccess','ResourceLoader','load(','.erase(','.clear(','.duplicate(','_scene_sessions','_transition_validation']:assert bad not in helper
assert 'if _canonical_keys_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))'in func(text,'_symmetric_record_wire_equal',True)
key=pin(h['pending_key']);beforekey=pin(h['parent_probe']);kt=key.decode();bt=beforekey.decode()
assert offset_transform(beforekey,h['hunks'])==key and offset_transform(key,h['hunks'],True)==beforekey
assert func(kt,'compare_case')==func(bt,'compare_case')
assert kt[kt.index('\tpacket_decodes+=1'):]==bt[bt.index('\tpacket_decodes+=1'):]
diagnostic=func(kt,'diagnose');scan=func(kt,'scan_unique_canonical_children')
assert 'if not ok: return false'not in diagnostic and 'path+[String(k)]'not in diagnostic
assert diagnostic.count('String(k)')==2 and diagnostic.count('path+[str(k)]')==6
assert 'left_seen: Dictionary={};var right_seen: Dictionary={};var ambiguous: Dictionary={}'in diagnostic
assert 'ambiguous[c]=true;li.erase(c);ok=false'in diagnostic and 'ambiguous[c]=true;ri.erase(c);ok=false'in diagnostic
assert 'for c: String in ambiguous:\n\t\tli.erase(c);ri.erase(c);ok=false'in scan
assert scan.index('var child_ok: bool=diagnose(')<scan.index('ok=child_ok and ok')
assert 'return scan_unique_canonical_children(old,li,ri,ambiguous,out,path,depth,ok)'in diagnostic
assert 'if li.size()!=ri.size():\n\t\trejection('in scan and 'MISSING_LEFT_CANON_KEY'in scan and 'MISSING_RIGHT_CANON_KEY'in scan
assert 'Mixed badkey numeric diagnostic rejects'in kt and 'Canonical scanner retains both badkey and valid sibling Vector rejection'in kt
assert 'and not has_rejection(excluded,"UNSUPPORTED_VARIANT",["dup"])'in kt and 'synthetic_index_unit_only_not_actual_Dictionary_collision_credit'in kt
assert 'collision_runtime_coverage_claim":false'in kt and 'ordinary_Dictionary_merged_String_StringName_keys'in kt
assert kt.count('bytes_to_var(')==1 and kt.count('packet_decodes+=1')==1
assert 'diagnostic_scans_excluded_from_timed_wall":true'in kt and 'canonical_keys_whole_success":canonical'in kt
assert kt.index('var proposed_usec: int=Time.get_ticks_usec()-before')<kt.index('var numeric_diagnosed: bool=diagnose(')
assert 'check(baseline,label+": independently reconstructed old complete inverse must accept")'in kt
f=json.loads(pin(h['pending_fixture']));assert not f['ready']and f['allowed_binary_decode_count']==1 and f['large_pairs']==2 and len(f['source_sha256'])==4
assert f['source_sha256'][f['candidate_path']]==sha(candidate)and f['source_sha256'][f['T_packet_path']]=='04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'and f['source_sha256'][f['JSON_parent_path']]=='b606f4913456fc967a7a650c979d3f20ced97bb41a4f8bd3da4a6a445670aee3'
pin(h['complete_diff'])
out=QA/'canonical9D5B_probeA590_independent_static_review_READY.json'
r={'status':'CANONICAL_CANDIDATE_AND_CORRECTED_TYPED_DIAGNOSTIC_NO_STATIC_BLOCKER_PENDING_ROOT','candidate_sha256':sha(candidate),'candidate_whole_byte_inverse3F00_then7123':True,'old_strict_numeric_helpers_unchanged':True,'StringName_key_canonicalization_per_side_injective_no_case_Unicode_normalization':True,'allString_path_no_canonical_index_map_allocation':True,'String_or_Name_scalar_cross_representation_uses_original_leaf_wire':True,'numeric_finite_leaf_old_wire_and_whole_fallback_unchanged':True,'unknown_Vector_Packed_Object_nonfinite_depth64_not_new_fast_domain':True,'candidate_mutation_alias_cache_source_or_owner_delta':False,'key_sha256':sha(key),'probe_full_forward_inverse_E7C3':True,'timed_comparison_and_actual_pair_decode_tail_bytes_unchanged':True,'bad_keys_no_longer_hide_unique_valid_siblings':True,'collision_name_removed_both_indexes_seen_names_prevent_reentry':True,'unsupported_key_diagnostic_str_not_String':True,'new_mixed_key_and_vector_sibling_and_synthetic_ambiguity_negative_controls':True,'ordinary_dictionary_collision_runtime_claim_if_construction_merges':False,'fast_hit_separate_from_semantic_pass':True,'rejection_reason_type_count_firstpath_outside_timers':True,'coverage_boundary':'Only uniquely paired key/index child domains are scanned. Unsupported key values and both sides of ambiguous canonical names are intentionally not guessed; array shape rejection is at its container. Counts are rejecting-domain occurrences, not executed fast-helper branch counts.','pending_ready':False,'Root_new_ready_freeze_and_external_wallbound_required':True,'QA_engine_parse_typeddecode_parentJSONparse_collector_formalwrite':0,'blocking_findings':[],'not_promoted_or_measured':'9D5B has not been executed or admitted. Previous3F002 rejection and123820 slow results remain.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
