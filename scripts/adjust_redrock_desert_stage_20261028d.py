"""Record narrow authoring revisions in the private project, preserving first versions."""
import json
import re
import shutil
from pathlib import Path
from redrock_desert_complete_20261028d import PROJECT,STAGE,ART,SCENE
from build_redrock_desert_complete_20261028d import ROADS
from build_redrock_town_20261028a import fmt,vec,save

scene=PROJECT/SCENE
archive=STAGE/'initial-authoring';archive.mkdir(exist_ok=True)
for path in [scene,PROJECT/ART/'ground.gdshader',PROJECT/'layout.json']:
    target=archive/path.name
    if not target.exists():shutil.copyfile(path,target)
text=scene.read_text('utf-8')
for name,foot in [('WestMarket',[800,1660]),('EastMarket',[5000,1500]),('TravelCargo1',[550,1670]),('TravelCargo2',[5280,1490])]:
    pattern=r'(\[node name="'+name+r'"[^\]]*\]\nposition = )Vector2\([^\n]+'
    text,n=re.subn(pattern,lambda m:m[1]+vec(foot),text,count=1);assert n==1
text=text.replace('collision_layer = 4\ncollision_mask = 1','collision_layer = 5\ncollision_mask = 1')
scene.write_text(text,'utf-8')
layout=json.loads((PROJECT/'layout.json').read_text('utf-8'));old=layout['new_routes'];layout['new_routes']=ROADS
for row in layout['instances']:
    for name,foot in [('WestMarket',[800,1660]),('EastMarket',[5000,1500]),('TravelCargo1',[550,1670]),('TravelCargo2',[5280,1490])]:
        if row['name']==name:row['foot']=foot
shader=PROJECT/ART/'ground.gdshader';source=shader.read_text('utf-8')
def lines(roads):
    return ''.join(f'secondary=min(secondary,dseg(p,vec2({fmt(a[0])},{fmt(a[1])}),vec2({fmt(b[0])},{fmt(b[1])})));\n' for points in roads.values() for a,b in zip(points,points[1:]))
assert lines(old) in source
shader.write_text(source.replace(lines(old),lines(ROADS),1),'utf-8')
save(PROJECT/'layout.json',layout);save(STAGE/'layout.json',layout)
print('Revised market positions/approaches and solid NPC layer; initial authoring retained')
