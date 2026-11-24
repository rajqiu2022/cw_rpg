"""Assemble the six-zone town and connected canyon approach in an exclusive project."""
import json
import re
import shutil
from pathlib import Path

import numpy as np
from PIL import Image

from redrock_desert_complete_20261028d import ROOT,NAME,RAW,STAGE,PROJECT,ART,SCENE,SCRIPT
from build_redrock_town_20261028a import save,sha,vec,poly,fmt

B='redrock_luoyang_standard_20261028b'
ROOM=f'scenes/drafts/{NAME}/inn_hall.tscn'
HOME=f'scenes/drafts/{NAME}/home_room.tscn'
OUTLINE=[[600,400],[4300,300],[5200,600],[5600,1600],[5540,3250],[5100,4150],[4250,4550],[4300,6300],[3500,7150],[1800,7500],[1000,6800],[1200,5800],[1800,5100],[1650,4200],[300,4080],[180,2700],[300,1100]]
ROADS={
 'approach':[[2250,4480],[2250,5100],[2950,5600],[2950,6200],[2400,6850]],
 'waystation':[[2950,6000],[3650,6000],[3650,5840]],
 'wildlife':[[2400,6850],[1700,6850],[1550,6500]],
 'upper_stairs':[[3700,2100],[3700,1720],[3700,1320],[3700,1010],[4300,1010]],
 'market_lane':[[1300,1560],[1150,1560],[1150,1715],[800,1715]],
 'east_market':[[3700,1560],[5000,1560]],
 'home':[[1300,1560],[1700,1560]],
}

def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]

def copy_existing(rel):
    source=ROOT/'game'/rel;target=PROJECT/rel
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
    side=Path(str(source)+'.import')
    if side.exists():
        shutil.copyfile(side,Path(str(target)+'.import'))
        for leaf in set(re.findall(r'res://(\.godot/imported/[^"\s]+)',side.read_text('utf-8'))):
            p=ROOT/'game'/leaf;q=PROJECT/leaf;q.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,q)
            if p.with_suffix('.md5').exists():shutil.copyfile(p.with_suffix('.md5'),q.with_suffix('.md5'))

def spans(values,gap=12):
    groups=[]
    for x in np.where(values)[0]:
        if not groups or x-groups[-1][-1]>gap:groups.append([int(x)])
        else:groups[-1].append(int(x))
    return [[g[0],g[-1]+1] for g in groups]

def atlas(path,key):
    a=np.array(Image.open(path).getchannel('A'));mask=a>=128
    rows=spans(mask.sum(1)>10);assert len(rows)==(1 if key=='fox' else 4),(key,rows)
    frames=[]
    for row,(y0,y1) in enumerate(rows):
        columns=spans(mask[y0:y1].sum(0)>3);assert len(columns)==4,(key,columns)
        line=[]
        for x0,x1 in columns:
            y,x=np.where(mask[y0:y1,x0:x1]);bbox=[x0+int(x.min()),y0+int(y.min()),x0+int(x.max()+1),y0+int(y.max()+1)]
            # Only renderer regions and foot anchors. No PNG pixels are transformed.
            region=[x0-6,y0-6,x1-x0+12,y1-y0+12]
            line.append({'region':region,'pivot':[(bbox[0]+bbox[2])/2-region[0],bbox[3]-region[1]],'height':bbox[3]-bbox[1]})
        frames.append(line)
    return {'rows':frames,'native_size':list(a.shape[::-1]),'left_runtime_flip':key=='worker_walk','native_rgba_unchanged':True}

def build():
    assert not PROJECT.exists()
    (PROJECT/ART).mkdir(parents=True)
    old=json.loads((ROOT/'assets/staging'/B/'layout.json').read_text('utf-8'))
    for r in old['media']:copy_existing(r['destination'])
    copy_existing(f'art/modules/{B}/ground.gdshader')
    for rel in ['scenes/player.tscn','scripts/field/player.gd',f'scripts/drafts/{B}/preview_player.gd',f'scripts/drafts/{B}/town_controller.gd','art/characters/hero_idle_down_25d_runtime_4f.png']:
        copy_existing(rel)
    for p in (ROOT/'game/art/characters/weapon_variants/lengguyun/v7_idle_stable/sword').glob('*.png'):copy_existing(p.relative_to(ROOT/'game').as_posix())
    rows=json.loads((RAW/'resource-pack.json').read_text('utf-8'))['assets'];assert len(rows)==12
    media=[];boxes={}
    for row in rows:
        dest=f'{ART}/{row["key"]}.png';shutil.copyfile(ROOT/row['output'],PROJECT/dest)
        im=Image.open(PROJECT/dest);a=np.array(im.getchannel('A'));y,x=np.where(a>=128);boxes[row['key']]=[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
        media.append({'key':row['key'],'kind':row['kind'],'label':row['label'],'source':row['output'],'destination':dest,'sha256':sha(PROJECT/dest)})
    for key,file in [('bed','household_bed_v1.png'),('cloth_rack','garment_rack_v1.png')]:
        source='game/art/modules/luoyang_assembled_interiors_20261016g/'+file;dest=f'{ART}/{key}.png';shutil.copyfile(ROOT/source,PROJECT/dest)
        im=Image.open(PROJECT/dest);a=np.array(im.getchannel('A'));y,x=np.where(a>=128);boxes[key]=[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
        media.append({'key':key,'kind':'scene_prop','label':'赤岩民居·'+('卧榻' if key=='bed' else '衣架'),'source':source,'destination':dest,'sha256':sha(PROJECT/dest)})
    atlases={key:atlas(PROJECT/ART/(key+'.png'),key) for key in ['merchant_walk','worker_walk','fox']}
    save(PROJECT/'atlases.json',atlases)
    save(PROJECT/ART/'atlases.json',atlases)
    text=(ROOT/'game/scenes/drafts'/B/'redrock_town.tscn').read_text('utf-8')
    text=text.replace(f'res://scripts/drafts/{B}/town_controller.gd','res://'+SCRIPT).replace(f'res://scenes/drafts/{B}/inn_hall.tscn','res://'+ROOM)
    header,body=text.split('[node ',1);parts=[header]
    for r in media:parts.append(f'[ext_resource type="Texture2D" path="res://{r["destination"]}" id="d_{r["key"]}"]')
    parts.append(f'[ext_resource type="Script" path="res://scripts/drafts/{NAME}/ambient_actor.gd" id="ambient"]')
    parts.append(f'[ext_resource type="PackedScene" path="res://{HOME}" id="home_scene"]')
    # Ext resources must precede sub-resources. Reassemble header in valid order.
    additions='\n\n'.join(parts[1:]);header=header.replace('[sub_resource',additions+'\n\n[sub_resource',1)
    text=header+'[node '+body
    # Ground extends beneath native cliff bases, eliminating the exposed polygon cut edge.
    text=re.sub(r'(\[node name="Ground"[^\]]*\][\s\S]*?polygon = )PackedVector2Array\([^\n]+',lambda m:m[1]+poly([[-3500,-3000],[9500,-3000],[9500,11000],[-3500,11000]]),text,count=1)
    text=re.sub(r'(\[node name="Outline"[^\]]*\][\s\S]*?polygon = )PackedVector2Array\([^\n]+',lambda m:m[1]+poly(OUTLINE),text,count=1)
    # Alternate silhouettes without changing the original lane footprints.
    for name in ['Dwelling2','Dwelling4','Dwelling8','Dwelling10']:
        pattern=r'(\[node name="Art" type="Sprite2D" parent="Town/'+name+r'"\][\s\S]*?)(?=\[node|\Z)'
        b=boxes['side_house'];s=345/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]]
        replacement=f'[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-p*s for p in pivot])}\nscale = {vec([s,s])}\ntexture = ExtResource("d_side_house")\ncentered = false\n\n'
        text=re.sub(pattern,lambda _m:replacement,text,count=1)
    chunks=[text];instances=[]
    def item(name,key,foot,height,polygons=None,label=''):
        b=boxes.get(key)
        if b is None:
            oldrow=next(r for r in old['media'] if r['key']==key);b=oldrow['diagnostic_alpha128_bbox']
        s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];tex=('d_'+key) if key in boxes else key
        chunks.append(f'[node name="{name}" type="Node2D" parent="Town"]\nposition = {vec(foot)}\nmetadata/label = "{label}"')
        chunks.append(f'[node name="Art" type="Sprite2D" parent="Town/{name}"]\nposition = {vec([-p*s for p in pivot])}\nscale = {vec([s,s])}\ntexture = ExtResource("{tex}")\ncentered = false')
        if polygons:
            chunks.append(f'[node name="Body" type="StaticBody2D" parent="Town/{name}"]\ncollision_layer = 1\ncollision_mask = 0')
            for i,p in enumerate(polygons):chunks.append(f'[node name="Block{i}" type="CollisionPolygon2D" parent="Town/{name}/Body"]\npolygon = '+poly(p))
        instances.append({'name':name,'key':key,'foot':foot,'height':height,'polygons':polygons or []})
    # Continuous overlapping natural rock banks outside all authored town routes.
    for i,(x,y,h) in enumerate([(-180,900,700),(-220,1550,750),(-260,2230,760),(-220,2890,720),(-120,3540,690),(350,400,650),(1300,380,680),(2250,320,700),(3200,300,720),(4150,340,710),(5100,500,700),(6040,1100,760),(6150,1800,780),(6090,2500,750),(5970,3250,730),(5650,3900,700)]):
        item(f'OuterRock{i+1}','canyon',[x,y],h,[rect(-380,-140,760,140)])
    # Connected approach: rock banks continue down from both gate shoulders.
    for i,(x,y,h) in enumerate([(1230,4650,540),(1150,5200,560),(1250,5780,530),(740,6430,580),(950,7070,510),(1600,7610,530),(2670,7780,540),(3740,7460,560),(4490,6860,590),(4770,6190,600),(4770,5510,590),(4140,4900,540)]):
        item(f'ApproachRock{i+1}','canyon',[x,y],h,[rect(-300,-115,600,115)])
    for name,foot,height in [('LaneStairs',[3700,2045],220),('LookoutStairs',[3700,1325],205),('WestLaneStairs',[1300,1190],185)]:
        # Open center for the full adult foot; solid visible side cheeks only.
        item(name,'stairs',foot,height,[rect(-150,-170,32,165),rect(118,-170,32,165)],'石阶：上下口留通，沿中央行走。')
    for name,foot in [('WestMarket',[800,1660]),('EastMarket',[5000,1500])]:
        item(name,'market',foot,240,[rect(-250,-62,295,62),rect(210,-35,35,35)],'遮阳商棚：布包、篮筐与货架。')
    item('RoadShelter','waystation',[3650,5790],260,[rect(-210,-68,420,45),rect(-210,-15,38,20),rect(177,-15,38,20)],'关外避风小驿：商路休息点。')
    for name,foot in [('StableCamel',[3150,3175]),('StableCamel2',[3650,3160]),('RoadCamel',[3900,5940])]:
        item(name,'camel',foot,118,[rect(-63,-32,126,32)],'商队卧驼：普通驮兽。')
    for i,foot in enumerate([[550,1670],[5280,1490],[3520,5800],[2080,6540],[4830,2480]]):
        item(f'TravelCargo{i+1}','caravan_props',foot,90,[rect(-38,-26,76,26)],'商旅货箱：场景调查物件；未新增正式任务或奖励。')
    for i,(x,y,h) in enumerate([(680,1520,72),(950,1950,65),(1560,1900,70),(2950,1900,61),(3250,1900,68),(4860,1030,65),(3950,6100,65),(3300,6550,72),(1440,6950,60),(2700,7280,66),(1780,5320,60),(4000,5110,65)]):
        item(f'CompletionShrub{i+1}','dry_shrub',[x,y],h)
    for name,foot,height in [('OuterTree',[1760,5790],250),('ShelterTree',[4130,5830],230)]:item(name,'dry_tree',foot,height,[rect(-20,-24,40,24)])
    for name,key,foot,path,speed,label in [
        ('Merchant','merchant_walk',[2140,3420],[[2140,3420],[2780,3420],[2780,3620],[2140,3620]],52,'商旅：正在沿驿舍外街转运货物。'),
        ('StoneWorker','worker_walk',[4400,2590],[[4400,2590],[4780,2590]],42,'石匠：石料与修车工具放在工作棚边。'),
        ('SandFox','fox',[1750,6910],[[1750,6910],[2500,6910]],64,'沙狐：普通荒漠动物，未绑定战斗或掉落。')]:
        chunks.append(f'[node name="{name}" type="CharacterBody2D" parent="Town"]\nposition = {vec(foot)}\ncollision_layer = 5\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("ambient")\natlas_key = "{key}"\nroute = '+poly(path)+f'\nwalk_speed = {speed}.0\nmetadata/label = "{label}"')
        chunks.append(f'[node name="Art" type="Sprite2D" parent="Town/{name}"]\ntexture = ExtResource("d_{key}")\ncentered = false\nregion_enabled = true')
        chunks.append(f'[node name="Body" type="CollisionShape2D" parent="Town/{name}"]\nshape = SubResource("actor_body")')
    chunks.append(f'[node name="HomeRoom" parent="." instance=ExtResource("home_scene")]\nvisible = false\nposition = Vector2(12000, 1000)')
    chunks.append('[node name="HomeDoor" type="Marker2D" parent="Town"]\nposition = Vector2(1700, 1545)')
    target=PROJECT/SCENE;target.parent.mkdir(parents=True,exist_ok=True);target.write_text('\n\n'.join(chunks)+'\n','utf-8')
    room=(ROOT/'game/scenes/drafts'/B/'inn_hall.tscn').read_text('utf-8');(PROJECT/ROOM).write_text(room,'utf-8')
    # One marked dwelling owns one cached domestic room, with independent native furniture.
    home=room[:room.index('[node name="Counter"')]
    home=home.replace('[node name="InnHall"','[node name="HomeRoom"')
    addition='\n\n'.join(f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="home_{key}"]' for key in ['bed','cloth_rack'])
    home=home.replace('[sub_resource',addition+'\n\n[sub_resource',1)
    for name,key,foot,height,body in [('Bed','bed',[-330,-155],150,rect(-140,-70,280,70)),('Clothes','cloth_rack',[340,-225],150,rect(-90,-35,180,35))]:
        b=boxes[key];s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]]
        home+=f'\n[node name="{name}" type="Node2D" parent="Sort"]\nposition = {vec(foot)}\n\n[node name="Art" type="Sprite2D" parent="Sort/{name}"]\nposition = {vec([-v*s for v in pivot])}\nscale = {vec([s,s])}\ntexture = ExtResource("home_{key}")\ncentered = false\n\n[node name="Body" type="StaticBody2D" parent="Sort/{name}"]\ncollision_layer = 1\ncollision_mask = 0\n\n[node name="Footprint" type="CollisionPolygon2D" parent="Sort/{name}/Body"]\npolygon = {poly(body)}\n'
    home+='\n[node name="Exit" type="Marker2D" parent="."]\nposition = Vector2(0,-45)\n'
    (PROJECT/HOME).write_text(home,'utf-8')
    controller=PROJECT/SCRIPT;controller.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(STAGE/'source/town_controller.gd',controller)
    shutil.copyfile(STAGE/'source/ambient_actor.gd',controller.parent/'ambient_actor.gd')
    shader=(ROOT/'game/art/modules'/B/'ground.gdshader').read_text('utf-8')
    insertion=''
    for name,points in ROADS.items():
        for a,b in zip(points,points[1:]):insertion+=f'secondary=min(secondary,dseg(p,vec2({fmt(a[0])},{fmt(a[1])}),vec2({fmt(b[0])},{fmt(b[1])})));\n'
    shader=shader.replace('vec3 a=texture',insertion+'vec3 a=texture')
    (PROJECT/ART/'ground.gdshader').write_text(shader,'utf-8')
    # Scene's existing ground material adopts the new road shader.
    target.write_text(target.read_text('utf-8').replace(f'res://art/modules/{B}/ground.gdshader',f'res://{ART}/ground.gdshader'),'utf-8')
    config=(ROOT/'assets/staging'/B/'town_project/project.godot').read_text('utf-8').replace(B,NAME).replace(f'scenes/drafts/{B}/redrock_town.tscn',SCENE)
    (PROJECT/'project.godot').write_text(config,'utf-8')
    (PROJECT/'artifacts').mkdir()
    layout={'scene':SCENE,'room':ROOM,'home':HOME,'media':media,'base_media':old['media'],'instances':instances,'new_routes':ROADS,'inherited_routes':old['full_routes'],'outline':OUTLINE,'atlases':atlases,'formal_world_entry':False}
    save(STAGE/'layout.json',layout);save(PROJECT/'layout.json',layout)
    print(json.dumps({'new_media':len(media),'new_instances':len(instances),'new_routes':len(ROADS),'atlas_frames':36,'project':str(PROJECT)}))

if __name__=='__main__':build()
