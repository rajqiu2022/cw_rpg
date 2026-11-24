"""Assemble the dedicated successor with real courtyard feet and cached inn hall."""
import copy
import json
import re
import shutil

import numpy as np
from PIL import Image

from redrock_luoyang_standard_20261028b import ROOT,NAME,RAW,STAGE,PROJECT,ART,SCENE,SCRIPT,save,sha
from build_redrock_town_20261028a import vec,poly,fmt

A='redrock_town_20261028a'
ROOM=f'scenes/drafts/{NAME}/inn_hall.tscn'
ROUTES={
 'living_main':[[2250,3380],[2475,3380],[2475,2720],[2350,2720]],
 'inn_gate':[[2250,3380],[1550,3380],[1550,3150],[1530,3110]],
 'stable_gate':[[2475,3340],[3400,3340],[3400,3170]],
 'water_gate':[[2350,2720],[1900,2720],[1900,2560],[1100,2560],[1100,2380]],
 'work_gate':[[2475,2720],[3650,2720],[3650,2570],[4500,2570],[4500,2380]],
}


def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]


def build():
    assert not PROJECT.exists()
    (PROJECT/ART).mkdir(parents=True)
    old=json.loads((ROOT/'assets/staging'/A/'layout.json').read_text('utf-8'))
    source={r['key']:r['source'] for r in old['media']}
    rows=json.loads((RAW/'resource-pack.json').read_text('utf-8'))['assets'];assert len(rows)==4
    source.update({r['key']:r['output'] for r in rows})
    for key,file in {'counter':'inn_counter_v1.png','table':'dining_table_v1.png','bench':'long_bench_v1.png','shelf':'wine_tea_shelf_v1.png'}.items():
        source[key]='game/art/modules/luoyang_assembled_interiors_20261016g/'+file
    media=[];boxes={};sizes={}
    for key,path in source.items():
        dest=PROJECT/ART/(key+'.png');shutil.copyfile(ROOT/path,dest)
        with Image.open(dest) as im:
            sizes[key]=list(im.size)
            if 'A' in im.getbands():
                a=np.array(im.getchannel('A'));y,x=np.where(a>=128);b=[int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
            else:b=[0,0,im.width,im.height]
        boxes[key]=b
        media.append({'key':key,'source':path,'destination':f'{ART}/{key}.png','sha256':sha(dest),'diagnostic_alpha128_bbox':b,'original_pixels_changed':False})
    text=(ROOT/'game/scenes/drafts'/A/'redrock_town.tscn').read_text('utf-8').replace(A,NAME)
    header=text[:text.index('[node ')]
    additions=[f'[ext_resource type="Texture2D" path="res://{ART}/{k}.png" id="{k}"]' for k in source if k not in {r['key'] for r in old['media']}]
    additions.append(f'[ext_resource type="PackedScene" path="res://{ROOM}" id="inn_room_scene"]')
    header=header.replace('[sub_resource', '\n\n'.join(additions)+'\n\n[sub_resource',1)
    matches=list(re.finditer(r'\[node name="([^"]+)"[^\n]*\]',text))
    blocks=[text[m.start():matches[i+1].start() if i+1<len(matches) else len(text)] for i,m in enumerate(matches)]
    moved={'Inn':[1650,3045],'Stable':[3400,3070],'InnCargo':[2110,3100],'StableTrough':[3830,3125],'LowLeft':[1110,3750]}
    updated=[]
    for b in blocks:
        h=b.splitlines()[0]
        if 'name="Dwelling11"' in h or 'parent="Town/Dwelling11' in h:continue
        for name,position in moved.items():
            if f'name="{name}" type="Node2D" parent="Town"' in h:
                b=re.sub(r'(?m)^position = Vector2\([^)]+\)', 'position = '+vec(position), b, count=1)
        if 'name="WaterLedge" type="Node2D" parent="Town"' in h:
            # Entire old ledge moves away from the new front-street band; no art scaling.
            b=re.sub(r'(?m)^position = Vector2\([^)]+\)','position = Vector2(995, 3000)',b,count=1)
        if 'name="WorkLedge" type="Node2D" parent="Town"' in h:
            b=re.sub(r'(?m)^position = Vector2\([^)]+\)','position = Vector2(4900, 3010)',b,count=1)
        if 'name="TopPanel"' in h:b=b.replace('offset_right = 1000.0','offset_right = 1120.0')
        if 'name="Detail" type="Panel"' in h:b=b.replace('offset_left = 1120.0','offset_left = 1160.0').replace('offset_bottom = 210.0','offset_bottom = 650.0')
        if 'name="Text" type="Label" parent="UI/Detail"' in h:
            b=b.replace('offset_left = 22.0','offset_left = 230.0').replace('offset_right = 748.0','offset_right = 710.0').replace('offset_bottom = 150.0','offset_bottom = 590.0')
        updated.append(b)
    parts=[header]+updated
    # Native region view partitions reuse the full immutable PNG; no cropped raster is written.
    native_w,native_h=sizes['court_wall'];pivot=[889,708]
    native_bodies=[[[373,347],[1470,347],[1470,373],[373,373]],[[350,350],[390,365],[245,530],[148,615],[110,595],[185,450]],[[1456,350],[1495,350],[1655,585],[1640,615],[1540,527]],[[141,571],[630,655],[630,709],[145,620]],[[1160,655],[1650,570],[1650,620],[1160,709]]]
    courts=[]
    for name,foot in [('InnCourt',[1550,3220]),('StableCourt',[3400,3240]),('WaterCourt',[1100,2450]),('WorkCourt',[4500,2470])]:
        scale=.9
        bodies=[[[ (x-pivot[0])*scale,(y-pivot[1])*scale] for x,y in points] for points in native_bodies]
        parts.append(f'[node name="{name}Physics" type="StaticBody2D" parent="Town"]\nposition = {vec(foot)}\ncollision_layer = 1\ncollision_mask = 0')
        for i,points in enumerate(bodies):parts.append(f'[node name="Wall{i}" type="CollisionPolygon2D" parent="Town/{name}Physics"]\npolygon = '+poly(points))
        for suffix,y0,y1,sort_y in [('Back',0,373,373),('Sides',373,510,510),('Front',510,native_h,708)]:
            pos=[foot[0],foot[1]+(sort_y-pivot[1])*scale]
            parts.append(f'[node name="{name}{suffix}" type="Node2D" parent="Town"]\nposition = {vec(pos)}\nmetadata/static_region = true')
            parts.append(f'[node name="Art" type="Sprite2D" parent="Town/{name}{suffix}"]\nposition = {vec([-pivot[0]*scale,(y0-sort_y)*scale])}\nscale = {vec([scale,scale])}\ntexture = ExtResource("court_wall")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2(0, {y0}, {native_w}, {y1-y0})')
        courts.append({'name':name,'foot':foot,'scale':scale,'source_pivot':pivot,'footprints':bodies,'region_partitions':[[0,373],[373,510],[510,native_h]],'source_pixels_changed':0})
    parts+=['[node name="Door" type="Marker2D" parent="Town"]\nposition = Vector2(1530, 3110)', '[node name="Label" type="Label" parent="Town/Door"]\noffset_left = -85.0\noffset_top = -8.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 18\ntext = "驿舍前厅 · 空格"', '[node name="InnHall" parent="." instance=ExtResource("inn_room_scene")]\nvisible = false\nposition = Vector2(9000, 1000)', '[node name="Portrait" type="TextureRect" parent="UI/Detail"]\nvisible = false\noffset_left = 18.0\noffset_top = 18.0\noffset_right = 214.0\noffset_bottom = 410.0\ntexture = ExtResource("keeper_portrait")\nexpand_mode = 1\nstretch_mode = 5']
    target=PROJECT/SCENE;target.parent.mkdir(parents=True,exist_ok=True);target.write_text('\n\n'.join(parts)+'\n','utf-8')
    room=['[gd_scene format=3]']+[f'[ext_resource type="Texture2D" path="res://{ART}/{k}.png" id="{k}"]' for k in ['inn_room','keeper_sprite','counter','table','bench','shelf']]
    room += ['[sub_resource type="SystemFont" id="font"]\nfont_names = PackedStringArray("Microsoft YaHei", "Noto Sans CJK SC")','[node name="InnHall" type="Node2D"]','[node name="Architecture" type="Sprite2D" parent="."]\nz_index = -10\ntexture = ExtResource("inn_room")\ncentered = false\nposition = Vector2(-998.4,-968.5)\nscale = Vector2(1.3,1.3)', '[node name="Sort" type="Node2D" parent="."]\ny_sort_enabled = true','[node name="Boundary" type="StaticBody2D" parent="."]\ncollision_layer = 1\ncollision_mask = 0']
    floor=[[(x-768)*1.3,(y-745)*1.3] for x,y in [[375,505],[1165,505],[1250,745],[280,745]]]
    room.append('[node name="FloorEdge" type="CollisionPolygon2D" parent="Boundary"]\nbuild_mode = 1\npolygon = '+poly(floor))
    furniture=[]
    for name,key,foot,height,body in [('Counter','counter',[-330,-210],100,rect(-161,-46.6,322,46.6)),('Dining','table',[340,-90],80,rect(-59,-27.8,118,27.8)),('Bench','bench',[-330,-65],50,rect(-130,-28,260,28)),('Shelf','shelf',[350,-265],140,rect(-100,-32,200,32)),('Keeper','keeper_sprite',[-330,-285],112,rect(-17.5,-12.5,35,25))]:
        b=boxes[key];scale=height/(b[3]-b[1]);p=[(b[0]+b[2])/2,b[3]]
        room += [f'[node name="{name}" type="Node2D" parent="Sort"]\nposition = {vec(foot)}',f'[node name="Art" type="Sprite2D" parent="Sort/{name}"]\nposition = {vec([-v*scale for v in p])}\nscale = {vec([scale,scale])}\ntexture = ExtResource("{key}")\ncentered = false',f'[node name="Body" type="StaticBody2D" parent="Sort/{name}"]\ncollision_layer = 1\ncollision_mask = 0',f'[node name="Footprint" type="CollisionPolygon2D" parent="Sort/{name}/Body"]\npolygon = '+poly(body)]
        furniture.append({'name':name,'key':key,'foot':foot,'height':height,'footprint':body})
    room += ['[node name="Exit" type="Marker2D" parent="."]\nposition = Vector2(0,-45)','[node name="Label" type="Label" parent="Exit"]\noffset_left = -150.0\noffset_top = -15.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 18\ntext = "返回驿舍马院 · 空格"']
    (PROJECT/ROOM).write_text('\n\n'.join(room)+'\n','utf-8')
    controller=PROJECT/SCRIPT;controller.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(STAGE/'source/town_controller.gd',controller)
    old_routes=copy.deepcopy(old['routes']);old_routes['main']=old_routes['main'][:2]+ROUTES['living_main'][1:]+old_routes['main'][5:]
    old_routes.update({'water':ROUTES['water_gate'],'workshop':ROUTES['work_gate'],'inn_front':ROUTES['inn_gate'],'stable_front':ROUTES['stable_gate']})
    shader='shader_type canvas_item;\nrender_mode unshaded;\nuniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;\nuniform sampler2D rock_tex:source_color,repeat_enable,filter_linear;\nvarying vec2 p;\nvoid vertex(){p=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}\nfloat dseg(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/dot(v,v),0.,1.));}\nvoid fragment(){float main=99999.;float secondary=99999.;float alley=99999.;\n'
    for name,points in old_routes.items():
        bucket='main' if name=='main' else ('alley' if name=='lanes' else 'secondary')
        for a,b in zip(points,points[1:]):shader+=f'{bucket}=min({bucket},dseg(p,vec2({fmt(a[0])},{fmt(a[1])}),vec2({fmt(b[0])},{fmt(b[1])})));\n'
    shader+='vec3 a=texture(earth_tex,p/1450.).rgb;vec3 b=texture(rock_tex,p/1850.).rgb;float m=1.-smoothstep(120.,160.,main);float s=1.-smoothstep(65.,100.,secondary);float l=1.-smoothstep(45.,72.,alley);vec3 smoothsoil=(a+texture(earth_tex,p/1450.+vec2(.31,.27)).rgb)*.5;float path=max(m,max(s,l));COLOR=vec4(mix(mix(a,b,.28)*.86,mix(smoothsoil,vec3(.68,.47,.29),.56),path),1.);}\n'
    (PROJECT/ART/'ground.gdshader').write_text(shader,'utf-8')
    (PROJECT/'project.godot').write_text('config_version=5\n[application]\nconfig/name="赤岩生活街段规范验证28b"\nrun/main_scene="res://'+SCENE+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+NAME+'_validation"\nconfig/features=PackedStringArray("4.6","GL Compatibility")\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nenvironment/defaults/default_clear_color=Color(0.16,0.10,0.065,1)\n','utf-8')
    layout={'scene':SCENE,'room_scene':ROOM,'media':media,'courts':courts,'routes':ROUTES,'full_routes':old_routes,'room_floor':floor,'furniture':furniture,'door':[1530,3110],'room_origin':[9000,1000],'room_entry':[0,-75],'moved':moved,'removed':['Dwelling11'],'old_geometry_credit':'28a unchanged gate, upper zones and original imports not repeated','road_target_widths':{'main':320,'secondary':200,'alley':144},'formal_world_entry':False}
    save(STAGE/'layout.json',layout);save(PROJECT/'layout.json',layout)
    print(json.dumps({'media':len(media),'courts':4,'real_room':ROOM,'local_routes':len(ROUTES)}))


def imports():
    n=0
    for p in (PROJECT/ART).glob('*.png.import'):
        text=p.read_text('utf-8').replace('process/fix_alpha_border=true','process/fix_alpha_border=false').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
        p.write_text(text,'utf-8');n+=1
    assert n==28
    print('Configured 28 exact-RGBA imports')


def finish():
    assert not (STAGE/'publication.json').exists()
    layout=json.loads((STAGE/'layout.json').read_text('utf-8'));text=(PROJECT/ROOM).read_text('utf-8')
    changed=[]
    for name,height in [('Counter',100),('Dining',80)]:
        row=next(r for r in layout['furniture'] if r['name']==name);ratio=height/row['height']
        assert ratio<1
        marker=r'\[node name="Art" type="Sprite2D" parent="Sort/'+name+r'"\](.*?)(?=\[node|\Z)'
        found=re.search(marker,text,re.S);block=found[0]
        for prop in ['position','scale']:
            values=[float(x) for x in re.search(prop+r' = Vector2\(([^)]+)\)',block)[1].split(',')]
            block=re.sub(prop+r' = Vector2\([^)]+\)',prop+' = '+vec([v*ratio for v in values]),block)
        text=text[:found.start()]+block+text[found.end():]
        old=copy.deepcopy(row['footprint']);row['footprint']=[[x*ratio,y*ratio] for x,y in old];row['height']=height
        marker=r'(\[node name="Footprint" type="CollisionPolygon2D" parent="Sort/'+name+r'/Body"\]\s*)polygon = PackedVector2Array\([^)]+\)'
        text=re.sub(marker,lambda m:m[1]+'polygon = '+poly(row['footprint']),text)
        changed.append({'name':name,'ratio':ratio,'old_body':old,'new_body':row['footprint'],'only_contained_shrink':all(old[0][0]<=x<=old[1][0] and old[0][1]<=y<=old[2][1] for x,y in row['footprint'])})
    (PROJECT/ROOM).write_text(text,'utf-8');save(STAGE/'layout.json',layout);save(PROJECT/'layout.json',layout)
    controller=(STAGE/'source/town_controller.gd').read_text('utf-8')
    controller=controller.replace('\t$UI/Detail.visible=show_details','\tif not in_hall and view_mode>=2:\n\t\t$UI/Hint.text="分区观察镜头　Tab切回全景/跟随；空格交互以角色位置为准"\n\t$UI/Detail.visible=show_details')
    (STAGE/'source/town_controller.gd').write_text(controller,'utf-8');(PROJECT/SCRIPT).write_text(controller,'utf-8')
    path=PROJECT/SCENE;text=path.read_text('utf-8').replace('驿舍：平顶接待楼，本轮仅外观与院场。','驿舍：独立前厅已接，主门按空格进入并原脚返回。');path.write_text(text,'utf-8')
    save(STAGE/'final-proportion-delta.json',{'changes':changed,'old_79_checks_inherited':True,'new_blocking_area_added':False})


if __name__=='__main__':
    import sys
    {'build':build,'imports':imports,'finish':finish}[sys.argv[1]]()
