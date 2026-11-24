"""Make foot depth explicit; preserve globally low floor layers and independent local fade materials."""
import re
import shutil
from miao_town_20261029f import STAGE, PROJECT, SCENE, SCRIPT
from build_redrock_town_20261028a import save, sha

p=PROJECT/SCENE;text=p.read_text('utf-8');old=sha(p);subs=[]
for i in range(1,16):
    name='ClusterHome'+str(i);pattern=r'(\[node name="Art" type="Sprite2D" parent="Town/'+name+r'"\]\nmaterial = SubResource\(")([^\"]+)("\))'
    match=re.search(pattern,text);assert match,name
    original=match[2];new='fade_'+name
    material=re.search(r'\[sub_resource type="ShaderMaterial" id="'+original+r'"\][\s\S]*?(?=\n\[|\Z)',text)[0]
    subs.append(material.replace('id="'+original+'"','id="'+new+'"',1).rstrip())
    text,n=re.subn(pattern,lambda m:m[1]+new+m[3],text,count=1);assert n==1
text=text.replace('[node name="MiaoTown"','\n\n'.join(subs)+'\n\n[node name="MiaoTown"',1)
text=re.sub(r'load_steps=(\d+)',lambda m:'load_steps='+str(int(m[1])+15),text,count=1);p.write_text(text,'utf-8')
c=(STAGE/'town_controller.gd').read_text('utf-8')
c=c.replace('\tactor.set_can_move(false)\n','\tactor.set_can_move(false)\n\tinitialize_foot_depth()\n',1)
c=c.replace('func update_view() -> void:\n','func update_view() -> void:\n\tactor.z_as_relative=false\n\tactor.z_index=foot_depth(actor.global_position.y)\n',1)
c+='''
func foot_depth(y: float) -> int:
	return clampi(roundi(y/4.0),-4000,4000)

func initialize_foot_depth() -> void:
	for item in $Town.get_children():
		if not item is Node2D or item is StaticBody2D:continue
		item.z_as_relative=false
		if not item.has_meta("ground_cover") and not (item.has_meta("visual_rect") and item.z_index<0):
			item.z_index=foot_depth(item.global_position.y)
		if item.has_node("Base"):
			item.get_node("Base").z_as_relative=false
		if item.has_node("Foreground"):
			item.get_node("Foreground").z_as_relative=false
			item.get_node("Foreground").z_index=foot_depth(item.global_position.y+22)
	for item in $HouseHall/Sort.get_children():
		if item is Node2D:
			item.z_as_relative=false
			item.z_index=foot_depth(item.global_position.y)
'''
(STAGE/'town_controller.gd').write_text(c,'utf-8');shutil.copyfile(STAGE/'town_controller.gd',PROJECT/SCRIPT)
p=STAGE/'resident.gd';r=p.read_text('utf-8')
r=r.replace('func _physics_process(delta: float) -> void:\n','func _physics_process(delta: float) -> void:\n\tz_as_relative=false\n\tz_index=clampi(roundi(global_position.y/4.0),-4000,4000)\n',1)
p.write_text(r,'utf-8');shutil.copyfile(p,PROJECT/'scripts/drafts/miao_town_20261029f/resident.gd')
save(STAGE/'foot-depth-fix.json',{'scene_before':old,'scene_after':sha(PROJECT/SCENE),'depth':'global foot y /4, absolute at entity root','bridge_and_stair_floor_absolute':True,'15_cloned_fade_materials_independent':True,'physics_or_PNG_changed':False,'cause':'native screenshot showed resident painting in front of foreground roof'})
print('Explicit foot depth for props/characters, fixed low floor layers;15independent cloned fade materials')
