"""Incremental image-review corrections: denser roof pockets, earthen aprons and shop depth."""
import json
import re
from miao_recompose_20261029g import ROOT, STAGE, PROJECT, SCENE, SCRIPT, ART
from build_redrock_town_20261028a import save, sha, vec, fmt

layout=json.loads((STAGE/'layout.json').read_text('utf-8'));p=PROJECT/SCENE;text=p.read_text('utf-8');assert not (STAGE/'visual-refinement.json').exists()
save(STAGE/'visual-first-review.json',{'status':'ART_NOT_ACCEPTED','scene_sha256':sha(p),'issues':['over-green repeated terrain at broad scale','roof pockets too separated','shop front pedestrians hidden by foreground depth'],'screenshots':['01-panorama','02-raised-market','03-earthen-plaza','04-slope-neighborhood']})
nodes=[];added=[];bodies=[];materials=[]
def clone(name,original,foot,factor=1):
    original_row=next(x for x in layout['objects'] if x['name']==original);oldfoot=original_row['foot'];blocks=[]
    for b in re.split(r'(?=\[node )',text):
        h=b.splitlines()[0] if b else ''
        if (f'name="{original}" type=' in h and 'parent="Town"' in h) or re.search(r'parent="Town/'+original+r'(?:/|")',h):
            if 'parent="Town"' in h:
                b=b.replace('name="'+original+'"','name="'+name+'"',1);b=re.sub(r'^position = Vector2\([^\n]+','position = '+vec(foot),b,count=1,flags=re.M)
                if factor!=1:b+='\nscale = '+vec([factor,factor])+'\n'
            else:
                b=b.replace('parent="Town/'+original,'parent="Town/'+name)
                oldmat=re.search(r'material = SubResource\("([^\"]+)"\)',b)
                if oldmat:
                    sid='gfade_'+name;materials.append(f'[sub_resource type="ShaderMaterial" id="{sid}"]\nshader = ExtResource("occlusion_shader")\nshader_parameter/fade_enabled = 0.0');b=b.replace(oldmat[1],sid)
            blocks.append(b.rstrip())
    assert len(blocks)==4,(original,len(blocks));nodes.extend(blocks)
    added.append(dict(original_row,name=name,foot=foot,height=original_row['height']*factor,width=original_row['width']*factor,scale=original_row['scale']*factor))
    bodies.extend(dict(r,path=r['path'].replace('/'+original+'/', '/'+name+'/')) for r in layout['blockers'] if r['path'].startswith('Town/'+original+'/'))
for i,(old,foot) in enumerate([('PocketHome3',[3200,1420]),('PocketHome4',[4110,1180]),('PocketHome3',[5320,880]),('PocketHome1',[6160,770]),
    ('PocketHome5',[6300,2050]),('PocketHome12',[5240,2870]),('PocketHome13',[2820,2660]),('PocketHome16',[6000,3420])]):clone('PocketInfill'+str(i+1),old,foot)
for i,(old,foot,factor) in enumerate([('RockLedge2',[3460,1000],1.45),('RockLedge3',[4570,1250],1.45),('RockLedge4',[5400,1510],1.45),('RockLedge10',[6140,2060],1.2)]):clone('HighRock'+str(i+1),old,foot,factor)
text=text.replace('[node ', '\n\n'.join(materials)+'\n\n[node ',1);text=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+len(materials)),text,count=1)
for i in range(1,5):
    nm='RaisedMarket'+str(i);depth=-40 if i<3 else -25
    text,n=re.subn(r'(\[node name="'+nm+r'" type="Node2D" parent="Town"\]\nposition = [^\n]+)',lambda m:m[1]+'\nmetadata/foreground_depth_y = '+str(depth),text,count=1);assert n==1
text=text.rstrip()+'\n\n'+'\n\n'.join(nodes)+'\n';p.write_text(text,'utf-8')
layout['objects']+=added;layout['blockers']+=bodies;layout['homes']=36
sp=PROJECT/SCRIPT;code=sp.read_text('utf-8').replace('Vector2(3800,2500)','Vector2(4020,2370)').replace('Vector2.ONE*.205','Vector2.ONE*.22')
code=code.replace('foot_depth(item.global_position.y+22)','foot_depth(item.global_position.y+float(item.get_meta("foreground_depth_y",22)))');sp.write_text(code,'utf-8')
shader=PROJECT/ART/'ground.gdshader';g=shader.read_text('utf-8')
wear=[]
for r in layout['objects']:
    if r['key'] not in ['house_front','house_side','house_back','stilt_house','weaving_house','granary']:continue
    x,y=r['foot'];wear.append('wear=max(wear,1.-smoothstep(.65,1.,length((p-vec2('+fmt(x)+','+fmt(y+20)+'))/vec2('+fmt(r['width']*.7)+',200.))));')
g=g.replace('vec3 mixed=mix(woodland,mix(soil,stone,.22),path*.96);','float wear=0.;\n'+'\n'.join(wear)+'\nwoodland=mix(woodland,soil,.45);\nvec3 mixed=mix(woodland,mix(soil,stone,.18),max(path,wear*.85)*.96);')
shader.write_text(g,'utf-8');save(STAGE/'layout.json',layout)
save(STAGE/'visual-refinement.json',{'new_homes':8,'new_rock_shoulders':4,'earthen_aprons':len(wear),'green_material_mix':'native woodland/earth blending, PNG unchanged','shop_front_depth':[-40,-25],'scene_sha256':sha(p)})
print('Refined:36homes,4higher native rock shoulders, native earth aprons, shop-front depth; no PNG edits')
