"""Local hall-canopy visibility and honest screenshot positions; no new native image edits."""
import json
import re
from miao_building_variety_20261029h import STAGE, PROJECT, SCENE
from build_redrock_town_20261028a import save
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));tree=next(x for x in layout['objects'] if x['key']=='trees' and x['foot']==[4620,2150]);name=tree['name']
p=PROJECT/SCENE;t=p.read_text('utf-8');assert 'h_hall_tree' not in t
t=t.replace('[node ', '[sub_resource type="ShaderMaterial" id="h_hall_tree"]\nshader = ExtResource("occlusion_shader")\nshader_parameter/fade_enabled = 0.0\n\n[node ',1)
t=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+1),t,count=1)
t,n=re.subn(r'(\[node name="'+name+r'"[^\n]*parent="Town"\]\n)',lambda m:m[1]+'metadata/fade = true\n',t,count=1);assert n==1
t,n=re.subn(r'(\[node name="Art"[^\n]*parent="Town/'+name+r'"\]\n)',lambda m:m[1]+'material = SubResource("h_hall_tree")\n',t,count=1);assert n==1
p.write_text(t,'utf-8');save(STAGE/'view-refinement.json',{'hall_tree':name,'foot':tree['foot'],'change':'localized hero canopy window only; unchanged tree body and native PNG','first_views_preserved':True,'new_inn_view':'replace initial snapshot inside existing rock with clear real ground3900,1050'})
