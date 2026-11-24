"""Stage existing hero dependencies without importing the shared game project."""
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'assets/staging/redrock_luoyang_standard_20261028b'
PROJECT = STAGE / 'town_project'
NAME = 'redrock_luoyang_standard_20261028b'
SCRIPT = f'scripts/drafts/{NAME}/town_controller.gd'
SCENE = f'scenes/drafts/{NAME}/redrock_town.tscn'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    paths = ['scenes/player.tscn', 'scripts/field/player.gd',
             'art/characters/hero_idle_down_25d_runtime_4f.png',
             f'scripts/drafts/{NAME}/preview_player.gd']
    paths += [p.relative_to(ROOT / 'game').as_posix() for p in
              (ROOT / 'game/art/characters/weapon_variants/lengguyun/v7_idle_stable/sword').glob('*.png')]
    records = []
    for relative in paths:
        source = ROOT / 'game' / relative
        target = PROJECT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        records.append({'path': relative, 'sha256': digest(source)})
        sidecar = Path(str(source) + '.import')
        if sidecar.exists():
            shutil.copyfile(sidecar, Path(str(target) + '.import'))
            for resource in set(re.findall(r'res://(\.godot/imported/[^"\s]+)', sidecar.read_text('utf-8'))):
                leaf = ROOT / 'game' / resource
                destination = PROJECT / resource
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(leaf, destination)
                md5 = leaf.with_suffix('.md5')
                if md5.exists():
                    shutil.copyfile(md5, destination.with_suffix('.md5'))
    before = {relative: digest(PROJECT / relative) for relative in [SCRIPT, SCENE]}
    for relative in [SCRIPT, SCENE]:
        shutil.copyfile(ROOT / 'game' / relative, PROJECT / relative)
    shutil.copyfile(ROOT / 'game' / SCRIPT, STAGE / 'source/town_controller.gd')
    record = {'change': 'default follow camera and real existing Player with four direction animation',
              'previous_staged_sha256': before,
              'current_sha256': {p: digest(ROOT / 'game' / p) for p in [SCRIPT, SCENE]},
              'dependencies': records, 'shared_sources_modified': False,
              'production_import_invoked': False, 'images_modified': False}
    (STAGE / 'player-camera-delta-20261028c.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', 'utf-8')
    print(f'Staged {len(paths)} existing hero dependencies; no game-wide import')

if __name__ == '__main__':
    main()
