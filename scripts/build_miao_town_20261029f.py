"""Assemble the approved hillside city in its own project with native UV floors."""
import hashlib
import json
import math
import re
import shutil
from pathlib import Path
from PIL import Image
from miao_town_20261029f import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha, vec, poly, fmt

PROCESSED=ROOT/'assets/processed'/NAME
B='redrock_luoyang_standard_20261028b'
def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]

def build():
    assert not PROJECT.exists() and not PROCESSED.exists()
    old=ROOT/'assets/staging/desert_town_20261029d/town_project';PROJECT.mkdir()
    for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(old/folder,PROJECT/folder)
    (PROJECT/'artifacts').mkdir()
    (PROJECT/'project.godot').write_text('''config_version=5
[application]
config/name="苗风山城·六区木楼溪街"
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
environment/defaults/default_clear_color=Color(0.25,0.28,0.22,1.0)
''','utf-8')
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));assert len(m['assets'])==23
    media={};padding=[]
    for r in m['assets']:
        src=ROOT/r['output'];assert sha(src)==r['sha256'];im=Image.open(src);px=py=0
        if r['transparent']:
            assert im.mode=='RGBA';w,h=im.size;b=im.getchannel('A').getbbox()
            px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
            out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py))
            dst=PROCESSED/r['kind']/(r['id']+'_padded.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
            assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
            bb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh];assert min(margins)>=.1
            padding.append({'key':r['key'],'source':r['output'],'output':dst.relative_to(ROOT).as_posix(),'offset':[px,py],
                'source_sha256':sha(src),'sha256':sha(dst),'source_size':[w,h],'size':[nw,nh],'all_original_RGBA_exact':True,
                'new_pixels_RGBA_zero':True,'margins':margins,'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'padded_A1_pass':True,'alpha_cleaned_pixels':0})
        else:
            dst=PROCESSED/r['kind']/src.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
        b=im.convert('RGBA').getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()
        target=PROJECT/ART/(r['key']+'.png');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(dst,target)
        media[r['key']]={**r,'processed':dst.relative_to(ROOT).as_posix(),'processed_sha256':sha(dst),'destination':ART+'/'+r['key']+'.png','padding':[px,py],'bbox':list(b),'native_size':list(im.size)}
    save(STAGE/'padding-verification.json',{'authorization':'ai-rules6.7 blanket RGBA0 padding','rows':padding,'all_original_RGBA_exact':True,'alpha_cleaned_pixels':0})
    save(PROCESSED/'resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(r,output=r['processed'],sha256=r['processed_sha256']) for r in media.values()]})
    # Atlas regions remain original pixel regions; each frame is uniformly drawn at112px.
    def frame(key,col,row,columns,rows):
        r=media[key];im=Image.open(ROOT/r['output']);w,h=im.size
        x0=w*col//columns;y0=h*row//rows;x1=w*(col+1)//columns;y1=h*(row+1)//rows
        a=im.getchannel('A').crop((x0,y0,x1,y1));b=a.point(lambda v:255 if v>=128 else 0).getbbox();assert b
        assert b[0]>0 and b[1]>0 and b[2]<x1-x0 and b[3]<y1-y0,(key,col,row,b)
        px,py=r['padding'];height=b[3]-b[1]
        return {'texture':key,'region':[x0+px,y0+py,x1-x0,y1-y0],'pivot':[(b[0]+b[2])/2,b[3]],'height':height,'scale':112/height,'body_bbox':list(b)}
    atlas={}
    for who,side_row in [('man',0),('woman',1)]:
        atlas[who]={'idle':[frame(who+'_walk',0,row,4,4) for row in range(4)],'side_walk':[frame('side_stride',col,side_row,4,2) for col in range(4)],
            'left_runtime_flip':True,'vertical_walk_enabled':False,'note':'Four native directional idle frames; accepted side contact/passing cycle; weak original vertical walk not adopted for patrol.'}
    save(PROJECT/ART/'atlases.json',atlas);save(STAGE/'atlas-native-regions.json',atlas)
    ext=[];subs=[];nodes=[];objects=[];blockers=[];bridges=[];stairs=[];roads=[];reused=[]
    def texture(key,path):ext.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{key}"]')
    for key in media:texture(key,ART+'/'+key+'.png')
    for key in ['table','bench','counter','shelf','cargo','water_jars']:
        path=f'art/modules/{B}/{key}.png';texture(key,path);reused.append(path)
    ext += [f'[ext_resource type="Script" path="res://{SCRIPT}" id="controller"]',
        f'[ext_resource type="Script" path="res://scripts/drafts/{NAME}/resident.gd" id="resident"]',
        '[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="player"]',
        f'[ext_resource type="Script" path="res://scripts/drafts/{B}/preview_player.gd" id="adapter"]',
        f'[ext_resource type="Shader" path="res://{ART}/ground.gdshader" id="ground_shader"]',
        f'[ext_resource type="Shader" path="res://{ART}/water.gdshader" id="water_shader"]',
        f'[ext_resource type="Shader" path="res://{ART}/occlusion.gdshader" id="occlusion_shader"]']
    subs += ['[sub_resource type="RectangleShape2D" id="hero_body"]\nsize = Vector2(35,25)',
        '[sub_resource type="RectangleShape2D" id="npc_body"]\nsize = Vector2(25,18)',
        '[sub_resource type="SystemFont" id="font"]\nfont_names = PackedStringArray("Microsoft YaHei", "SimHei")',
        '[sub_resource type="StyleBoxFlat" id="panel"]\nbg_color = Color(0.07,0.10,0.085,0.93)\ncorner_radius_top_left = 8\ncorner_radius_top_right = 8\ncorner_radius_bottom_left = 8\ncorner_radius_bottom_right = 8',
        '[sub_resource type="ShaderMaterial" id="ground_mat"]\nshader = ExtResource("ground_shader")\nshader_parameter/earth_tex = ExtResource("ground")\nshader_parameter/path_tex = ExtResource("path")',
        '[sub_resource type="ShaderMaterial" id="water_mat"]\nshader = ExtResource("water_shader")\nshader_parameter/water_tex = ExtResource("water")']
    def node(name,kind,parent='.',props=''):
        nodes.append(f'[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent else '')+']\n'+props)
    def body(name,parent,points):
        node(name,'StaticBody2D',parent,'collision_layer = 1\ncollision_mask = 0')
        node('Outline','CollisionPolygon2D',parent+'/'+name,'polygon = '+poly(points));blockers.append({'path':parent+'/'+name,'polygon':points})
    def info(key):
        if key in media:return media[key]['bbox'],media[key]['padding']
        path=PROJECT/f'art/modules/{B}/{key}.png';im=Image.open(path).convert('RGBA');b=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox();return list(b),[0,0]
    def fade_material(name):
        sid='fade_'+name
        subs.append(f'[sub_resource type="ShaderMaterial" id="{sid}"]\nshader = ExtResource("occlusion_shader")\nshader_parameter/fade_enabled = 0.0');return sid
    def prop(name,key,foot,height,label,solid=True,points=None,parent='Town',fade=False,z=None):
        b,pad=info(key);s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*s
        props='position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+f'\nmetadata/visual_rect = Rect2({fmt(-width/2)}, {fmt(-height)}, {fmt(width)}, {fmt(height)})'
        if z is not None:props+='\nz_index = '+str(z)
        if fade:props+='\nmetadata/fade = true'
        node(name,'Node2D',parent,props)
        material='material = SubResource("'+fade_material(name)+'")\n' if fade else ''
        node('Art','Sprite2D',parent+'/'+name,material+'position = '+vec([-(pivot[0]+pad[0])*s,-(pivot[1]+pad[1])*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("{key}")\ncentered = false')
        points=points if points is not None else rect(-width*.44,-min(height*.21,100),width*.88,min(height*.21,100))
        if solid:body('Body',parent+'/'+name,points)
        result={'name':name,'key':key,'foot':foot,'height':height,'width':width,'scale':s,'pivot':pivot,'parent':parent,'body':points if solid else None,'label':label};objects.append(result);return result
    def road(points,width=95):roads.append({'points':points,'width':width})
    node('MiaoTown','Node2D',None,'script = ExtResource("controller")')
    node('Ground','Polygon2D','.','z_index = -20\nmaterial = SubResource("ground_mat")\npolygon = '+poly(rect(-1400,-1200,9800,7800)))
    # Narrow creek: only registered bridge corridors are walkable across its full width.
    waterpoly=[[1250,100],[1750,100],[1750,3750],[2200,3900],[6750,3900],[6750,4350],[2050,4350],[1250,4050]]
    node('Creek','Polygon2D','.','z_index = -15\nmaterial = SubResource("water_mat")\npolygon = '+poly(waterpoly))
    node('Town','Node2D','.','y_sort_enabled = true')
    # Native bridge deck underneath, original roof/rail foreground pieces above walking feet.
    def uv(name,key,points,parent,pivot,s,z=0,fade=False):
        pad=media[key]['padding'];props='z_index = '+str(z)+'\ntexture = ExtResource("'+key+'")\npolygon = '+poly([[(x-pivot[0])*s,(y-pivot[1])*s] for x,y in points])+'\nuv = '+poly([[x+pad[0],y+pad[1]] for x,y in points])
        if fade:props+='\nmaterial = SubResource("'+fade_material(parent.replace('/','_')+'_'+name)+'")'
        node(name,'Polygon2D',parent,props)
    for name,key,center,s in [('GateBridge','covered_bridge',[1500,3310],1.05),('MiddleBridge','open_bridge',[1500,2360],.67),('UpperBridge','open_bridge',[1500,1510],.67)]:
        covered=key=='covered_bridge';pivot=[887,520] if covered else [1086,327]
        w,h=media[key]['native_size'];back=499 if covered else 277;front=541 if covered else 352
        # Back and deck have no overlaid floor copy: original UV partition covers every source row exactly once.
        node(name,'Node2D','Town','position = '+vec(center)+'\nmetadata/bridge = true\nmetadata/label = '+json.dumps('有盖木桥：两端平接石路，桥栏独立阻挡。' if covered else '露天小桥：连接两岸巷路，桥外为不可行走水域。',ensure_ascii=False))
        node('Base','Node2D','Town/'+name,'z_index = -3')
        uv('Deck',key,rect(0,back,w,front-back),'Town/'+name+'/Base',pivot,s)
        under=front if covered else 406
        uv('Under',key,rect(0,under,w,h-under),'Town/'+name+'/Base',pivot,s)
        # Roof/back rail carries localized actor window. Native front rail is a separate slice.
        node('Foreground','Node2D','Town/'+name,'position = Vector2(0,22)')
        # Compensate parent sort offset in the source pivot, preserving original world UV placement.
        uv('Roof',key,rect(0,0,w,back),'Town/'+name+'/Foreground',[pivot[0],pivot[1]+22/s],s,0,True)
        if not covered:uv('Rail',key,rect(0,352,w,54),'Town/'+name+'/Foreground',[pivot[0],pivot[1]+22/s],s,0,True)
        # Front rails and deck supports: collision only on actual channel rails, clear both ends.
        x0=-650 if covered else -575;x1=650 if covered else 575
        ymin=(back-pivot[1])*s;ymax=(front-pivot[1])*s
        body('BackRail','Town/'+name,rect(x0,ymin-14,x1-x0,12))
        body('FrontRail','Town/'+name,rect(x0,ymax-2,x1-x0,14))
        bridges.append({'name':name,'key':key,'center':center,'scale':s,'source_pivot':pivot,'native_deck_rows':[back,front],
            'walk_y':[center[1]+ymin,center[1]+ymax-2],'open_water_y':[center[1]+ymin,center[1]+ymax-2]})
        road([[600,center[1]],[2300,center[1]]],85 if covered else 65)
    last=100
    for bridge in sorted(bridges,key=lambda r:r['center'][1]):
        lo,hi=bridge['open_water_y'];body('Water'+str(int(last)),'Town',rect(1250,last,500,lo-last));last=hi
    body('WaterLower','Town',rect(1250,last,500,4050-last))
    body('WaterBend','Town',[[1750,3750],[2200,3900],[2200,4350],[1750,4230]])
    body('WaterFront','Town',rect(2200,3900,4550,450))
    # Three levels, two short stairs per retaining edge; native middle strips repeat in original UV.
    for front,centers in [(1800,[3300,5250]),(2900,[2800,5100])]:
        cuts=[1850]
        spans=[];last=1850
        for x in centers:spans.append((last,x-220));last=x+220
        spans.append((last,6250))
        for i,(a,b) in enumerate(spans):
            if b<=a:continue
            wall_s=.86;remaining=b-a;cursor=a
            while remaining>.1:
                span=min(remaining,1640*wall_s);source_width=span/wall_s;pad=media['terrace']['padding'];nm='Terrace'+str(front)+'_'+str(i)+'_'+str(int(cursor))
                node(nm,'Node2D','Town','position = '+vec([cursor,front]))
                node('Art','Sprite2D','Town/'+nm,'position = '+vec([0,-465*wall_s])+'\nscale = '+vec([wall_s,wall_s])+f'\ntexture = ExtResource("terrace")\ncentered = false\nregion_enabled = true\nregion_rect = Rect2({pad[0]+260}, {pad[1]}, {fmt(source_width)}, 724)')
                cursor+=span;remaining-=span
            body('Retain'+str(front)+'_'+str(i),'Town',rect(a,front-170,b-a,178))
        for i,x in enumerate(centers):
            name='Stairs'+str(front)+'_'+str(i+1);s=440/844;pivot=[768,780]
            node(name,'Node2D','Town','position = '+vec([x,front])+'\nmetadata/label = "石阶：短踏面连接上下平台，侧沿独立阻挡。"')
            node('Base','Node2D','Town/'+name,'z_index = -2')
            # Split side cheeks along their real diagonal inner edges; central treads stay behind hero.
            middle=[[500,0],[1040,0],[1040,358],[1125,780],[1125,1024],[410,1024],[410,780],[500,358]]
            left=[[0,0],[500,0],[500,358],[410,780],[410,1024],[0,1024]]
            right=[[1040,0],[1536,0],[1536,1024],[1125,1024],[1125,780],[1040,358]]
            uv('Treads','stairs',middle,'Town/'+name+'/Base',pivot,s)
            uv('LeftCheek','stairs',left,'Town/'+name,pivot,s)
            uv('RightCheek','stairs',right,'Town/'+name,pivot,s)
            lp=[[450,358],[500,358],[410,780],[346,780]];rp=[[1040,358],[1090,358],[1190,780],[1125,780]]
            body('LeftSide','Town/'+name,[[(a-pivot[0])*s,(b-pivot[1])*s] for a,b in lp]);body('RightSide','Town/'+name,[[(a-pivot[0])*s,(b-pivot[1])*s] for a,b in rp])
            stairs.append({'name':name,'foot':[x,front],'scale':s,'top':[x,front+(390-780)*s],'left_native':lp,'right_native':rp,'floor_z':-2})
            road([[x,front+80],[x,front-260]],105)
    # Irregular close groups: upper homes, middle plaza neighborhoods, lower creek shops, west work yards.
    homes=[('house_front',[2380,1050],470),('house_back',[3070,960],450),('house_side',[3800,1020],490),('house_front',[4530,920],470),('house_back',[5260,1110],460),
        ('house_side',[2590,1480],460),('house_front',[4030,1440],450),('house_back',[4720,1500],450),
        ('house_front',[2280,2150],460),('house_side',[3000,2190],450),('house_back',[4550,2150],450),('house_front',[5450,2260],470),
        ('house_front',[2300,2580],450),('house_back',[5550,2690],450),('house_front',[620,1820],440),('house_back',[600,2880],430),
        ('house_front',[2450,3780],430),('house_side',[3280,3740],450),('house_back',[4430,3780],430),('house_front',[5450,3770],430),
        ('house_back',[2240,3000],430),('house_side',[5900,2980],450)]
    for i,(key,foot,h) in enumerate(homes):prop('Home'+str(i+1),key,foot,h,'木楼住户：门前接同层巷路，支柱下方不通行。',True,None,fade=True)
    for i,foot in enumerate([[2800,3260],[3920,3300],[5100,3270]]):prop('CreekShop'+str(i+1),'shop',foot,335,'临溪铺面：竹篮、农货与布匹沿檐下陈列。',True,None,fade=True)
    prop('WeavingHouse','weaving_house',[620,1220],420,'绣坊前厅：从门前空格进入木楼。',True,None,fade=True)
    prop('DyeWorkshop','weaving_house',[700,2250],410,'蜡染作坊：染缸和晾布架置于院边，主巷保持开放。',True,None,fade=True)
    for i,foot in enumerate([[5750,1320],[6000,1570],[5920,3630]]):prop('Granary'+str(i+1),'granary',foot,320,'抬高粮仓：粮院接田间路，储粮与晾晒分列。',True,None,fade=True)
    prop('Gate','gate',[650,3510],340,'山口寨门：穿过门洞，过木桥进入溪街。',False,None,fade=True)
    # Only the feet/fence wings block; gate passage is left open.
    body('GateLeft','Town',rect(330,3440,190,80));body('GateRight','Town',rect(765,3440,215,80))
    for i,foot in enumerate([[5870,800],[6120,1080]]):
        prop('Paddy'+str(i+1),'paddy',foot,300,'小片梯田：生产区与街巷分开。',True,rect(-390,-160,780,155),z=-4)
    for i,foot in enumerate([[300,1330],[350,2370],[820,2370]]):prop('DryingRack'+str(i+1),'cloth_rack',foot,160,'晾布架：蓝白蜡染布与染缸沿院边摆放。')
    props=[('table',[520,1320],80),('bench',[520,1400],50),('water_jars',[920,1280],80),('cargo',[430,2450],85),
        ('table',[1030,2510],80),('bench',[1030,2580],50),('bench',[3430,2540],50),('bench',[4120,2540],50),
        ('table',[4150,2360],80),('water_jars',[2800,2320],80),('water_jars',[4900,2330],80),('cargo',[5800,1680],85),
        ('cargo',[6150,3670],85),('water_jars',[2180,3840],75),('water_jars',[3710,3840],75),('cargo',[4900,3840],85),
        ('bench',[980,3650],50),('cargo',[370,3640],85),('table',[3540,3500],80),('bench',[3540,3570],50)]
    for i,(key,foot,h) in enumerate(props):prop('LifeProp'+str(i+1),key,foot,h,'街院陈设：置于门侧或院边，桥头与阶口留空。')
    prop('PlazaTree','trees',[3370,2360],320,'芦笙坪树荫：活动场地中央保持开敞。',True,rect(-45,-32,90,40))
    # Tree clusters enclose the map organically. No giant rectangular city wall.
    forest=[]
    for i,x in enumerate(range(-100,6701,430)):forest.append([x,260+(i%3)*65])
    for i,y in enumerate(range(680,4201,400)):forest.extend([[-100+(i%2)*80,y],[6600-(i%2)*60,y+50]])
    for i,x in enumerate(range(1600,6701,430)):forest.append([x,4750+(i%2)*45])
    for i,foot in enumerate(forest):prop('Forest'+str(i+1),'trees',foot,420+(i%3)*20,'山林边界。',True,rect(-130,-45,260,50))
    routes=[('WestWeaver','woman',[[560,1410],[900,1410]]),('DyeWorker','woman',[[540,2450],[850,2450]]),
        ('CreekVendor','man',[[2600,3450],[3050,3450]]),('ClothVendor','woman',[[4000,3460],[4350,3460]]),
        ('PlazaCraftsman','man',[[3700,2560],[4000,2560]]),('UpperResident','woman',[[3500,1610],[4300,1610]]),
        ('Farmer','man',[[5860,1390],[6190,1390]]),('LaneWorker','man',[[2250,2670],[2550,2670]])]
    for name,identity,route in routes:
        node(name,'CharacterBody2D','Town','position = '+vec(route[0])+'\ncollision_layer = 4\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("resident")\nidentity = "'+identity+'"\nroute = '+poly(route)+'\nmetadata/portrait = "'+identity+'_portrait"\nmetadata/label = '+json.dumps('绣坊居民：沿院前巷照料布料。' if identity=='woman' else '普通工匠：沿街候行，工具与货物放在路旁。',ensure_ascii=False))
        node('Art','Sprite2D','Town/'+name,'texture = ExtResource("'+identity+'_walk")\ncentered = false\nregion_enabled = true')
        node('Foot','CollisionShape2D','Town/'+name,'shape = SubResource("npc_body")')
    nodes.append('[node name="Player" parent="Town" instance=ExtResource("player")]\nposition = Vector2(650,3780)\nz_index = 0\ncollision_layer = 2\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("adapter")')
    nodes.append('[node name="CollisionShape2D" parent="Town/Player" index="1"]\nposition = Vector2(0,0)\nshape = SubResource("hero_body")')
    node('WorkshopDoor','Marker2D','Town','position = Vector2(590,1255)')
    # Cached wooden reception: split original floor and wall UV; furniture remains independently solid.
    node('HouseHall','Node2D','.','visible = false\nposition = Vector2(10000,3000)');node('Sort','Node2D','HouseHall','y_sort_enabled = true')
    pivot=[768,740];s=1.35
    uv('Floor','interior',[[320,487],[1230,487],[1320,740],[220,740]],'HouseHall',pivot,s,-2)
    for i,points in enumerate([[[181,243],[1372,243],[1230,487],[320,487]],[[181,243],[320,487],[220,740],[181,749]],[[1230,487],[1372,243],[1372,749],[1320,740]]]):uv('Wall'+str(i+1),'interior',points,'HouseHall',pivot,s,-1)
    body('Back','HouseHall',rect(-600,-355,1230,20));body('Left','HouseHall',[[-755,0],[-610,-345],[-585,-335],[-730,10]])
    body('Right','HouseHall',[[750,0],[635,-345],[610,-335],[725,10]])
    body('FrontLeft','HouseHall',rect(-760,-2,635,20));body('FrontRight','HouseHall',rect(125,-2,635,20))
    node('Exit','Marker2D','HouseHall','position = Vector2(0,-40)')
    for name,key,foot,h in [('Table','table',[-250,-145],80),('Bench','bench',[-250,-65],50),('Counter','counter',[320,-170],110),('Shelf','shelf',[-490,-270],170)]:prop(name,key,foot,h,'木楼前厅家具。',True,None,'HouseHall/Sort')
    node('Keeper','CharacterBody2D','HouseHall/Sort','position = Vector2(320,-235)\ncollision_layer = 4\ncollision_mask = 1\nscript = ExtResource("resident")\nidentity = "woman"\nmetadata/portrait = "woman_portrait"')
    node('Art','Sprite2D','HouseHall/Sort/Keeper','texture = ExtResource("woman_walk")\ncentered = false\nregion_enabled = true')
    node('Foot','CollisionShape2D','HouseHall/Sort/Keeper','shape = SubResource("npc_body")')
    outline=[[-250,4200],[-250,700],[400,350],[1200,350],[1200,450],[1800,450],[6200,450],[6460,900],[6460,4370],[5900,4630],[1800,4630],[900,4280]]
    node('Boundary','StaticBody2D','.','collision_layer = 1\ncollision_mask = 0');node('Outline','CollisionPolygon2D','Boundary','build_mode = 1\npolygon = '+poly(outline))
    node('Camera','Camera2D','.','position = Vector2(650,3590)\nzoom = Vector2(0.9,0.9)')
    node('UI','CanvasLayer')
    node('TopPanel','Panel','UI','offset_left = 20.0\noffset_top = 18.0\noffset_right = 1020.0\noffset_bottom = 105.0\ntheme_override_styles/panel = SubResource("panel")')
    for name,x,y,size,text in [('Title',40,28,28,'苗风山城'),('Status',42,70,19,'木楼溪街'),('Hint',28,1033,20,'WASD移动')]:node(name,'Label','UI',f'offset_left = {x}.0\noffset_top = {y}.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = {size}\ntext = '+json.dumps(text,ensure_ascii=False))
    node('Detail','Panel','UI','visible = false\noffset_left = 1100.0\noffset_top = 24.0\noffset_right = 1890.0\noffset_bottom = 590.0\ntheme_override_styles/panel = SubResource("panel")')
    node('Portrait','TextureRect','UI/Detail','offset_left = 18.0\noffset_top = 24.0\noffset_right = 260.0\noffset_bottom = 460.0\nexpand_mode = 1\nstretch_mode = 5')
    node('Text','Label','UI/Detail','offset_left = 286.0\noffset_top = 28.0\noffset_right = 755.0\noffset_bottom = 540.0\nautowrap_mode = 2\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 23')
    # Graded road graph, with turns around shop and house footprints rather than crossing them.
    for points,width in [([[650,4070],[650,3650],[650,3310],[2300,3310],[2300,3450],[5800,3450]],110),
        ([[2200,3450],[2200,3070],[2800,3070],[2800,2970]],95),([[5750,3450],[5750,3060],[5100,3060],[5100,2970]],95),
        ([[2800,2630],[3800,2630],[3800,2420],[5100,2420],[5100,2630]],115),
        ([[3300,1880],[3300,1950],[3800,1950],[3800,2450]],95),([[5250,1880],[5900,1880],[5900,2500],[5100,2500]],90),
        ([[3300,1540],[3300,1580],[5400,1580],[6200,1390]],90),([[2300,1580],[3300,1580]],80),
        ([[1050,1180],[1050,3310]],75),([[1050,1410],[590,1410],[590,1255]],75),([[1050,2450],[550,2450]],80),
        ([[2000,1510],[2300,1510],[2300,1580]],75),([[2000,2360],[2060,2360],[2060,2660],[2800,2660]],80),
        ([[2350,3840],[5770,3840],[5770,3450]],75),([[2220,3450],[2220,3840],[2350,3840]],75)]:road(points,width)
    scene=PROJECT/SCENE;scene.parent.mkdir(parents=True,exist_ok=True);scene.write_text('[gd_scene load_steps='+str(1+len(ext)+len(subs))+' format=3]\n\n'+'\n\n'.join(ext+subs+nodes)+'\n','utf-8')
    # Native ground sampled with mirrored repeat to suppress texture edge discontinuity.
    lines=[]
    for row in roads:
        for a,b in zip(row['points'],row['points'][1:]):
            lines.append(' path=max(path,1.-smoothstep('+fmt(row['width']*.7)+','+fmt(row['width']+24)+',segment(p,'+','.join('vec2('+','.join(fmt(x) for x in v)+')' for v in [a,b])+')));')
    ground='''shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
'''+ '\n'.join(lines)+'''
 float plaza=1.-smoothstep(.88,1.,length((p-vec2(3800.,2430.))/vec2(650.,310.)));
 path=max(path,plaza);
 vec3 soil=texture(earth_tex,folded(p/900.)).rgb;
 vec3 stone=texture(path_tex,folded(p/440.)).rgb;
 COLOR=vec4(mix(soil,stone,path*.96),1.);}
'''
    water='''shader_type canvas_item;
uniform sampler2D water_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
void fragment(){vec2 q=p/650.+vec2(TIME*.004,TIME*.007);vec3 c=texture(water_tex,folded(q)).rgb;COLOR=vec4(c*.9,1.);}
'''
    occlusion='''shader_type canvas_item;
uniform vec2 hero_foot=vec2(0.);
uniform float fade_enabled=0.;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){vec4 t=texture(TEXTURE,UV);vec2 d=world_pixel-hero_foot;
 float x=1.-smoothstep(72.,125.,abs(d.x));float y=smoothstep(-195.,-155.,d.y)*(1.-smoothstep(8.,40.,d.y));
 COLOR=vec4(t.rgb,t.a*mix(1.,.13,x*y*fade_enabled));}
'''
    for file,code in [('ground.gdshader',ground),('water.gdshader',water),('occlusion.gdshader',occlusion)]: (PROJECT/ART/file).write_text(code,'utf-8')
    for file in ['town_controller.gd','resident.gd']:
        p=PROJECT/f'scripts/drafts/{NAME}/{file}';p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(STAGE/file,p)
    # Lossless alpha-preserving private imports, with stable resource-relative import IDs.
    template=(old/'art/modules/desert_town_20261029d/house_front.png.import')
    if not template.is_file():template=old/'art/modules/desert_town_20261029d/dwelling.png.import'
    base=template.read_text('utf-8');base=re.sub(r'^uid=.*\n','',base,flags=re.M)
    old_source=re.search(r'source_file="([^"]+)"',base)[1];old_import=re.search(r'path="([^"]+)"',base)[1]
    for p in (PROJECT/ART).glob('*.png'):
        rel=p.relative_to(PROJECT).as_posix();res='res://'+rel;imp='res://.godot/imported/'+p.name+'-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
        text=base.replace(old_source,res).replace(old_import,imp).replace('process/fix_alpha_border=true','process/fix_alpha_border=false').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
        p.with_suffix('.png.import').write_text(text,'utf-8')
    save(STAGE/'layout.json',{'scene':SCENE,'script':SCRIPT,'art':ART,'media':media,'objects':objects,'blockers':blockers,'bridges':bridges,'stairs':stairs,'roads':roads,
        'patrols':[{'name':n,'identity':i,'route':r} for n,i,r in routes],'reused_art':reused,'town_outline':outline,
        'new_native_images':23,'native_identity_count':2,'live_residents':8,'static_keeper':1,'formal_world_enabled':False,'PNG_processing':'RGBA0 padding only; all original RGBA exact'})
    print(f'Built private hillside city: {len(homes)}homes /3shops/2workhouses/3granaries, {len(objects)}objects, {len(blockers)}blockers,3bridges/4stairs,8walkers')

if __name__=='__main__':build()
