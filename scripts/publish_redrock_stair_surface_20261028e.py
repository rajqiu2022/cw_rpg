"""Publish the tested three-stair scene correction, preserving all native media."""
import json
import shutil
from pathlib import Path

from build_redrock_town_20261028a import ROOT, sha, save

STAGE = ROOT / 'assets/staging/redrock_stair_surface_20261028e'
PRIVATE = ROOT / 'assets/staging/redrock_desert_complete_20261028d/town_project'


def main():
    candidate = json.loads((STAGE / 'candidate.json').read_text('utf-8'))
    target = ROOT / candidate['target']
    source = PRIVATE / Path(candidate['target']).relative_to('game')
    report = json.loads((PRIVATE / 'artifacts/stairs_20261028e/verification.json').read_text('utf-8'))
    assert report['passed'] and report['failed'] == 0 and len(report['checks']) == 41
    assert report['real_input_physics_ticks'] == 357
    assert sha(target) == candidate['before_sha256']
    assert sha(source) == candidate['candidate_sha256']
    assert source.read_bytes().endswith(b'\n') and not source.read_bytes().endswith(b'\n\n')
    protected = json.loads((STAGE / 'protected-before.json').read_text('utf-8'))
    for row in protected:
        path = Path(row['path'])
        assert sha(path) == row['sha256'] and path.stat().st_size == row['bytes']
        assert path.stat().st_mtime_ns == row['mtime_ns']
    assert not (STAGE / 'publication.json').exists()
    shutil.copyfile(source, target)
    assert sha(target) == candidate['candidate_sha256']
    save(STAGE / 'publication.json', {
        **candidate, 'production_scene_written': True,
        'published_sha256': sha(target), 'changed_production_files': [candidate['target']],
        'checks': 41, 'failed': 0, 'real_input_physics_ticks': 357,
        'protected_paths': len(protected), 'protected_sha_bytes_mtime_unchanged': True,
        'native_media_changed': False, 'shared_player_router_project_changed': False,
        'scope': 'three stair surface draw layers, original UV side overlays and aligned collision polygons',
    })
    print('Published one scene; 41 checks passed; five protected paths exact.')


if __name__ == '__main__':
    main()
