"""Build an isolated, native-art adobe city; no production/shared mutations."""
import json
import math
import re
import shutil
from pathlib import Path

from PIL import Image, ImageChops
from build_redrock_town_20261028a import ROOT, save, sha, vec, poly, fmt
from desert_town_20261029d import NAME, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT

PROCESSED=ROOT/'assets/processed'/NAME
D='redrock_desert_complete_20261028d'
B='redrock_luoyang_standard_20261028b'

def rectangle(x,y,w,h):
    return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]

def build():
    assert not PROJECT.exists() and not PROCESSED.exists()
    old=ROOT/'assets/staging/redrock_city_life_20261029a/town_project'
    PROJECT.mkdir()
    for folder in ['art','scripts','scenes','.godot/imported']:
        shutil.copytree(old/folder,PROJECT/folder)
    (PROJECT/'artifacts').mkdir()
    (PROJECT/'project.godot').write_text('''config_version=5
[application]
config/name="黄沙土坯城镇·六区"
run/main_scene="res://'''+SCENE+'''"
config/use_custom_user_dir=true
config/custom_user_dir_name="'''+NAME+'''_validation"
config/features=PackedStringArray("4.6","GL Compatibility")
[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
environment/defaults/default_clear_color=Color(0.6,0.45,0.25,1.0)
''','utf-8')
    manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
    media={};pad_receipts=[]
    for r in manifest['assets']:
        if r.get('rejected'):continue
        src=ROOT/r['output'];assert sha(src)==r['sha256']
        im=Image.open(src)
        if r['transparent']:
            assert im.mode=='RGBA'
            w,h=im.size;b=im.getchannel('A').getbbox()
            px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1
            py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
            padded=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));padded.paste(im,(px,py))
            out=PROCESSED/r['kind']/(r['id']+'_padded.png');out.parent.mkdir(parents=True,exist_ok=True);padded.save(out)
            assert ImageChops.difference(padded.crop((px,py,px+w,py+h)),im).getbbox() is None
            assert padded.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
            nb=padded.getchannel('A').getbbox();nw,nh=padded.size
            margins=[nb[0]/nw,nb[1]/nh,(nw-nb[2])/nw,(nh-nb[3])/nh]
            assert min(margins)>=.1
            pivot_bbox=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()
            pad_receipts.append({'key':r['key'],'source':r['output'],'output':out.relative_to(ROOT).as_posix(),
                'source_sha256':sha(src),'sha256':sha(out),'offset':[px,py],'source_size':[w,h],'size':[nw,nh],
                'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'margins':margins,
                'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'padded_A1_pass':True,'alpha_cleaned_pixels':0})
        else:
            out=PROCESSED/r['kind']/src.name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,out)
            px=py=0;pivot_bbox=[0,0,*im.size]
        dest=PROJECT/ART/(r['key']+'.png');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(out,dest)
        media[r['key']]={**r,'processed':out.relative_to(ROOT).as_posix(),'destination':ART+'/'+r['key']+'.png',
            'processed_sha256':sha(out),'padding':[px,py],'bbox':list(pivot_bbox),'native_size':list(im.size)}
    assert len(media)==13
    save(STAGE/'padding-verification.json',{'authorization':'User blanket permission ai-rules 6.7: transparent padding only',
        'rows':pad_receipts,'all_original_RGBA_preserved':True,'original_A1_failures_retained':True})
    save(PROCESSED/'resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(r,output=r['processed'],sha256=r['processed_sha256']) for r in media.values()]})

    ext=[];subs=[];nodes=[];objects=[];blockers=[];reused=set()
    def texture(key,path):
        ext.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{key}"]')
        if not path.startswith(ART+'/'):reused.add(path)
    for key in media:texture(key,ART+'/'+key+'.png')
    for key,file in [('water_jars','water_jars'),('trough','trough'),('cargo','cargo'),('wheelbench','wheelbench'),('table','table'),('bench','bench'),('counter','counter'),('shelf','shelf')]:
        texture(key,f'art/modules/{B}/{file}.png')
    for key in ['camel','merchant_walk','worker_walk','merchant_portrait','worker_portrait']:
        texture(key,f'art/modules/{D}/{key}.png')
    texture('keeper_sprite',f'art/modules/{B}/keeper_sprite.png')
    texture('keeper_portrait',f'art/modules/{B}/keeper_portrait.png')
    ext += [f'[ext_resource type="Script" path="res://{SCRIPT}" id="controller"]',
        '[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="player"]',
        f'[ext_resource type="Script" path="res://scripts/drafts/{B}/preview_player.gd" id="adapter"]',
        f'[ext_resource type="Script" path="res://scripts/drafts/{D}/ambient_actor.gd" id="ambient"]',
        f'[ext_resource type="Shader" path="res://{ART}/ground.gdshader" id="ground_shader"]']
    subs += ['[sub_resource type="RectangleShape2D" id="hero_body"]\nsize = Vector2(35,25)',
        '[sub_resource type="RectangleShape2D" id="npc_body"]\nsize = Vector2(25,18)',
        '[sub_resource type="SystemFont" id="font"]\nfont_names = PackedStringArray("Microsoft YaHei", "SimHei")',
        '[sub_resource type="StyleBoxFlat" id="panel"]\nbg_color = Color(0.12,0.085,0.04,0.92)\ncorner_radius_top_left = 8\ncorner_radius_top_right = 8\ncorner_radius_bottom_left = 8\ncorner_radius_bottom_right = 8',
        '[sub_resource type="ShaderMaterial" id="ground_mat"]\nshader = ExtResource("ground_shader")\nshader_parameter/sand_tex = ExtResource("sand")']
    def node(name,kind,parent='.',props=''):
        nodes.append(f'[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent else '')+']\n'+props)
    def body(name,parent,points):
        node(name,'StaticBody2D',parent,'collision_layer = 1\ncollision_mask = 0')
        node('Outline','CollisionPolygon2D',parent+'/'+name,'polygon = '+poly(points))
        blockers.append({'path':parent+'/'+name,'polygon':points})
    def source_info(key):
        if key in media:return media[key]['bbox'],media[key]['padding']
        p=PROJECT/next(re.search('path="res://([^\"]+)"',e)[1] for e in ext if f'id="{key}"' in e)
        im=Image.open(p).convert('RGBA');b=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()
        return list(b),[0,0]
    def prop(name,key,foot,height,label,solid=True,custom_body=None,parent='Town'):
        b,pad=source_info(key);scale=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]]
        width=(b[2]-b[0])*scale
        node(name,'Node2D',parent,'position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+f'\nmetadata/visual_rect = Rect2({fmt(-width/2)}, {fmt(-height)}, {fmt(width)}, {fmt(height)})')
        node('Art','Sprite2D',parent+'/'+name,'position = '+vec([-(pivot[0]+pad[0])*scale,-(pivot[1]+pad[1])*scale])+'\nscale = '+vec([scale,scale])+f'\ntexture = ExtResource("{key}")\ncentered = false')
        points=custom_body if custom_body is not None else rectangle(-width*.43,-min(height*.2,95),width*.86,min(height*.2,95))
        if solid:body('Body',parent+'/'+name,points)
        row={'name':name,'key':key,'foot':foot,'height':height,'width':width,'scale':scale,'pivot':pivot,'padding':pad,'parent':parent,'label':label,'body':points if solid else None}
        objects.append(row);return row
    node('DesertTown','Node2D',None,'script = ExtResource("controller")')
    node('Ground','Polygon2D','.', 'z_index = -20\nmaterial = SubResource("ground_mat")\npolygon = '+poly(rectangle(-2200,-800,13200,7500)))
    node('Town','Node2D','.', 'y_sort_enabled = true')
    # Complete native ring, partitioned in renderer regions, with identical UV and uniform scale.
    pad=media['enclosure_v2']['padding'];w,h=media['enclosure_v2']['native_size'];s=5;ox=200;oy=300;split=625
    node('WallRear','Node2D','Town','z_index = -1')
    node('Art','Sprite2D','Town/WallRear','position = '+vec([ox,oy])+f'\nscale = Vector2(5,5)\ntexture = ExtResource("enclosure_v2")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2({pad[0]}, {pad[1]}, {w}, {split})')
    node('WallFront','Node2D','Town','position = '+vec([ox,oy+793*s])+'\nmetadata/label = "沙路城门：连体土坯城廓，左侧城门接入巷市。"')
    node('Art','Sprite2D','Town/WallFront',f'position = Vector2(0,{(split-793)*s})\nscale = Vector2(5,5)\ntexture = ExtResource("enclosure_v2")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2({pad[0]}, {pad[1]+split}, {w}, {h-split})')
    walls=[[[190,315],[1430,315],[1430,350],[190,350]],[[190,330],[215,335],[113,665],[100,792],[20,792],[30,655]],
        [[1400,335],[1435,315],[1598,790],[1510,790],[1490,660]],[[100,768],[420,768],[420,798],[100,798]],[[525,768],[1520,768],[1520,798],[525,798]]]
    for i,points in enumerate(walls):body('WallBody'+str(i),'Town',[[ox+x*s,oy+y*s] for x,y in points])
    # Three native-depth rows, central winding street and two forecourts.
    for i,x in enumerate([1700,2550,3380,4230,5070,5900,6740]):
        prop('BackHome'+str(i+1),'corner_house' if i in [1,5] else 'dwelling',[x,2290],440 if i in [1,5] else 320,'土坯住户：平顶储物，门前留出横巷。')
    prop('Guesthouse','inn',[1350,2865],480,'驼队客栈：前方主门可进入前厅。')
    prop('CamelShelter','stable',[2310,2860],310,'驼棚：开放棚湾，货包与饮水分置。',True,rectangle(-465,-35,930,18))
    prop('BazaarWest','shop',[3620,2900],330,'遮阳巷市：陶器铺面与候行位置分开。')
    prop('BazaarEast','shop',[4620,2900],330,'遮阳巷市：布货棚下留出步行通道。')
    prop('Workshop','workshop',[5510,2900],335,'防沙工坊：陶窑和车轮作业放在背风侧。')
    prop('Well','well',[6630,2950],300,'井台蓄水：水井和加盖蓄水池，院内集中取水。')
    for i,x in enumerate([1080,1900,3400,4250,5100,5950,6800,7540]):
        prop('FrontHome'+str(i+1),'corner_house' if i in [1,5] else 'dwelling',[x,3550],420 if i in [1,5] else 310,'土坯民巷：屋前小坪连接主街，后侧留有服务巷。')
    # Native low courtyard wall: front foot at 616, inner ground at 415, entrance 700..1085.
    for name,foot,width,label in [('CaravanCourt',[1780,3090],1630,'驼队客院：正中院口供人行，驼兽和货包靠两侧。'),('WaterCourt',[6610,3090],1380,'井院：入口正对巷路，陶罐置于井边。')]:
        b,pad=source_info('court_wall');scale=width/(b[2]-b[0]);pivot=[(b[0]+b[2])/2,b[3]]
        row=prop(name,'court_wall',foot,(b[3]-b[1])*scale,label,False)
        # Trace only visible low wall feet, preserve open entrance; main building is beyond rear wall.
        pieces=[[[410,402],[1365,402],[1365,420],[410,420]],[[410,410],[427,420],[240,595],[212,582]],[[1360,410],[1380,400],[1572,580],[1540,595]],[[230,593],[697,593],[697,619],[230,619]],[[1088,593],[1555,593],[1555,619],[1088,619]]]
        for j,pts in enumerate(pieces):body('Edge'+str(j),'Town/'+name,[[(x-pivot[0])*scale,(y-pivot[1])*scale] for x,y in pts])
    for i,foot in enumerate([[6290,2570],[7040,2770]]):prop('DatePalm'+str(i+1),'palm',foot,360,'井边枣椰：仅在取水院旁保留少量树荫。',True,rectangle(-17,-16,34,24))
    for i,(foot,width) in enumerate([([-200,1900],2400),([2200,1000],3100),([6200,850],2800),([8870,3000],3200),([6300,5200],4000),([700,5400],3200)]):
        b,_=source_info('dune');prop('OuterDune'+str(i+1),'dune',foot,width*(b[3]-b[1])/(b[2]-b[0]),'城外缓沙丘。',False)
    for i,(key,foot,height) in enumerate([
        ('camel',[1630,2990],124),('camel',[2030,2980],124),('cargo',[1170,3010],90),('cargo',[2400,3010],90),('trough',[2260,2960],55),
        ('water_jars',[6350,3000],90),('water_jars',[7040,3010],90),('bench',[6200,3180],52),('wheelbench',[5770,3040],90),('cargo',[5370,3040],80),
        ('table',[3220,3090],76),('bench',[3220,3180],50),('water_jars',[710,3630],80),('water_jars',[3820,3630],80),('cargo',[5590,3630],80),
        ('bench',[1540,3650],50),('bench',[4710,3630],50),('water_jars',[6400,3630],80),('cargo',[2960,4100],90),('bench',[3000,4230],50),
        ('water_jars',[2090,2360],80),('cargo',[2950,2360],85),('water_jars',[4660,2360],80),('water_jars',[6300,2360],80)]):
        prop('LifeProp'+str(i+1),key,foot,height,{'camel':'驼兽：驼队客院休整。','water_jars':'储水陶罐：靠门侧存放。','wheelbench':'修车工作台：木轮和轴具。'}.get(key,'街院物件：靠院边布置，主路留空。'))
    # Ordinary reused residents, matching native portraits and genuine walk frames.
    patrols=[('CaravanTraveller','merchant_walk',[[1780,3130],[2090,3130]]),('BazaarTraveller','merchant_walk',[[3680,3070],[4460,3070]]),
        ('WaterTraveller','merchant_walk',[[6610,3140],[6880,3140]]),('WorkshopHand','worker_walk',[[5520,3110],[5790,3110]]),
        ('LaneResident','worker_walk',[[3440,3700],[4100,3700]]),('GateTraveller','merchant_walk',[[2550,3890],[2800,3890]])]
    for name,key,route in patrols:
        node(name,'CharacterBody2D','Town','position = '+vec(route[0])+f'\ncollision_layer = 4\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("ambient")\natlas_key = "{key}"\nroute = '+poly(route)+'\nmetadata/label = '+json.dumps('商旅：在巷市与客院间候行。' if key=='merchant_walk' else '工坊帮工：沿街照料院边物件。',ensure_ascii=False)+f'\nmetadata/portrait = "{key.replace("_walk","_portrait")}"')
        node('Art','Sprite2D','Town/'+name,f'texture = ExtResource("{key}")\ncentered = false\nregion_enabled = true')
        node('Body','CollisionShape2D','Town/'+name,'shape = SubResource("npc_body")')
    nodes.append('[node name="Player" parent="Town" instance=ExtResource("player")]\nposition = Vector2(2560,4550)\nz_index = 0\ncollision_layer = 2\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("adapter")')
    nodes.append('[node name="CollisionShape2D" parent="Town/Player" index="1"]\nposition = Vector2(0,0)\nshape = SubResource("hero_body")')
    node('InnDoor','Marker2D','Town','position = Vector2(1330,2895)')
    # Cached room: floor polygon always below actor; walls retain exact native UV.
    node('InnHall','Node2D','.','visible = false\nposition = Vector2(12000,3000)')
    node('Sort','Node2D','InnHall','y_sort_enabled = true')
    pad=media['guest_hall']['padding'];scale=1.5;pivot=[768,736]
    floor=[[416,536],[1144,536],[1252,736],[270,736]]
    wallparts=[[[223,288],[1314,288],[1144,536],[416,536]],[[223,288],[416,536],[270,736],[223,736]],[[1314,288],[1314,736],[1252,736],[1144,536]]]
    def uvpiece(name,points,z,parent):
        node(name,'Polygon2D',parent,'z_index = '+str(z)+'\ntexture = ExtResource("guest_hall")\npolygon = '+poly([[(x-pivot[0])*scale,(y-pivot[1])*scale] for x,y in points])+'\nuv = '+poly([[x+pad[0],y+pad[1]] for x,y in points]))
    uvpiece('Floor',floor,-2,'InnHall')
    for i,pts in enumerate(wallparts):uvpiece('Wall'+str(i+1),pts,-1,'InnHall')
    body('Back','InnHall',rectangle(-540,-315,1100,20));body('Left','InnHall',[[-730,-10],[-540,-310],[-515,-295],[-710,5]])
    body('Right','InnHall',[[720,-10],[560,-310],[535,-295],[700,5]])
    body('FrontLeft','InnHall',rectangle(-750,-2,630,20));body('FrontRight','InnHall',rectangle(120,-2,630,20))
    node('Exit','Marker2D','InnHall','position = Vector2(0,-35)')
    prop('Counter','counter',[330,-170],112,'客栈柜台。',True,None,'InnHall/Sort')
    prop('Keeper','keeper_sprite',[330,-235],112,'客栈掌柜：前厅照料行旅。',True,rectangle(-14,-16,28,22),'InnHall/Sort')
    prop('Shelf','shelf',[-450,-255],180,'客栈货架。',True,None,'InnHall/Sort')
    prop('Table','table',[-260,-130],80,'候行桌：桌前通道通向前厅入口。',True,None,'InnHall/Sort')
    prop('Bench','bench',[-260,-65],50,'候行长凳。',True,None,'InnHall/Sort')
    node('Boundary','StaticBody2D','.','collision_layer = 1\ncollision_mask = 0')
    node('Outline','CollisionPolygon2D','Boundary','build_mode = 1\npolygon = '+poly(rectangle(-1600,-200,12200,6500)))
    node('Camera','Camera2D','.','position = Vector2(2560,4350)\nzoom = Vector2(0.9,0.9)')
    node('UI','CanvasLayer')
    node('TopPanel','Panel','UI','offset_left = 20.0\noffset_top = 18.0\noffset_right = 980.0\noffset_bottom = 105.0\ntheme_override_styles/panel = SubResource("panel")')
    for name,x,y,size,text in [('Title',40,28,28,'黄沙土坯城镇'),('Status',42,70,19,'六区街院'),('Hint',28,1033,20,'WASD移动')]:
        node(name,'Label','UI',f'offset_left = {x}.0\noffset_top = {y}.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = {size}\ntext = '+json.dumps(text,ensure_ascii=False))
    node('Detail','Panel','UI','visible = false\noffset_left = 1110.0\noffset_top = 24.0\noffset_right = 1890.0\noffset_bottom = 570.0\ntheme_override_styles/panel = SubResource("panel")')
    node('Portrait','TextureRect','UI/Detail','offset_left = 18.0\noffset_top = 24.0\noffset_right = 260.0\noffset_bottom = 430.0\nexpand_mode = 1\nstretch_mode = 5')
    node('Text','Label','UI/Detail','offset_left = 286.0\noffset_top = 28.0\noffset_right = 748.0\noffset_bottom = 520.0\nautowrap_mode = 2\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 23')
    p=PROJECT/SCENE;p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text('[gd_scene load_steps='+str(1+len(ext)+len(subs))+' format=3]\n\n'+'\n\n'.join(ext+subs+nodes)+'\n','utf-8')
    for target,source in [(PROJECT/SCRIPT,STAGE/'town_controller.gd'),(PROJECT/ART/'ground.gdshader',STAGE/'ground.gdshader')]:
        target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
    save(STAGE/'layout.json',{'scene':SCENE,'script':SCRIPT,'art':ART,'media':media,'objects':objects,'blockers':blockers,
        'patrols':[{'name':n,'atlas':k,'route':r} for n,k,r in patrols],'reused_art':sorted(reused),
        'wall_original_uv_partition':625,'wall_uniform_scale':5,'palm_count':2,'formal_world_enabled':False})
    print(f'Built isolated city: {len(objects)} objects, {len(blockers)} static blockers, 6 walking residents, 13 native media')

if __name__=='__main__':build()
