"""Align native building entrances with forecourt back edges before first runtime."""
import json
import re
import shutil
from desert_town_20261029d import STAGE, PROJECT, SCENE, SCRIPT
from build_redrock_town_20261028a import save, sha, vec

p=PROJECT/SCENE;text=p.read_text('utf-8');old=sha(p)
layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
changes={'Guesthouse':[1350,2865],'CamelShelter':[2310,2860],'Well':[6630,2950],
         'BackHome5':[5510,2900],'Workshop':[5070,2290],
         'LifeProp9':[5290,2410],'LifeProp10':[4840,2410],'WorkshopHand':[5070,2470]}
for name,foot in changes.items():
    pattern=r'(\[node name="'+name+r'"[^\n]*parent="Town"[^\n]*\]\nposition = )Vector2\([^\n]+'
    text,n=re.subn(pattern,lambda m:m[1]+vec(foot),text,count=1);assert n==1,name
    row=next((r for r in layout['objects'] if r['name']==name),None)
    if row:row['foot']=foot
text=text.replace('position = Vector2(1330,2820)','position = Vector2(1330,2895)',1)
text=text.replace('route = PackedVector2Array(5520, 3110, 5790, 3110)','route = PackedVector2Array(5070, 2470, 5340, 2470)',1)
layout['patrols'][3]['route']=[[5070,2470],[5340,2470]]
pattern=r'(\[node name="Outline" type="CollisionPolygon2D" parent="Town/CamelShelter/Body"\]\npolygon = )[^\n]+'
text,n=re.subn(pattern,r'\g<1>PackedVector2Array(-465, -35, 465, -35, 465, -17, -465, -17)',text,count=1);assert n==1
next(r for r in layout['objects'] if r['name']=='CamelShelter')['body']=[[-465,-35],[465,-35],[465,-17],[-465,-17]]
next(r for r in layout['blockers'] if r['path']=='Town/CamelShelter/Body')['polygon']=[[-465,-35],[465,-35],[465,-17],[-465,-17]]
p.write_text(text,'utf-8');shutil.copyfile(STAGE/'town_controller.gd',PROJECT/SCRIPT)
save(STAGE/'layout.json',layout)
save(STAGE/'alignment-before-runtime.json',{'scene_before':old,'scene_after':sha(p),'moves':changes,'reason':'door clear of native low wall and well inside water court; workshop in windward rear row'})
