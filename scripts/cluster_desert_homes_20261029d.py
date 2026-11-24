"""Native residential forecourts, using the already verified joined wall module."""
import json
import re
from desert_town_20261029d import PROJECT, STAGE, SCENE, ART
from build_redrock_town_20261028a import save, sha, vec

p=PROJECT/SCENE;text=p.read_text('utf-8');before=sha(p)
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));parts=re.split(r'(?=\[node )',text)
template=[b for b in parts if (b.startswith('[node name="CaravanCourt" ') or 'parent="Town/CaravanCourt' in b.splitlines()[0])]
assert len(template)==13,len(template)
row=next(r for r in layout['objects'] if r['name']=='CaravanCourt')
extras=[]
for i,foot in enumerate([[1450,3770],[3850,3770],[6375,3770]]):
    name='HomeCourt'+str(i+1)
    for b in template:
        if b.startswith('[node name="CaravanCourt" '):
            b=b.replace('name="CaravanCourt"','name="'+name+'"',1)
            b=re.sub(r'^position = Vector2\([^\n]+','position = '+vec(foot),b,count=1,flags=re.M)
            b=re.sub(r'^metadata/label = [^\n]+','metadata/label = "民居院落：储水和歇脚在院内，主街沿院口外通行。"',b,count=1,flags=re.M)
        else:b=b.replace('parent="Town/CaravanCourt','parent="Town/'+name)
        extras.append(b.rstrip())
    new=dict(row,name=name,foot=foot,label='民居院落：储水和歇脚在院内，主街沿院口外通行。')
    layout['objects'].append(new)
    for body in [r for r in layout['blockers'] if r['path'].startswith('Town/CaravanCourt/')]:
        layout['blockers'].append(dict(body,path=body['path'].replace('CaravanCourt',name)))
text=text.rstrip()+'\n\n'+'\n\n'.join(extras)+'\n'
moves={'LifeProp13':[860,3640],'LifeProp15':[5800,3640],'LifeProp17':[4710,3860]}
for name,foot in moves.items():
    text,n=re.subn(r'(\[node name="'+name+r'"[^\n]*\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),text,count=1);assert n==1
    next(r for r in layout['objects'] if r['name']==name)['foot']=foot
p.write_text(text,'utf-8')
shader=PROJECT/ART/'ground.gdshader';code=shader.read_text('utf-8')
code=code.replace('vec2(800.,3700.),vec2(7600.,3700.)','vec2(800.,3900.),vec2(7600.,3900.)')
for x in [1450,3850,6375]:
    code=code.replace(' float road=',f' d=min(d,line_dist(p,vec2({x}.,3900.),vec2({x}.,3730.)));\n float road=',1)
shader.write_text(code,'utf-8')
layout['residential_courts']=3;save(STAGE/'layout.json',layout)
save(STAGE/'home-courts-revision.json',{'scene_before':before,'scene_after':sha(p),'new_courts':3,'moves':moves,'new_PNG':0,'new_body_count':15,'native_UV_and_uniform_scale_preserved':True})
