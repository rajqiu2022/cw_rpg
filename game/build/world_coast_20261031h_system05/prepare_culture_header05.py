"""NEW-only exact CT C-source header succession; no production or engine writes."""
import copy, importlib.util, json, re
from pathlib import Path

OWN = Path(__file__).resolve().parent
REPO = OWN.parents[2]
spec = importlib.util.spec_from_file_location('accepted04', REPO / 'game/build/world_coast_20261031h_system04/prepare_culture_successor04.py')
h04 = importlib.util.module_from_spec(spec); spec.loader.exec_module(h04)
h = h04.helpers
sha, read, disk = h.sha, h.read, h.disk
COORD, EX, EI, REGION, ROUTER = h04.COORD, h.EX, h.EI, h.REGION, h.ROUTER
CT = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
CT_OLD = '68ea5e81652f46e1ec162e8081aa302cd113836e6c5fb6ea95cfbf6d4bb5258d'
C_CURRENT = '55ef5dae43eed15e040058cb2d0f218fd2fd94e32a6607c6aca9029fe614bc71'
SNAPSHOT = 'res://build/luoyang_world_coast_20261031h_snapshot05/luoyang_cultural_sidequests_coordinator_20261019x.gd'
PRIOR04 = REPO / 'game/build/world_coast_20261031h_system04/sealed_candidate04/receipt_REVIEW_ONLY.json'
PRIOR04_SHA = '8ff79f44ba5d7b6060878c249d53086be095f1b4cb84f48e535b19ec69d8a3a0'


def approved_exact(ex, path, historical):
    """Static mirror of existing authority traversal, not new runtime policy."""
    row = ex['owned'][path]; current = row['current_sha256']
    assert sha(read(path)) == current
    visited, frontier = set(), [current]
    validated = 0
    for _ in range(len(row['edges'])):
        if not frontier: break
        following = []
        for current in frontier:
            if current == historical: return validated
            if current in visited: continue
            visited.add(current)
            for edge in row['edges']:
                if edge['new_sha256'] != current: continue
                assert edge['path'] == path and edge['whole_inverse'] is True
                old_path, new_path = edge['old_snapshot'], edge['new_snapshot']
                assert old_path != path and (new_path == path or new_path.startswith('res://build/luoyang_'))
                assert ex['source_sha256'][old_path] == edge['old_sha256']
                assert new_path == path or ex['source_sha256'][new_path] == current
                old, new = read(old_path), read(new_path)
                assert sha(old) == edge['old_sha256'] and sha(new) == current
                inverse = new.decode()
                for replacement in edge['replacements']:
                    assert set(replacement) == {'old', 'new'} and replacement['old'] != replacement['new'] and replacement['new']
                    assert inverse.count(replacement['new']) == 1
                    inverse = inverse.replace(replacement['new'], replacement['old'])
                assert inverse.encode() == old
                if 'navigation_source' in edge:
                    assert edge['navigation_source'] and new.decode().count(edge['navigation_source']) == old.decode().count(edge['navigation_source']) == 1
                validated += 1
                if edge['old_sha256'] == historical: return validated
                following.append(edge['old_sha256'])
        frontier = following
    raise AssertionError(('EX_HISTORICAL_NOT_APPROVED', path, historical))


def main():
    raw04 = PRIOR04.read_bytes(); assert sha(raw04) == PRIOR04_SHA
    r04 = json.loads(raw04)
    targets = list(r04['all_38_before_pins']) + [CT]
    assert len(targets) == len(set(targets)) == 39
    before = {p: read(p) for p in targets}; old_sha = {p: sha(b) for p, b in before.items()}
    pins04 = dict(r04['all_38_before_pins'])
    pins04.update({h.resource(row['path']): row['candidate_sha256'] for row in r04['targets']})
    assert all(old_sha[p] == digest for p, digest in pins04.items())
    assert old_sha[CT] == CT_OLD and old_sha[h.C] == C_CURRENT
    ct = json.loads(before[CT]); assert ct['source_sha256'][h.C] == 'f1c8da74c69bf6660b2d9c9637b54e15d2679dfa7a2d75b1e0ed3f48a25374ab'
    after = {CT: h.map_update(before[CT], 'source_sha256', {h.C: C_CURRENT}, {h.C: ct['source_sha256'][h.C]})}
    ct_next = json.loads(after[CT]); expected = copy.deepcopy(ct); expected['source_sha256'][h.C] = C_CURRENT
    assert ct_next == expected
    assert before[COORD].count(CT_OLD.encode()) == 1
    after[COORD] = before[COORD].replace(CT_OLD.encode(), sha(after[CT]).encode(), 1)
    assert b'and path != FIELD)' in after[COORD]

    ex = json.loads(before[EX]); next_ex = copy.deepcopy(ex); row = next_ex['owned'][COORD]
    assert row['current_sha256'] == old_sha[COORD]
    previous = row['edges'][-1]['new_snapshot']; assert read(previous) == before[COORD]
    assert SNAPSHOT not in ex['source_sha256'] and not disk(SNAPSHOT).exists()
    replacements = h.hunks(before[COORD], after[COORD]); inverse = after[COORD].decode()
    for replacement in replacements:
        assert inverse.count(replacement['new']) == 1
        inverse = inverse.replace(replacement['new'], replacement['old'])
    assert inverse.encode() == before[COORD]
    row['current_sha256'] = sha(after[COORD])
    row['edges'].append({'path': COORD, 'old_sha256': old_sha[COORD], 'new_sha256': sha(after[COORD]), 'old_snapshot': previous, 'new_snapshot': SNAPSHOT, 'whole_inverse': True, 'replacements': replacements})
    text = before[EX].decode(); marker = '    ' + json.dumps(COORD) + ': '
    start = text.index(marker) + len(marker); _, used = json.JSONDecoder().raw_decode(text[start:])
    text = text[:start] + json.dumps(row, ensure_ascii=False, indent=2).replace('\n', '\n    ') + text[start + used:]
    snapshot_pins = {SNAPSHOT: sha(after[COORD])}
    after[EX] = h.map_update(text.encode(), 'source_sha256', {CT: sha(after[CT])}, old_sha, snapshot_pins)
    assert json.loads(after[EX])['owned'] == next_ex['owned']
    assert before[EI].count(old_sha[EX].encode()) == 1
    after[EI] = before[EI].replace(old_sha[EX].encode(), sha(after[EX]).encode(), 1)
    known = {p: sha(data) for p, data in after.items()}; pending = [p for p in targets if p not in after]
    for _ in targets:
        progress = False
        for p in list(pending):
            dependencies = {q for q, digest in old_sha.items() if q != p and digest.encode() in before[p]}
            if dependencies.intersection(pending): continue
            data = before[p]
            if p.endswith('.json'):
                for field in ['runtime_modules', 'sources', 'source_sha256', 'legacy_source_sha256']:
                    additions = snapshot_pins if field == 'legacy_source_sha256' and h.active_map(data, field) is not None else None
                    data = h.map_update(data, field, known, old_sha, additions)
            else:
                data = h.edit(data, [(old_sha[q], known[q]) for q in known if q in old_sha and known[q] != old_sha[q] and old_sha[q].encode() in data])
            after[p] = data; known[p] = sha(data); pending.remove(p); progress = True
        if not pending: break
        assert progress, ('SOURCE_PIN_CYCLE_OR_MISSING_ORDER', pending)
    assert not pending
    for p in [REGION, ROUTER, h.FIELD, h.NATIVE, h.C]: assert after[p] == before[p]
    # Every CT source must match actual/candidate bytes or the already-admitted
    # exact Router/Field historical proof. No other mismatches are tolerated.
    mismatches, accepted = [], {}
    for p, digest in ct_next['source_sha256'].items():
        actual = sha(after[p] if p in after else read(p))
        if actual != digest:
            mismatches.append(p); assert p in [ROUTER, h.FIELD]
            accepted[p] = {'historical_sha256': digest, 'current_sha256': actual, 'full_inverse_edges_validated': approved_exact(ex, p, digest)}
    assert set(mismatches) == {ROUTER, h.FIELD}
    wpath = 'res://scripts/city/luoyang_cultural_sidequests_candidate_20261019w.gd'
    wtext = read(wpath).decode(); wmanifest = re.search(r'^const MANIFEST := "([^"]+)"', wtext, re.M).group(1)
    wsha = re.search(r'^const MANIFEST_SHA := "([a-f0-9]{64})"', wtext, re.M).group(1)
    assert sha(read(wmanifest)) == wsha
    w = json.loads(read(wmanifest)); assert len(w['source_sha256']) == 24
    assert all(sha(read(p)) == digest for p, digest in w['source_sha256'].items())
    assert not any('field_walkable_controller' in p for p in w['source_sha256'])
    baseline = REPO / 'game/build/world_coast_20261031h_qa01/baseline_NOW_ACTUAL.json'
    baseline_raw = baseline.read_bytes(); baseline_data = json.loads(baseline_raw)
    baseline_ct = {p: fact for p, fact in baseline_data['facts'].items() if 'culture_integration_20261019x/runtime_contract.json' in p}
    changed = [p for p in targets if before[p] != after[p]]; out = OWN / 'sealed_candidate05'; assert not out.exists()
    records = []
    for p in changed:
        h.write_new(out, 'copies/game/' + p[6:], after[p]); h.write_new(out, 'before/game/' + p[6:], before[p])
        records.append({'path': 'game/' + p[6:], 'before_sha256': old_sha[p], 'candidate_sha256': sha(after[p]), 'before_bytes': len(before[p]), 'candidate_bytes': len(after[p])})
    h.write_new(out, 'new_snapshots/game/' + SNAPSHOT[6:], after[COORD])
    forward = '*** Begin Patch\n' + ''.join(h.whole_diff(before[p], after[p], p) for p in changed) + '*** End Patch\n'
    h.write_new(out, 'SOURCE_SUCCESSORS_REVIEW_ONLY.patch', forward.encode())
    receipt = {'status': 'ROOT_REVIEW_ONLY_NOT_APPLIED_NOT_ACTUAL_READINESS', 'scope': 'CT_EXACT_C_HEADER_SUCCESSION_NO_NEW_GUARD_EXCEPTION', 'prior04_receipt_sha256': PRIOR04_SHA, 'all_39_before_pins': old_sha, 'target_count': len(records), 'targets': records, 'new_snapshot_pins': snapshot_pins, 'EX_new_edges': 1, 'EX_old_edges_and_keys_preserved': True, 'ct_only_source_C_changed': True, 'ct_original_before_sha256': CT_OLD, 'baseline3221_sha256': sha(baseline_raw), 'CT_in_original3221_facts': bool(baseline_ct), 'original3221_CT_facts': baseline_ct, 'unchanged_region_router_field_native_C': True, 'CT_static_preflight': {'all_26_sources_accounted': len(ct_next['source_sha256']) == 26, 'remaining_direct_mismatches': mismatches, 'only_existing_exact_EX_admission': accepted, 'W_manifest_sha_exact': True, 'W_24_sources_exact': True, 'W_contains_no_Field': True}, 'patch_sha256': sha(forward.encode()), 'actual_culture_readiness_pending': True, 'actual_C_collector_B_describe_pending': True, 'engine_runs': 0, 'canonical_writes': 0, 'real_save_API_calls': 0}
    h.write_new(out, 'receipt_REVIEW_ONLY.json', h.encode(receipt))
    print(json.dumps({'target_count': len(records), 'out': str(out), 'patch_sha256': receipt['patch_sha256'], 'receipt_sha256': sha(h.encode(receipt)), 'CT_candidate_sha256': sha(after[CT]), 'Coordinator_candidate_sha256': sha(after[COORD]), 'CT_in_original3221_facts': bool(baseline_ct)}))


if __name__ == '__main__': main()
