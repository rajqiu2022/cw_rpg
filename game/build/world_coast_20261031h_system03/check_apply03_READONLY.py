"""Bounded Root pre/post apply gate. No writes, engine, or user-save APIs.

Run --phase before before Root applies SOURCE_SUCCESSORS_REVIEW_ONLY.patch and
installs the two NEW exact snapshot copies. Run --phase after once, afterwards.
The independently reconstructed patch must equal the sealed bytes and all 37
current targets must match the chosen phase, never a mixed partial deployment.
"""
from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SEALED = HERE / 'sealed_candidate03'


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def disk(uri: str) -> Path:
    assert uri.startswith('res://') and '..' not in uri.split('/'), uri
    result = (REPO / 'game' / uri[6:]).resolve()
    assert result.is_relative_to(REPO / 'game'), uri
    return result


def patch_for(path: str, before: bytes, after: bytes) -> str:
    rows = list(difflib.unified_diff(before.decode().splitlines(),
                                   after.decode().splitlines(), n=3, lineterm=''))
    assert len(rows) > 2
    return ('*** Update File: ' + path + '\n' +
            ''.join(('@@' if line.startswith('@@') else line) + '\n'
                    for line in rows[2:]))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase', choices=['before', 'after'], required=True)
    parser.add_argument('--receipt-sha', required=True)
    args = parser.parse_args()
    receipt_bytes = (SEALED / 'receipt_REVIEW_ONLY.json').read_bytes()
    assert digest(receipt_bytes) == args.receipt_sha, 'ROOT_EXACT_RECEIPT_REQUIRED'
    receipt = json.loads(receipt_bytes)
    assert receipt['target_count'] == 37 and len(receipt['targets']) == 37
    assert receipt['status'] == 'ROOT_REVIEW_ONLY_NOT_APPLIED_NOT_ACTUAL_COLLECTOR'
    assert receipt['actual_C_collector_B_describe_pending'] is True
    expectation = (HERE / 'SourceExpected03_ROOT_APPROVED.json').read_bytes()
    assert digest(expectation) == receipt['source_expected_sha256']
    expected = json.loads(expectation)
    assert expected['status'] == 'ROOT_APPROVED_EXACT_CANDIDATE_INPUTS'
    assert expected['approved_by'] == 'root'
    assert expected['art02_approved'] is True
    assert expected['full_resolution_component02_passed'] is True
    before_all, after_all, patch_parts = {}, {}, []
    for row in receipt['targets']:
        path = row['path']
        assert path.startswith('game/'), path
        uri = 'res://' + path[5:]
        assert uri not in before_all, 'DUPLICATE_TARGET'
        before = (SEALED / 'before' / path).read_bytes()
        after = (SEALED / 'copies' / path).read_bytes()
        assert digest(before) == row['before_sha256'] == expected['old_sources'][uri]
        assert digest(after) == row['candidate_sha256']
        assert len(before) == row['before_bytes'] and len(after) == row['candidate_bytes']
        assert before != after
        current = disk(uri).read_bytes()
        assert current == (before if args.phase == 'before' else after), ('WRONG_PHASE', uri)
        before_all[uri], after_all[uri] = before, after
        patch_parts.append(patch_for(path, before, after))
    assert set(before_all) == set(expected['old_sources'])
    patch = ('*** Begin Patch\n' + ''.join(patch_parts) + '*** End Patch\n').encode()
    assert patch == (SEALED / 'SOURCE_SUCCESSORS_REVIEW_ONLY.patch').read_bytes()
    assert digest(patch) == receipt['patch_sha256']
    for uri, pin in expected['new_artifact_sha256'].items():
        assert digest(disk(uri).read_bytes()) == pin, ('ARTIFACT_CHANGED', uri)
    canonical = 'res://data/scenes/world_map_jianghu.tres'
    private = disk('res://build/world_coast_20261031h_system01/world_v16_scene03.tres').read_bytes()
    assert b'[sub_resource' not in private
    assert private.count(b'scene_id = &"world_map_jianghu_v16"') == 1
    assert private.replace(b'scene_id = &"world_map_jianghu_v16"',
                           b'scene_id = &"world_map_jianghu"', 1) == after_all[canonical]
    assert len(after_all[canonical]) < 2048, 'THIN_SCENE_REQUIRED'
    assert digest(after_all[canonical]) == expected['canonical_candidate_sha256']
    snapshot_count = 0
    for source, snapshot in expected['snapshot_paths'].items():
        stored = (SEALED / 'new_snapshots' / ('game/' + snapshot[6:])).read_bytes()
        assert stored == after_all[source]
        assert digest(stored) == receipt['new_snapshot_pins'][snapshot]
        if args.phase == 'before':
            assert not disk(snapshot).exists(), ('NEW_SNAPSHOT_ALREADY_EXISTS', snapshot)
        else:
            assert disk(snapshot).read_bytes() == stored, ('SNAPSHOT_MISSING_OR_DIFFERENT', snapshot)
        snapshot_count += 1
    assert snapshot_count == 2
    ex_uri = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
    old_ex, new_ex = json.loads(before_all[ex_uri]), json.loads(after_all[ex_uri])
    assert set(old_ex['source_sha256']).issubset(new_ex['source_sha256'])
    assert set(old_ex['owned']) == set(new_ex['owned'])
    edges = []
    for uri, old_owned in old_ex['owned'].items():
        new_owned = new_ex['owned'][uri]
        if uri not in expected['snapshot_paths']:
            assert new_owned == old_owned
            continue
        assert new_owned['edges'][:-1] == old_owned['edges']
        edge = new_owned['edges'][-1]
        assert edge['old_sha256'] == digest(before_all[uri])
        assert edge['new_sha256'] == digest(after_all[uri]) == new_owned['current_sha256']
        assert edge['whole_inverse'] is True
        assert edge['old_snapshot'] == old_owned['edges'][-1]['new_snapshot']
        assert edge['new_snapshot'] == expected['snapshot_paths'][uri]
        assert disk(edge['old_snapshot']).read_bytes() == before_all[uri]
        inverse = after_all[uri].decode()
        for change in edge['replacements']:
            assert inverse.count(change['new']) == 1
            inverse = inverse.replace(change['new'], change['old'], 1)
        assert inverse.encode() == before_all[uri], ('WHOLE_INVERSE_FAILED', uri)
        edges.append(uri)
    assert len(edges) == 2
    for uri, member, old_count, new_count in [
        ('res://build/three_towns_world_20261029j_system01/native_sources.json', 'sources', 226, 228),
        ('res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json', 'runtime_modules', 567, 569),
    ]:
        old_map, new_map = json.loads(before_all[uri])[member], json.loads(after_all[uri])[member]
        assert len(old_map) == old_count and len(new_map) == new_count
        assert set(new_map) - set(old_map) == set(expected['approved_new_code_keys'])
        for path, pin in old_map.items():
            wanted = digest(after_all[path]) if path in after_all and pin == digest(before_all[path]) else pin
            assert new_map[path] == wanted, ('ACTIVE_PIN_WRONG', uri, path)
    print(json.dumps({'status': 'BOUNDED_EXACT_SOURCE_PHASE_PASS_NOT_ENGINE_OR_C_COLLECTOR',
                      'phase': args.phase, 'old_targets': 37, 'snapshots': snapshot_count,
                      'patch_bytes': len(patch), 'patch_sha256': digest(patch),
                      'canonical_bytes': len(after_all[canonical]), 'old_EX_edges_preserved': True,
                      'source_writes': 0, 'engine_runs': 0, 'real_save_API_calls': 0}, indent=2))


if __name__ == '__main__':
    main()
