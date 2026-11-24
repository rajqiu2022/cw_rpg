"""Retain the first failed revision, then adjust only its seven new placements."""
import json
import re
import shutil

from redrock_city_life_20261029a import STAGE, PROJECT, SCENE, ART
from build_redrock_town_20261028a import save, vec, sha

archive = STAGE / 'first-runtime-failure'
assert not archive.exists()
archive.mkdir()
for p in (PROJECT / 'artifacts').iterdir():
    if p.is_file():
        shutil.copyfile(p, archive / p.name)
for p in [PROJECT / SCENE, PROJECT / ART / 'ground.gdshader', PROJECT / 'life-layout.json', STAGE / 'runtime.stdout.log', STAGE / 'runtime.stderr.log']:
    shutil.copyfile(p, archive / p.name)

moved = {
    'LifeEastHome': [4900,1000], 'LifeEastJars': [5210,1060],
    'LifeWaterJars2': [1560,2310], 'LifeWorkBench': [4090,2335],
    'LifeWorkCargo': [4710,2375], 'LifeInnBench': [1300,3130],
    'LifeLookoutBench': [4450,1160],
}
text = (PROJECT / SCENE).read_text('utf-8')
for name, foot in moved.items():
    text,n = re.subn(r'(\[node name="'+name+r'"[^\n]*\]\nposition = )Vector2\([^\n]+', lambda m:m[1]+vec(foot), text, count=1)
    assert n == 1
(PROJECT / SCENE).write_text(text, 'utf-8')
config = json.loads((PROJECT / 'life-layout.json').read_text('utf-8'))
for row in config['new_objects']:
    if row['name'] in moved:
        row['foot'] = moved[row['name']]
save(PROJECT / 'life-layout.json', config)
shader = PROJECT / ART / 'ground.gdshader'
s = shader.read_text('utf-8')
needle = 'alley=min(alley,dseg(p,vec2(3500,1020),vec2(3700,1150)));'
assert needle in s
s = s.replace(needle, 'alley=min(alley,dseg(p,vec2(3500,1020),vec2(3700,1020)));\nalley=min(alley,dseg(p,vec2(3700,1020),vec2(3700,1150)));')
assert 'fold_uv(p/1024.)' in s
s = s.replace('fold_uv(p/1024.)','fold_uv(p/512.)')
shader.write_text(s,'utf-8')
save(STAGE / 'residual-change.json', {'moved':moved, 'old_report_preserved':True,
     'first_checks':83, 'first_failures':8, 'successful_components':75,
     'stair_png_and_geometry_unchanged':True,
     'north_access':'old diagonal crossing cheek replaced by orthogonal top landing approach',
     'paving_native_period':512, 'scene_candidate_sha256':sha(PROJECT/SCENE)})
print('Seven new objects adjusted; north landing route corrected; first 8 failures retained')
