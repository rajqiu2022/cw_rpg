"""Close native bank joins and fit the main staircase to the terrace elevation."""
import json
import re
import shutil
from redrock_desert_complete_20261028d import ROOT,STAGE,PROJECT,SCENE
from build_redrock_town_20261028a import save,vec,poly
from build_redrock_desert_complete_20261028d import rect

scene=PROJECT/SCENE;archive=STAGE/'before-edge-closure';assert not archive.exists();archive.mkdir()
shutil.copyfile(scene,archive/scene.name)
for name in ['verification-residual.json','region_overview_final.png']:
    shutil.copyfile(PROJECT/'artifacts'/name,archive/name)
layout=json.loads((PROJECT/'layout.json').read_text('utf-8'))
base=json.loads((ROOT/'assets/staging/redrock_luoyang_standard_20261028b/layout.json').read_text('utf-8'))
b=next(r['diagnostic_alpha128_bbox'] for r in base['media'] if r['key']=='terrace')
text=scene.read_text('utf-8');joints=[]
for name,foot,height in [('WestGateShoulder',[500,4040],200),('EastGateShoulder',[5350,4150],200),('ApproachWestJoin',[700,4750],180),('SouthWestJoin',[1300,7480],250),('SouthEastJoin',[4300,7480],200)]:
    scale=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*scale;body=rect(-width*.47,-height*.55,width*.94,height*.55)
    text+=f'\n[node name="{name}" type="Node2D" parent="Town"]\nposition = {vec(foot)}\n\n[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-p*scale for p in pivot])}\nscale = {vec([scale,scale])}\ntexture = ExtResource("terrace")\ncentered = false\n\n[node name="Body" type="StaticBody2D" parent="Town/{name}"]\ncollision_layer = 1\ncollision_mask = 0\n\n[node name="Face" type="CollisionPolygon2D" parent="Town/{name}/Body"]\npolygon = {poly(body)}\n'
    joints.append({'name':name,'key':'terrace','foot':foot,'height':height,'polygons':[body]})
# Increase the native staircase uniformly; use its actual cheeks as collision boundaries.
factor=400/220
def grow(match):
    block=match[0]
    block=re.sub(r'(?m)^(position|scale) = Vector2\(([^)]+)\)',lambda m:m[1]+' = '+vec([float(v)*factor for v in m[2].split(',')]),block)
    return block
text=re.sub(r'\[node name="Art" type="Sprite2D" parent="Town/LaneStairs"\][\s\S]*?(?=\[node|\Z)',grow,text,count=1)
for i,points in enumerate([rect(-275,-310,48,310),rect(227,-310,48,310)]):
    pattern=r'(\[node name="Block'+str(i)+r'" type="CollisionPolygon2D" parent="Town/LaneStairs/Body"\]\npolygon = )PackedVector2Array\([^\n]+'
    text,n=re.subn(pattern,lambda m:m[1]+poly(points),text,count=1);assert n==1
for r in layout['instances']:
    if r['name']=='LaneStairs':r['height']=400;r['polygons']=[rect(-275,-310,48,310),rect(227,-310,48,310)]
layout['instances']+=joints
scene.write_text(text,'utf-8');save(PROJECT/'layout.json',layout);save(STAGE/'layout.json',layout)
save(STAGE/'edge-closure.json',{'native_joint_instances':joints,'main_stair_height':400,'uniform_visual_scale':True,'no_native_png_write':True})
print('Five native joins and uniform staircase height; prior scene/evidence retained')
