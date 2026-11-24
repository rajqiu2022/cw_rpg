"""Six native layouts for four places; old story assets remain untouched."""
from prepare_four_settlements_20261030e import *
import build_sect_maps_20261029k as base
from build_redrock_town_20261028a import vec,poly
base.NAME=NAME;base.STAGE=STAGE;base.PROJECT=PROJECT;base.ART=ART;base.SCRIPT='scripts/drafts/'+NAME+'/'
Scene=base.Scene;rect=base.rect
def paths(s,rows):
 for pts,w in rows:s.road(pts,w)
def building(s,name,key,p,h,label):
 r=s.prop(name,key,p,h,label);assert r['scale']<=1,(name,r['scale']);return [p[0]+r['width']*({'office':.15,'cottage':-.1}.get(key,0)),p[1]+38]
def details(s,homes):
 for i,(x,y) in enumerate(homes):
  s.prop('Jars'+str(i),'water_jars',[x+145,y+35],58,'屋前水缸',points=rect(-25,-20,50,20))
  if i%2==0:s.prop('Bench'+str(i),'bench',[x-150,y+55],38,'屋前长凳',points=rect(-65,-13,130,13))
def groves(s,points,key='trees',h=360):
 for i,p in enumerate(points):s.prop('Grove'+str(i),key,p,h+(i%3)*15,'树木与林缘',points=rect(-28,-25,56,25))
def fence(s,x,y,n):
 r=s.media['fence'];h=155*(r['bbox'][3]-r['bbox'][1])/(r['bbox'][2]-r['bbox'][0])
 for i in range(n):s.prop('Fence'+str(len(s.objects)),'fence',[x+150*i,y],h,'院落篱笆',points=rect(-76,-12,152,16))
def finish(s,business):
 # House-sized back buildings and connected service lanes enclose the street.
 additions={
 'bailu':[('cottage',[1500,830],260),('small_home',[550,1280],250),('cottage',[1370,2820],245)],
 'donghai':[('small_home',[430,2630],230),('cottage',[1330,2610],260),('warehouse',[2240,2200],275)],
 'linxi_center':[('cottage',[1190,740],255),('small_home',[650,670],235),('cottage',[2260,2490],255)],
 'linxi_south':[('small_home',[1220,900],245),('cottage',[2490,900],255),('cottage',[3600,930],250)],
 'zhuwei':[('cottage',[1550,660],255),('small_home',[2590,720],245),('cottage',[730,1270],250),('small_home',[3400,1220],245),('warehouse',[1470,2820],270)]}
 for i,(k,p,h) in enumerate(additions.get(s.key,[])):
  building(s,'BackHouse'+str(i),k,p,h,'街坊侧舍');s.road([[p[0],p[1]+35],[p[0]+120,p[1]+170]],75)
 # Short material periods preserve adult scale, with earth lanes for inland villages.
 s.layout['business']=business;s.layout['description']=s.layout['subtitle']+'。原剧情人物与室内入口由正式场景宿主接入。'
 s.finish();p=PROJECT/ART/(s.key+'_ground.gdshader')
 text=p.read_text('utf-8').replace('folded(p/1350.)','p/1000.').replace('folded(p/650.)','p/280.')
 if s.key!='donghai':text=text.replace('vec3 stone=texture(path_tex,p/280.).rgb','vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18)')
 p.write_text(text,'utf-8')
def water(s,bank,ys):
 s.node('Water','Polygon2D','.','z_index = -15\nmaterial = SubResource("water_mat")\npolygon = '+poly(rect(bank,100,s.layout['size'][0]-bank-100,s.layout['size'][1]-200)))
 # Whole native pier deck is below actors; collision leaves only its authored top open.
 openings=[]
 for i,y in enumerate(ys):
  r=s.prop('Pier'+str(i),'wood_pier',[bank+350,y],235,'木栈台：踏面通行，边缘不可落水。',False,ground=True)
  y0=y-190;y1=y-85;right=bank+350+r['width']*.44
  s.body('PierEnd'+str(i),'Town',rect(right,y0,16,y1-y0),True);openings.append((y0,y1,right))
  s.prop('Ferry'+str(i),'ferry_boat',[bank+580,y+240],210,'系泊渡船',False)
 cursor=100
 for i,(a,b,right) in enumerate(openings):
  s.body('WaterBand'+str(i),'Town',rect(bank,cursor,s.layout['size'][0]-bank,b-a+ a-cursor-(b-a)),True)
  s.body('WaterBeyondPier'+str(i),'Town',rect(right+10,a,s.layout['size'][0]-right,b-a),True);cursor=b
 s.body('WaterLast','Town',rect(bank,cursor,s.layout['size'][0]-bank,s.layout['size'][1]-cursor),True)
 for i,y in enumerate(range(320,s.layout['size'][1]-180,220)):
  if any(a-80<y<b+90 for a,b,_ in openings):continue
  s.prop('Bank'+str(i),'bank_shrub',[bank-15,y],105,'临水岸沿',False)
 return [[bank+260,y-135] for y in ys]
def build():
 # Keep reused source files/imports exact.
 media=json.loads((STAGE/'media.json').read_text('utf-8'))
 for key,rel in {'stall':'art/modules/luoyang_district_life_20261016f/herbal_medicine_stall_v1.png','cart':'art/modules/luoyang_assembled_interiors_20261016g/wood_handcart_v1.png','tablet':'art/modules/prop/linxi_stone_tablet_v2.png'}.items():
  if not (ROOT/'game'/rel).exists():rel=next((ROOT/'game/art').rglob(Path(rel).name)).relative_to(ROOT/'game').as_posix()
  copy_resource(rel);im=Image.open(PROJECT/rel).convert('RGBA');media[key]={'path':rel,'bbox':list(im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()),'size':list(im.size),'padding':[0,0],'reused':True}
 save(STAGE/'media.json',media)
 flat=base.terrain([0],[],[],.35,65,120)
 s=Scene('bailu','白鹿渡 · 柳岸渡栈','候船柳坪 · 渡船双栈 · 渔家巷 · 货栈前院',[4000,3000],[620,2510],flat)
 dock=water(s,2650,[1500,2400]);homes=[]
 for nm,k,p,h in [('Inn','inn',[950,820],380),('Tally','office',[2140,810],280),('FisherA','cottage',[710,1680],270),('FisherB','small_home',[1420,1580],265),('FisherC','cottage',[820,2280],255),('FisherD','small_home',[1670,2230],245),('Store','warehouse',[2100,1840],285)]:building(s,nm,k,p,h,nm);homes.append(p)
 s.prop('Waiting','pavilion',[1860,1260],260,'柳坪候船亭');s.prop('NetShed','repair_shed',[2110,2650],240,'渔家补网棚')
 for i,p in enumerate([[2470,1170],[2470,1990],[2460,2750],[470,1150],[1550,620]]):s.prop('Willow'+str(i),'willow',p,440,'渡边垂柳',points=rect(-28,-25,56,25))
 details(s,homes);fence(s,500,1940,3);fence(s,1260,1880,3)
 for i,p in enumerate([[2210,1560],[2250,2140],[2300,2500]]):s.prop('Cargo'+str(i),'cargo',p,75,'货物离开候船通路')
 paths(s,[([[620,2600],[1150,2550],[1150,1970],[1720,1970],[2450,1970]],140),([[1150,1970],[1150,1180],[1750,1430],[2500,1360],[2930,1360]],120),([[1720,1970],[1720,2360],[2500,2260],[2930,2260]],110),([[1150,1180],[2150,1010],[2450,1010],[2450,2260]],100)])
 groves(s,[[300,600],[500,330],[1200,330],[1850,350],[300,1950],[1850,2840]],'willow',400)
 finish(s,{'portals':{'bailu_ferry_to_world_map':[620,2600]},'portal_targets':{'world_map_jianghu':[620,2600]},'npcs':{'openworld_bailu_ferry_boatman':dock[0],'duan_changfeng':[1770,1510]},'interactions':{}})
 t=base.terrain([0,90],[rect(700,350,2100,850)],[('OfficeRise','码头—港署石台',0,1,[1600,1200]),('FreightRise','货路—仓院石台',0,1,[2500,1200])],.45,90,155)
 s=Scene('donghai','东海埠 · 石岸货港','港署高台 · 双仓货院 · 修帆棚 · 石埠双栈',[4400,3300],[540,2800],t)
 dock=water(s,3030,[1850,2800]);homes=[]
 for nm,k,p,h in [('PortOffice','office',[1510,760],310),('WarehouseA','warehouse',[2380,790],320),('WarehouseB','warehouse',[2250,1670],285),('Inn','inn',[800,1560],390),('HouseA','cottage',[740,2320],255),('HouseB','small_home',[1450,2550],240),('HouseC','cottage',[2160,2700],260)]:building(s,nm,k,p,h,nm);homes.append(p)
 for i,p in enumerate([[2620,2400],[1450,1950]]):s.prop('RepairShed'+str(i),'repair_shed',p,270,'海埠修帆作棚')
 s.prop('FishMarket','stall',[1140,2920],210,'沿街鱼货摊棚');s.prop('BoatCargo','ship',[3890,1320],500,'货船泊位',False)
 for i,p in enumerate([[2700,1760],[2680,2050],[2360,3040],[1300,1040],[2200,1000]]):s.prop('Cargo'+str(i),'cargo',p,80,'货栈码放')
 details(s,homes);groves(s,[[350,700],[500,400],[600,2000],[2800,400]],'wudang_pine',310)
 paths(s,[([[540,2890],[1050,2740],[1050,2160],[1600,2160],[1600,1410],[1600,1200],[1600,920]],140),([[1600,2160],[2800,2110],[2800,1700],[3340,1715]],130),([[1050,2740],[1850,2920],[2800,2920],[2800,2660],[3340,2665]],110),([[2800,2110],[2800,1450],[2500,1400],[2500,1200],[2500,1010]],100)])
 finish(s,{'portal_targets':{'world_map_jianghu':[540,2890]},'portals':{},'npcs':{'openworld_east_sea_port_boatman':dock[0]},'interactions':{}})
 t=base.terrain([0,60],[rect(500,350,1900,750)],[('HallRise','练功院—师徒居舍',0,1,[1150,1100]),('BedroomRise','竹径—卧房',0,1,[2050,1100])],.35,65,120)
 s=Scene('linxi_master','林西村 · 师徒院落','北台师居 · 练功土坪 · 石坛 · 东侧竹径',[2900,2400],[1450,2140],t)
 main=building(s,'MasterHall','office',[1130,780],290,'师父正堂');bed=building(s,'Bedroom','cottage',[2100,820],270,'冷孤云卧房')
 building(s,'Kitchen','small_home',[650,1660],245,'师徒灶房');s.prop('StoneTablet','tablet',[2010,1630],155,'石坛铭文')
 s.prop('Staffs','staff_rack',[1010,1370],122,'练功木架');details(s,[[1130,780],[2100,820],[650,1660]])
 fence(s,700,1930,3);fence(s,1900,1930,3)
 groves(s,[[350,700],[350,1250],[350,1850],[600,350],[1250,300],[2000,300],[2550,700],[2560,1150],[2520,1700],[2450,2100],[650,2200]])
 paths(s,[([[1450,2210],[1450,1690],[1150,1330],[1150,1100],[1150,900]],130),([[1450,1690],[2050,1800],[2220,1450],[2050,1300],[2050,1100],[2050,940]],85)])
 s.plaza([1450,1690],[480,300])
 finish(s,{'portals':{'master_house_entry':main,'hero_bedroom_entry':bed,'exit_to_center':[1450,2230]},'portal_targets':{'linxi_master_hall':main,'linxi_hero_bedroom':bed,'linxi_village_center':[1450,2230]},'npcs':{},'npc_prefixes':{'xingfantian':[1280,1550],'duqingshan':[1780,1450],'feng_yanqiu':[1940,1770]},'interactions':{'stone_altar_read':[2010,1700]}})
 s=Scene('linxi_center','林西村 · 老井村心','老井树坪 · 私塾院 · 村民家 · 采药院 · 南坊路',[3600,2800],[500,2360],flat)
 school=building(s,'School','office',[1650,740],290,'私塾旧宅');farmer=building(s,'FarmerHome','cottage',[2840,1100],280,'村民家');herb=building(s,'HerbHome','small_home',[2790,2110],265,'采药人家')
 homes=[[1650,740],[2840,1100],[2790,2110]]
 for nm,k,p,h in [('HerbShop','repair_shed',[750,1180],250),('Tavern','inn',[770,2030],360),('HouseA','cottage',[2250,700],250),('HouseB','small_home',[1730,2250],240)]:building(s,nm,k,p,h,nm);homes.append(p)
 s.prop('Well','well',[1720,1450],140,'老井');s.prop('OldWillow','willow',[2040,1250],460,'老井旁树坪',points=rect(-32,-25,64,25));details(s,homes)
 fence(s,2530,1440,2);fence(s,2930,1440,2);fence(s,2480,2440,2)
 groves(s,[[330,600],[650,350],[1400,310],[2200,350],[3180,650],[3420,1970],[3200,2520],[700,2560]])
 paths(s,[([[400,2420],[1200,2440],[1290,1750],[1600,1620],[2480,1650],[3320,1650]],135),([[1290,1750],[1150,1280],[1650,1040],[1650,840]],100),([[2480,1650],[2840,1300],[2840,1160]],90),([[2480,1650],[2510,2290],[2790,2210]],100),([[2480,1650],[2480,1000],[2840,750],[3070,400]],105)])
 finish(s,{'portals':{},'portal_targets':{'linxi_tutorial':[420,2420],'ch1_s1_road':[3070,400],'linxi_village_scrollmap':[3320,1650],'linxi_scholar_house':school,'linxi_farmer_cottage':farmer,'linxi_herbal_home':herb},'npcs':{'linxi_herbalist':[880,1350],'linxi_peddler':[1410,1880],'linxi_granny':[2110,1580],'linxi_farmer':[2640,1310],'linxi_apothecary_apprentice':[700,1390],'linxi_herb_gatherer':[2570,2290],'tang_xingzhou_recruit':[1370,2200],'shen_qinghe_recruit':[2890,1380]},'interactions':{'linxi_center_well':[1720,1535]}})
 s=Scene('linxi_south','林西村 · 南坊','村塾巷 · 药铺院 · 晒谷土坪 · 通江湖村口',[4200,2600],[3810,1500],flat)
 home=building(s,'VillagerHome','cottage',[700,900],270,'南坊民居');school=building(s,'SouthSchool','office',[1850,850],290,'南坊私塾');herb=building(s,'Apothecary','warehouse',[3100,900],285,'药铺内堂')
 homes=[[700,900],[1850,850],[3100,900]]
 for i,(k,p,h) in enumerate([('small_home',[850,2050],240),('cottage',[1610,2140],260),('small_home',[2610,2050],235),('cottage',[3380,2180],270),('repair_shed',[3100,1500],215)]):building(s,'Home'+str(i),k,p,h,'南坊生活院');homes.append(p)
 details(s,homes);fence(s,550,1200,2);fence(s,900,1200,2);fence(s,2800,1200,2);fence(s,3230,1200,3)
 s.prop('PracticeRack','staff_rack',[2060,1590],120,'乡勇木架');s.prop('Cart','cart',[1150,1730],110,'运粮木车')
 groves(s,[[350,600],[1000,350],[2000,350],[3000,350],[3800,700],[3890,2140],[2300,2380],[450,2280]])
 paths(s,[([[300,1500],[3800,1500]],135),([[700,1500],[700,1000]],85),([[1850,1500],[1850,950]],85),([[3100,1500],[3100,1000]],85),([[700,1500],[700,2250],[2300,2350],[3600,2350],[3600,1500]],85)])
 finish(s,{'portals':{},'portal_targets':{'linxi_south_villager_home':home,'linxi_south_scholar_house':school,'linxi_south_apothecary_home':herb,'linxi_village_center':[300,1500],'world_map_jianghu':[3890,1500]},'npcs':dict(zip(['linxi_south_herbalist','linxi_south_peddler','linxi_south_granny','linxi_south_farmer','linxi_south_apprentice','linxi_south_herb_gatherer','linxi_south_militia_coach','linxi_south_guard','linxi_south_porter','linxi_south_veteran','linxi_south_teacher'],[[2980,1110],[1230,1470],[970,1060],[2580,1750],[3310,1100],[900,2230],[2060,1720],[3540,1690],[1020,1760],[3730,1390],[1850,1070]])),'interactions':{}})
 t=base.terrain([0,60],[rect(600,350,2700,650)],[('BackLane','市街—后巷',0,1,[1500,1000]),('ForestLane','东街—北林路',0,1,[2800,1000])],.35,65,120)
 s=Scene('zhuwei','竹尾村 · 棚巷街市','客栈街 · 药摊 · 铁作院 · 后巷旧宅 · 北林口',[4200,3200],[2100,2860],t)
 inn=building(s,'Inn','inn',[950,1800],400,'竹尾客栈');hall=building(s,'Hall','office',[3020,1660],300,'村中武馆');building(s,'Smithy','smithy',[3230,2310],210,'铁作铺')
 homes=[]
 for i,(k,p,h) in enumerate([('cottage',[850,710],260),('small_home',[2120,720],245),('cottage',[3020,710],265),('small_home',[800,2510],230),('cottage',[3200,2810],255)]):building(s,'Home'+str(i),k,p,h,'后巷民居');homes.append(p)
 for i,p in enumerate([[1670,1750],[2200,1750],[1730,2490],[2510,2410]]):s.prop('Market'+str(i),'stall',p,195,'沿街摊棚')
 s.prop('RepairCart','cart',[2820,2390],115,'街口货车');s.prop('WorkCart','cart',[3060,2460],105,'工坊木车');details(s,homes)
 for i,p in enumerate([[1250,1900],[2850,1900],[2300,2620]]):s.prop('RestBench'+str(i),'bench',p,40,'沿街长凳')
 groves(s,[[350,700],[700,320],[1600,300],[2450,300],[3500,650],[3700,1250],[3820,2140],[3700,2870],[600,2900]])
 paths(s,[([[2100,2950],[2100,2700],[2100,2120],[2100,1930],[1500,1460],[1500,1000],[1500,840]],140),([[430,2360],[1300,2180],[2100,2120],[2800,2130],[3500,2130]],125),([[2800,2130],[2800,1200],[2800,1000],[2800,850],[3180,850],[3180,430]],90),([[1500,1270],[700,1270],[430,1000]],85),([[3500,2130],[3500,2940]],100)])
 finish(s,{'portals':{},'portal_targets':{'interior_inn_hall':inn,'ch2_s1_market_inn':inn,'ch2_s1_market_training_hall':hall,'ch1_s3_west_ruin':[430,1000],'ch1_s3_ruin_inner':[430,1000],'ch1_s3_zhuwei_forest':[3180,430],'ch2_s2_forest_edge':[3180,430],'ch1_s1_road':[430,2360],'world_map_jianghu':[2100,2950],'ch2_s6_river_camp':[3500,2940]},'npcs':{'vegetable_vendor':[1680,1880],'inn_waiter':[1110,1950],'merchant':[2350,2110],'crying_woman':[2680,1950],'crying_woman_waiting':[2680,1950],'guard':[2200,2820],'patrol_scout':[2830,2170],'patrol_scout_partner':[2990,2120],'zhuwei_gatekeeper_ch2':[2200,2820],'zhuwei_hawker_ch2':[2350,2110],'zhuwei_apothecary_ch2':[2350,1900],'zhuwei_ginseng_farmer_ch2':[1680,1880],'zhuwei_constable_ch2':[1890,2760],'zhuwei_tournament_host_ch2':[2820,1850],'zhuwei_boatman_ch2':[3370,2720],'feng_yanqiu_ch2':[3380,1910]},'interactions':{'village_dojo_spar':[3020,1790],'market_old_book_stall':[1720,2580]}})
 p=PROJECT/'scripts/drafts'/NAME;p.mkdir(parents=True,exist_ok=True)
 (p/'controller.gd').write_text('extends "res://scripts/drafts/sect_completion_20261030a/controller.gd"\n','utf-8')
 print('Six private layouts built')
if __name__=='__main__':build()
