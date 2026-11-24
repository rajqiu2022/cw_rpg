"""Close the remaining two source-foot conflicts and the new east-home paving link."""
import json
import re
import shutil

from redrock_city_life_20261029a import STAGE, PROJECT, SCENE, ART
from build_redrock_town_20261028a import save, vec, sha

archive=STAGE/'residual-first-failure'
assert not archive.exists()
archive.mkdir()
for name in ['verification-life-residual.json','work_residual_native.png','east_home_residual_native.png','town_overview_residual_REVIEW.png']:
    shutil.copyfile(PROJECT/'artifacts'/name,archive/name)
for p in [PROJECT/SCENE,PROJECT/ART/'ground.gdshader',STAGE/'residual.stdout.log',STAGE/'residual.stderr.log']:
    shutil.copyfile(p,archive/p.name)
text=(PROJECT/SCENE).read_text('utf-8')
moved={'LifeWorkBench':[4300,2360],'LifeLookoutBench':[4160,965]}
config=json.loads((PROJECT/'life-layout.json').read_text('utf-8'))
for name,foot in moved.items():
    text,n=re.subn(r'(\[node name="'+name+r'"[^\n]*\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),text,count=1)
    assert n==1
    next(r for r in config['new_objects'] if r['name']==name)['foot']=foot
(PROJECT/SCENE).write_text(text,'utf-8')
save(PROJECT/'life-layout.json',config)
shader=PROJECT/ART/'ground.gdshader'
s=shader.read_text('utf-8')
needle='vec3 a=mix('
assert needle in s
s=s.replace(needle,'secondary=min(secondary,dseg(p,vec2(4300,1010),vec2(4300,1100)));\nsecondary=min(secondary,dseg(p,vec2(4300,1100),vec2(4900,1100)));\n'+needle,1)
shader.write_text(s,'utf-8')
save(STAGE/'last-placement-delta.json',{'moved':moved,'new_east_street':[[4300,1010],[4300,1100],[4900,1100]],
     'old_negative_oracle_correction':'approach inn bench from its east inside the open yard, not from inside the solid front wall',
     'scene_sha256':sha(PROJECT/SCENE)})
print('Two placements aligned with exact old base polygons; east-home street connected')
