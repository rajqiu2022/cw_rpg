"""Build only an isolated Bianzhou candidate. Never write to game/ or its cache."""
from __future__ import annotations
import argparse, hashlib, heapq, json, math, re, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/staging/bianzhou_city_20261022a'
SIZE=(3072,2048)
SOURCES=['game/data/scenes/openworld_bianzhou_city.tres','game/data/maps/openworld_bianzhou_city_layout_v2.tres','game/data/scenes/openworld_bianzhou_old_post.tres']

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n','utf-8')
def copy_asset(source,key):
    p=ROOT/source;dst=BASE/'media'/(key+p.suffix)
    if dst.exists():assert sha(dst)==sha(p),dst
    else:shutil.copyfile(p,dst)
    return {'source':source,'path':'media/'+dst.name,'sha256':sha(p),'size':list(Image.open(p).size)}

def prepare():
    if (BASE/'author.json').exists():raise RuntimeError('Existing author is immutable; inspect it rather than overwrite')
    (BASE/'media').mkdir(parents=True,exist_ok=True)
    (BASE/'artifacts').mkdir(exist_ok=True)
    facts={p:{'sha256':sha(ROOT/p),'bytes':(ROOT/p).stat().st_size,'mtime_ns':str((ROOT/p).stat().st_mtime_ns)} for p in SOURCES}
    for p in SOURCES:
        dst=BASE/'originals'/Path(p).name;dst.parent.mkdir(exist_ok=True);shutil.copyfile(ROOT/p,dst)
    assets={}
    def asset(key,path):assets[key]=copy_asset(path,key);return key
    asset('stone','game/art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png')
    asset('earth','game/art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg')
    asset('road','game/art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png')
    asset('posthouse','assets/raw/other_city_modules_20261022/bianzhou/maps/other_city_20261022_bianzhou_posthouse_front_v1.png')
    prefix='assets/raw/world_expansion_100_20261022/maps/bianzhou/world100_20261022_bianzhou_'
    for k,n in [('store','merchant_store_front'),('wall','posthouse_sidewall'),('corner','courtyard_corner'),('gateway','market_gateway')]:asset(k,prefix+n+'_v1.png')
    asset('inn','game/art/modules/building/build_linxi_inn_storefront.png')
    asset('smithy','game/art/modules/building/build_linxi_smithy_front.png')
    asset('cottage','game/art/modules/prop/prop_zhuwei_cottage_25d_v2.png')
    asset('tea','assets/raw/world_placeables_walk_20261022/small_buildings/placewalk_20261022_tea_shed_v1.png')
    asset('stall','game/art/modules/luoyang_district_life_20261016f/stock_goods.png')
    asset('tree','game/art/modules/luoyang_district_life_20261016f/stock_tree.png')
    asset('lamp','game/art/modules/luoyang_district_life_20261016f/stock_lamp.png')
    asset('board','game/art/maps/luoyang_modular_v3/source/notice_pavilion_v2.png')
    asset('cart','game/art/modules/prop/prop_linxi_cart_wood.png')
    asset('box','game/art/modules/prop/prop_linxi_box_wood_a.png')
    asset('jar','game/art/modules/prop/prop_linxi_wine_jar_stack.png')
    asset('bench','game/art/modules/luoyang_assembled_interiors_20261016g/long_bench_v1.png')
    asset('merchant','game/art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png')
    asset('postmaster','game/art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png')
    asset('player','game/art/characters/hero_idle_down_25d_runtime_4f.png')
    objects=[];solids=[]
    def obj(ident,key,foot,width,body=None,label='',category='prop'):
        a=assets[key];im=Image.open(BASE/a['path']).convert('RGBA');bbox=im.getchannel('A').getbbox()
        ratio=width/im.width;anchor=[(bbox[0]+bbox[2])/2,bbox[3]]
        origin=[foot[0]-anchor[0]*ratio,foot[1]-anchor[1]*ratio]
        r={'id':ident,'asset':key,'foot_px':list(foot),'origin_px':origin,'scale':ratio,'render_size_px':[im.width*ratio,im.height*ratio],'full_alpha_bbox':list(bbox),'full_alpha_world_bbox':[origin[0]+bbox[0]*ratio,origin[1]+bbox[1]*ratio,origin[0]+bbox[2]*ratio,origin[1]+bbox[3]*ratio],'label':label,'category':category,'solid_ids':[]}
        bodies=[] if body is None else (body if isinstance(body[0],list) else [body])
        for n,b in enumerate(bodies):
            sid=ident+'_body_'+str(n);solids.append({'id':sid,'owner':ident,'rect':[foot[0]+b[0],foot[1]+b[1],b[2],b[3]]});r['solid_ids'].append(sid)
        objects.append(r)
    obj('west_store','store',(560,650),780,[-285,-210,570,200],'行商货栈','building')
    obj('west_inn','inn',(560,1225),780,[-310,-175,620,165],'沿街客舍（装饰）','building')
    obj('west_workshop','smithy',(560,1790),730,[-285,-150,570,140],'修具铺（装饰）','building')
    obj('east_posthouse','posthouse',(2400,650),760,[-270,-210,540,200],'汴州驿馆','building')
    obj('east_residence','cottage',(2450,1240),700,[-215,-240,430,225],'驿馆后街民居','building')
    obj('east_tea_shed','tea',(2400,1800),650,[-235,-140,470,125],'路边茶棚（装饰）','building')
    obj('south_market_gate','gateway',(1551,1965),800,[[-265,-170,65,155],[200,-170,65,155]],'南市坊门','gateway')
    obj('northwest_wall','wall',(580,170),670,[-280,-55,560,50],category='wall')
    obj('northeast_corner','corner',(2600,170),520,[-190,-75,380,65],category='wall')
    obj('goods_stall_a','stall',(1140,920),310,[-115,-62,230,60],'行商摊位','stall')
    obj('goods_stall_b','stall',(1130,1460),300,[-110,-62,220,60],'街市摊位','stall')
    obj('notice_board','board',(1850,1080),320,[-105,-36,210,34],'汴州府缉捕榜','board')
    for i,(key,foot,width,body) in enumerate([
        ('cart',(875,710),160,[-58,-40,116,38]),('box',(930,700),65,[-24,-20,48,18]),
        ('box',(2750,700),70,[-26,-22,52,20]),('jar',(2710,1350),80,[-28,-22,56,20]),
        ('bench',(2630,1890),160,[-65,-18,130,16]),('jar',(850,1820),80,[-28,-22,56,20]),
        ('box',(990,1570),70,[-26,-22,52,20]),('box',(1065,1570),60,[-23,-18,46,16])]):obj('life_prop_'+str(i),key,foot,width,body)
    for i,foot in enumerate([(1250,540),(1820,560),(1270,1190),(1820,1510),(1250,1770),(1830,1850)]):obj('street_lamp_'+str(i),'lamp',foot,78,[-11,-14,22,13])
    for i,foot in enumerate([(145,690),(2940,690),(130,1290),(2940,1320),(150,1900),(2920,1920),(1040,260),(2000,280)]):obj('street_tree_'+str(i),'tree',foot,145,[-12,-16,24,14])
    # These outer solids match the positive navigation rectangle, including two authored exits.
    solids += [{'id':'boundary_'+str(i),'owner':'boundary','rect':r} for i,r in enumerate([[0,0,3072,36],[0,2012,3072,36],[0,0,36,2048],[3036,0,36,2048]])]
    terrain=[{'asset':'earth','rect':[0,0,3072,2048],'tile_scale':.25},
        {'asset':'stone','rect':[1320,36,460,1976],'tile_scale':.25},
        {'asset':'stone','rect':[245,700,2560,230],'tile_scale':.25},
        {'asset':'stone','rect':[230,1280,2600,230],'tile_scale':.25},
        {'asset':'road','rect':[350,930,855,350],'tile_scale':.35},
        {'asset':'stone','rect':[1940,650,905,400],'tile_scale':.25},
        {'asset':'road','rect':[2040,1510,730,400],'tile_scale':.35}]
    npcs=[{'npc_id':'bianzhou_postmaster','npc_name':'汴州驿丞','asset':'postmaster','foot_px':[2120,790],'dialog_id':'openworld_bianzhou_guide','scale':.96},
        {'npc_id':'bianzhou_merchant','npc_name':'中原行商','asset':'merchant','foot_px':[1120,1050],'interaction_action':'shop:wulin_trade_hall','scale':.90}]
    portals=[{'id':'return_world','foot_px':[1551.36,1955.84],'action':'world_map','label':'离开汴州 · 江湖大地图'},
        {'id':'old_post','foot_px':[1551.36,133.12],'target_scene':'openworld_bianzhou_old_post','target_pos':[.5,.88],'label':'出城历练 · 中原旧驿（2～6级）'}]
    interactions=[{'id':'bianzhou_bounty_board','label':'查看汴州府缉捕榜','foot_px':[1850,1150],'action':'bounty_board:bianzhou'}]
    author={'status':'ISOLATED_CANDIDATE_NOT_GAME_ENABLED','scene_id':'openworld_bianzhou_city','display_name':'汴州城 · 中轴坊市','size':list(SIZE),'player_spawn':[1551.36,1843.2],'bgm_path':'res://art/audio/bgm/bgm_city_ceremony_v4.wav','assets':assets,'objects':objects,'solids':solids,'terrain':terrain,'npcs':npcs,'portals':portals,'interactions':interactions,'protected_sources':facts,'formal_enabled':False,'limits':['素材原有完整alpha留白失败继承，未清理或晋升','身体/门洞/遮挡/原生Field、真实动作与音频交互仍待正式验收','预览交互仅显示保留action，不运行商店/对白/任务或切换大地图','匿名装饰建筑不新增室内入口或剧情NPC']}
    dump(BASE/'author.json',author)
    print(json.dumps({'objects':len(objects),'solids':len(solids),'assets':len(assets),'root':str(BASE)}))

def make_navigation(author):
    mask=Image.new('L',SIZE,255);draw=ImageDraw.Draw(mask)
    for s in author['solids']:
        x,y,w,h=s['rect'];draw.rectangle([math.floor(x),math.floor(y),math.ceil(x+w),math.ceil(y+h)],fill=0)
    mask.save(BASE/'walk.png')
    a=(np.array(mask)==0).astype(np.uint32)
    integral=np.pad(a,((1,0),(1,0))).cumsum(0,dtype=np.uint32).cumsum(1,dtype=np.uint32)
    # Exact full 35*25 pixel footprint: x=-17..17, y=-12..12. No threshold or sparse probes.
    counts=integral[25:,35:]-integral[:-25,35:]-integral[25:,:-35]+integral[:-25,:-35]
    safe=np.zeros((2048,3072),dtype=bool);safe[12:2036,17:3055]=(counts==0)
    Image.fromarray(np.uint8(safe)*255).save(BASE/'body_safe.png')
    def route(start,end):
        sx,sy=[round(x/16) for x in start];tx,ty=[round(x/16) for x in end]
        startcell=(sx,sy);goal=(tx,ty);q=[(0,0,startcell)];cost={startcell:0};parent={}
        while q:
            _,g,c=heapq.heappop(q)
            if c==goal:break
            if g!=cost[c]:continue
            for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
                n=(c[0]+dx,c[1]+dy);x,y=n[0]*16,n[1]*16
                if not (0<=x<3072 and 0<=y<2048 and safe[y,x]):continue
                if g+1<cost.get(n,1e9):cost[n]=g+1;parent[n]=c;heapq.heappush(q,(g+1+abs(n[0]-tx)+abs(n[1]-ty),g+1,n))
        assert goal in cost,('No route',start,end)
        cells=[goal]
        while cells[-1]!=startcell:cells.append(parent[cells[-1]])
        points=[list(start)]+[[c[0]*16,c[1]*16] for c in cells[::-1]]+[list(end)]
        samples=0
        for p1,p2 in zip(points,points[1:]):
            length=math.dist(p1,p2)
            for i in range(max(1,math.ceil(length/4))+1):
                t=i/max(1,math.ceil(length/4));x=round(p1[0]+(p2[0]-p1[0])*t);y=round(p1[1]+(p2[1]-p1[1])*t)
                assert safe[y,x],('Unsafe route',x,y);samples+=1
        return {'points':points,'body_samples':samples,'length_px':sum(math.dist(a,b) for a,b in zip(points,points[1:]))}
    spawn=author['player_spawn'];routes=[]
    targets=[('north_exit',author['portals'][1]['foot_px']),('world_exit',author['portals'][0]['foot_px']),('merchant',author['npcs'][1]['foot_px']),('postmaster',author['npcs'][0]['foot_px']),('bounty_board',author['interactions'][0]['foot_px']),('west_south',(1100,1650)),('east_tea',(2070,1870))]
    for name,end in targets:routes.append(dict(id=name,**route(spawn,end)))
    routes.append(dict(id='market_to_posthouse',**route(author['npcs'][1]['foot_px'],author['npcs'][0]['foot_px'])))
    dump(BASE/'routes.json',routes)
    report={'status':'EXACT_RASTER_BODY_CLEARANCE_PASS_NOT_FIELD','routes':len(routes),'samples':sum(r['body_samples'] for r in routes),'body_pixel_footprint':[35,25],'nominal_body_size':[34,24],'mask_sha256':sha(BASE/'walk.png'),'safe_mask_sha256':sha(BASE/'body_safe.png'),'formal_enabled':False}
    dump(BASE/'artifacts/navigation-check.json',report);print(json.dumps(report))

def verify(author):
    for p,f in author['protected_sources'].items():
        x=ROOT/p;assert sha(x)==f['sha256'] and x.stat().st_size==f['bytes'] and str(x.stat().st_mtime_ns)==f['mtime_ns'],p
    for a in author['assets'].values():assert sha(ROOT/a['source'])==sha(BASE/a['path'])==a['sha256']
    old=(BASE/'originals/openworld_bianzhou_city.tres').read_text('utf-8')
    for s in ['bianzhou_postmaster','汴州驿丞','openworld_bianzhou_guide','bianzhou_merchant','中原行商','shop:wulin_trade_hall',author['bgm_path']]:assert s in old
    layout=(BASE/'originals/openworld_bianzhou_city_layout_v2.tres').read_text('utf-8')
    for s in ['bounty_board:bianzhou','world_map','openworld_bianzhou_old_post','Vector2(0.50,0.88)']:assert s in layout
    # Opaque building envelope overlaps are reported, never erased by local alpha edits.
    big=[o for o in author['objects'] if o['category']=='building'];overlaps=[]
    for i,a in enumerate(big):
        for b in big[i+1:]:
            x1,y1,x2,y2=a['full_alpha_world_bbox'];u1,v1,u2,v2=b['full_alpha_world_bbox']
            if min(x2,u2)>max(x1,u1) and min(y2,v2)>max(y1,v1):overlaps.append([a['id'],b['id']])
    report={'status':'SOURCE_AND_FUNCTION_CONTRACT_PASS','source_png_copies':len(author['assets']),'protected_bianzhou_files_exact':len(SOURCES),'npc_identity_actions_preserved':2,'portal_actions_preserved':2,'bounty_action_preserved':True,'bgm_preserved':True,'major_building_alpha_bbox_overlaps':overlaps,'game_files_written':0,'production_engine_used':False}
    dump(BASE/'artifacts/source-check.json',report);print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','navigation','verify']);a=p.parse_args()
    if a.action=='prepare':prepare()
    else:
        author=json.loads((BASE/'author.json').read_text('utf-8'))
        make_navigation(author) if a.action=='navigation' else verify(author)
