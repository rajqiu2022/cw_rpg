"""Build Huashan in a private project, reusing verified terrain mechanics only."""
import math,json,shutil,re,sys
from PIL import Image
from huashan_map_20261029m import *
import build_sect_maps_20261029k as base
from build_redrock_town_20261028a import vec,poly
base.NAME=NAME;base.STAGE=STAGE;base.PROJECT=PROJECT;base.ART=ART;base.SCRIPT='scripts/drafts/'+NAME+'/'
Scene=base.Scene;rect=base.rect
OUTLINE=[[650,650],[1800,200],[3350,250],[4030,750],[4250,1450],[5100,1350],[5500,1700],[5450,2300],[4730,2350],[4450,2200],[4260,2450],[4480,3100],[4900,3250],[4930,3650],[4430,3750],[3980,3200],[3650,3030],[3300,3400],[3100,3950],[3200,4570],[2510,4700],[2290,4200],[2120,3690],[1200,3350],[650,2850]]
def prepare():
    assert not PROJECT.exists();prior=ROOT/'assets/staging/sect_maps_20261029k/town_project';PROJECT.mkdir()
    for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(prior/folder,PROJECT/folder)
    (PROJECT/'artifacts-m').mkdir()
    config=(prior/'project.godot').read_text('utf-8').replace('sect_maps_20261029k/wudang.tscn',NAME+'/huashan.tscn').replace('sect_maps_20261029k_validation',NAME+'_validation').replace('武当与茗雾·独立编辑地图','华山·险峰剑院独立地图').replace('Color(0.25,0.28,0.22,1.0)','Color(0.28,0.33,0.37,1.0)')
    (PROJECT/'project.godot').write_text(config,'utf-8');media={};checks=[]
    for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
        assert r['status']=='RAW_CANDIDATE';im=Image.open(ROOT/r['output']);w,h=im.size;px=py=0
        if r['transparent']:
            assert im.mode=='RGBA';a=im.getchannel('A');b=a.getbbox();assert a.getextrema()[0]==0
            margins=[b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h]
            px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
            out=Image.new('RGBA',(w+px*2,h+py*2),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
            bb=out.getchannel('A').getbbox();nw,nh=out.size;assert min(bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh)>=.1
            native=a.point(lambda v:255 if v>=128 else 0).getbbox()
            checks.append({'key':r['key'],'raw_A1_pass':min(margins)>=.1,'raw_margins':margins,'derived_A1_pass':True,'original_RGBA_exact':True,'only_RGBA0_padding':True,'alpha_cleaned_pixels':0,'offset':[px,py]})
        else:out=im;native=[0,0,w,h]
        dst=ROOT/'assets/processed'/NAME/(r['key']+'.png');dst.parent.mkdir(parents=True,exist_ok=True)
        if not r['transparent']:shutil.copyfile(ROOT/r['output'],dst)
        else:out.save(dst)
        target=PROJECT/ART/dst.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(dst,target)
        template=(ROOT/'game/art/modules/sect_maps_20261029k/wudang_hall.png.import').read_text('utf-8')
        rel='res://'+ART+'/'+dst.name;cache=dst.name+'-'+hashlib.md5(rel.encode()).hexdigest()+'.ctex'
        template=re.sub(r'uid="[^"]+"\n','',template).replace('res://art/modules/sect_maps_20261029k/wudang_hall.png',rel)
        template=template.replace('wudang_hall.png-eaf1a97e8ff5fcf5c60c2264aff64c20.ctex',cache)
        Path(str(target)+'.import').write_text(template,'utf-8')
        media[r['key']]={'path':ART+'/'+dst.name,'bbox':[native[0]+px,native[1]+py,native[2]+px,native[3]+py],'padding':[px,py],'size':list(out.size),'raw':r['output'],'processed':dst.relative_to(ROOT).as_posix(),'label':r['label']}
    old=json.loads((ROOT/'assets/staging/sect_maps_20261029k/media.json').read_text('utf-8'))
    for k in ['ground','path','water','wudang_pine','bench','table','cargo','water_jars','shelf','pavilion']:media[k]=old[k]
    media['quiet_ground']=media['granite_ground']
    save(STAGE/'media.json',media);save(STAGE/'padding-verification.json',checks)

def build():
    p1=[[850,900],[1800,400],[3300,450],[3900,950],[3950,1670],[4750,1600],[5150,1720],[5150,2090],[4670,2160],[4140,1990],[4120,2460],[4110,2800],[1050,2800],[800,2300]]
    p2=[[1900,700],[2600,420],[3350,700],[3670,1100],[3690,1550],[1950,1550],[1780,1200]]
    t=base.terrain([0,240,480],[p1,p2],[('MainRise','山门—练剑前坪',0,1,[2700,2800]),('WestRise','生活侧径—弟子居舍',0,1,[1400,2800]),('HallRise','练剑坪—主堂剑院',1,2,[2700,1550]),('HallSideRise','东廊—主堂侧院',1,2,[3420,1550]),('CliffRise','思过崖径—论剑台',0,1,[3930,2800])],1.1,238,370)
    t['base_outline']=OUTLINE
    s=Scene('huashan','华山派 · 险峰剑院','山门石径 · 练剑前坪 · 主堂剑院 · 弟子居舍 · 论剑台 · 思过崖',[5800,5000],[2780,4420],t)
    # The ground and its collision boundary share one irregular ridge outline.
    s.nodes[1]=s.nodes[1].replace(poly(rect(-1000,-1000,7800,7000)),poly(OUTLINE))
    s.layout['overview']=[2900,2320];s.layout['overview_zoom']=.168
    s.layout['description']='华山山门沿主阶抵达练剑坪与主堂。西侧生活径可返山门；东侧山径通往论剑台和思过崖。空格查看附近物件。'
    hall=s.prop('MainHall','main_hall',[2770,1040],450,'主堂剑院：正门前台基，东西阶可到达。')
    gate=s.prop('MountainGate','mountain_gate',[2770,4050],330,'山门：双柱之间为通行口。',False)
    r=s.media['mountain_gate'];cx=(r['bbox'][0]+r['bbox'][2])/2;px,py=r['padding'];sc=gate['scale']
    for nm,x0,x1,y0,y1 in [('LeftPier',345,610,690,823),('RightPier',935,1220,780,916)]:
        s.body(nm,'Town/MountainGate',rect((x0+px-cx)*sc,(y0+py-r['bbox'][3])*sc,(x1-x0)*sc,(y1-y0)*sc))
    for name,key,p,h,label in [
        ('WestLongHouse','dormitory',[1300,2110],345,'弟子长舍：起居院'),('NorthLongHouse','dormitory',[1270,1380],345,'北侧居舍'),
        ('WestStudy','tall_house',[1880,2050],560,'两层书舍'),('UpperStudy','tall_house',[3420,1100],525,'主堂侧书舍'),
        ('Kitchen','kitchen',[1060,2480],315,'生活院灶房与柴棚'),('Storehouse','kitchen',[1850,2590],290,'储物小屋'),
        ('UpperWing','dormitory',[2150,1160],320,'主堂西厢'),('GateHouse','kitchen',[2320,3780],290,'山口值守小屋')]:s.prop(name,key,p,h,label)
    for i,(p,h) in enumerate([([2280,2480],113),([3270,2480],113),([4780,1810],113),([3050,1250],106)]):s.prop('SwordRack'+str(i),'sword_rack',p,h,'练剑架：陈设，不产生装备或奖励。')
    for name,key,p,h in [('KitchenJars','water_jars',[1370,2530],80),('YardTable','table',[1490,2320],86),('Cargo','cargo',[2080,2580],80),('StudyShelf','shelf',[2090,2050],110),('WestBench','bench',[1550,2610],42),('HallBench','bench',[3100,1250],42),('CliffBench','bench',[4670,3480],42),('DebateBench','bench',[4870,1980],42)]:s.prop(name,key,p,h,'山院日用陈设')
    for points,w in [
        ([[2780,4550],[2770,4050],[2640,3560],[2700,3200],[2700,2800],[2700,2480],[2700,2080],[2700,1550],[2770,1270]],140),
        ([[2640,3560],[1700,3210],[1400,3200],[1400,2800],[1450,2590],[1500,2260],[1550,1600]],110),
        ([[1450,2590],[2100,2590],[2240,2200],[2700,2200]],100),
        ([[2770,1270],[3420,1350],[3420,1550],[3420,2080],[3890,2020],[4480,1880],[4880,1880]],110),
        ([[3420,2080],[3930,2350],[3930,2800],[3930,3100],[4470,3400],[4720,3500]],105),
        ([[2700,3200],[3500,3180],[3930,3100]],100)]:s.road(points,w)
    for c,r in [([2780,2280],[710,540]),([2770,1270],[850,350]),([1510,2320],[650,400]),([4800,1900],[280,150]),([4650,3450],[220,140])]:s.plaza(c,r)
    # Rim crags overlap along the perimeter, never placed across playable courtyards.
    rocks=[(1930,600,720),(2680,410,900),(3420,530,740)]
    for i,(x,y,h) in enumerate(rocks):
        # Rock graphics are scenery outside the solid ridge rim. Their feet may extend outward.
        s.prop('RidgeCrag'+str(i),'granite_crag',[x,y],h,'花岗岩崖体',False)
    for i,(x,y,h) in enumerate([(800,1630,370),(890,2750,360),(2200,3000,330),(2240,3500,330),(3160,3990,380),(1700,1780,320),(3560,780,380),(2100,760,330),(4150,2160,350),(5140,2120,310),(4450,3250,290),(4910,3600,260)]):s.prop('MountainPine'+str(i),'wudang_pine',[x,y],h,'崖畔松树',points=rect(-27,-25,54,25))
    s.finish()
    shader=PROJECT/ART/'huashan_ground.gdshader'
    shader.write_text(shader.read_text('utf-8').replace('p/1350.','p/700.').replace('p/650.','p/300.'),'utf-8')
    target=PROJECT/'scripts/drafts'/NAME;target.mkdir(parents=True,exist_ok=True)
    for file in ['controller.gd','terrain.gd']:
        src=(ROOT/'scripts/templates/sect_maps_20261029k'/file).read_text('utf-8').replace('sect_maps_20261029k',NAME)
        if file=='terrain.gd':
            # Remove old unrelated special case; no legacy resident names in the new map.
            src=re.sub(r'\n\t\tif item.name=="DyeWorker":\n\t\t\t[^\n]+','',src)
            src=src.replace('\t\tbuild_surfaces()','\t\tbuild_ridge_boundary()\n\t\tbuild_surfaces()')
            src+='''
func build_ridge_boundary() -> void:
\tvar outline: Array=data.base_outline
\tvar texture: Texture2D=load("res://art/modules/huashan_map_20261029m/granite_crag.png")
\tfor i in range(outline.size()):
\t\tvar a:=Vector2(outline[i][0],outline[i][1]);var b:=Vector2(outline[(i+1)%outline.size()][0],outline[(i+1)%outline.size()][1])
\t\tfence(a,b,8,"RidgeEdge"+str(i))
\t\tif b.x>=a.x and b.y<=a.y:continue
\t\tvar count:=maxi(1,ceili(a.distance_to(b)/360.0))
\t\tfor j in range(count):
\t\t\tvar u:=a.lerp(b,float(j)/count);var v:=a.lerp(b,float(j+1)/count)
\t\t\tvar x0:=650.0+float(j%2)*270.0;var x1:=x0+u.distance_to(v)
\t\t\tvar face:=polygon_node(PackedVector2Array([u,v,v+Vector2(0,470),u+Vector2(0,470)]),PackedVector2Array([Vector2(x0,580),Vector2(x1,580),Vector2(x1,820),Vector2(x0,820)]),texture,self,-21)
\t\t\tface.name="RidgeFace"+str(i)+"_"+str(j)
'''
        (target/file).write_text(src,'utf-8')
    save(STAGE/'layout-summary.json',{'objects':len(s.objects),'blockers':len(s.blockers),'ramps':t['ramps'],'outline':OUTLINE})
    print('Built Huashan',len(s.objects),'objects',len(t['ramps']),'real stair connections')
if __name__=='__main__':
    if sys.argv[1]=='prepare':prepare()
    build()
