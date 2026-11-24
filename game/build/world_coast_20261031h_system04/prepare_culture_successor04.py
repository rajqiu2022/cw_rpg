"""NEW-only culture Field admission and exact current source closure.

Never writes canonical production sources or runs the engine. The 37 prior
sealed heads plus Coordinator are exact before-pins. Historical maps, inverse
edges, baseline receipts, saves, and sealed_candidate03 remain untouched.
"""
from __future__ import annotations
import copy, importlib.util, json
from pathlib import Path

OWN = Path(__file__).resolve().parent
REPO = OWN.parents[2]
PREPARE03 = REPO / 'game/build/world_coast_20261031h_system03/prepare_source_successors03.py'
PRIOR03 = REPO / 'game/build/world_coast_20261031h_system03/sealed_candidate03/receipt_REVIEW_ONLY.json'
spec = importlib.util.spec_from_file_location('pure_accepted03', PREPARE03)
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
sha, read, disk = helpers.sha, helpers.read, helpers.disk
COORD = 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
COORD_BEFORE_SHA = '2e57ca4fbb377925e70f86ca4c65f5138f946f123ac661cc31c1262953214c71'
EX, EI, REGION, ROUTER = helpers.EX, helpers.EI, helpers.REGION, helpers.ROUTER
SNAPSHOT = 'res://build/luoyang_world_coast_20261031h_snapshot04/luoyang_cultural_sidequests_coordinator_20261019x.gd'


def main():
    prior_raw = PRIOR03.read_bytes()
    prior = json.loads(prior_raw)
    targets = [helpers.resource(row['path']) for row in prior['targets']] + [COORD]
    assert len(targets) == len(set(targets)) == 38
    before = {p: read(p) for p in targets}
    old_sha = {p: sha(b) for p, b in before.items()}
    assert all(old_sha[helpers.resource(row['path'])] == row['candidate_sha256'] for row in prior['targets'])
    assert old_sha[COORD] == COORD_BEFORE_SHA
    old = '\t\t\tif path != "res://scripts/autoload/scene_router.gd" or not AP_NPC._source_matches(path, String(raw.source_sha256[path])): return _fail("CULTURE_X_SOURCE_CHANGED:" + path)'
    new = '\t\t\tif (path != "res://scripts/autoload/scene_router.gd" and path != FIELD) or not AP_NPC._source_matches(path, String(raw.source_sha256[path])): return _fail("CULTURE_X_SOURCE_CHANGED:" + path)'
    assert before[COORD].count(old.encode()) == 1
    after = {COORD: before[COORD].replace(old.encode(), new.encode(), 1)}
    assert helpers.edit(before[COORD], [(r['old'], r['new']) for r in helpers.hunks(before[COORD], after[COORD])]) == after[COORD]

    # Coordinator is already an explicitly OWNED executable. Retain its entire
    # original proof history and add one byte-exact whole-inverse edge.
    ex = json.loads(before[EX]); next_ex = copy.deepcopy(ex)
    row = next_ex['owned'][COORD]
    assert row['current_sha256'] == old_sha[COORD]
    previous = row['edges'][-1]['new_snapshot']
    assert read(previous) == before[COORD]
    assert SNAPSHOT not in ex['source_sha256'] and not disk(SNAPSHOT).exists()
    replacements = helpers.hunks(before[COORD], after[COORD])
    inverse = after[COORD].decode()
    for replacement in replacements:
        assert inverse.count(replacement['new']) == 1
        inverse = inverse.replace(replacement['new'], replacement['old'], 1)
    assert inverse.encode() == before[COORD]
    row['current_sha256'] = sha(after[COORD])
    row['edges'].append({'path': COORD, 'old_sha256': old_sha[COORD], 'new_sha256': sha(after[COORD]), 'old_snapshot': previous, 'new_snapshot': SNAPSHOT, 'whole_inverse': True, 'replacements': replacements})
    assert row['edges'][:-1] == ex['owned'][COORD]['edges']
    text = before[EX].decode()
    marker = '    ' + json.dumps(COORD) + ': '
    start = text.index(marker) + len(marker)
    _, used = json.JSONDecoder().raw_decode(text[start:])
    row_text = json.dumps(row, ensure_ascii=False, indent=2).replace('\n', '\n    ')
    text = text[:start] + row_text + text[start + used:]
    snapshot_pins = {SNAPSHOT: sha(after[COORD])}
    after[EX] = helpers.map_update(text.encode(), 'source_sha256', {}, old_sha, snapshot_pins)
    assert json.loads(after[EX])['owned'] == next_ex['owned']
    assert before[EI].count(old_sha[EX].encode()) == 1
    after[EI] = before[EI].replace(old_sha[EX].encode(), sha(after[EX]).encode(), 1)

    # No guessed Region/Router successor: first prove this exact Coordinator
    # current SHA is not a Region dependency. All remaining changes are finite
    # top-level runtime source maps or byte-exact dependent headers.
    assert old_sha[COORD].encode() not in before[REGION]
    known = {p: sha(data) for p, data in after.items()}
    pending = [p for p in targets if p not in after]
    for _ in targets:
        progress = False
        for p in list(pending):
            dependencies = {q for q, h in old_sha.items() if q != p and h.encode() in before[p]}
            if dependencies.intersection(pending):
                continue
            data = before[p]
            if p.endswith('.json'):
                for field in ['runtime_modules', 'sources', 'source_sha256', 'legacy_source_sha256']:
                    additions = snapshot_pins if field == 'legacy_source_sha256' and helpers.active_map(data, field) is not None else None
                    data = helpers.map_update(data, field, known, old_sha, additions)
            else:
                pairs = [(old_sha[q], known[q]) for q in known if q in old_sha and known[q] != old_sha[q] and old_sha[q].encode() in data]
                data = helpers.edit(data, pairs)
            after[p] = data; known[p] = sha(data); pending.remove(p); progress = True
        if not pending:
            break
        assert progress, ('SOURCE_PIN_CYCLE_OR_MISSING_ORDER', pending)
    assert not pending and set(after) == set(targets)
    assert after[REGION] == before[REGION] and after[ROUTER] == before[ROUTER]
    assert after[helpers.NATIVE] == before[helpers.NATIVE]
    assert after[helpers.FIELD] == before[helpers.FIELD]
    for p in targets:
        if p.endswith('.json'):
            a, b = json.loads(before[p]), json.loads(after[p])
            for field in ['runtime_modules', 'sources', 'source_sha256', 'legacy_source_sha256']:
                if field in a:
                    assert set(a[field]).issubset(b[field]), (p, field, 'OLD_KEY_REMOVED')

    changed = [p for p in targets if before[p] != after[p]]
    out = OWN / 'sealed_candidate04'
    assert not out.exists(), 'NO_OVERWRITE_SEALED_CANDIDATE'
    records = []
    for p in changed:
        helpers.write_new(out, 'copies/game/' + p[6:], after[p])
        helpers.write_new(out, 'before/game/' + p[6:], before[p])
        records.append({'path': 'game/' + p[6:], 'before_sha256': old_sha[p], 'candidate_sha256': sha(after[p]), 'before_bytes': len(before[p]), 'candidate_bytes': len(after[p])})
    helpers.write_new(out, 'new_snapshots/game/' + SNAPSHOT[6:], after[COORD])
    forward = '*** Begin Patch\n' + ''.join(helpers.whole_diff(before[p], after[p], p) for p in changed) + '*** End Patch\n'
    helpers.write_new(out, 'SOURCE_SUCCESSORS_REVIEW_ONLY.patch', forward.encode())
    receipt = {'status': 'ROOT_REVIEW_ONLY_NOT_APPLIED_NOT_ACTUAL_COLLECTOR', 'scope': 'NARROW_CULTURE_FIELD_EXACT_OWNED_SUCCESSION', 'prior03_receipt_sha256': sha(prior_raw), 'all_38_before_pins': old_sha, 'target_count': len(records), 'targets': records, 'new_snapshot_pins': snapshot_pins, 'EX_old_keys_preserved': True, 'EX_old_edges_preserved': True, 'EX_new_edges': 1, 'EX_new_edge_path': COORD, 'unchanged_region_router_field_native': True, 'patch_sha256': sha(forward.encode()), 'actual_culture_readiness_pending': True, 'actual_C_collector_B_describe_pending': True, 'engine_runs': 0, 'canonical_writes': 0, 'real_save_API_calls': 0}
    helpers.write_new(out, 'receipt_REVIEW_ONLY.json', helpers.encode(receipt))
    print(json.dumps({'status': receipt['status'], 'target_count': len(records), 'out': str(out), 'patch_sha256': receipt['patch_sha256']}))


if __name__ == '__main__':
    main()
