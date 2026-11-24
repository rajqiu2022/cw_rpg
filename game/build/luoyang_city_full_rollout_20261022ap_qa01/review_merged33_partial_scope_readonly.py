import copy
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
DIR = SF / 'performance33_merged_code_dependencies'
OUT = QA / 'merged33_seven_stable_sources_scope29_partial_static_review_READY.json'
assert not OUT.exists()
res = lambda p: GAME / p.removeprefix('res://')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
scopefile = SF / 'performance32_merged_dependencies/exact29_existing_scope_PROPOSAL_NOT_APPROVED.json'
s = read(scopefile)
assert sha(scopefile) == 'c431b9725252268cffbe9fead091bc0230e491b85dfbcddd912bc21983983c4f'
assert len(s['targets']) == len({x['target'] for x in s['targets']}) == 29
assert sum(x['kind'] == 'GD' for x in s['targets']) == 15 and sum(x['kind'] == 'JSON' for x in s['targets']) == 14
for row in s['targets']:
    file = res(row['target'])
    assert sha(file) == row['old_sha256'] and file.read_bytes() == res(row['old_snapshot']).read_bytes()
proof = read(DIR / 'whole_code_and_binding_inverse_READY.json')
assert sha(DIR / 'whole_code_and_binding_inverse_READY.json') == 'dd23a47c22f2414d757e1313d2aef3c32666782d5e438374b41418b31ac2096c'
verified = {}
for name, row in proof['records'].items():
    if name == 'DT':
        continue
    a, b = res(row['parent']['path']), res(row['candidate']['path'])
    av, bv = a.read_bytes(), b.read_bytes()
    assert sha(a) == row['parent']['sha256'] and sha(b) == row['candidate']['sha256']
    forward = av
    for h in row['hunks']:
        old, new = h['old'].encode(), h['new'].encode()
        assert forward.count(old) == 1, (name, 'forward')
        forward = forward.replace(old, new)
    assert forward == bv
    for h in reversed(row['hunks']):
        old, new = h['old'].encode(), h['new'].encode()
        assert forward.count(new) == 1, (name, 'reverse')
        forward = forward.replace(new, old)
    assert forward == av
    verified[name] = {'parent': row['parent']['sha256'], 'candidate': row['candidate']['sha256'], 'hunks': len(row['hunks']), 'whole_forward_reverse': True}
oldbind = read(res(proof['records']['temple_binding']['parent']['path']))
newbind = read(res(proof['records']['temple_binding']['candidate']['path']))
assert set(oldbind) == set(newbind)
assert set(oldbind['source_delta']) == set(newbind['source_delta'])
delta = [p for p in oldbind['source_delta'] if oldbind['source_delta'][p] != newbind['source_delta'][p]]
assert delta == ['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd']
back = copy.deepcopy(newbind)
back['source_delta'][delta[0]] = oldbind['source_delta'][delta[0]]
assert back == oldbind
parentexec = read(SF / 'performance24_canonical_B_dependencies/execution_successor_PROPOSAL.json')
newexec = read(DIR / 'execution_successor_PROPOSAL.json')
assert sha(DIR / 'execution_successor_PROPOSAL.json') == '47c61614fba3c9daa678298621cee72deb4d5f2220ff14969bcc51d6e24c02ec'
assert set(parentexec['owned']) == set(newexec['owned']) and len(newexec['owned']) == 10
changed = []
back = copy.deepcopy(newexec)
for path, old in parentexec['owned'].items():
    new = newexec['owned'][path]
    if old == new:
        continue
    changed.append(path)
    assert new['edges'][:-1] == old['edges'] and len(new['edges']) == len(old['edges']) + 1
    assert new['edges'][-1]['old_sha256'] == old['current_sha256'] and new['edges'][-1]['new_sha256'] == new['current_sha256']
    back['owned'][path] = copy.deepcopy(old)
expected = {'res://scripts/city/' + p for p in ['luoyang_precomputed_bundle_20261018r.gd', 'luoyang_assembled_interiors_20261016g.gd', 'luoyang_district_life_20261016f.gd', 'luoyang_temple_assembly_20261016.gd']}
assert set(changed) == expected
assert len(parentexec['source_sha256']) == 71 and len(newexec['source_sha256']) == 80
assert all(newexec['source_sha256'].get(k) == v for k, v in parentexec['source_sha256'].items())
for path in set(newexec['source_sha256']) - set(parentexec['source_sha256']):
    del back['source_sha256'][path]
assert back == parentexec
parent_bytes = (SF / 'performance24_canonical_B_dependencies/execution_successor_PROPOSAL.json').read_bytes()
assert (json.dumps(back, ensure_ascii=False, indent=2) + '\n').encode() == parent_bytes
out = {
    'status': 'PARTIAL_STABLE_SOURCE_AND_SCOPE_REVIEW_ONLY_WAIT_FINAL_DT_AND_EXECUTION_NOT_STAGE_ADMISSION',
    'scope': {'sha256': sha(scopefile), 'unique_existing_targets': 29, 'GD': 15, 'JSON': 14, 'all29_current_old_SHA_and_snapshot_bytes_exact': True},
    'necessity': ['AP14 prior22 source/header targets retained; add exactly G,DT,C,Fade,Temple,existing finite adapter and registry7.', 'Canonical scripts contain old999A direct adapter pin in B,C,DT,Fade only; all four successors in scope. C single-source Temple189 binding successor requires Temple two literals. DT current declaration migrates only five AP room registry rows.', 'B Fade history gate needs exact source-only55DE->5846 history/path successor plus four city metadata rows; no fade behavior or native changes.', 'Family/ENV/Field/Router/Coordinator/runtime_contract/hash/adapter bindingDC21 remain non-targets; no geometry, room/native/quest or FIRST/FINAL weakening allowed.'],
    'stable_seven_records': verified,
    'B_Fade_gate': 'Whole same-owner/proof token/id/current-source and candidate SHA/describe checks preserved. prior_sha still firstF359; requires firstF359,BC295,3F2D and55DE in history; current_before exactly55DE, new exactly5846 and exact candidate path. No broad accepted history fallback.',
    'Temple': {'source_delta_only_C_changed': True, 'other188_merged_sources_unchanged_claim_supported_by_exact_one_literal_whole_byte_inverse': True, 'binding_EOL_preserved_by_literal_byte_replacement': True},
    'provisional47C6_structure': {'owned_members': 10, 'only_four_append_edges': changed, 'other_six_rows_same': True, 'old71_pins_whole_preserved_plus9': True, 'whole_typed_and_serialized_byte_inverse': True, 'final_authority_admission': False, 'reason': 'DT6F0A is being superseded with passive scalar subspans; old47C6/oldDD23 are not the final execution/driver authority.'},
    'next_actual_design': {'Root_decision': 'Keep original06 single default public Yamen entry,60s,0INPUT/0pictures/0geometry/0collector; only consume added passive DT subspans after frozen draw/natural proof. No warm key written.', 'warm_boundary': 'Menu exit plus same-city fresh rebuild is process-hot full rebuild, not user resident-room return. Real repeat-load lease should be a separately chosen existing hall roundtrip with exact original feet; not part of this check.', 'sameID_measurement_hazard_for_any_future_design': 'Old Yamen remains ready during next request. A future multi-leg observer must bind new generation/token and new Field/Scene before any ready clock, reset per-leg observations without resetting whole deadline, and never reuse old DT setup as fresh.'},
    'review_operations': {'engine': 0, 'collector': 0, 'packet_decode': 0, 'large_media_hash': 0, 'sourceStage': 0, 'canonical_writes': 0, 'new_test_key': 0},
    'local_review_note': 'Initial metadata inspection used platform default GBK and failed decoding UTF8 execution before output; corrected explicit UTF8 inspection and this complete readonly checker passed. No candidate changed.'
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT)}))
