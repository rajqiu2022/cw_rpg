"""Recompose around the approved diagonal creek, clustered slope and raised timber market."""
import hashlib
import json
import math
import re
import shutil
from PIL import Image
from miao_recompose_20261029g import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha, vec, poly, fmt

OLD='miao_town_20261029f';OLDART='art/modules/'+OLD
def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]

assert not PROJECT.exists()
oldproj=ROOT/'assets/staging'/OLD/'town_project';shutil.copytree(oldproj,PROJECT)
(PROJECT/'artifacts-g').mkdir()
config=(PROJECT/'project.godot').read_text('utf-8').replace('res://scenes/drafts/'+OLD+'/miao_town.tscn','res://'+SCENE).replace(OLD+'_validation',NAME+'_validation')
(PROJECT/'project.godot').write_text(config,'utf-8')
processed=ROOT/'assets/processed'/NAME;media={};padding=[]
for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
    src=ROOT/r['output'];assert sha(src)==r['sha256'];im=Image.open(src);w,h=im.size;px=py=0
    if r['transparent']:
        b=im.getchannel('A').getbbox();px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
        out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
        dst=processed/r['kind']/(r['id']+'_padded.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
        bb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh];assert min(margins)>=.1
        padding.append({'key':r['key'],'source':r['output'],'output':dst.relative_to(ROOT).as_posix(),'offset':[px,py],'source_sha256':sha(src),'sha256':sha(dst),'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'raw_A1_pass':r['metrics']['margin_10_percent_pass'],'margins':margins})
    else:
        dst=processed/r['kind']/src.name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
    b=im.convert('RGBA').getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();target=PROJECT/ART/(r['key']+'.png');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(dst,target)
    media[r['key']]={**r,'processed':dst.relative_to(ROOT).as_posix(),'processed_sha256':sha(dst),'destination':ART+'/'+r['key']+'.png','bbox':list(b),'padding':[px,py],'native_size':[w,h]}
    base=(PROJECT/OLDART/'trees.png.import').read_text('utf-8');base=re.sub(r'^uid=.*\n','',base,flags=re.M)
    oldsource=re.search(r'source_file="([^"]+)"',base)[1];oldimport=re.search(r'path="([^"]+)"',base)[1];res='res://'+ART+'/'+r['key']+'.png'
    imp='res://.godot/imported/'+r['key']+'.png-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
    target.with_suffix('.png.import').write_text(base.replace(oldsource,res).replace(oldimport,imp),'utf-8')
save(STAGE/'padding-verification.json',{'authorization':'ai-rules6.7','rows':padding,'alpha_cleaned_pixels':0})
save(processed/'resource-pack.json',{'status':'PADDED_NATIVE_CANDIDATES','assets':[dict(r,output=r['processed'],sha256=r['processed_sha256']) for r in media.values()]})
oldlayout=json.loads((ROOT/'assets/staging'/OLD/'layout.json').read_text('utf-8'));allmedia={**oldlayout['media'],**media}
original=(PROJECT/('scenes/drafts/'+OLD+'/miao_town.tscn')).read_text('utf-8');head=original[:original.index('[node ')]
head=head.replace('res://scripts/drafts/'+OLD+'/town_controller.gd','res://'+SCRIPT)
head=head.replace('res://'+OLDART+'/ground.gdshader','res://'+ART+'/ground.gdshader')
head=head.replace('shader_parameter/earth_tex = ExtResource("ground")','shader_parameter/earth_tex = ExtResource("woodland_floor")\nshader_parameter/dirt_tex = ExtResource("ground")')
extra=[f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="{key}"]' for key in media]
head=head.replace('[sub_resource','\n\n'.join(extra)+'\n\n[sub_resource',1)
nodes=[];subs=[];objects=[];blockers=[];bridges=[];stairs=[];roads=[];patrols=[]
def node(name,kind,parent='.',props=''):
    nodes.append(f'[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent else '')+']\n'+props)
def body(name,parent,points):
    node(name,'StaticBody2D',parent,'collision_layer = 1\ncollision_mask = 0');node('Outline','CollisionPolygon2D',parent+'/'+name,'polygon = '+poly(points));blockers.append({'path':parent+'/'+name,'polygon':points})
def info(key):
    if key in allmedia:return allmedia[key]['bbox'],allmedia[key]['padding']
    p=PROJECT/f'art/modules/redrock_luoyang_standard_20261028b/{key}.png';im=Image.open(p);return list(im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()),[0,0]
def fade(name):
    sid='gfade_'+name;subs.append(f'[sub_resource type="ShaderMaterial" id="{sid}"]\nshader = ExtResource("occlusion_shader")\nshader_parameter/fade_enabled = 0.0');return sid
def prop(name,key,foot,height,label,solid=True,points=None,z=None,fade_on=False,ground=False):
    b,pad=info(key);s=height/(b[3]-b[1]);pivot=[(b[0]+b[2])/2,b[3]];width=(b[2]-b[0])*s
    props='position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+f'\nmetadata/visual_rect = Rect2({fmt(-width/2)}, {fmt(-height)}, {fmt(width)}, {fmt(height)})'
    if z is not None:props+='\nz_index = '+str(z)
    if ground:props+='\nmetadata/ground_cover = true'
    if fade_on:props+='\nmetadata/fade = true'
    node(name,'Node2D','Town',props)
    material='material = SubResource("'+fade(name)+'")\n' if fade_on else ''
    node('Art','Sprite2D','Town/'+name,material+'position = '+vec([-(pivot[0]+pad[0])*s,-(pivot[1]+pad[1])*s])+'\nscale = '+vec([s,s])+f'\ntexture = ExtResource("{key}")\ncentered = false')
    if points is None:points=rect(-width*.41,-min(height*.18,85),width*.82,min(height*.18,85))
    if solid:body('Body','Town/'+name,points)
    r={'name':name,'key':key,'foot':foot,'height':height,'width':width,'scale':s,'pivot':pivot,'body':points if solid else None};objects.append(r);return r
def uv(name,key,points,parent,pivot,s,z=0,mat=None):
    pad=allmedia[key]['padding'];props='z_index = '+str(z)+'\ntexture = ExtResource("'+key+'")\npolygon = '+poly([[(x-pivot[0])*s,(y-pivot[1])*s] for x,y in points])+'\nuv = '+poly([[x+pad[0],y+pad[1]] for x,y in points])
    if mat:props+='\nmaterial = SubResource("'+mat+'")'
    node(name,'Polygon2D',parent,props)
def road(points,width=64):roads.append({'points':points,'width':width})
node('MiaoTown','Node2D',None,'script = ExtResource("controller")')
node('Ground','Polygon2D','.','z_index = -20\nmaterial = SubResource("ground_mat")\npolygon = '+poly(rect(-1500,-1300,11200,8200)))
node('Town','Node2D','.','y_sort_enabled = true')

# A continuous DIAGONAL creek follows the concept's upper-left to lower-right valley.
curve=[[-450,-200],[300,400],[490,1000],[700,1500],[1050,2000],[1550,2480],[1850,2770],[2300,3110],[2650,3350],[3300,3720],[4200,4030],[5500,4330],[7000,4560],[8600,4800]]
def cx(y):
    for a,b in zip(curve,curve[1:]):
        if a[1]<=y<=b[1]:return a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1])
    return curve[0][0] if y<curve[0][1] else curve[-1][0]
def banks(y):
    width=430+35*math.sin(y/410);return cx(y)-width/2,cx(y)+width/2
def waterpart(lo,hi):
    ys=sorted(set([lo,hi]+[float(y) for y in range(math.ceil(lo/70)*70,math.floor(hi/70)*70+1,70)]))
    return [[banks(y)[0],y] for y in ys]+[[banks(y)[1],y] for y in reversed(ys)]
node('Creek','Polygon2D','.','z_index = -15\nmaterial = SubResource("water_mat")\npolygon = '+poly(waterpart(-200,4800)))
for name,key,center,s in [('GateBridge','covered_bridge',[2650,3350],1.05),('MiddleBridge','open_bridge',[1850,2770],.67),('UpperBridge','open_bridge',[1050,2000],.67)]:
    covered=key=='covered_bridge';pivot=[887,520] if covered else [1086,327];w,h=allmedia[key]['native_size'];back=499 if covered else 277;front=541 if covered else 352;under=front if covered else 406
    node(name,'Node2D','Town','position = '+vec(center)+'\nmetadata/bridge = true\nmetadata/label = "溪桥：跨过斜穿山城的溪谷。"')
    node('Base','Node2D','Town/'+name,'z_as_relative = false\nz_index = -3');uv('Deck',key,rect(0,back,w,front-back),'Town/'+name+'/Base',pivot,s);uv('Under',key,rect(0,under,w,h-under),'Town/'+name+'/Base',pivot,s)
    node('Foreground','Node2D','Town/'+name,'position = Vector2(0,22)');uv('Roof',key,rect(0,0,w,back),'Town/'+name+'/Foreground',[pivot[0],pivot[1]+22/s],s,0,fade(name+'Roof'))
    if not covered:uv('Rail',key,rect(0,352,w,54),'Town/'+name+'/Foreground',[pivot[0],pivot[1]+22/s],s,0,fade(name+'Rail'))
    ymin=(back-pivot[1])*s;ymax=(front-pivot[1])*s;x0=-650 if covered else -575
    body('BackRail','Town/'+name,rect(x0,ymin-14,-x0*2,12));body('FrontRail','Town/'+name,rect(x0,ymax-2,-x0*2,14))
    bridges.append({'name':name,'center':center,'open_water_y':[center[1]+ymin,center[1]+ymax-2]})
last=-200
for i,b in enumerate(sorted(bridges,key=lambda x:x['center'][1])):
    lo,hi=b['open_water_y'];body('Water'+str(i),'Town',waterpart(last,lo));last=hi
body('WaterLast','Town',waterpart(last,4800))

# Raised market UV: original board face below; people walk on the original narrow plank strip.
for i,(key,foot,s,pivot,back,front) in enumerate([
    ('market_stilt',[4340,3880],.86,[887,530],495,556),('market_stilt',[5620,4160],.86,[887,530],495,556),
    ('boardwalk',[3650,3560],.58,[990,288],253,323),('boardwalk',[6740,3930],.58,[990,288],253,323)]):
    nm='RaisedMarket'+str(i+1);w,h=allmedia[key]['native_size'];width=w*s
    node(nm,'Node2D','Town','position = '+vec(foot)+'\nmetadata/bridge = true\nmetadata/label = "临溪架空木街：铺面沿木栈道展开，支柱落在溪岸坡下。"')
    node('Base','Node2D','Town/'+nm,'z_as_relative = false\nz_index = -2')
    uv('Deck',key,rect(0,back,w,front-back),'Town/'+nm+'/Base',pivot,s)
    uv('Supports',key,rect(0,front,w,h-front),'Town/'+nm+'/Base',pivot,s)
    node('Foreground','Node2D','Town/'+nm)
    uv('Shops' if key=='market_stilt' else 'BackRail',key,rect(0,0,w,back),'Town/'+nm+'/Foreground',pivot,s,0,fade(nm))
    if key=='market_stilt':body('ShopBody','Town/'+nm,rect(-width*.4,(back-pivot[1])*s-88,width*.8,82))
    else:body('BackRail','Town/'+nm,rect(-width*.43,(back-pivot[1])*s-14,width*.86,12))
    objects.append({'name':nm,'key':key,'foot':foot,'scale':s,'native_partition':[back,front],'width':width,'body':None})

# Houses follow several offset pockets, with exposed high stilts interleaved among modest roofs.
tall=[([2780,1010],.59),([3900,850],.62),([4900,1110],.59),([5950,1280],.57),([2920,1920],.63),([5040,2380],.63),([3670,3200],.63),([5740,3040],.57)]
for i,(foot,s) in enumerate(tall):
    r=prop('HighStilt'+str(i+1),'stilt_house',foot,(allmedia['stilt_house']['bbox'][3]-allmedia['stilt_house']['bbox'][1])*s,'高脚木楼：门接坡上巷道，支柱撑向坡下。',True,rect(-320,-95,640,95),fade_on=True)
homes=[('house_back',[2300,670],360),('house_front',[3310,500],400),('house_side',[4560,570],420),('house_back',[5490,590],380),('house_front',[6430,870],410),
    ('house_back',[2220,1350],360),('house_side',[3650,1450],420),('house_back',[4320,1730],370),('house_front',[5470,1770],410),('house_side',[6650,1650],420),
    ('house_front',[2420,2140],380),('house_side',[5810,2310],440),('house_back',[6600,2540],365),
    ('house_front',[3130,2990],390),('house_back',[4900,3190],370),('house_side',[6270,3540],420),('house_back',[6820,3310],350),
    ('house_front',[1270,1520],350),('house_back',[730,2450],340),('house_side',[1160,3020],400)]
for i,(key,foot,h) in enumerate(homes):prop('PocketHome'+str(i+1),key,foot,h,'坡巷住户：随岩岸错落成组。',True,fade_on=True)
prop('WeavingHouse','weaving_house',[1780,1810],420,'绣坊前厅：门前空格进入。',True,fade_on=True)
prop('DyeWorkshop','weaving_house',[2450,1670],420,'蜡染作坊：檐下作业，蓝白布料沿侧院晾晒。',True,fade_on=True)
prop('Gate','gate',[1610,3610],340,'山口寨门：沿坡路去有盖桥，再入临溪街市。',False,fade_on=True)
body('GateLeft','Town',rect(1275,3540,190,80));body('GateRight','Town',rect(1725,3540,215,80))
for i,foot in enumerate([[6600,1960],[6970,2320]]):prop('Granary'+str(i+1),'granary',foot,300,'粮院接田埂，谷物沿坡晾晒。',True,fade_on=True)
for i,(foot,h) in enumerate([([6960,1260],370),([7110,1660],340),([7270,2120],320),([7070,2820],320)]):prop('Paddy'+str(i+1),'paddy',foot,h,'沿山坡分布的小梯田。',True,z=-4)

# Short irregular ledges, interrupted by lane openings. No continuous across-city horizontal retaining wall.
rocks=[([2160,1110],210),([3570,1180],240),([4750,1450],210),([6180,1520],230),
    ([1970,2260],200),([3330,2220],215),([3460,2820],220),([4910,2840],230),
    ([4600,1940],210),([5990,1990],210),([5500,2670],210),([6830,2660],210),
    ([2890,3350],190),([5850,3680],190),([7300,3300],260)]
for i,(foot,h) in enumerate(rocks):
    b,_=info('rock_bank');width=(b[2]-b[0])*h/(b[3]-b[1]);prop('RockLedge'+str(i+1),'rock_bank',foot,h,'苔岩坡与短段毛石坎，巷路沿肩部绕行。',True,rect(-width*.43,-h*.40,width*.86,h*.4))
for i,(x,y) in enumerate([[2680,2250],[4200,2810],[5320,1940],[6150,2610]]):
    nm='Stairs'+str(i+1);s=440/844;pivot=[768,780]
    node(nm,'Node2D','Town','position = '+vec([x,y])+'\nmetadata/label = "短石阶：沿岩坡转折接上层巷。"')
    node('Base','Node2D','Town/'+nm,'z_as_relative = false\nz_index = -2')
    middle=[[500,0],[1040,0],[1040,358],[1125,780],[1125,1024],[410,1024],[410,780],[500,358]]
    left=[[0,0],[500,0],[500,358],[410,780],[410,1024],[0,1024]];right=[[1040,0],[1536,0],[1536,1024],[1125,1024],[1125,780],[1040,358]]
    uv('Treads','stairs',middle,'Town/'+nm+'/Base',pivot,s);uv('LeftCheek','stairs',left,'Town/'+nm,pivot,s);uv('RightCheek','stairs',right,'Town/'+nm,pivot,s)
    for side,pts in [('Left',[[450,358],[500,358],[410,780],[346,780]]),('Right',[[1040,358],[1090,358],[1190,780],[1125,780]])]:body(side,'Town/'+nm,[[(a-pivot[0])*s,(b-pivot[1])*s] for a,b in pts])
    stairs.append({'name':nm,'foot':[x,y],'top':[x,y-203],'floor_z':-2})
    road([[x,y+100],[x,y-290]],65)

# Central open earthen activity court, tree is at one side rather than filling the center.
prop('PlazaTree','trees',[3420,2440],560,'芦笙坪树荫：中央土坪留空。',True,rect(-65,-42,130,45))
for nm,key,foot,h in [('LushengRack','lusheng_rack',[3650,2600],155),('Bench1','bench',[3600,2690],50),('Bench2','bench',[4650,2600],50),
    ('Dry1','cloth_rack',[1450,1920],170),('Dry2','cloth_rack',[2180,1930],170),('Dry3','cloth_rack',[2660,1810],170),
    ('Table1','table',[2030,1950],80),('WaterJars','water_jars',[2250,2030],85),('Cargo1','cargo',[6850,2450],85),
    ('GateCargo','cargo',[1260,3800],85),('MarketCargo','cargo',[5240,3980],85)]:prop(nm,key,foot,h,'院边生活作业陈设，留出通路。')
for i,foot in enumerate([[180,1000],[610,1570],[1300,2490],[2300,3160],[3600,3850],[4900,4180],[6430,4440]]):
    prop('Cascade'+str(i+1),'waterfall',foot,500 if i<3 else 340,'溪水穿过苔岩叠瀑。',False,z=-13,ground=True)
for i,y in enumerate(range(550,4451,150)):
    a,b=banks(y)
    if min(abs(y-z['center'][1]) for z in bridges)<95:continue
    for j,x in enumerate([a-15,b+15]):prop('Bank'+str(i)+'_'+str(j),'bank_shrub',[x,y],95+(i%3)*15,'溪岸石草。',False,z=-12,ground=True)

# Irregular forest masses and pockets, not a perimeter line of identical isolated trees.
forest=[]
for ix in range(-2,20):
    x=ix*430
    for iy in range(3):forest.append([x+140*math.sin(ix*1.6+iy),iy*250-110+100*math.cos(ix*.7)])
for iy in range(3,18):
    y=iy*270
    for side in [0,1]:
        x=(-350+iy*18) if side==0 else (7970-iy*13)
        forest.extend([[x,y],[x+(-210 if side==0 else 210),y-110]])
for i,x in enumerate(range(0,7801,360)):forest.extend([[x,5010+180*math.sin(i*.8)],[x+170,5180+120*math.cos(i)]])
forest += [[1850,780],[1750,1270],[3280,930],[4490,1020],[5490,1340],[6310,1920],[4620,2150],[2780,2710],
    [5330,3150],[6540,3070],[7210,3790],[940,3440],[1160,4000],[2360,3950],[4280,4500],[5720,4770]]
for i,foot in enumerate(forest):prop('Forest'+str(i+1),'trees',foot,470+(i%4)*35,'山林组团与谷地围合。',True,rect(-80,-38,160,40))
for i,r in enumerate([o for o in objects if o['key'] in ['house_front','house_side','house_back','stilt_house','granary']]):
    x,y=r['foot'];prop('Moss'+str(i),'moss_patch',[x-r['width']*.4,y+18],90,'岩脚林下草。',False,z=-16,ground=True)

routes=[('WestWeaver','woman',[[1650,2050],[2100,2050]]),('DyeWorker','woman',[[2170,2110],[2430,2110]]),
    ('CreekVendor','man',[[4060,3880],[4520,3880]]),('ClothVendor','woman',[[5350,4160],[5780,4160]]),
    ('PlazaCraftsman','man',[[3890,2600],[4340,2600]]),('UpperResident','woman',[[3700,1610],[4160,1610]]),
    ('Farmer','man',[[6600,2510],[6910,2510]]),('LaneWorker','man',[[3020,2490],[3320,2490]])]
for name,identity,route in routes:
    node(name,'CharacterBody2D','Town','position = '+vec(route[0])+'\ncollision_layer = 4\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("resident")\nidentity = "'+identity+'"\nroute = '+poly(route)+'\nmetadata/portrait = "'+identity+'_portrait"\nmetadata/label = "普通山城居民：沿铺前或作业院巡行。"')
    node('Art','Sprite2D','Town/'+name,'texture = ExtResource("'+identity+'_walk")\ncentered = false\nregion_enabled = true');node('Foot','CollisionShape2D','Town/'+name,'shape = SubResource("npc_body")')
    patrols.append({'name':name,'identity':identity,'route':route})
nodes.append('[node name="Player" parent="Town" instance=ExtResource("player")]\nposition = Vector2(1610,3900)\ncollision_layer = 2\ncollision_mask = 1\nmotion_mode = 1\nscript = ExtResource("adapter")')
nodes.append('[node name="CollisionShape2D" parent="Town/Player" index="1"]\nposition = Vector2(0,0)\nshape = SubResource("hero_body")')
node('WorkshopDoor','Marker2D','Town','position = Vector2(1750,1845)')
for block in re.split(r'(?=\[node )',original[original.index('[node '):]):
    first=block.splitlines()[0] if block else ''
    if 'name="HouseHall" type=' in first or 'parent="HouseHall' in first or 'parent="HouseHall/' in first or 'name="UI" type=' in first or 'parent="UI' in first or 'parent="UI/' in first:nodes.append(block.rstrip())
outline=[[-700,500],[-100,-450],[7200,-450],[7980,600],[7980,4750],[7400,5100],[1100,5100],[-700,3500]]
node('Boundary','StaticBody2D','.','collision_layer = 1\ncollision_mask = 0');node('Outline','CollisionPolygon2D','Boundary','build_mode = 1\npolygon = '+poly(outline))
node('Camera','Camera2D','.','position = Vector2(1610,3710)\nzoom = Vector2(0.9,0.9)')
head=re.sub(r'load_steps=\d+','load_steps='+str(1+len(re.findall(r'\[ext_resource|\[sub_resource',head))+len(subs)),head,count=1)
p=PROJECT/SCENE;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(head+'\n\n'.join(subs+nodes)+'\n','utf-8')

paths=[([[1610,4070],[1610,3650],[2000,3350],[3300,3350],[3650,3560],[4060,3880],[4620,3880],[4920,4010],[5350,4160],[5900,4160]],83),
    ([[3200,3350],[3200,3120],[4200,3000],[4200,2810],[4200,2510],[4070,2410]],72),
    ([[4070,2410],[4350,2190],[4600,2070],[5320,2050],[5320,1940],[5320,1650],[6350,1620],[6740,1800],[6740,2510]],68),
    ([[4070,2410],[3770,2240],[3540,2050],[3540,1620],[4010,1620],[4430,1490],[4430,1280]],64),
    ([[4070,2410],[3050,2440],[2680,2420],[2680,2250],[2680,2050],[2100,2050],[1750,1845]],65),
    ([[2100,2050],[2440,2050],[2440,2400],[2420,2770],[1850,2770],[1260,2770],[1260,2120],[1050,2000],[1700,2000]],65),
    ([[1610,3650],[1610,3200],[1250,3200],[1260,2770]],62),
    ([[4350,2600],[5240,2580],[5710,2760],[6150,2760],[6150,2610],[6150,2420],[6740,2510]],62),
    ([[5900,4160],[6260,4000],[6740,3930],[7100,3690],[7100,3010],[6740,2750],[6740,2510]],62),
    ([[6740,1800],[7070,1510],[7100,1100]],50)]
for pts,width in paths:road(pts,width)
lines=[]
for r in roads:
    for a,b in zip(r['points'],r['points'][1:]):lines.append('path=max(path,1.-smoothstep('+fmt(r['width']*.6)+','+fmt(r['width']+28)+',segment(p,'+','.join('vec2('+','.join(fmt(x) for x in v)+')' for v in [a,b])+')));')
shader='''shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
'''+ '\n'.join(lines)+'''
float plaza=1.-smoothstep(.84,1.,length((p-vec2(4030.,2460.))/vec2(700.,360.)));
vec3 woodland=texture(earth_tex,folded(p/650.)).rgb;
vec3 soil=texture(dirt_tex,folded(p/780.)).rgb;
vec3 stone=texture(path_tex,folded(p/450.)).rgb;
vec3 mixed=mix(woodland,mix(soil,stone,.22),path*.96);
COLOR=vec4(mix(mixed,soil,plaza),1.);}
'''
(PROJECT/ART/'ground.gdshader').write_text(shader,'utf-8')
code=(PROJECT/f'scripts/drafts/{OLD}/town_controller.gd').read_text('utf-8')
code=code.replace('Vector2(650,3780)','Vector2(1610,3900)').replace('Vector2(590,1255)','Vector2(1750,1845)')
code=re.sub(r'const FOCUS := \[[^\n]+','const FOCUS := [Vector2(1800,3500),Vector2(4900,3830),Vector2(4030,2460),Vector2(2040,1860),Vector2(4510,1230),Vector2(6800,2190)]',code)
code=code.replace('Vector2(3250,2410)','Vector2(3800,2500)').replace('Vector2.ONE*.215','Vector2.ONE*.205')
code=code.replace('木楼顺坡 / 溪街回环','溪谷斜穿 / 吊脚栈街')
sp=PROJECT/SCRIPT;sp.parent.mkdir(parents=True,exist_ok=True);sp.write_text(code,'utf-8')
save(STAGE/'layout.json',{'scene':SCENE,'script':SCRIPT,'art':ART,'media':media,'reused_media':oldlayout['media'],'objects':objects,'blockers':blockers,
    'bridges':bridges,'stairs':stairs,'roads':roads,'patrols':patrols,'creek_centerline':curve,'town_outline':outline,
    'homes':28,'high_stilt_homes':8,'market_modules':2,'market_bays':6,'formal_world_enabled':False})
print('Recomposed:diagonalcreek,28homes incl8tallstilts,6marketbays,3bridges4shortstairs;',len(objects),'objects',len(blockers),'bodies')
