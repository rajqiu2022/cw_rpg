"""Static bytes and finite component design only. Never compiles or runs GDScript."""
from pathlib import Path
import hashlib
import json
import re

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
S = GAME / 'build/luoyang_city_full_rollout_20261022ap_system01'
D = S / 'B_stringname_microbench_isolate_epoch01'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))

hp, fp, kp, pp = D/'handoff_NOTREADY.json', D/'project/fixture_NOTREADY.json', D/'project/probe_NOTREADY.gd', D/'project/project.godot'
h, f = rd(hp), rd(fp)
assert not h['ready'] and not f['ready']
for field, p in [('key', kp), ('fixture', fp), ('project', pp)]:
    assert sha(p) == h[field]['sha256'].lower() and p.stat().st_size == h[field]['bytes']
assert sha(kp) == '1bf7ad7c8732483a78769670a9df1e16c2d7b4b2b261b456604ac3563cea8a4e'
assert sha(fp) == '3b6b81b1ff89d6ba59f07b8c3717a004eed6d0e3dabbbf4c02ee92b47d7cedb0'
assert len(f['source_sha256']) == 6
for path, digest in f['source_sha256'].items():
    p = Path(path)
    assert p.stat().st_size < 1048576 and sha(p) == digest
proof = rd(Path(f['proof_path']))
assert len(proof['hunks']) == 1
parent = Path(f['module_paths']['parent']).read_bytes()
child = Path(f['module_paths']['candidate']).read_bytes()
old, new = (proof['hunks'][0][k].encode('utf-8') for k in ['old', 'new'])
assert parent.count(old) == 1 and child.count(new) == 1
assert parent.replace(old, new) == child and child.replace(new, old) == parent
assert hashlib.sha256(parent).hexdigest() == 'ade264af748e1beaf211d4a5e84d956deb50a312a29570c4e5a1fc73000c6703'
assert hashlib.sha256(child).hexdigest() == '22eca27bce7bd51468ef529882489130ad431669053108b6bf985d221c9ff810'
for role, value in [('parent', parent), ('candidate', child)]:
    text = value.decode('utf-8')
    combined = 'extends RefCounted\n'
    for name in f['function_order']:
        marker = 'static func ' + name + '('
        assert text.count(marker) == 1
        start = text.index(marker)
        end = text.find('\nstatic func ', start + len(marker))
        if end < 0: end = len(text)
        block = text[start:end] + '\n'
        assert hashlib.sha256(block.encode()).hexdigest() == f['function_sha256'][role][name]
        combined += block + '\n'
    assert len(combined.encode()) == f['pure_module_bytes'][role]
    assert hashlib.sha256(combined.encode()).hexdigest() == f['pure_module_sha256'][role]
assert all(f['function_sha256']['parent'][x] == f['function_sha256']['candidate'][x] for x in ['equal', '_wire', '_symmetric_record_wire_equal'])
assert new.index(b'if all_string:') < new.index(b'if all_string_name:') < new.index(b'var left_index:')
assert new.count(b'if typeof(key)!=TYPE_STRING_NAME: all_string_name=false') == 2
assert b'for key: StringName in left:' in new and b'if not right.has(key) or not _canonical_keys_record_wire_success(left[key],right[key],depth+1): return false' in new
assert old[old.index(b'\t\tvar left_index:'):] == new[new.index(b'\t\tvar left_index:'):]
k = kp.read_text(encoding='utf-8')
assert 'const FIXTURE_READY := false' in k and 'const WHOLE_MS := 15000' in k
assert 'const ROUNDS := 4' in k and 'const QUERIES := 128' in k
assert 'fixture.get("ready") == true' in k and 'root.get_child_count() == 0' in k
assert '[autoload]' not in pp.read_text() and 'run/main_scene' not in pp.read_text()
assert len(f['expected_boundary_case_ids']) == 10 and len(f['expected_negative_case_ids']) == 18
assert len(set(f['expected_boundary_case_ids'] + f['expected_negative_case_ids'])) == 28
reg = k[k.index('func regressions()'):k.index('func workload(')]
for case in f['expected_boundary_case_ids'] + f['expected_negative_case_ids']:
    assert reg.count('"' + case + '"') == 1
assert f['workload_modes'] == ['all_string', 'all_string_name', 'mixed']
assert f['rounds'] * len(f['workload_modes']) * 2 * f['queries_per_round_per_variant'] == f['expected_total_timed_comparisons'] == 3072
assert f['record_count'] == 16 and f['keys_per_record'] == 32
assert 'if bool(api.call("_symmetric_record_wire_equal", left, right)): true_count += 1' in k
assert '["parent", "candidate"] if round_index % 2 == 0 else ["candidate", "parent"]' in k
assert '"do_not_hide_all_String_regression": mode == "all_string"' in k
assert '"candidate_minus_parent_usec": new_total - old_total' in k
assert '"two_key_collision_exercised": duplicate_keys.size() == 2' in k
assert 'unsupported_full_JSON_not_invoked' in k
assert 'func reference(' in k and 'api.call("equal", api.call("_wire", left), api.call("_wire", right))' in k
assert k.count('script.reload()') == 1
assert re.search(r'^\s*(?:var\s+\w+.*?=\s*)?(?:preload|load)\(', k, re.M) is None
assert 'bytes_to_var' not in k and 'ResourceLoader.load' not in k
out = QA/'StringName22ECA_false_microbench_independent_static_review_NOT_RUNTIME_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status': 'STATIC_NO_BLOCKER_FOR_FALSE_COMPONENT_CANDIDATE_NOT_RUN_OR_READY',
    'pins': {'handoff': sha(hp), 'key': sha(kp), 'fixture': sha(fp), 'project': sha(pp), 'candidate': hashlib.sha256(child).hexdigest()},
    'wholebyte': {'one_complete_function_hunk_forward_and_inverse_exact': True, 'six_small_sources_current_exact': True,
        'four_function_extraction_blocks_and_combined_SHAbytes_exact': True, 'wrapper_equal_wire_and_all_outside_function_bytes_unchanged': True},
    'semantic_review': {'both_key_prepasses_before_success': True, 'only_both_wholly_StringName_domains_direct': True,
        'equal_size_plus_original_StringName_membership_injective_text_domain': True, 'recursive_value_sufficient_success_only': True,
        'allString_first_emptydict_old_branch': True, 'mixed_canon_indexes_and_collision_rejection_unchanged': True,
        'finite_numeric_and_scalar_leaf_old_codec_preserved': True, 'unknown_nonfinite_depth64_false_then_original_whole_fallback': True,
        'no_alias_cache_FRESHFIRSTFINAL_or_pair_dependency_change': True},
    'test_design': {'boundary_ids': 10, 'negative_groups': 18, 'modes': f['workload_modes'], 'rounds': 4, 'queries_each_block': 128,
        'total_timed_comparisons': 3072, 'same16x32shape_independent_left_right': True,
        'whole15s_includes_compile_construction_oracles_hashes': True, 'per_block_only_call_loop_and_accumulation': True,
        'role_order_alternates_allString_and_mixed_costs_retained': True, 'no_required_faster_threshold': True,
        'unsupported_native_nonfinite_boolVector_keys_fast_only': True, 'actual_StringName_String_key_merge_not_collision_credit': True,
        'independent_second_pair_and_depth63_64_boundaries': True},
    'limits': ['Still false; Root authorization and NEW mechanical READY successor required before any parse/run',
        'No parser/runtime pass claimed', 'Synthetic workload frequency is not actual Yamen/Market record evidence',
        'Four rounds and api.call overhead do not establish cold performance or game loading seconds',
        'Key protects six sources; 15save protection requires Root external before/after guard',
        'No actual restore_parent_record/whole_bound/FIRSTFINAL/DT runtime or source-DAG credit'],
    'operations': {'engine': 0, 'parse': 0, 'typed_decode': 0, 'collector': 0, 'canonical': 0, 'READY_freeze': 0}
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(out), 'sha256': sha(out), 'blocker': False, 'ready': False, 'executed': False}))
