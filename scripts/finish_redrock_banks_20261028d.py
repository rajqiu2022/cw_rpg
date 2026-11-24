"""Replace failed loose perimeter with purpose-drawn banks; preserve first GPU failure."""
import json
import re
import shutil
import numpy as np
from PIL import Image
from redrock_desert_complete_20261028d import ROOT,RAW,STAGE,PROJECT,ART,SCENE
from build_redrock_town_20261028a import save,sha,vec,poly
from build_redrock_desert_complete_20261028d import rect

archive=STAGE/'first-runtime-failure';assert not archive.exists();archive.mkdir()
for p in (PROJECT/'artifacts').iterdir():
    if p.is_file():shutil.copyfile(p,archive/p.name)
for p in [PROJECT/SCENE,PROJECT/'verify.stdout.log',PROJECT/'verify.stderr.log']:
    shutil.copyfile(p,archive/p.name)
layout=json.loads((PROJECT/'layout.json').read_text('utf-8'))
raw=json.loads((RAW/'resource-pack.json').read_text('utf-8'))['assets']
scene=PROJECT/SCENE;text=scene.read_text('utf-8')
media=[];boxes={}
for key in ['west_bank','east_bank','north_bank']:
    r=next(r for r in raw if r['key']==key);dest=f'{ART}/{key}.png';shutil.copyfile(ROOT/r['output'],PROJECT/dest)
    a=np.array(Image.open(PROJECT/dest).getchannel('A'));y,x=np.where(a>=128);boxes[key]=[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
    media.append({'key':key,'kind':'landform','label':r['label'],'source':r['output'],'destination':dest,'sha256':sha(PROJECT/dest)})
header='\n\n'.join(f'[ext_resource type="Texture2D" path="res://{r["destination"]}" id="d_{r["key"]}"]' for r in media)
text=text.replace('[sub_resource',header+'\n\n[sub_resource',1)
blocks=re.split(r'(?=\[node )',text)
def retired(block):
    h=block.splitlines()[0]
    if re.search(r'(name="OuterRock\d+"|parent="Town/OuterRock\d+(/|"))',h):return True
    if re.search(r'(name="ApproachRock(?:[2-9]|10|11)"|parent="Town/ApproachRock(?:[2-9]|10|11)(/|"))',h):return True
    return False
text=''.join(b for b in blocks if not retired(b))
for name,foot in [('WestLaneStairs',[1300,1250]),('StoneWorker',[4400,2660])]:
    text,n=re.subn(r'(\[node name="'+name+r'"[^\]]*\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),text,count=1);assert n==1
text=text.replace('route = PackedVector2Array(4400, 2590, 4780, 2590)','route = PackedVector2Array(4400, 2660, 4780, 2660)')
text=re.sub(r'(\[node name="Ground"[^\]]*\][\s\S]*?polygon = )PackedVector2Array\([^\n]+',lambda m:m[1]+poly([[-20000,-20000],[24000,-20000],[24000,24000],[-20000,24000]]),text,count=1)
layout['instances']=[r for r in layout['instances'] if not r['name'].startswith('OuterRock') and r['name'] not in {f'ApproachRock{i}' for i in range(2,12)}]
for r in layout['instances']:
    if r['name']=='WestLaneStairs':r['foot']=[1300,1250]
banks=[]
for name,key,foot,height in [('TownWestBank','west_bank',[-500,4000],3900),('TownEastBank','east_bank',[6300,4200],3900),('TownNorthBank','north_bank',[2850,450],850),('ApproachWestBank','west_bank',[100,7500],3300),('ApproachEastBank','east_bank',[5200,7500],3300),('ApproachSouthRidge','north_bank',[2900,7800],330)]:
    b=boxes[key];s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*s
    body=rect(-width*.48,-height*.96,width*.96,height*.96) if key!='north_bank' else rect(-width*.45,-110,width*.9,110)
    text+=f'\n[node name="{name}" type="Node2D" parent="Town"]\nposition = {vec(foot)}\n\n[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-v*s for v in pivot])}\nscale = {vec([s,s])}\ntexture = ExtResource("d_{key}")\ncentered = false\n\n[node name="Body" type="StaticBody2D" parent="Town/{name}"]\ncollision_layer = 1\ncollision_mask = 0\n\n[node name="Rock" type="CollisionPolygon2D" parent="Town/{name}/Body"]\npolygon = {poly(body)}\n'
    banks.append({'name':name,'key':key,'foot':foot,'height':height,'polygons':[body]})
scene.write_text(text,'utf-8')
layout['media']+=media;layout['instances']+=banks
save(PROJECT/'layout.json',layout);save(STAGE/'layout.json',layout)
save(STAGE/'bank-revision.json',{'first_checks':66,'first_failures':2,'first_successes_inherited':64,'fixed':'worker stand/patrol at2660, west stair1250','new_art_bank_instances':6,'retired_loose_rocks':26,'original_runtime_failure_retained':True})
print('Replaced 26 loose rocks with six banks; original two-failure report archived')
