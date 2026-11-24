"""Retain native UV; place rear courtyard wall behind its actual contents."""
import json
import re
import shutil
from desert_town_20261029d import PROJECT, STAGE, SCENE, SCRIPT, ART
from build_redrock_town_20261028a import save, sha, vec, fmt

layout=json.loads((STAGE/'layout.json').read_text('utf-8'));p=PROJECT/SCENE;text=p.read_text('utf-8');old=sha(p)
extra=[]
for name in ['CaravanCourt','WaterCourt']:
    r=next(x for x in layout['objects'] if x['name']==name);s=r['scale'];pivot=r['pivot'];pad=r['padding']
    header=f'[node name="Art" type="Sprite2D" parent="Town/{name}"]'
    pattern=re.escape(header)+r'\n[\s\S]*?(?=\n\[node |\Z)'
    rear=header+'\nz_index = -1\nposition = '+vec([-pivot[0]*s,-pivot[1]*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("court_wall")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2({pad[0]}, {pad[1]}, 1774, 470)\n'
    text,n=re.subn(pattern,lambda m:rear,text,count=1);assert n==1
    extra.append(f'[node name="ForeArt" type="Sprite2D" parent="Town/{name}"]\nposition = '+vec([-pivot[0]*s,(470-pivot[1])*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("court_wall")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2({pad[0]}, {pad[1]+470}, 1774, 417)')
text=text.rstrip()+'\n\n'+'\n\n'.join(extra)+'\n'
pattern=r'(\[node name="OuterDune4"[^\n]*\]\nposition = )Vector2\([^\n]+'
text,n=re.subn(pattern,r'\g<1>Vector2(10200, 3000)',text,count=1);assert n==1
for i in range(1,7):
    marker=f'[node name="OuterDune{i}" type="Node2D" parent="Town"]\n'
    assert text.count(marker)==1;text=text.replace(marker,marker+'z_index = -5\n',1)
p.write_text(text,'utf-8')
next(x for x in layout['objects'] if x['name']=='OuterDune4')['foot']=[10200,3000]
layout['court_original_UV_split']=470;save(STAGE/'layout.json',layout)
controller=(STAGE/'town_controller.gd').read_text('utf-8')
line='\t\titem.get_node("Art").modulate.a=.45 if d.y < -8 and d.y > -area.size.y and absf(d.x)<area.size.x*.46 else 1.0'
assert controller.count(line)==1
controller=controller.replace(line,line+'\n\t\tif item.has_node("ForeArt"):item.get_node("ForeArt").modulate.a=item.get_node("Art").modulate.a',1)
(STAGE/'town_controller.gd').write_text(controller,'utf-8');shutil.copyfile(STAGE/'town_controller.gd',PROJECT/SCRIPT)
save(STAGE/'court-layer-revision.json',{'before':old,'after':sha(p),'PNG_modified':False,'original_UV_partition':470,'right_dune_outside_wall':True,'cause':'rear low wall incorrectly sorted over well'})
