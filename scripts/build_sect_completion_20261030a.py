"""Build private candidates, leaving the published maps intact until actual QA."""
import math,re
from sect_completion_20261030a import *
import build_sect_maps_20261029k as base
from build_redrock_town_20261028a import vec,poly
base.NAME=NAME;base.STAGE=STAGE;base.PROJECT=PROJECT;base.ART=ART;base.SCRIPT='scripts/drafts/'+NAME+'/'
Scene=base.Scene;rect=base.rect
def copy_resource(rel):
 src=ROOT/'game'/rel;dst=PROJECT/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
 imp=Path(str(src)+'.import')
 if imp.exists():
  shutil.copy2(imp,Path(str(dst)+'.import'))
  for leaf in re.findall(r'res://(\.godot/imported/[^"\]]+)',imp.read_text('utf-8')):
   if (ROOT/'game'/leaf).exists():shutil.copy2(ROOT/'game'/leaf,PROJECT/leaf)
def prepare():
 assert not PROJECT.exists();prior=ROOT/'assets/staging/sect_maps_20261029k/town_project';PROJECT.mkdir()
 for folder in ['art','scripts','scenes','.godot/imported']:shutil.copytree(prior/folder,PROJECT/folder)
 (PROJECT/'review').mkdir();(PROJECT/'project.godot').write_text((prior/'project.godot').read_text('utf-8').replace('sect_maps_20261029k/wudang.tscn',NAME+'/lingyue.tscn').replace('sect_maps_20261029k_validation',NAME+'_validation'),'utf-8')
 media=json.loads((ROOT/'assets/staging/sect_maps_20261029k/media.json').read_text('utf-8'));checks=[]
 for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
  im=Image.open(ROOT/r['output']);assert im.mode=='RGBA';w,h=im.size;a=im.getchannel('A');b=a.getbbox()
  px=math.ceil(max(.1*w-b[0],.1*w-(w-b[2]),0)/.8)+1;py=math.ceil(max(.1*h-b[1],.1*h-(h-b[3]),0)/.8)+1
  out=Image.new('RGBA',(w+2*px,h+2*py),(0,0,0,0));out.paste(im,(px,py));assert out.crop((px,py,px+w,py+h)).tobytes()==im.tobytes()
  bb=out.getchannel('A').getbbox();nw,nh=out.size;assert min(bb[0]/nw,bb[1]/nh,(nw-bb[2])/nw,(nh-bb[3])/nh)>=.1
  dst=ROOT/'assets/processed'/NAME/(r['key']+'.png');dst.parent.mkdir(parents=True,exist_ok=True);out.save(dst)
  target=PROJECT/ART/dst.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,target)
  template=(ROOT/'game/art/modules/sect_maps_20261029k/wudang_hall.png.import').read_text('utf-8');rel='res://'+ART+'/'+dst.name;cache=dst.name+'-'+hashlib.md5(rel.encode()).hexdigest()+'.ctex'
  template=re.sub(r'uid="[^"]+"\n','',template).replace('res://art/modules/sect_maps_20261029k/wudang_hall.png',rel);template=re.sub(r'wudang_hall.png-[0-9a-f]+\.ctex',cache,template);Path(str(target)+'.import').write_text(template,'utf-8')
  native=a.point(lambda n:255 if n>=128 else 0).getbbox();media[r['key']]={'path':ART+'/'+dst.name,'bbox':[native[0]+px,native[1]+py,native[2]+px,native[3]+py],'padding':[px,py],'size':list(out.size),'raw':r['output'],'processed':dst.relative_to(ROOT).as_posix(),'label':r['label']}
  checks.append({'key':r['key'],'raw_A1_pass':min(b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h)>=.1,'padded_A1_pass':True,'original_RGBA_exact':True,'only_RGBA0_padding':True,'alpha_cleaned_pixels':0,'offset':[px,py]})
 for key,rel in {'crag':'art/modules/huashan_map_20261029m/granite_crag.png','granite':'art/modules/huashan_map_20261029m/granite_ground.png','bell':'art/modules/ancient_temple_assembled_20261016/ancient_bell_v1.png'}.items():
  copy_resource(rel);im=Image.open(PROJECT/rel).convert('RGBA');media[key]={'path':rel,'bbox':list(im.getchannel('A').point(lambda n:255 if n>=128 else 0).getbbox()),'size':list(im.size),'padding':[0,0],'reused':True}
 for r in media.values():
  if not (PROJECT/r['path']).exists():copy_resource(r['path'])
 save(STAGE/'media.json',media);save(STAGE/'padding-verification.json',checks)
 for rel in ['scripts/drafts/sect_maps_20261029k/terrain.gd','scripts/drafts/sect_maps_20261029k/controller.gd','scripts/drafts/town_layout_20261029r/actor_ghost.gd']:copy_resource(rel)
def gate(s,key,p,h,piers):
 g=s.prop('MountainGate',key,p,h,'山门：中央通行，两侧柱脚阻挡。',False);r=s.media[key];cx=(r['bbox'][0]+r['bbox'][2])/2;px,py=r['padding'];sc=g['scale']
 for i,(x,y,w,d) in enumerate(piers):s.body('Pier'+str(i),'Town/MountainGate',rect((x+px-cx)*sc,(y+py-r['bbox'][3])*sc,w*sc,d*sc))
def paths(s,rows):
 for pts,width in rows:s.road(pts,width)
def water_bands(s,outline,openings):
 # Clip the exact water polygon into solid bands, leaving only authored bridge decks open.
 def clip(points,y,above):
  result=[]
  for a,b in zip(points,points[1:]+points[:1]):
   ia=a[1]>=y if above else a[1]<=y;ib=b[1]>=y if above else b[1]<=y
   if ia:result.append(a)
   if ia!=ib:
    t=(y-a[1])/(b[1]-a[1]);result.append([a[0]+t*(b[0]-a[0]),y])
  return result
 lo=min(p[1] for p in outline);hi=max(p[1] for p in outline);bands=[]
 for a,b in sorted(openings):bands.append((lo,a));lo=b
 bands.append((lo,hi))
 for i,(a,b) in enumerate(bands):
  points=clip(clip(outline,a,True),b,False)
  if len(points)>2:s.body('WaterBand'+str(i),'Town',points,True)
def build():
 t=base.terrain([0,90,180],[rect(700,550,3650,1700),rect(2350,550,1850,800)],[('CourtRise','山门—演棍坪',0,1,[1900,2250]),('EastRise','山门东径—竹舍院',0,1,[4000,2250]),('HallRise','寒潭—临潭主楼',1,2,[3250,1350]),('SideRise','东院—后山静台',1,2,[3950,1350])],.7,145,235)
 s=Scene('lingyue','凌月派 · 寒潭竹院','竹径山门 · 演棍坪 · 临潭主楼 · 弟子竹舍 · 月潭双桥 · 后山静台',[4800,3600],[1900,3370],t)
 s.prop('MainHall','lingyue_hall',[3250,950],415,'临潭主楼：二级高台，双阶通往潭院。')
 gate(s,'lingyue_gate',[1900,3070],300,[(405,755,180,125),(990,785,190,125)])
 for name,p in [('WestDorm',[1150,1540]),('NorthDorm',[1700,1100]),('EastDorm',[3850,2000]),('LowerDorm',[3800,2820])]:s.prop(name,'lingyue_dorm',p,305,'弟子竹舍：沿屋前小径通行。')
 s.prop('QuietPavilion','pavilion',[4050,1030],245,'后山静台')
 s.prop('Kitchen','tea_workshop',[950,2780],235,'日常作棚')
 for i,p in enumerate([[1510,1960],[2220,1960],[3540,1150]]):s.prop('StaffRack'+str(i),'staff_rack',p,125,'演棍坪长棍架')
 s.prop('OldBell','bell',[2300,2800],145,'山门旧钟')
 pond=[[2490,1440],[2630,1440],[2630,1590],[2800,1750],[2830,1950],[2700,2040],[2650,2200],[2460,2200],[2400,2060],[2280,1940],[2290,1780],[2450,1590]]
 s.node('MoonPool','Polygon2D','.','position = Vector2(0,-90)\nz_index = -5\nmaterial = SubResource("water_mat")\npolygon = '+poly(pond))
 for nm,y in [('MoonBridge',1720),('BambooBridge',2120)]:s.bridge(nm,[2555,y])
 water_bands(s,pond,[br['walk_y'] for br in s.bridges])
 for i,p in enumerate([[2450,1520],[2670,1580],[2260,1810],[2870,1810],[2240,1960],[2860,1980],[2380,2090],[2700,2110]]):s.prop('PoolBank'+str(i),'bank_shrub',p,95,'寒潭曲岸石丛',False)
 for i,p in enumerate([[1100,3000],[1300,1710],[3560,2120],[3700,1190]]):s.prop('Bench'+str(i),'bench',p,42,'竹院长凳')
 for i,(p,k,h) in enumerate([([1040,2840],'water_jars',70),([3500,2860],'cargo',75),([3630,2100],'table',80)]):s.prop('Household'+str(i),k,p,h,'院落日用陈设')
 for i,p in enumerate([[550,2700],[650,1900],[650,1100],[1100,600],[1950,550],[4300,850],[4400,1800],[4400,2850],[2550,3150],[3100,2800],[3050,2080]]):s.prop('Bamboo'+str(i),'bamboo',p,320,'竹林',points=rect(-45,-25,90,25))
 for i,p in enumerate([[600,700],[2000,380],[3450,320],[4450,650]]):s.prop('Ridge'+str(i),'crag',p,480,'灰岩山脊',points=rect(-300,-80,600,80))
 for i,p in enumerate([[800,750],[1250,600],[1550,600],[2030,820],[900,2000],[810,2400],[2950,730],[4300,1300],[4300,2300],[4180,3070],[3150,3200],[1500,3220],[2400,3060],[3020,1630],[3550,2650]]):s.prop('BambooGrove'+str(i),'bamboo',p,280+(i%3)*20,'成片竹林',points=rect(-38,-25,76,25))
 for name,p in [('WestService',[1070,2220]),('UpperWing',[2460,980])]:s.prop(name,'lingyue_dorm',p,285,'竹院侧舍')
 for i,p in enumerate([[1150,1700],[3880,2150],[3860,2950],[1700,1260],[2520,1170]]):s.prop('YardJars'+str(i),'water_jars',p,65,'屋前水缸')
 paths(s,[([[1900,3450],[1900,3070],[1900,2500],[1900,2250],[1900,2020],[1900,1720],[2150,1720],[3000,1720],[3250,1580],[3250,1350],[3250,1140]],120),([[1900,2500],[4000,2500],[4000,2250],[4120,2100],[4120,1600],[3950,1600],[3950,1350],[3950,1150]],100),([[1900,2020],[2140,2120],[3000,2120],[3450,2120],[4120,2100]],90),([[1900,1720],[1300,1720],[1300,1280],[1750,1280]],90),([[1900,2900],[1100,2900]],85)])
 for p,r in [([1900,1980],[600,340]),([3250,1130],[650,260]),([3850,2160],[460,200])]:s.plaza(p,r)
 s.finish()
 t=base.terrain([0,120,240],[rect(1700,500,2700,2000),rect(2350,500,1900,850)],[('WardRise','渡口—寨前院',0,1,[2600,2500]),('FreightRise','货路—东院',0,1,[4000,2500]),('HallRise','寨前院—寨厅高台',1,2,[3100,1350]),('SideRise','东院—高台侧径',1,2,[3900,1350])],.75,155,250)
 s=Scene('lieyun','烈云谷 · 峡渡寨院','旧渡口 · 关寨门 · 驮货场 · 分舵前院 · 木石寨厅 · 东侧货路',[4800,4000],[2600,3730],t)
 s.media['quiet_ground']=s.media['woodland'];s.ext=[x.replace('art/modules/sect_maps_20261029k/quiet_ground.png',s.media['woodland']['path']) if 'id="quiet_ground"' in x else x for x in s.ext]
 gate(s,'lieyun_gate',[2600,3320],330,[(170,670,470,160),(945,690,450,170)])
 s.prop('MainHall','lieyun_hall',[3100,990],385,'木石寨厅：台前通往原有分舵区域。')
 for name,p in [('FerryStore',[1570,2860]),('EastStore',[4080,2170]),('UpperStore',[3940,1030]),('WestHouse',[2180,1910])]:s.prop(name,'lieyun_store',p,430,'木石货舍：沿屋前货路通行。')
 s.prop('GuardLodge','lieyun_hall',[3340,2070],340,'分舵前院值守厅')
 s.node('River','Polygon2D','.','z_index = -15\nmaterial = SubResource("water_mat")\npolygon = '+poly([[450,100],[920,100],[960,1100],[1020,2200],[1040,3900],[450,3900]]))
 s.body('RiverBank','Town',rect(450,100,590,3800),True)
 # Reused complete bridge deck makes the small ferry landing; bank collision keeps river closed.
 s.bridge('FerryLanding',[1080,3000])
 for i,(p,k,h) in enumerate([([1460,3060],'cargo',95),([1800,3100],'cargo',85),([3500,2250],'water_jars',80),([3570,2340],'bench',42),([2100,2050],'table',90),([3410,1190],'bench',42)]):s.prop('Freight'+str(i),k,p,h,'渡口与寨院日用陈设')
 for i,p in enumerate([[1400,1000],[1540,1700],[1300,2450],[2100,500],[3100,300],[4230,500],[4580,1350],[4590,2300],[4500,3200],[1900,3530]]):s.prop('Ridge'+str(i),'crag',p,480,'峡谷岩脊',points=rect(-210,-70,420,70))
 for i,p in enumerate([[1220,2100],[1600,3350],[2200,2850],[4390,2800],[4360,1750],[2020,1180]]):s.prop('Pine'+str(i),'wudang_pine',p,310,'峡畔松树',points=rect(-30,-25,60,25))
 for i,p in enumerate([[1470,660],[2200,480],[2750,350],[3500,350],[4000,410],[4550,870],[4570,1600],[4580,2000],[4580,2700],[4470,3600]]):s.prop('ConnectedRidge'+str(i),'crag',p,430,'连续峡壁',points=rect(-220,-65,440,65))
 for name,p in [('LowerStore',[3400,2960]),('SideResidence',[2060,1300])]:s.prop(name,'lieyun_store',p,390,'寨院居舍与仓房')
 for i,p in enumerate([[1090,850],[1070,1350],[1110,1840],[1140,2280],[1160,2600],[1200,3400]]):s.prop('RiverRocks'+str(i),'crag',p,260,'峡溪岸石',points=rect(-120,-35,240,35))
 for i,p in enumerate([[1670,2740],[1930,2550],[1750,3080],[3500,3050],[3580,3090],[4150,2330]]):s.prop('CargoGroup'+str(i),'cargo',p,75,'分散货堆，留人行通道')
 paths(s,[([[2600,3800],[2600,3320],[2600,2780],[2600,2500],[2600,2240],[2800,1800],[3100,1600],[3100,1350],[3100,1170]],120),([[2600,3100],[1660,3100],[1250,3000]],110),([[2600,2780],[4000,2780],[4000,2500],[4080,2360],[4280,1840],[3900,1590],[3900,1350],[3900,1230]],110),([[2600,2240],[2140,2140],[2140,2040]],90),([[2600,2240],[3350,2240],[4080,2360]],90)])
 for p,r in [([2600,2920],[530,330]),([2800,2240],[600,300]),([3100,1180],[730,250])]:s.plaza(p,r)
 s.finish()
 for key in ['lingyue','lieyun']:
  p=PROJECT/ART/(key+'_ground.gdshader');p.write_text(p.read_text('utf-8').replace('folded(p/1350.)','p/1254.').replace('folded(p/650.)','p/650.'),'utf-8')
 # Keep the reviewed tea estate layout, redirect only its local controller and layout reference.
 rel='scenes/drafts/sect_maps_20261029k/mingwu.tscn';copy_resource(rel)
 text=(PROJECT/rel).read_text('utf-8').replace('res://scripts/drafts/sect_maps_20261029k/controller.gd','res://scripts/drafts/'+NAME+'/controller.gd').replace('layout_path = "res://art/modules/sect_maps_20261029k/mingwu.json"','layout_path = "res://'+ART+'/mingwu.json"')
 (PROJECT/'scenes/drafts'/NAME/'mingwu.tscn').write_text(text,'utf-8');layout=json.loads((ROOT/'game/art/modules/sect_maps_20261029k/mingwu.json').read_text('utf-8'));save(PROJECT/ART/'mingwu.json',layout)
 target=PROJECT/'scripts/drafts'/NAME;target.mkdir(parents=True,exist_ok=True)
 for src in (ROOT/'scripts/templates'/NAME).glob('*.gd'):shutil.copy2(src,target/src.name)
 print('Built Lingyue, Lieyun and retained Mingwu reviewed geometry')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 build()
