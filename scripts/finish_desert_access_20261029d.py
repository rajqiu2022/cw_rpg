"""Clear two jar stacks from court axes and localize foreground transparency."""
import json
import re
import shutil
from desert_town_20261029d import PROJECT, STAGE, SCENE, SCRIPT, ART
from build_redrock_town_20261028a import save, sha, vec

p=PROJECT/SCENE;text=p.read_text('utf-8');old=sha(p)
layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
for name,foot in {'LifeProp14':[3670,3640],'LifeProp18':[6550,3640]}.items():
    text,n=re.subn(r'(\[node name="'+name+r'"[^\n]*\]\nposition = )Vector2\([^\n]+',lambda m:m[1]+vec(foot),text,count=1);assert n==1
    next(r for r in layout['objects'] if r['name']==name)['foot']=foot
text=text.replace('[sub_resource',f'[ext_resource type="Shader" path="res://{ART}/foreground.gdshader" id="foreground_shader"]\n\n[sub_resource',1)
text=text.replace('[node name="DesertTown"', '[sub_resource type="ShaderMaterial" id="foreground_mat"]\nshader = ExtResource("foreground_shader")\nshader_parameter/fade_enabled = 0.0\n\n[node name="DesertTown"',1)
text=text.replace('[node name="Art" type="Sprite2D" parent="Town/WallFront"]\n','[node name="Art" type="Sprite2D" parent="Town/WallFront"]\nmaterial = SubResource("foreground_mat")\n',1)
text=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+2),text,count=1)
p.write_text(text,'utf-8')
shader='''shader_type canvas_item;
uniform vec2 hero_foot=vec2(0.);
uniform float fade_enabled=0.;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){vec4 t=texture(TEXTURE,UV);vec2 d=world_pixel-hero_foot;
 float x=1.-smoothstep(68.,118.,abs(d.x));
 float y=smoothstep(-195.,-155.,d.y)*(1.-smoothstep(10.,50.,d.y));
 COLOR=vec4(t.rgb,t.a*mix(1.,.12,x*y*fade_enabled));}
'''
(PROJECT/ART/'foreground.gdshader').write_text(shader,'utf-8')
c=(STAGE/'town_controller.gd').read_text('utf-8')
oldline='\t$Town/WallFront/Art.modulate.a=.38 if not in_hall and actor.global_position.y>3500 and actor.global_position.y<4290 else 1.0'
assert c.count(oldline)==1
c=c.replace(oldline,'\tvar wall_material: ShaderMaterial=$Town/WallFront/Art.material\n\twall_material.set_shader_parameter("hero_foot",actor.global_position)\n\twall_material.set_shader_parameter("fade_enabled",1.0 if view_mode==1 and not in_hall and actor.global_position.y>3500 and actor.global_position.y<4290 else 0.0)',1)
c=c.replace('item.get_node("Art").modulate.a=.45 if d.y','item.get_node("Art").modulate.a=.45 if view_mode==1 and d.y',1)
(STAGE/'town_controller.gd').write_text(c,'utf-8');shutil.copyfile(STAGE/'town_controller.gd',PROJECT/SCRIPT)
save(STAGE/'layout.json',layout)
save(STAGE/'access-residual-fix.json',{'scene_before':old,'scene_after':sha(p),'two_jars_moved_off_centerline':True,'foreground_fade':'local 236px feathered hero window; overview opaque','PNG_changed':False,'previous_222_5_FAIL_retained':True})
