"""Isolated art registration and city-life authoring utilities for Redrock."""
import json
import os
import re
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

from build_redrock_town_20261028a import ROOT, save, sha

NAME = 'redrock_city_life_20261029a'
D = 'redrock_desert_complete_20261028d'
B = 'redrock_luoyang_standard_20261028b'
STAGE = ROOT / 'assets/staging' / NAME
RAW = ROOT / 'assets/raw' / NAME
PROJECT = STAGE / 'town_project'
SCENE = f'scenes/drafts/{D}/redrock_town.tscn'
ART = f'art/modules/{NAME}'
PROMPT = '''Use case: stylized-concept
Asset type: ONE seamless native ground material texture for a 2.5D hand-painted realistic wuxia RPG red sandstone canyon town.
Primary request: a flat FULL FRAME edge-to-edge orthographic top-down texture of weathered modest red-ochre sandstone paving. Small irregular rectangular flagstones laid in offset rows, worn softened edges, narrow dusty joints, dry tawny sand settled into a few joints. Restrained matte painted texture, fine mineral grain, softly mottled rose sandstone and warm pale ochre. The stones are practical small street slabs, not giant temple blocks or polished marble. About 12 to 16 stones across the image, only subtle low contrast variation so it can tile over streets without a large repeating feature. Match warm natural red sandstone masonry and dark timber desert settlement, with medium-light sandstone paving a little lighter than red dirt. Broad completely even diffuse light, no directional cast shadows or bright highlights.
Composition: square full-bleed surface, EXACT straight down view with no perspective, horizon, visible thickness, border, pavement island, bevel at image edges or transparency. Seamless left/right and top/bottom edges, joints and stone courses must flow across opposite edges. All four image corners occupied by the same paving material. No central motif, cracks forming one large pattern, footprints, wheel tracks, rubble piles, vegetation, objects, people, animals, buildings, letters, text, watermark or diagram. One continuous low-contrast texture only, not a scene or contact sheet. Do not imitate a photographic wet glossy floor.
'''


def prepare():
    assert not STAGE.exists()
    queue = STAGE / 'production/prompts'
    (queue / 'templates').mkdir(parents=True)
    template = 'redrock_sandstone_paving_20261029a'
    (queue / 'templates' / (template + '.yaml')).write_text(yaml.safe_dump({
        'name': template, 'prompt_template': '{asset_prompt}', 'size': '1024x1024',
        'quality': 'high', 'background': 'opaque',
    }, allow_unicode=True, sort_keys=False), 'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR = queue / 'templates'
    assert renderer.render_template(template, {'asset_prompt': PROMPT}, {})['prompt'] == PROMPT.strip()
    (queue / 'sandstone_paving.txt').write_text(PROMPT, 'utf-8')
    (queue / 'tasks.yaml').write_text(yaml.safe_dump({'tasks': [{
        'id': NAME + '_sandstone_paving_v1', 'template': template, 'skip': True,
        'execution_backend': 'builtin_image_gen', 'attempt_budget': 1,
        'retries_allowed': False, 'cli_fallback_allowed': False,
        'transparent_background': False, 'vars': {'asset_prompt': PROMPT},
    }]}, allow_unicode=True, sort_keys=False), 'utf-8')
    save(STAGE / 'preflight.json', {'passed': True, 'rendered': 1, 'builtin_only': True,
         'root_queue_written': False, 'prompt_sha256': sha(queue / 'sandstone_paving.txt')})
    protected = [ROOT / 'game/project.godot', ROOT / 'prompts/tasks.yaml', ROOT / 'scripts/gen_assets.py',
                 ROOT / 'game/scripts/autoload/scene_router.gd', ROOT / 'game/scripts/field/player.gd']
    for rel in [f'game/art/modules/{D}', f'game/art/modules/{B}', f'game/scripts/drafts/{D}',
                f'game/scripts/drafts/{B}', f'game/scenes/drafts/{D}']:
        protected += [p for p in (ROOT / rel).rglob('*') if p.is_file() and p != ROOT / 'game' / SCENE]
    protected += [p for p in (Path(os.environ['APPDATA']) / 'Godot/app_userdata/云影侠传').rglob('save*') if p.is_file()]
    save(STAGE / 'protected-before.json', [{'path': str(p), 'sha256': sha(p), 'bytes': p.stat().st_size,
         'mtime_ns': p.stat().st_mtime_ns} for p in sorted(set(protected))])
    save(STAGE / 'scene-before.json', {'path': 'game/' + SCENE, 'sha256': sha(ROOT / 'game' / SCENE)})
    shutil.copyfile(ROOT / 'game' / SCENE, STAGE / 'scene-before.tscn')
    save(RAW / 'manifest.json', {'status': 'DISPATCHED', 'calls': 1, 'model': None, 'provider': None,
         'cost': None, 'backend': 'builtin_image_gen', 'prompt': str(queue / 'sandstone_paving.txt'),
         'fallback_used': False})
    print(PROMPT)


def record(source):
    source = Path(source)
    manifest = json.loads((RAW / 'manifest.json').read_text('utf-8'))
    assert manifest['status'] == 'DISPATCHED'
    dest = RAW / 'ground' / (NAME + '_sandstone_paving_v1.png')
    dest.parent.mkdir(parents=True)
    shutil.copyfile(source, dest)
    with Image.open(dest) as im:
        size, mode = list(im.size), im.mode
    manifest.update(status='RAW_CANDIDATE', output=dest.relative_to(ROOT).as_posix(),
                    sha256=sha(dest), size=size, mode=mode, source_path=str(source),
                    original_pixels_changed=False)
    assert sha(dest) == sha(source)
    save(RAW / 'manifest.json', manifest)
    save(dest.with_suffix('.meta.json'), manifest)
    print(json.dumps({'saved': str(dest), 'size': size, 'mode': mode}))


if __name__ == '__main__':
    {'prepare': prepare, 'record': lambda: record(sys.argv[2])}[sys.argv[1]]()
