"""Build two independent sect maps from the approved j plans. Never writes old game files."""
import json,math,re,shutil,sys
from pathlib import Path
from PIL import Image
from sect_maps_20261029k import ROOT,NAME,RAW,STAGE,PROJECT,ART,save,sha
from build_redrock_town_20261028a import vec,poly,fmt

F='art/modules/miao_town_20261029f/'
B='art/modules/redrock_luoyang_standard_20261028b/'
PROCESSED=ROOT/'assets/processed'/NAME
SCRIPT='scripts/drafts/'+NAME+'/'
def rect(x,y,w,h):return [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]

def prepare_media():
    assert not PROJECT.exists()
    prior=ROOT/'assets/staging/miao_terrain_20261029i/town_project'
    PROJECT.mkdir()
    for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(prior/folder,PROJECT/folder)
    (PROJECT/'artifacts-k').mkdir()
    config=(prior/'project.godot').read_text('utf-8').replace('miao_terrain_20261029i/miao_town.tscn',NAME+'/wudang.tscn').replace('miao_building_variety_20261029h_validation',NAME+'_validation').replace('苗风山城·六区木楼溪街','武当与茗雾·独立编辑地图')
    (PROJECT/'project.godot').write_text(config,'utf-8')
    manifest=json.loads((RAW/'manifest.json').read_text('utf-8'));media={};checks=[]
    for r in manifest['assets']:
        im=Image.open(ROOT/r['output']);assert im.mode=='RGBA';w,h=im.size
        b=im.getchannel('A').getbbox();px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
        out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py))
        dst=PROCESSED/(r['key']+'.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
        assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
        bb=out.getchannel('A').getbbox();nw,nh=out.size;margins=[bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh];assert min(margins)>=.1
        native=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
        target=PROJECT/ART/(r['key']+'.png');target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(dst,target)
        media[r['key']]={'path':ART+'/'+r['key']+'.png','bbox':[native[0]+px,native[1]+py,native[2]+px,native[3]+py],'padding':[px,py],'size':list(out.size),'raw':r['output'],'label':r['label'],'processed':dst.relative_to(ROOT).as_posix()}
        raw_margins=[b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h]
        checks.append({'key':r['key'],'raw_A1_pass':min(raw_margins)>=.1,'raw_margins':raw_margins,'padded_A1_pass':True,'all_original_RGBA_exact':True,'new_pixels_RGBA_zero':True,'alpha_cleaned_pixels':0,'offset':[px,py],'sha256':sha(dst)})
    save(STAGE/'padding-verification.json',checks)
    reuse={'ground':F+'ground.png','path':F+'path.png','woodland':'art/modules/miao_recompose_20261029g/woodland_floor.png','water':F+'water.png','bridge':F+'open_bridge.png',
        'pavilion':'art/modules/luoyang_full_city_20261022ap/pavilion.png','bamboo':'art/modules/veg/veg_bamboo_cluster_a.png','estate_wing':'art/modules/luoyang_estate_components_20261021am/wing.png','corridor':'art/modules/luoyang_estate_components_20261021am/corridor.png'}
    reuse.update({k:B+k+'.png' for k in ['bench','table','cargo','water_jars','shelf']})
    for key,path in reuse.items():
        target=PROJECT/path
        if not target.exists():
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'game'/path,target)
            imp=ROOT/'game'/(path+'.import')
            if imp.exists():
                shutil.copyfile(imp,PROJECT/(path+'.import'))
                for ref in set(re.findall(r'res://(\.godot/imported/[^"\]]+)',imp.read_text('utf-8'))):
                    src=ROOT/'game'/ref
                    if src.exists():shutil.copyfile(src,PROJECT/ref)
                for leaf in (ROOT/'game/.godot/imported').glob(target.name+'-*'):
                    shutil.copyfile(leaf,PROJECT/'.godot/imported'/leaf.name)
        im=Image.open(target).convert('RGBA');media[key]={'path':path,'bbox':list(im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()),'size':list(im.size),'padding':[0,0],'reused':True}
    save(STAGE/'media.json',media)

def terrain(heights,platforms,ramps,scale,width,opening):
    result={'heights':heights,'platforms':[{'level':i+1,'polygon':p} for i,p in enumerate(platforms)],'ramps':[], 'source_stair_scale':scale,'portal_half_width':width,'facade_opening_half_width':opening,'object_moves':{}}
    for name,label,low,high,top in ramps:
        rise=heights[high]-heights[low];run=390*scale-rise;assert run>0
        result['ramps'].append({'id':name,'label':label,'low':low,'high':high,'top':top,'bottom':[top[0],top[1]+run],'rise':rise,'ground_run':run})
    return result

class Scene:
    def __init__(self,key,title,subtitle,size,spawn,td):
        self.key=key;self.media=json.loads((STAGE/'media.json').read_text('utf-8'));self.ext=[];self.sub=[];self.nodes=[];self.objects=[];self.blockers=[];self.roads=[];self.plazas=[];self.bridges=[]
        for extra in ['trees','bank_shrub']:
            im=Image.open(PROJECT/F/(extra+'.png')).convert('RGBA');self.media[extra]={'path':F+extra+'.png','bbox':list(im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()),'size':list(im.size),'padding':[0,0]}
        self.layout={'key':key,'title':title,'subtitle':subtitle,'size':size,'spawn':spawn,'overview':[size[0]/2,size[1]/2-140],'overview_zoom':min(1760/size[0],900/size[1]),'terrain':td,'description':subtitle+'。WASD行走；Tab切换全景。当前为独立门派编辑地图，室内服务与正式世界入口待接。'}
        for k,r in self.media.items():self.ext.append(f'[ext_resource type="Texture2D" path="res://{r["path"]}" id="{k}"]')
        for k,path,typ in [('controller',SCRIPT+'controller.gd','Script'),('player','scenes/player.tscn','PackedScene'),('adapter','scripts/drafts/redrock_luoyang_standard_20261028b/preview_player.gd','Script'),('ground_shader',ART+'/'+key+'_ground.gdshader','Shader'),('water_shader',F+'water.gdshader','Shader'),('fade_shader',F+'occlusion.gdshader','Shader')]:self.ext.append(f'[ext_resource type="{typ}" path="res://{path}" id="{k}"]')
        self.sub += ['[sub_resource type="RectangleShape2D" id="hero_body"]\nsize = Vector2(35,25)', '[sub_resource type="SystemFont" id="font"]\nfont_names = PackedStringArray("Microsoft YaHei", "SimHei")', '[sub_resource type="StyleBoxFlat" id="panel"]\nbg_color = Color(0.06,0.09,0.08,0.92)\ncorner_radius_top_left = 8\ncorner_radius_bottom_right = 8', '[sub_resource type="ShaderMaterial" id="ground_mat"]\nshader = ExtResource("ground_shader")\nshader_parameter/earth_tex = ExtResource("quiet_ground")\nshader_parameter/dirt_tex = ExtResource("ground")\nshader_parameter/path_tex = ExtResource("path")', '[sub_resource type="ShaderMaterial" id="water_mat"]\nshader = ExtResource("water_shader")\nshader_parameter/water_tex = ExtResource("water")']
        self.node('SectMap','Node2D',None,'script = ExtResource("controller")\nlayout_path = "res://'+ART+'/'+key+'.json"')
        self.node('Ground','Polygon2D','.','z_index = -20\nmaterial = SubResource("ground_mat")\npolygon = '+poly(rect(-1000,-1000,size[0]+2000,size[1]+2000)))
        self.node('Town','Node2D')
        # Boundary is a real shared-layer closed perimeter, outside all designed routes.
        for i,(a,b) in enumerate(zip(rect(100,100,size[0]-200,size[1]-200),rect(100,100,size[0]-200,size[1]-200)[1:]+rect(100,100,size[0]-200,size[1]-200)[:1])):
            x=min(a[0],b[0]);y=min(a[1],b[1]);self.body('Boundary'+str(i),'Town',rect(x-10,y-10,abs(a[0]-b[0])+20,abs(a[1]-b[1])+20),common=True)
    def node(self,name,kind,parent='.',props=''):
        self.nodes.append(f'[node name="{name}" type="{kind}"'+(f' parent="{parent}"' if parent else '')+']\n'+props)
    def body(self,name,parent,points,common=False):
        self.node(name,'StaticBody2D',parent,'collision_layer = '+('8' if common else '16')+'\ncollision_mask = 0'+ ('\nmetadata/common_layer = true' if common else ''))
        self.node('Shape','CollisionPolygon2D',parent+'/'+name,'polygon = '+poly(points));self.blockers.append({'path':parent+'/'+name,'polygon':points})
    def prop(self,name,key,foot,height,label='',solid=True,points=None,ground=False):
        r=self.media[key];b=r['bbox'];s=height/(b[3]-b[1]);w=(b[2]-b[0])*s;pivot=[(b[0]+b[2])/2,b[3]]
        props='position = '+vec(foot)+'\nmetadata/label = '+json.dumps(label,ensure_ascii=False)+f'\nmetadata/visual_rect = Rect2({fmt(-w/2)}, {fmt(-height)}, {fmt(w)}, {fmt(height)})'
        if ground:props+='\nmetadata/ground_cover = true\nz_index = -5'
        else:props+='\nmetadata/fade = true'
        self.node(name,'Node2D','Town',props)
        self.sub.append(f'[sub_resource type="ShaderMaterial" id="fade_{name}"]\nshader = ExtResource("fade_shader")')
        self.node('Art','Sprite2D','Town/'+name,'material = SubResource("fade_'+name+'")\nposition = '+vec([-pivot[0]*s,-pivot[1]*s])+'\nscale = '+vec([s,s])+'\ntexture = ExtResource("'+key+'")\ncentered = false')
        if solid:self.body('Body','Town/'+name,points if points is not None else rect(-w*.42,-min(height*.25,120),w*.84,min(height*.25,120)))
        row={'name':name,'key':key,'foot':foot,'height':height,'width':w,'scale':s,'label':label};self.objects.append(row);return row
    def road(self,points,width=90):self.roads.append({'points':points,'width':width})
    def plaza(self,center,radius):self.plazas.append([center,radius])
    def wall(self,name,x,y,width=600):
        b=self.media['white_wall']['bbox'];height=width*(b[3]-b[1])/(b[2]-b[0]);self.prop(name,'white_wall',[x,y],height,'院界：沿开口进入院落。',points=rect(-width/2,-18,width,24))
    def bridge(self,name,center):
        # A short bridge ends on the flat bank, before the raised courtyard side.
        r=self.media['bridge'];s=.5;pad=[273,51];pivot=[1086,327];w,h=[2172,724]
        self.node(name,'Node2D','Town','position = '+vec(center)+'\nmetadata/bridge = true')
        for label,y0,y1,z in [('Deck',277,352,-4),('Under',406,h,-4),('Back',0,277,round((center[1]-40)/4)),('Front',352,406,round((center[1]+20)/4))]:
            points=rect(0,y0,w,y1-y0)
            self.node(label,'Polygon2D','Town/'+name,'z_as_relative = false\nz_index = '+str(z)+'\ntexture = ExtResource("bridge")\npolygon = '+poly([[(x-pivot[0])*s,(y-pivot[1])*s] for x,y in points])+'\nuv = '+poly([[x+pad[0],y+pad[1]] for x,y in points]))
        ymin=(277-327)*s;ymax=(352-327)*s
        for nm,y in [('BackRail',ymin-12),('FrontRail',ymax)]:self.body(nm,'Town/'+name,rect(-390,y,780,10))
        self.bridges.append({'name':name,'center':center,'walk_y':[center[1]+ymin,center[1]+ymax]})
    def finish(self):
        self.nodes.append('[node name="Player" parent="Town" instance=ExtResource("player")]\nposition = '+vec(self.layout['spawn'])+'\nscript = ExtResource("adapter")')
        self.nodes.append('[node name="CollisionShape2D" parent="Town/Player" index="1"]\nposition = Vector2(0,0)\nshape = SubResource("hero_body")')
        self.node('Camera','Camera2D','.','position = '+vec(self.layout['spawn'])+'\nzoom = Vector2(0.9,0.9)')
        self.node('UI','CanvasLayer')
        self.node('Top','Panel','UI','offset_left = 18.0\noffset_top = 12.0\noffset_right = 1080.0\noffset_bottom = 102.0\ntheme_override_styles/panel = SubResource("panel")\nmouse_filter = 2')
        for nm,y,size,text in [('Title',22,30,self.layout['title']),('Status',63,20,self.layout['subtitle']),('Hint',1038,22,'WASD / 方向键移动　Shift快走　Tab全景/跟随　空格查看　R回山口　Esc关闭说明')]:
            self.node(nm,'Label','UI',f'offset_left = 34.0\noffset_top = {y}.0\noffset_right = 1800.0\noffset_bottom = {y+38}.0\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = {size}\ntheme_override_colors/font_color = Color(0.96,0.94,0.83,1)\ntext = '+json.dumps(text,ensure_ascii=False))
        self.node('Detail','Panel','UI','visible = false\noffset_left = 400.0\noffset_top = 760.0\noffset_right = 1500.0\noffset_bottom = 1000.0\ntheme_override_styles/panel = SubResource("panel")')
        self.node('Text','Label','UI/Detail','offset_left = 25.0\noffset_top = 25.0\noffset_right = 1075.0\noffset_bottom = 215.0\nautowrap_mode = 3\ntheme_override_fonts/font = SubResource("font")\ntheme_override_font_sizes/font_size = 24')
        src='[gd_scene load_steps='+str(len(self.ext)+len(self.sub)+1)+' format=3]\n\n'+'\n\n'.join(self.ext+self.sub+self.nodes)+'\n'
        target=PROJECT/'scenes/drafts'/NAME/(self.key+'.tscn');target.parent.mkdir(parents=True,exist_ok=True);target.write_text(src,'utf-8')
        self.layout.update(objects=self.objects,blockers=self.blockers,roads=self.roads,bridges=self.bridges,formal_world_enabled=False)
        save(PROJECT/ART/(self.key+'.json'),self.layout);save(STAGE/(self.key+'-layout.json'),self.layout)
        shader='''shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
'''
        for route in self.roads:
            for a,b in zip(route['points'],route['points'][1:]):shader+=f'path=max(path,1.-smoothstep({route["width"]*.6:.2f},{route["width"]:.2f},segment(p,vec2({float(a[0])},{float(a[1])}),vec2({float(b[0])},{float(b[1])}))));\n'
        for c,r in self.plazas:shader+=f'path=max(path,1.-smoothstep(.85,1.,length((p-vec2({float(c[0])},{float(c[1])}))/vec2({float(r[0])},{float(r[1])}))));\n'
        shader+='vec3 grass=texture(earth_tex,folded(p/1350.)).rgb;vec3 stone=texture(path_tex,folded(p/650.)).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}\n'
        (PROJECT/ART/(self.key+'_ground.gdshader')).write_text(shader,'utf-8')

def maps():
    t=terrain([0,180,360],[[[1100,650],[2100,250],[3900,450],[4700,1500],[4700,2650],[4100,2900],[1300,2900],[1000,2300]],[[2000,550],[2800,400],[3700,650],[3850,1200],[3500,1600],[1900,1600],[1750,1200]]],[('MainRise','山门—太极道场',0,1,[2400,2900]),('ServiceRise','东麓—生活道院',0,1,[3900,2900]),('HallRise','道场—正殿高台',1,2,[2600,1600]),('LibraryRise','道院—藏经台',1,2,[3300,1600])],.82,180,300)
    s=Scene('wudang','武当派 · 松崖三重院','山门石道 / 太极道场 / 正殿高台 / 藏经院 / 东麓道院 / 崖畔静修',[5200,4400],[1700,4100],t)
    s.prop('MainHall','wudang_hall',[2700,950],520,'正殿：位于第三重台地，主阶与东侧阶道均可到达。')
    g=s.prop('MountainGate','wudang_gate',[1700,3800],380,'山门：中央通行，两侧石柱真实阻挡。',False)
    # Native passage is source x650..870, lower foot rows740..820; keep clear center.
    sc=g['scale'];b=s.media['wudang_gate']['bbox'];cx=(b[0]+b[2])/2;px,py=s.media['wudang_gate']['padding']
    for nm,x0,x1 in [('LeftPier',105,650),('RightPier',875,1497)]:s.body(nm,'Town/MountainGate',rect((x0+px-cx)*sc,-75,(x1-x0)*sc,75))
    s.prop('TaijiCourt','taiji_floor',[2500,2570],510,'太极道场：整片可行走石坪。',False,ground=True)
    for name,p,h,label in [('Scripture',[3990,1730],360,'藏经院'),('EastDormitory',[4050,2320],325,'弟子起居厢房'),('Kitchen',[3470,2580],290,'道院灶房'),('UpperWing',[3370,1130],310,'正殿东厢'),('WestWing',[2060,1250],285,'清修小院'),('GateHouse',[1140,3650],270,'山门值守小屋')]:s.prop(name,'wudang_wing',p,h,label)
    s.prop('Meditation','pavilion',[1430,1540],390,'崖畔静修亭：由西侧石径到达。')
    for name,p in [('CourtBench',[2030,2630]),('DormBench',[4350,2420]),('HallBench',[3020,1240])]:s.prop(name,'bench',p,46,'石路边歇脚长凳')
    for name,key,p,h in [('KitchenJars','water_jars',[3750,2620],78),('Storage','cargo',[4440,2250],90),('GardenTable','table',[1420,1740],90)]:s.prop(name,key,p,h,'生活陈设')
    for i,(x,y,h) in enumerate([(800,3400,450),(2250,3650,480),(3200,3420,510),(4480,3300,450),(920,2600,460),(1180,1980,420),(1540,2100,370),(4530,1810,460),(4450,1250,490),(1630,950,450),(3830,760,480),(3050,380,460),(1110,3330,320),(3590,2160,350)]):s.prop('Pine'+str(i),'wudang_pine',[x,y],h,'山松',points=rect(-38,-40,76,40))
    # Continuous mountain massing sits outside the temple walks, with real rock footprints.
    for i,(x,y,h) in enumerate([(500,1800,430),(520,2580,390),(850,920,510),(1700,400,540),(2800,240,650),(4010,420,500),(4930,1510,480),(5050,2520,440),(4450,3790,350),(700,4050,360)]):
        s.prop('MountainRock'+str(i),'limestone_mass',[x,y],h,'灰岩山体',points=rect(-h*.9,-h*.3,h*1.8,h*.3))
    for i,(x,y,h) in enumerate([(740,1400,370),(710,2050,430),(780,2840,350),(1130,1070,380),(1470,620,330),(1950,490,380),(3700,340,350),(4480,780,360),(4660,1050,340),(4810,2220,330),(4750,2830,370),(4230,3450,290),(3800,3740,380),(1000,3950,370),(2160,3430,320),(2940,2840,240),(3090,2730,280),(1780,2600,300)]):s.prop('Grove'+str(i),'wudang_pine',[x,y],h,'松林',points=rect(-32,-30,64,30))
    s.plaza([2500,2400],[840,510])
    for points,w in [([[1700,4200],[1700,3500],[2400,3250],[2400,2900],[2400,2600],[2500,2200],[2600,1870],[2600,1600],[2600,1200]],135),([[2400,3250],[3900,3250],[3900,2900],[3900,2700],[4050,2470],[4200,1900],[3990,1870]],100),([[2500,2200],[3300,2200],[3300,1600],[3300,1310],[2700,1190]],100),([[2500,2200],[1700,2200],[1450,1770],[1430,1650]],90)]:s.road(points,w)
    s.plaza([2700,1150],[900,400]);s.plaza([4050,2480],[450,210]);s.finish()
    t=terrain([0,60,120],[[[3400,720],[4800,720],[5000,1100],[5050,2600],[4800,2800],[3400,2800]],[[3600,720],[4730,720],[4800,1200],[4800,1510],[3600,1510]]],[('GuestRise','平桥—内院',0,1,[3800,2800]),('FreightRise','东侧货路—作院',0,1,[4600,2800]),('ManorRise','内院—议事庄厅',1,2,[4080,1510]),('SideRise','回廊—庄厅侧院',1,2,[4640,1510])],.36,74,130)
    s=Scene('mingwu','茗雾山庄 · 溪桥茶院','茶镇入口 / 临溪客堂 / 双桥平路 / 庄厅内院 / 茶圃 / 制茶作院',[5600,3800],[1700,3470],t)
    s.prop('ManorHall','mingwu_hall',[4210,1130],465,'议事庄厅：内院第二级低台，短阶连接。')
    s.prop('GuestHall','mingwu_guest',[1950,2420],480,'临溪客堂：高低错落的客房与茶廊。')
    s.prop('InnerGuest','mingwu_guest',[4370,2210],410,'内院客舍')
    for name,p,h,label in [('TeaWorkshop',[1390,1330],260,'制茶作坊'),('TeaStore',[2150,1220],235,'茶叶晾制棚'),('LowerTeaShop',[1160,3070],245,'入口茶铺')]:s.prop(name,'tea_workshop',p,h,label)
    s.prop('TeaPavilion','pavilion',[2450,960],320,'茶圃歇息亭')
    s.prop('SmallWing','estate_wing',[1050,2150],310,'茶工小院厢房')
    for i,(p,h) in enumerate([([850,820],260),([1500,720],285),([2100,620],240),([900,1220],230),([850,1700],250)]):s.prop('TeaGarden'+str(i),'tea_rows',p,h,'沿田埂采茶，茶垄本体不可穿过。',points=rect(-h*.8,-h*.42,h*1.6,h*.42))
    # Front white walls form real openings; independent buildings provide side massing.
    for i,(x,y,w) in enumerate([(1430,2730,600),(2360,2730,600),(3640,2450,450),(4620,2450,570),(3700,1300,300),(4710,1300,270),(1110,1510,420),(2060,1510,420)]):s.wall('WhiteWall'+str(i),x,y,w)
    # Roofed inner and tea-work courts: pillar footprints leave the bays open.
    for name,pos,h in [('InnerGallery',[4050,1810],280),('TeaGallery',[1950,1850],240)]:
        r=s.prop(name,'corridor',pos,h,'院廊：穿行柱间，廊柱独立阻挡。',False)
        for i,fraction in enumerate([-.33,-.11,.11,.33]):s.body('Pillar'+str(i),'Town/'+name,rect(r['width']*fraction-16,-32,32,32))
    for i,(x,y,w) in enumerate([(1600,2030,520),(2250,2030,520),(3710,2010,400),(4770,2010,400)]):s.wall('BackWall'+str(i),x,y,w)
    for i,(x,y,h) in enumerate([(600,3050,370),(2450,3100,380),(2530,2100,320),(3200,2050,390),(5100,3000,450),(5000,1770,360),(3240,720,390),(1750,1780,240),(650,2400,360)]):s.prop('Bamboo'+str(i),'bamboo',[x,y],h,'竹林院界',points=rect(-h*.25,-50,h*.5,50))
    for i,(x,y,h) in enumerate([(620,3500,450),(1010,3370,340),(2200,3360,320),(400,2150,420),(500,1800,380),(400,1000,400),(1800,400,330),(2390,500,380),(3300,410,400),(4400,540,350),(5000,700,420),(5270,1350,400),(5200,2300,430),(4800,3290,400),(3900,3420,330),(3550,2130,260),(3500,1080,270)]):s.prop('ValleyTree'+str(i),'trees',[x,y],h,'溪谷乔木',points=rect(-35,-32,70,32))
    for i,y in enumerate([350,620,880,1070,1580,1810,2070,2240,2810,3100,3390]):
        for side,x in enumerate([2665,2940]):s.prop('Bank'+str(i)+'_'+str(side),'bank_shrub',[x,y],90+(i%3)*12,'溪岸石丛',points=rect(-45,-30,90,30))
    for name,key,p,h in [('GuestBench','bench',[2200,2590],46),('TeaTable','table',[1720,2580],85),('WorkshopCargo','cargo',[2390,1440],85),('InnerJars','water_jars',[4850,2330],75),('TeaShelf','shelf',[1200,1430],120)]:s.prop(name,key,p,h,'茶院日用陈设')
    s.node('Creek','Polygon2D','.','z_index = -15\nmaterial = SubResource("water_mat")\npolygon = '+poly([[2670,100],[2930,100],[2930,3700],[2670,3700]]))
    for nm,y in [('GuestBridge',2500),('TeaBridge',1300)]:s.bridge(nm,[2800,y])
    last=100
    for bridge in sorted(s.bridges,key=lambda r:r['center'][1]):
        lo,hi=bridge['walk_y'];s.body('Water'+str(int(last)),'Town',rect(2670,last,260,lo-last),True);last=hi
    s.body('WaterEnd','Town',rect(2670,last,260,3700-last),True)
    for points,w in [([[1700,3600],[1700,2860],[1950,2860],[1950,2540],[2450,2540],[2450,2490],[3300,2490],[3300,3000],[3800,3000],[3800,2800],[3800,2600],[4050,2600],[4050,2350]],90),([[4050,2350],[4050,1720],[4080,1510],[4080,1320]],90),([[1950,2860],[2500,2860],[2500,1650],[2450,1650],[2450,1290],[3300,1290],[3300,3000],[4600,3000],[4600,2800],[4800,2630],[4800,1730],[4640,1730],[4640,1510],[4500,1320]],75),([[2500,1650],[1620,1650],[1620,1450],[1620,1000],[2200,1000]],75),([[1950,2540],[1050,2540],[1050,2300]],70)]:s.road(points,w)
    s.plaza([1950,2480],[650,330]);s.plaza([4220,2400],[650,350]);s.plaza([4200,1230],[650,380]);s.finish()

def scripts():
    target=PROJECT/SCRIPT;target.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(ROOT/'scripts/templates'/NAME/'controller.gd',target/'controller.gd')
    terrain_src=(ROOT/'game/scripts/drafts/miao_terrain_20261029i/terrain.gd').read_text('utf-8')
    terrain_src=terrain_src.replace('data=JSON.parse_string(FileAccess.get_file_as_string("res://art/modules/miao_terrain_20261029i/terrain.json"))','data=town.layout.terrain')
    terrain_src=re.sub(r'\n\t\tif item.name=="DyeWorker":.*?;level=1','',terrain_src)
    terrain_src=terrain_src.replace('body.name=="Boundary" or str(body.name).begins_with("Water")','body.has_meta("common_layer") or str(body.name).begins_with("Water")')
    # South-facing camera: north-facing risers are behind their top surface, not courtyard walls.
    terrain_src=terrain_src.replace('var p: Vector2=pair[0];var q: Vector2=pair[1];var count:=', 'var p: Vector2=pair[0];var q: Vector2=pair[1]\n\t\t\t\tif q.x>=p.x:continue\n\t\t\t\tvar count:=')
    start=terrain_src.index('func edge_pieces(');end=terrain_src.index('\nfunc build_boundaries',start)
    terrain_src=terrain_src[:start]+'''func edge_pieces(a: Vector2,b: Vector2,level: int,opening: float) -> Array:
\tvar pieces: Array=[[a,b]]
\tfor ramp: Dictionary in ramps:
\t\tif int(ramp.high)!=level:continue
\t\tvar t:=Vector2(ramp.top[0],ramp.top[1])
\t\tif absf(a.y-b.y)>.01 or absf(a.y-t.y)>.01:continue
\t\tvar next: Array=[]
\t\tfor pair: Array in pieces:
\t\t\tvar p: Vector2=pair[0];var q: Vector2=pair[1]
\t\t\tif t.x<=minf(p.x,q.x) or t.x>=maxf(p.x,q.x):next.append(pair);continue
\t\t\tvar left:=Vector2(maxf(t.x-opening,minf(p.x,q.x)),p.y)
\t\t\tvar right:=Vector2(minf(t.x+opening,maxf(p.x,q.x)),p.y)
\t\t\tnext.append([p,left] if p.x<q.x else [p,right]);next.append([right,q] if p.x<q.x else [left,q])
\t\tpieces=next
\treturn pieces
''' + terrain_src[end:]
    (target/'terrain.gd').write_text(terrain_src,'utf-8')
    shutil.copyfile(target/'terrain.gd',ROOT/'scripts/templates'/NAME/'terrain.gd')

if __name__=='__main__':
    if sys.argv[1]=='prepare':prepare_media()
    maps();scripts();print('Built two independent sect scenes and shared physical terrain controller')
