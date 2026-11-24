"""Author two new, native-size adventure maps. No old files, images or engine IO.
All authored pixels below are feet/world coordinates in a 4096 x 3072 plane.
Run without args for an immutable static report; --publish also writes resources
only after all complete 35x25 feet/24px route samples pass. Existing outputs reject.
"""
from pathlib import Path
from PIL import Image
import hashlib,json,math,sys

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[2]
SIZE=(4096,3072)
BASE='res://data/maps/adventure_20261030k/'
SPAWN=(2048,2764.8)
EXIT=(2048,2856.96)
ASSETS={
 'forest_floor':('art/modules/miao_recompose_20261029g/woodland_floor.png',None,None),
 'mine_floor':('art/modules/huashan_map_20261029m/granite_ground.png',None,None),
 'road':('art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png',None,None),
 'tree':('art/modules/miao_town_20261029f/trees.png',(865,1260),(520,1125,650,135)),
 'bamboo':('art/modules/linxi_scale_polish_20261030h/green_bamboo.png',(896,1140),(300,1000,1160,140)),
 'crag':('art/modules/huashan_map_20261029m/granite_crag.png',(1107,976),(310,520,1600,456)),
 'shed':('art/modules/redrock_luoyang_standard_20261028b/repair_shed.png',(900,785),(340,410,1120,365)),
 'cart':('art/modules/prop/prop_linxi_cart_wood.png',(170,309),(20,165,285,135)),
 'sign':('art/modules/prop/prop_zhuwei_road_sign.png',(110,310),(90,280,40,32)),
 'rubble':('art/modules/prop/prop_ruin_rubble_pile.png',(194,101),(30,58,330,45)),
 'ore':('art/modules/redrock_luoyang_standard_20261028b/ore_cluster.png',(802,766),(310,600,1000,180)),
 'herb':('art/modules/veg/veg_grass_tuft_a.png',(99,91),None),
 'tablet':('art/modules/prop/linxi_stone_tablet_v2.png',(164,350),(20,265,292,90)),
}
sizes={k:Image.open(GAME/a[0]).size for k,a in ASSETS.items()}
def norm(p):return [p[0]/SIZE[0],p[1]/SIZE[1]]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def fact(p):return {'sha256':sha(p),'bytes':p.stat().st_size}
def json_bytes(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def write(p,b):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb') as f:f.write(b)
class Raw(str):pass
def gd(v):
 if isinstance(v,Raw):return str(v)
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,(float,int)):return str(v)
 if isinstance(v,dict):return '{'+', '.join(gd(k)+': '+gd(x) for k,x in v.items())+'}'
 if isinstance(v,(tuple,list)):return '['+', '.join(gd(x) for x in v)+']'
 raise TypeError(type(v))
def vec(p):return Raw('Vector2(%s, %s)'%(p[0],p[1]))
def poly(points):return Raw('PackedVector2Array('+', '.join(str(x) for p in points for x in p)+')')
def route(id,points,width=160):return {'id':id,'points':points,'width':width}
def prop(id,key,foot,scale):
 path,source,rect=ASSETS[key];w,h=sizes[key]
 center=[foot[0]+(w/2-source[0])*scale,foot[1]+(h/2-source[1])*scale]
 body=None if rect is None else [foot[0]+(rect[0]-source[0])*scale,foot[1]+(rect[1]-source[1])*scale,rect[2]*scale,rect[3]*scale]
 return {'id':id,'key':key,'texture':'res://'+path,'foot':list(foot),'source_foot_px':list(source),'source_body_rect_px':list(rect) if rect else None,'source_size_px':[w,h],'scale':scale,'center':center,'body':body}

def forest():
 d={'key':'forest','scene_id':'adventure_zhuwei_hunting_ground','label':'竹尾猎径','floor':'forest_floor','bgm':'res://art/audio/bgm/bgm_forest_mystery_v4.wav',
 'outline':[(360,2920),(200,2480),(260,1850),(180,1260),(400,680),(740,360),(1500,250),(2100,420),(3000,280),(3630,640),(3890,1300),(3740,1950),(3900,2500),(3600,2870),(2450,2960)],
 'return_scene':'ch1_s3_zhuwei_forest','connector':{'source_scene':'ch1_s3_zhuwei_forest','source_basis':[1536,1024],'source_foot':[380,720]},'props':[]}
 d['routes']=[route('safe_trunk',[EXIT,SPAWN,(2048,2400),(1920,1960),(2100,1500),(2000,1000)],190),route('herbalist_west_loop',[(2048,2400),(1320,2220),(850,1740),(1050,1280),(1500,1020),(2000,1000)],130),route('beast_east_loop',[(2000,1000),(2640,1100),(3160,1460),(3150,1780),(3300,2000),(2700,2400),(2048,2400)],125),route('hidden_rock_hollow',[(1050,1280),(720,1070),(680,800)],105),route('northern_beast_spur',[(2640,1100),(2820,980),(3000,760)],105)]
 d['points']=[{'id':'forest_old_marks','label':'岩凹旧痕','kind':'clue','foot':[680,800],'text':'石缝中只有旧日柴痕和风干的树皮，静看林间便可循原路返回。'}, {'id':'forest_wolf_trail','label':'兽踪小径 · 普通试炼','kind':'challenge','tier':'normal','foot':[3150,1780],'enemy_group':'wolf','text':'东侧兽径有新鲜足迹。是否自愿追踪？南侧主路可直接绕行。'}, {'id':'forest_wolf_ridge','label':'北林狼踪 · 精英试炼','kind':'challenge','tier':'elite','foot':[3000,760],'enemy_group':'wolf','text':'更深处传来成群低吼。此处危险，是否仍要迎战？'}]
 d['signposts']=[{'foot':[2210,2720],'text':'竹尾猎径｜南返密林'}, {'foot':[2210,2350],'text':'西：采药环径｜东：兽踪险径'}, {'foot':[2280,1260],'text':'西南归路｜东北深林谨行'}]
 d['zones']=[{'id':'forest_main_safe','label':'回程与中央主路','kind':'safe','polygon':[(1740,2920),(2360,2920),(2380,1400),(2300,900),(1780,780),(1660,1400)]},{'id':'forest_herb_loop','label':'西侧采药小径','kind':'safe','polygon':[(550,2100),(1250,2480),(1740,2020),(1580,950),(550,650)]},{'id':'forest_beast','label':'东林兽区','kind':'danger','enemy_group':'wolf','polygon':[(2540,650),(3500,560),(3600,2150),(2850,2500),(2500,2100)]}]
 perimeter=[(600,650),(1100,500),(1550,650),(2150,650),(2650,500),(3250,650),(3650,900),(400,1000),(430,1500),(400,2100),(650,2600),(3650,1350),(3700,1900),(3570,2450),(1000,2850),(1500,2920),(2700,2900),(3200,2820)]
 for i,p in enumerate(perimeter):d['props'].append(prop('forest_edge_grove_%02d'%i,'tree',p,[.36,.40,.43][i%3]))
 for i,p in enumerate([(1800,1350),(1420,1810),(2780,1900),(2350,850),(2400,1820)]):d['props'].append(prop('forest_inner_grove_%02d'%i,'tree',p,.38))
 for i,p in enumerate([(650,2200),(550,1800),(850,2550),(1450,2640),(2650,2700),(3410,2260),(3450,1200),(2880,1500),(1170,800),(1800,570)]):d['props'].append(prop('forest_bamboo_%02d'%i,'bamboo',p,.28 if i%2 else .32))
 for i,(p,s) in enumerate([((650,650),.32),((350,970),.25),((1100,760),.30),((3400,1040),.30)]):d['props'].append(prop('forest_hollow_crag_%02d'%i,'crag',p,s))
 for i,row in enumerate(d['signposts']):d['props'].append(prop('forest_sign_%02d'%i,'sign',row['foot'],.55))
 d['props'].append(prop('forest_hollow_stone','tablet',(650,610),.46))
 d['sites']=[{'id':'adventure_forest_herb_%02d'%(i+1),'type':'herb','scene_id':d['scene_id'],'foot':list(p),'texture':'res://'+ASSETS['herb'][0],'source_foot':list(ASSETS['herb'][1]),'scale':.55} for i,p in enumerate([(1120,2050),(740,1560),(1320,1160),(1850,860)])]
 return d

def mine():
 d={'key':'mine','scene_id':'adventure_xiangzhou_deep_mine','label':'襄州深矿','floor':'mine_floor','bgm':'res://art/audio/bgm/bgm_cave_ominous_v5.wav',
 'outline':[(360,2930),(220,2400),(420,1750),(260,1100),(670,420),(1380,260),(2020,420),(2820,230),(3640,540),(3860,1120),(3720,1920),(3890,2530),(3460,2900)],
 'return_scene':'openworld_xiangzhou_mine_valley','connector':{'source_scene':'openworld_xiangzhou_mine_valley','source_basis':[3072,2048],'source_foot':[1000,1500]},'props':[]}
 d['routes']=[route('safe_haul_road',[EXIT,SPAWN,(2100,2360),(1960,1860),(2200,1300),(2080,900)],190),route('quarry_west_loop',[(2100,2360),(1280,2330),(800,1910),(900,1440),(1480,1140),(2200,1300)],140),route('outlaw_camp_loop',[(2200,1300),(2960,1150),(3350,1600),(3150,2130),(2640,2430),(2100,2360)],135),route('old_cut_spur',[(2080,900),(1750,650),(1150,740)],110),route('northern_camp_spur',[(2080,900),(2680,700),(3150,780)],115)]
 d['points']=[{'id':'mine_old_cut','label':'废采坑石壁','kind':'clue','foot':[1150,740],'text':'石壁上留有手凿痕迹，木楔早已风化。这里只能观察，不会取得额外物品。'}, {'id':'mine_camp_watch','label':'匪营外哨 · 普通试炼','kind':'challenge','tier':'normal','foot':[3350,1600],'enemy_group':'mine','text':'旧采具棚边有人窥探。是否自愿迎战？中央运矿道仍可安全绕行。'}, {'id':'mine_north_sentries','label':'北矿匪哨 · 精英试炼','kind':'challenge','tier':'elite','foot':[3150,780],'enemy_group':'mine','text':'北矿道有数名匪徒结伴。此战危险，是否仍要接近？'}]
 d['signposts']=[{'foot':[2260,2710],'text':'襄州深矿｜南返矿谷'}, {'foot':[2260,2340],'text':'西：旧采坑｜东：匪营险地'}, {'foot':[2350,1320],'text':'中路南返｜北矿道谨行'}]
 d['zones']=[{'id':'mine_main_safe','label':'中央运矿主路','kind':'safe','polygon':[(1750,2900),(2440,2900),(2460,1300),(2320,800),(1890,700),(1700,1400)]},{'id':'mine_quarry','label':'西侧石质采坑','kind':'danger','enemy_group':'mine','polygon':[(580,1260),(1560,900),(1750,1450),(1650,2200),(780,2400),(500,1900)]},{'id':'mine_outlaw_camp','label':'东侧匪营与北支口','kind':'danger','enemy_group':'mine','polygon':[(2750,530),(3530,650),(3670,1750),(3310,2280),(2710,2020)]}]
 for i,(p,s) in enumerate([((750,700),.42),((1450,500),.38),((2450,450),.46),((3300,650),.42),((3800,1050),.50),((3900,1700),.45),((3700,2600),.48),((300,1400),.40),((400,2300),.42),((800,3000),.42),((3200,3000),.46),((1350,1770),.34),((2700,1850),.33)]):d['props'].append(prop('mine_cliff_%02d'%i,'crag',p,s))
 for i,(p,s) in enumerate([((1450,2050),.43),((3480,1250),.48),((3000,630),.43)]):d['props'].append(prop('mine_low_toolshed_%02d'%i,'shed',p,s))
 for i,p in enumerate([(1580,2250),(2860,2240),(1300,950)]):d['props'].append(prop('mine_wood_handcart_%02d'%i,'cart',p,.62))
 for i,p in enumerate([(680,1770),(700,1250),(1760,1440),(2870,950),(3400,1960)]):d['props'].append(prop('mine_rubble_%02d'%i,'rubble',p,.70))
 for i,p in enumerate([(1190,1810),(1550,1510),(2490,580)]):d['props'].append(prop('mine_exposed_ore_%02d'%i,'ore',p,.16))
 for i,row in enumerate(d['signposts']):d['props'].append(prop('mine_sign_%02d'%i,'sign',row['foot'],.55))
 d['sites']=[{'id':'adventure_mine_ore_%02d'%(i+1),'type':'ore','scene_id':d['scene_id'],'foot':list(p),'texture':'res://'+ASSETS['ore'][0],'source_foot':list(ASSETS['ore'][1]),'scale':.12} for i,p in enumerate([(1040,1680),(1370,1230),(1600,740),(2750,760)])]
 return d

def inside(p,polygon):
 x,y=p;odd=False
 for a,b in zip(polygon,polygon[1:]+polygon[:1]):
  if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:odd=not odd
 return odd
def safe(p,d):
 feet=[(p[0]+x,p[1]+y) for x in [-17.5,0,17.5] for y in [-12.5,0,12.5]]
 if not all(inside(q,d['outline']) for q in feet):return 'OUTSIDE_NAV'
 for obj in d['props']:
  if obj['body'] is None:continue
  x,y,w,h=obj['body']
  if p[0]+17.5>=x and p[0]-17.5<=x+w and p[1]+12.5>=y and p[1]-12.5<=y+h:return obj['id']
 return ''
def sample_route(points):
 for a,b in zip(points,points[1:]):
  n=max(1,math.ceil(math.dist(a,b)/24))
  for i in range(n+1):yield (a[0]+(b[0]-a[0])*i/n,a[1]+(b[1]-a[1])*i/n)
maps=[forest(),mine()]
checks=[];errors=[]
for d in maps:
 for r in d['routes']:
  failures=[{'foot':list(p),'blocked_by':safe(p,d)} for p in sample_route(r['points']) if safe(p,d)]
  checks.append({'map':d['scene_id'],'check':'FULL35x25_ROUTE_24PX:'+r['id'],'samples':len(list(sample_route(r['points']))),'passed':not failures})
  if failures:errors.append({'map':d['key'],'route':r['id'],'failures':failures})
 for label,p in [('spawn',SPAWN),('return',EXIT)]+[(q['id'],q['foot']) for q in d['points']+d['sites']]:
  blocked=safe(p,d);checks.append({'map':d['scene_id'],'check':'FULL35x25_FOOT:'+label,'passed':not blocked,'blocked_by':blocked})
  if blocked:errors.append({'map':d['key'],'point':label,'foot':p,'blocked_by':blocked})
assert all(sizes[d['floor']]==(1254,1254) for d in maps)
report={'status':'STATIC_ONLY_NOT_ENGINE_PHYSICS_OR_ART','checks':checks,'errors':errors,'passed':not errors,'engine_runs':0,'PNG_writes':0,'old_source_writes':0}
attempt=1
while (HERE/('static_attempt_%02d.json'%attempt)).exists():attempt+=1
write(HERE/('static_attempt_%02d.json'%attempt),json_bytes(report))
print(json.dumps({'passed':not errors,'errors':errors,'static_checks':len(checks)},ensure_ascii=False))
if errors or '--publish' not in sys.argv:sys.exit(1 if errors else 0)

outputs={}
config={'schema_version':1,'coordinate_basis':'world_pixels','maps':[],'connectors':[]}
sites={'schema_version':1,'coordinate_basis':{},'sites':[]}
for d in maps:
 key=d['key'];floor='res://'+ASSETS[d['floor']][0]
 chunks=[]
 for y in range(3):
  for x in range(4):
   w=min(1254,4096-x*1254);h=min(1254,3072-y*1254)
   name='%s_tile_%d_%d.tres'%(key,x,y)
   outputs[HERE/name]=('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n[ext_resource type="Texture2D" path="%s" id="1"]\n[resource]\natlas = ExtResource("1")\nregion = Rect2(0, 0, %d, %d)\nfilter_clip = true\n'%(floor,w,h)).encode()
   chunks.append({'path':BASE+name,'logical_rect':Raw('Rect2(%d, %d, %d, %d)'%(x*1254,y*1254,w,h)),'draw_position':vec((x*1254,y*1254)),'draw_scale':1.0})
 stream='[gd_resource type="Resource" script_class="StreamedBackgroundSet" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/domain/streamed_background_set.gd" id="1"]\n[resource]\nscript = ExtResource("1")\nlogical_size = Vector2i(4096, 3072)\nmobile_preview_path = '+gd(floor)+'\ndesktop_preview_path = '+gd(floor)+'\nmobile_chunks = '+gd(chunks)+'\ndesktop_chunks = '+gd(chunks)+'\n'
 outputs[HERE/(key+'_background.tres')]=stream.encode()
 objects=[];blockers=[]
 for obj in d['props']:
  objects.append({'id':obj['id'],'texture':obj['texture'],'pos':vec(norm(obj['center'])),'scale':vec((obj['scale'],obj['scale'])),'centered':True,'sort_by_feet':True,'depth_sort_foot_y':obj['foot'][1]/3072})
  if obj['body']:
   x,y,w,h=obj['body'];blockers.append({'id':obj['id']+'_base','pos':vec(norm((x+w/2,y+h/2))),'size':vec(norm((w,h))),'walkability_margin':0.0})
 routes=[{'id':r['id'],'points':poly([norm(p) for p in r['points']]),'width_px':r['width'],'texture':'res://'+ASSETS['road'][0],'z_index':-10} for r in d['routes']]
 c=d['connector'];target=[c['source_foot'][0]/c['source_basis'][0],c['source_foot'][1]/c['source_basis'][1]]
 portal={'id':key+'_return','label':'返回'+('竹尾密林' if key=='forest' else '襄州矿谷'),'pos':vec(norm(EXIT)),'size':vec(norm((140,86))),'source_spawn_pos':vec(norm(SPAWN)),'target_scene':d['return_scene'],'target_pos':vec(target),'show_destination_label':True}
 probes=[{'id':'spawn','pos':vec(norm(SPAWN))},{'id':'return','pos':vec(norm(EXIT))}]+[{'id':p['id'],'pos':vec(norm(p['foot']))} for p in d['points']+d['sites']]
 blocked=[{'id':p['id'],'pos':vec(norm((p['body'][0]+p['body'][2]/2,p['body'][1]+p['body'][3]/2)))} for p in d['props'] if p['body']]
 layout='[gd_resource type="Resource" script_class="WalkableMapLayout" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="1"]\n[resource]\nscript = ExtResource("1")\nschema_version = 2\ndesign_size = Vector2i(4096, 3072)\nwalkable_mask_path = '+gd(BASE+key+'_walk.svg')+'\nwalkable_regions = '+gd([poly([norm(p) for p in d['outline']])])+'\ntravel_routes = '+gd(routes)+'\nvisual_objects = '+gd(objects)+'\nblockers = '+gd(blockers)+'\ninteractions = []\nportals = '+gd([portal])+'\nwalkable_probes = '+gd(probes)+'\nblocked_probes = '+gd(blocked)+'\n'
 outputs[HERE/(key+'_layout.tres')]=layout.encode()
 svg='<svg xmlns="http://www.w3.org/2000/svg" width="4096" height="3072" viewBox="0 0 4096 3072"><rect width="4096" height="3072" fill="black"/><polygon fill="white" points="'+' '.join('%s,%s'%p for p in d['outline'])+'"/>'
 for p in d['props']:
  if p['body']:svg+='<rect x="%s" y="%s" width="%s" height="%s" fill="black"/>'%tuple(p['body'])
 outputs[HERE/(key+'_walk.svg')]=(svg+'</svg>\n').encode()
 scene='[gd_resource type="Resource" script_class="SceneScript" load_steps=4 format=3]\n[ext_resource type="Script" path="res://scripts/domain/scene_script.gd" id="1"]\n[ext_resource type="Resource" path="'+BASE+key+'_layout.tres" id="2"]\n[ext_resource type="Resource" path="'+BASE+key+'_background.tres" id="3"]\n[resource]\nscript = ExtResource("1")\nscene_id = &'+gd(d['scene_id'])+'\ndisplay_name = '+gd(d['label'])+'\nbackground_path = '+gd(floor)+'\nstreamed_background = ExtResource("3")\nbgm_path = '+gd(d['bgm'])+'\nis_walkable = true\nactor_positions_are_feet = true\nis_settlement = false\nmap_layout = ExtResource("2")\nplayer_spawn = Vector2(0.5, 0.90)\ncamera_zoom = 1.0\nencounter_groups = []\nencounter_step_distance = 0.0\nencounter_chance = 0.0\nnpcs = []\nhotspots = []\nexits = []\ntrigger_zones = []\n'
 outputs[GAME/'data/scenes'/(d['scene_id']+'.tres')]=scene.encode()
 config['maps'].append({'scene_id':d['scene_id'],'label':d['label'],'size':list(SIZE),'spawn':list(SPAWN),'return':{'target_scene':d['return_scene'],'target_pos':target,'pos':list(EXIT),'source_spawn_pos':list(SPAWN)},'zones':d['zones'],'points':d['points'],'signposts':d['signposts'],'runtime_random_encounters':False})
 config['connectors'].append({**c,'target_scene':d['scene_id'],'target_spawn':[.5,.9],'label':'进入'+d['label']})
 sites['coordinate_basis'][d['scene_id']]=list(SIZE);sites['sites']+=d['sites']
outputs[HERE/'adventure_config.json']=json_bytes(config)
outputs[HERE/'gathering_additions.json']=json_bytes(sites)
outputs[HERE/'author_facts.json']=json_bytes({'status':'STATIC_ONLY_ROOT_RUNTIME_AND_ART_PENDING','size':list(SIZE),'maps':maps,'assets':{k:{'path':'res://'+a[0],'size':list(sizes[k]),**fact(GAME/a[0])} for k,a in ASSETS.items()},'native_floor_period_px':1254,'body_foot_px':[35,25],'route_sample_step_px':24,'no_rail_or_minecart_asset_claim':True,'engine_runs':0,'PNG_writes':0})
if '--refresh-unfrozen' in sys.argv:
 # Only this author's previously generated NEW namespace can be refined before
 # handoff. Preserve the prior candidate bytes; no production donor is writable.
 old_manifest=json.loads((HERE/'map_manifest_READY.json').read_bytes())
 previous=HERE/'unfrozen_candidate_01'
 assert not previous.exists()
 for p,b in outputs.items():
  assert p.is_relative_to(HERE) or p in [GAME/'data/scenes'/(d['scene_id']+'.tres') for d in maps]
  old_fact=old_manifest['new_modules'][p.relative_to(GAME.parent).as_posix()]
  assert fact(p)==old_fact
  if p.read_bytes()!=b:
   write(previous/p.relative_to(GAME),p.read_bytes())
   p.write_bytes(b) # deterministic mechanical resource regeneration only
 write(previous/'map_manifest_READY.json',(HERE/'map_manifest_READY.json').read_bytes())
else:
 assert all(not p.exists() for p in outputs),'Immutable output already exists'
 for p,b in outputs.items():write(p,b)
manifest={'status':'NEW_MAPS_ONLY_CANDIDATE_ROOT_ENGINE_PENDING','new_modules':{p.relative_to(GAME.parent).as_posix():{'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)} for p,b in outputs.items()},'runtime_inputs':{('game/'+a[0]):fact(GAME/a[0]) for a in ASSETS.values()},'scene_ids':[d['scene_id'] for d in maps],'nav_svg_root_isolated_import':['game/data/maps/adventure_20261030k/forest_walk.svg','game/data/maps/adventure_20261030k/mine_walk.svg'],'static_report':'game/data/maps/adventure_20261030k/static_attempt_%02d.json'%attempt,'old_source_writes':0,'engine_runs':0,'no_existing_gathering_table_write':True}
if '--refresh-unfrozen' in sys.argv:(HERE/'map_manifest_READY.json').write_bytes(json_bytes(manifest))
else:write(HERE/'map_manifest_READY.json',json_bytes(manifest))
print(json.dumps({'published_new_files':len(outputs),'manifest_sha256':sha(HERE/'map_manifest_READY.json'),'config_sha256':sha(HERE/'adventure_config.json'),'body_rows':[len(d['props']) for d in maps]}))
