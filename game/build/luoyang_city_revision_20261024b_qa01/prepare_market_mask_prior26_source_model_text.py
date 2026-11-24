"""Independent f32 coordinates + closed-domain model; never PNG/PIP/packet decode."""
from pathlib import Path
import copy,hashlib,json,math,struct
GAME=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/'market_mask_prior26_NOTREADY'
SRC=GAME/'build/luoyang_city_space_20261024b_source01'
guards={}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def pin(p,h=None):
    value=sha(p)
    if h: assert value==h,(p,value,h)
    guards[p.as_posix()]=value
    return value
def load(p,h=None): pin(p,h);return json.loads(p.read_bytes())
def emit(p,d):
    assert not p.exists(),str(p)
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(d,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
    return sha(p)
def f(x): return struct.unpack('<f',struct.pack('<f',float(x)))[0]
def v(raw):
    if isinstance(raw,dict): raw=raw['xy']
    assert len(raw)==2 and all(math.isfinite(x) for x in raw)
    return [f(x) for x in raw]
def add(a,b): return [f(x+y) for x,y in zip(a,b)]
def sub(a,b): return [f(x-y) for x,y in zip(a,b)]
def mul(a,s): return [f(x*f(s)) for x in a]
def world(poly,anchor,foot,scale): return [add(v(foot),mul(sub(v(p),v(anchor)),scale)) for p in poly]
ap=SRC/'author_space_delta_rect_domains_successor01_NOTREADY.json'
ip=SRC/'publication_input_rect_domains_successor01_NOTREADY.json'
pp=SRC/'current_market_native_projection_ROOT_ACTUAL.json'
a=load(ap,'462e0578dbc701e0d10be721773b6986c61c5c46561e4f0842d440b1e7d15a70')
inp=load(ip,'3cbcd2fa00a7a06fc7d9c007048778f18b4efa4dc209cecb1cebf777704e3f8d')
parent=load(pp,'fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a')
assert inp['author_path']=='res://'+ap.relative_to(GAME).as_posix()
old=[]
for row in parent['record']['objects']:
    old.append({'id':row['id'],'foot':v(row['world_foot_px']),'center':v(row.get('physical_center_px',row['world_foot_px'])),'size':v(row.get('collision_size_px',[0,0])),'polygons':[[v(p) for p in poly] for poly in row.get('solid_polygons_px',[])]})
assert len(old)==23 and len({x['id'] for x in old})==23
replacements={}
for place in a['complete_buildings']:
    asset=a['assets'][place['asset_id']]
    replacements[place['id']]={'id':place['id'],'foot':v(place['foot_px']),'center':v(place['foot_px']),'size':v([0,0]),'polygons':[world(poly,asset['source_ground_anchor_px'],place['foot_px'],place['uniform_scale']) for poly in asset['ground_solid_polygons_px']]}
moves={x['id']:x for x in a['native_object_moves']}
child=[]
for row in old:
    if row['id'] in a['retire_closed_stall_ids']: continue
    if row['id'] in replacements: child.append(replacements[row['id']]);continue
    fresh=copy.deepcopy(row)
    if row['id'] in moves:
        move=moves[row['id']];assert row['foot']==v(move['old_foot_px'])
        delta=sub(v(move['new_foot_px']),v(move['old_foot_px']))
        fresh['foot']=v(move['new_foot_px']);fresh['center']=add(row['center'],delta)
        fresh['polygons']=[[add(p,delta) for p in poly] for poly in row['polygons']]
    child.append(fresh)
for place in a['low_wall_components']:
    asset=a['low_wall_asset']
    child.append({'id':place['id'],'foot':v(place['foot_px']),'center':v(place['foot_px']),'size':v([0,0]),'polygons':[world(poly,asset['source_ground_anchor_px'],place['foot_px'],place['uniform_scale']) for poly in asset['ground_solid_polygons_px']]})
assert len(child)==25 and len({x['id'] for x in child})==25
def domain(row):
    points=[p for poly in row['polygons'] for p in poly]
    if row['size'][0]>0:
        low=sub(row['center'],mul(row['size'],.5));points += [low,add(low,row['size'])]
    if not points: return None
    low=[min(p[i] for p in points) for i in range(2)];high=[max(p[i] for p in points) for i in range(2)]
    end=add(low,sub(high,low)) # bounds returns Rect2(low, high-low), end is native add.
    return [math.floor(low[0])-1,math.floor(low[1])-1,math.ceil(end[0])+1,math.ceil(end[1])+1]
oldmap={x['id']:x for x in old};newmap={x['id']:x for x in child}
changed_ids=list(dict.fromkeys([x['id'] for key in ['complete_buildings','native_object_moves','low_wall_components'] for x in a[key]]+a['retire_closed_stall_ids']))
derived=[domain(table[id]) for id in changed_ids for table in [oldmap,newmap] if id in table and domain(table[id]) is not None]
assert len(derived)==26 and sorted(derived)==sorted(a['changed_mask_domains_closed'])
seen=set()
for x0,y0,x1,y1 in derived: seen.update(y*3072+x for y in range(y0,y1+1) for x in range(x0,x1+1))
assert len(seen)==inp['pixel_visit_budget']==147805
def project(row): return {key:row[key] for key in ['id','center','size','polygons']}
model={'status':'INDEPENDENT_STRUCT_F32_SOURCE_MODEL_NOT_PIP_OR_RGBA_PRIOR','old':[project(r) for r in old],'child':[project(r) for r in child],'derived_closed_domains':derived,'union_pixels':147805,'source_expression':'point/anchor/foot individually Vector2-real_t float32; subtract->float32, scalar cast float32 multiply->float32, add->float32. All coordinates fixed only from RootFB0B current23 and new462E source author; no native or publisher observation.','native_PIP_boundary_not_emulated':'Root oracle will use Geometry2D and must first match this coordinate model; no Python raycast/epsilon/native packet/PNG reads here.'}
modelsha=emit(OUT/'independent_f32_source_model_NOT_PIP.json',model)
pin(OUT/'independent_f32_source_model_NOT_PIP.json',modelsha)

# Confirm UTF8 name recovery independently, but names are not consumed by raster.
district=load(GAME/'data/maps/luoyang_district_life_20261016f/author.json','d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c')
names={r['id']:r['name'] for r in district['districts']['ch4_s3_luoyang_market']['crowd']}
for key in ['runtime_district','district_current_frozen']:
    assert len(a[key]['crowd'])==10
    assert all(row['name']==names[row['id']] for row in a[key]['crowd'])
for path,h in [
 (SRC/'market_replan_geometry_CANDIDATE.gd','55cf002d1e116a8a21c4c65f36bd6b334cbdf0e383383f9c84fe9c46ef74d9e3'),
 (GAME/'build/luoyang_city_full_rollout_20261022ap_system01/market_wall_retirement_epoch01/pure_wall_retirement_candidate.gd','831b6a705990f74e1e98d5de38c26478326d4d11e41b2cd991da4db18a6ab0c7'),
 (GAME/'scripts/city/luoyang_district_life_geometry_20261016f.gd','c3203d99ad1c5d3de86ed04ee9fdb4672606c9669f47792cd1c500d2e9f5e133'),
 (GAME/'build/luoyang_city_space_20261024b_art01/complete_shop_groundbase_BUILD_ONLY.json','63440447837c42fbe88e9639d46342ad9ebf7f49c5a1e4a83f8cb0fabfdf7506')]: pin(path,h)
parent_walk=GAME/inp['parent']['walk_path'][6:];raw_walk=GAME/inp['parent']['raw_walk_path'][6:]
pin(parent_walk,inp['parent']['walk_sha256']);pin(raw_walk,inp['parent']['raw_walk_sha256'])
assets={}
for id in ['apothecary','bookshop']:
    p=GAME/a['assets'][id]['texture'][6:];pin(p,a['assets'][id]['source_sha256']);assets[id]=p.as_posix()
project=OUT/'project.godot';pin(project)
save_root=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
save_paths=[(save_root/('save_'+str(slot)+suffix)).as_posix() for slot in range(5) for suffix in ['.json','.json.bak','.json.tmp']]
fixture={'ready':False,'status':'INDEPENDENT26_DOMAIN_MARKET_NATIVE_ORACLE_NOTREADY','blockers':['Root must read/approve one bounded no-autoload oracle; no agent has run it. Native PIP childRGBA/count remain unknown until old-local0diff proof.'],'whole_ms':30000,'author_absolute_path':ap.as_posix(),'projection_absolute_path':pp.as_posix(),'independent_f32_model_absolute_path':(OUT/'independent_f32_source_model_NOT_PIP.json').as_posix(),'parent_walk_absolute_path':parent_walk.as_posix(),'raw_walk_absolute_path':raw_walk.as_posix(),'parent_rgba_sha256':inp['parent']['mask_rgba_sha256'],'new_asset_absolute_paths':assets,'source_sha256':guards,'save_paths':save_paths,'fixed26_domain_count':26,'union_visited_pixels':147805,'scope':'One parent+one raw PNG decode, two new building PNG decodes; no packet/resource/Field/Physics/NAV/collector/helper calls. Original native integer PIP+ceil-half-open rectangle semantics. Only26 changed closed domains, not full raster/old875 routes. 5newplinth alpha/source-negative controls plus2door size/nonclosure checks+4threshold/return local34x24 controls. In-memory bytes only, no PNG output or production write.'}
fx=OUT/'fixture_NOTREADY.json';fxsha=emit(fx,fixture)
key=OUT/'oracle_NOTREADY.gd';oldkey=key.read_bytes();changed=oldkey
ops=[(b'PENDING_ABSOLUTE_FIXTURE_PATH',fx.as_posix().encode()),(b'PENDING_FIXTURE_SHA',fxsha.encode()),(b'PENDING_ABSOLUTE_NEW_OUTPUT_DIRECTORY',(OUT/'output_NOTREADY').as_posix().encode())]
for x,y in ops: assert changed.count(x)==1;changed=changed.replace(x,y,1)
restored=changed
for x,y in reversed(ops): assert restored.count(y)==1;restored=restored.replace(y,x,1)
assert restored==oldkey
key.write_bytes(changed)
handoff={'status':'INDEPENDENT_PRIOR_ORACLE_HARDFALSE_NOT_RUN','key':{'path':key.as_posix(),'sha256':sha(key)},'fixture':{'path':fx.as_posix(),'sha256':fxsha},'project':{'path':project.as_posix(),'sha256':sha(project),'autoloads':0},'independent_model':{'sha256':modelsha,'domains':26,'union_pixels':147805,'old23_child25_coordinates_only':True},'source_guard_count':len(guards),'source_UTF8_crowd_names_recovered_both10':True,'image_decode_count_planned':4,'nativepacket_ResourceLoader_Field_Physics_NAV_collector_calls':0,'old875_route_or_fullraster_replay':False,'prior_expected_RGBA_and_changed_pixels':'UNKNOWN until Root native oracle; never copied from futurepublisher','Root_run_scope':'At most one no-autoload headless30s oracle; fail bound never extended. Source3F/462E author staysfalse; publishing is separate Root authority.','preserved_source_firstdraft':'BCF36/CAC09/03D292 retain rectangle-domain omission and name-encoding errors; this prior only uses NEW26 author462E/input3CBC.'}
h=emit(OUT/'handoff_NOTREADY.json',handoff)
print('MODEL',modelsha,'KEY',sha(key),'FIXTURE',fxsha,'PROJECT',sha(project),'HANDOFF',h,'GUARDS',len(guards))
