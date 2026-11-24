"""NEW author successors and static portal ledger. No engine/collector/Stage."""
from pathlib import Path
import copy, hashlib, json, re, struct

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
NS = 'res://build/luoyang_city_finish_20261025i_source01/'

def sha(data): return hashlib.sha256(data).hexdigest()
def path(p): return GAME / p[6:]
def f(v): return struct.unpack('<f', struct.pack('<f', float(v)))[0]
def vecop(a, b, op): return [f(op(f(a[i]), f(b[i]))) for i in range(2)]
def normworld(p, design, world):
    return vecop(vecop(p, design, lambda a,b:a/b), world, lambda a,b:a*b)
def read(p, expected):
    raw = path(p).read_bytes()
    assert sha(raw) == expected, ('FIXED_PARENT_SOURCE_CHANGED', p)
    return raw
def fixed(name, h): return json.loads(read(NS+name, h))
def out(name, value):
    raw = (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False)+'\n').encode()
    with (HERE/name).open('xb') as stream: stream.write(raw)
    return {'path':NS+name, 'sha256':sha(raw), 'bytes':len(raw)}

library = fixed('reuse_asset_library01_SOURCE_ONLY.json', '17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d')
gate = fixed('author_gate_yamen_axis01_NOTREADY.json', '096065bededbc6cd748c944999f76d350c141ffae846a4551e4d0f8f2292468f')
craft = fixed('author_artisan_residential_block01_NOTREADY.json', 'cc9ab0377bbeb6996dbbac1fd3ceddf9d7ef2ceb7496cd5f3178ac58d3d030d2')
temple = fixed('author_temple_courts_loop01_NOTREADY.json', '479e93468610d800ee042d8a693d483bc8f444403dd6f6b0956b32818086706f')
audit = fixed('current_eight_fields_remaining_READONLY.json', '8189e3c5847d403277b07c78eb7ef738de752d826a80b65764e3e147137e597b')
stage = json.loads(read(gate['parent_stage']['path'], gate['parent_stage']['sha256']))
authority = {}
for key, row in stage['nodes'].items():
    if not key.startswith('expected_'): continue
    for p, h in row['value']['source_sha256'].items():
        assert p not in authority or authority[p] == h
        authority[p] = h
for row in stage['targets']: authority[row['target']] = row['candidate_sha256']
source_pins = []
def source(p, explicit=None):
    h = authority[p] if explicit is None else explicit
    raw = read(p, h)
    pin = {'path':p,'sha256':h,'bytes':len(raw)}
    if pin not in source_pins: source_pins.append(pin)
    return raw

def placement(id, kind, foot, scale, purpose):
    a = library['assets'][kind]
    anchor = a['source_ground_anchor_px']
    def transform(q):
        return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(scale))) for i in range(2)]
    polys = [[transform(q) for q in poly] for poly in a.get('source_solid_polygons_px', [])]
    for x,y,w,h in a.get('source_solid_rects_px', []):
        polys.append([transform(q) for q in ([x,y],[x+w,y],[x+w,y+h],[x,y+h])])
    x,y,w,h = a.get('alpha_bbox_xywh') or [0,0,*a['source_size_px']]
    return {'id':id,'asset_id':kind,'foot_px':foot,'scale':scale,'purpose':purpose,
            'source_derived_new_ground_polygons_f32':polys,
            'source_derived_bound_xyxy_f32':transform([x,y])+transform([x+w,y+h]),
            'bound_kind':'A1_FROM_FIXED_DONOR' if a.get('alpha_bbox_xywh') else 'CONSERVATIVE_FULL_CANVAS_NOT_MEASURED_ALPHA',
            'door_visible_height_px_before_scene_conversion':None if not a.get('door_clear_source_px') else a['door_clear_source_px']*scale,
            'polygon_PIP_Physics_or_mask_credit':False,'enters_new_room':False}

for n, row in enumerate(gate['scenes'][0]['placements']):
    if row['asset_id'] == 'open_gallery':
        gate['scenes'][0]['placements'][n] = placement(row['id'], row['asset_id'], row['foot_px'], .36, row['purpose'])
gate['scenes'][0]['gallery_clearance_source_expression'] = {'source_clear_height_px':357,'scale':.36,'world_clear_height_px':357*.36,'minimum':128,'geometric_or_Physics_credit':False}

# The actual adopted Temple successor, not the older legacy hotspot UV.
temple_code = source('res://scripts/city/luoyang_temple_assembly_20261016.gd').decode()
assert '"legacy_portal_6":Vector2(240.0,850.0)' in temple_code
assert '"legacy_portal_7":Vector2(1296.0,850.0)' in temple_code
temple['portal_local_position_migrations'] = [
    {'id':'legacy_portal_6','old_local_source_foot_px':[240,850],'new_local_source_foot_px':[170,980], 'target_scene':'ch4_s3_luoyang_market','target_action_flags_unchanged':True},
    {'id':'legacy_portal_7','old_local_source_foot_px':[1296,850],'new_local_source_foot_px':[1380,980], 'target_scene':'ch4_s2_canal_docks','target_action_flags_unchanged':True}]
temple['new_routes_source_px'][1] = {'id':'south_ring_to_east_docks_portal','points_px':[[768,960],[1380,960],[1380,980]]}
temple['closed_domain_budget_source_xywh'][-1] = [120,940,1290,68]
temple['incoming_target_migrations'] = [
    {'source_scene':'ch4_s3_luoyang_market','source_portal_id':'to_ancient_temple','target_source_foot_px':[170,980],'target_world_foot_f32':normworld([170,980],[1536,1024],[1920,1280]),'proof_pending':'NEW_PORTAL_SUPPORT_AND_ROUTE_NOT_OLD_BRIDGE_CREDIT'},
    {'source_scene':'ch4_s2_canal_docks','source_portal_id':'canal_world_ferry','target_source_foot_px':[1380,980],'target_world_foot_f32':normworld([1380,980],[1536,1024],[1920,1280]),'proof_pending':'NEW_RECIPROCAL_CITY_LINK_NOT_WORLD_FERRY'}]
temple['parent_foot_correction'] = '01 used historical legacy coordinates. Exact current Assembly successor feet are240850/1296850;01 retained unmodified and not a new prior.'

# Root approved a larger kitchen envelope, but its final uniform scale/anchor
# MUST come from the new ART raw measurements; no guessed door or pixel prior.
craft['new_asset_lots'][2].update({'lot_xywh':[1196,16,720,584],'foot_px':[1536,410],
    'max_A1_size_px':[606,390], 'final_scale_anchor_status':'ART_MANUAL_MEASUREMENTS_RECEIVED; WAIT_FOR_FIXED_SMALL_MEASUREMENT_DOCUMENT',
    'north_edge_constraint':'Transformed complete A1.y_min>=16 and no roof overlap with north homes. Move foot only after exact source bounds; no canvas-fit shrink.'})

GATE='ch4_s0_luoyang_gate';YAMEN='ch4_s1_luoyang_yamen';DOCKS='ch4_s2_canal_docks';MARKET='ch4_s3_luoyang_market'
ARTISAN='luoyang_artisan_residential_20261022ap';ESTATE='luoyang_estate_riverside_20261021ai';GARDEN='luoyang_riverside_garden_20261022ap';TEMPLE='ch4_s4_ancient_temple';WORLD='world_map_jianghu'

pair = [
 {'id':'finish_i_yamen_to_artisan','source':YAMEN,'target':ARTISAN,'source_foot_px':[120,1240],'target_foot_px':[128,1300],'action':'scene:'+ARTISAN},
 {'id':'finish_i_artisan_to_yamen','source':ARTISAN,'target':YAMEN,'source_foot_px':[128,1300],'target_foot_px':[120,1240],'action':'scene:'+YAMEN}]
gate['scenes'][1]['new_public_portal'] = copy.deepcopy(pair[0])
craft['new_public_portal'] = copy.deepcopy(pair[1])
for row in pair:
    row.update({'old_id_not_reused':True,'require_flag':'','hide_flag':'','new_door_threshold_size_px':[40,32], 'arrival_and_body_credit':False,
                'required_new_checks':['source threshold polygon full body34x24 and approach48','reciprocal same-scene target support','old task/room ids unchanged','route ownership exact pair not generic fallback']})

layouts = {
 GATE:'res://data/maps/luoyang_gate_fortification_v3_candidates/ch4_s0_luoyang_gate_layout.tres',
 YAMEN:'res://data/maps/luoyang_enclosure_v11_candidates/ch4_s1_luoyang_yamen_layout.tres',
 DOCKS:'res://data/maps/luoyang_enclosure_v11_candidates/ch4_s2_canal_docks_layout.tres',
 MARKET:'res://data/maps/luoyang_enclosure_v11_candidates/ch4_s3_luoyang_market_layout.tres',
 TEMPLE:'res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres'}
def vector(text, key):
    m = re.search(r'&?"'+key+r'":\s*Vector2\(([^,]+),\s*([^\)]+)\)', text)
    return [float(m[1]),float(m[2])] if m else None
def string(text, key):
    m = re.search(r'"'+key+r'":\s*"([^"]*)"', text)
    return m[1] if m else None
def portals(text):
    body = text.split('portals = Array[Dictionary]([',1)[1]
    result = []; start = None; depth = 0; quote = False; escape = False
    for i,ch in enumerate(body):
        if quote:
            if escape: escape=False
            elif ch=='\\': escape=True
            elif ch=='"': quote=False
            continue
        if ch=='"': quote=True
        elif ch=='{':
            if depth==0:start=i
            depth+=1
        elif ch=='}':
            depth-=1
            if depth==0: result.append(body[start:i+1])
        elif ch==']' and depth==0: break
    return result

c_text = source('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd').decode()
fresh = {}
for m in re.finditer(r'"([^"]+)->([^"]+)": \{"portal":"([^"]+)"[^\n]+?"slot":"([^"]+)","foot":Vector2\(([^,]+),([^\)]+)\)',c_text):
    fresh[(m[1],m[2])]={'source_portal_id':m[3],'target_slot':m[4],'historical_target_foot_px':[float(m[5]),float(m[6])]}
assert len(fresh)==12
market_author_p='res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json'
market_author=json.loads(source(market_author_p))
terminal_market={r['id']:r['foot_px'] for r in market_author['external_portal_migrations']}
preserved_market=market_author['external_portals_preserved']
if isinstance(preserved_market,list):
    for r in preserved_market:
        if isinstance(r,dict) and r.get('id') and r.get('foot_px'): terminal_market[r['id']]=r['foot_px']
elif isinstance(preserved_market,dict):
    for k,v in preserved_market.items(): terminal_market[k]=v if isinstance(v,list) else v.get('foot_px')
assert terminal_market['to_canal_docks']==[3008,1468]
assert terminal_market['to_ancient_temple']==[1170,1600]

current=[]
for sid,p in layouts.items():
    for raw in portals(source(p).decode()):
        id=string(raw,'id');target=string(raw,'target_scene');action=string(raw,'action')
        if action=='world_map':target=WORLD
        assert id and target,(sid,raw)
        design=[1536,1024] if sid==TEMPLE else [3072,2048]
        world=[1920,1280] if sid==TEMPLE else design
        local=vector(raw,'arrival_foot_px') or vecop(vector(raw,'pos'),design,lambda a,b:a*b)
        if sid==MARKET and id in terminal_market:local=terminal_market[id]
        authored_uv=vector(raw,'target_pos')
        target_world=[1920,1280] if target==TEMPLE else [3072,2048]
        arrival=None if authored_uv is None else vecop(authored_uv,target_world,lambda a,b:a*b)
        resolver=fresh.get((sid,target))
        if resolver:
            arrival=resolver['historical_target_foot_px']
            if target==MARKET and resolver['target_slot'] in terminal_market:arrival=terminal_market[resolver['target_slot']]
        current.append({'source':sid,'target':target,'portal_id':id,'action':action or 'scene:'+target,
                        'local_source_foot_px':local,'source_world_foot_f32':normworld(local,design,world),
                        'authored_target_uv':authored_uv,'effective_target_world_foot_px':arrival,
                        'current_arrival_model':'C exact fresh route and source-bound terminal slot' if resolver else 'original explicit authored target UV',
                        'source_declaration':{'path':p,'sha256':authority[p]},'fresh_route':resolver})

quarter_p='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
quarter=json.loads(source(quarter_p))
for r in quarter['connections']:
    if r['kind']!='PUBLIC_QUARTER_LINK':continue
    current.append({'source':r['source'],'target':r['target'],'portal_id':r['id'],'action':'scene:'+r['target'],
                    'local_source_foot_px':r['source_foot'],'source_world_foot_f32':r['source_foot'],
                    'effective_target_world_foot_px':r['target_foot'],
                    'source_declaration':{'path':quarter_p,'sha256':authority[quarter_p]},'current_arrival_model':'Family exact PUBLIC_QUARTER_LINK entry and same owner safety'})
estate_p='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
estate=json.loads(source(estate_p))
estate_family='res://scripts/city/luoyang_estate_family_20261021am.gd'
estate_text=source(estate_family).decode()
assert 'Vector2(1536,1840)/SIZE if source==MARKET' in estate_text
estate_projection='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd'
estate_projection_text=source(estate_projection).decode()
assert '"pos":uv(a.market_portal.foot)' in estate_projection_text
estate_author_p='res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_author_candidate.json'
estate_author_hash=re.search(r'const AUTHOR_SHA="([0-9a-f]{64})"',estate_projection_text)[1]
estate_author=json.loads(source(estate_author_p,estate_author_hash))
assert estate_author['market_portal']['foot']==[1536,1940]
assert estate_author['market_portal']['target_foot']==estate['market_foot_px']
for s,t,id,foot,arrival in [(MARKET,ESTATE,'am_market_estate_alley',estate['market_foot_px'],[1536,1840]),(ESTATE,MARKET,estate_author['market_portal']['id'],estate_author['market_portal']['foot'],estate_author['market_portal']['target_foot'])]:
    current.append({'source':s,'target':t,'portal_id':id,'action':'scene:'+t,'local_source_foot_px':foot,'source_world_foot_f32':foot,'effective_target_world_foot_px':arrival,
        'source_declaration':{'path':estate_p,'sha256':authority[estate_p]},'consumer_source':{'path':estate_family,'sha256':authority[estate_family]},'current_arrival_model':'Estate exact authored family arrival + remembered vicinity/safe-body'})
current.append({'source':WORLD,'target':GATE,'portal_id':'luoyang','action':'scene:'+GATE,'source_world_foot_f32':None,
                'effective_target_world_foot_px':[1536,1860], 'source_declaration':{'path':'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','sha256':authority['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd']},'current_arrival_model':'C FRESH_AUTHORED_ROUTES worldMap->Gate'})

changes=[{'kind':'REPLACE_ONLY_THIS_EXISTING_PORTAL','source':DOCKS,'portal_id':'canal_world_ferry',
 'old_action':'world_map','new_action':'scene:'+TEMPLE,'old_target':WORLD,'new_target':TEMPLE,
 'local_source_foot_px':[340,1840],'new_target_source_foot_px':[1380,980],
 'new_target_world_foot_f32':normworld([1380,980],[1536,1024],[1920,1280]),
 'new_label':'沿河东支路 · 古寺东巷','same_id_source_foot_and_flags':True,'new_route_credit':False}]
changes+=copy.deepcopy(pair)
changes+=copy.deepcopy(temple['portal_local_position_migrations'])
changes+=copy.deepcopy(temple['incoming_target_migrations'])
candidate=copy.deepcopy(current)
for row in candidate:
    if row['source']==DOCKS and row['portal_id']=='canal_world_ferry':
        row.update({'target':TEMPLE,'action':'scene:'+TEMPLE,'effective_target_world_foot_px':normworld([1380,980],[1536,1024],[1920,1280])})
    if row['source']==TEMPLE:
        local=[170,980] if row['portal_id']=='legacy_portal_6' else [1380,980]
        row.update({'local_source_foot_px':local,'source_world_foot_f32':normworld(local,[1536,1024],[1920,1280])})
    if row['source']==MARKET and row['target']==TEMPLE:row['effective_target_world_foot_px']=normworld([170,980],[1536,1024],[1920,1280])
for row in pair:candidate.append({'source':row['source'],'target':row['target'],'portal_id':row['id'],'action':row['action'],'local_source_foot_px':row['source_foot_px'],'source_world_foot_f32':row['source_foot_px'],'effective_target_world_foot_px':row['target_foot_px'],'new_candidate_only':True})
def edge_set(rows):return {(r['source'],r['target']) for r in rows}
def assert_ring(ring, edges):
    return all((a,b) in edges for a,b in zip(ring,ring[1:]+ring[:1]))
candidate_edges=edge_set(candidate)
west=[YAMEN,ARTISAN,MARKET]
east=[MARKET,ESTATE,GARDEN,DOCKS]
temple_ring=[MARKET,TEMPLE,DOCKS]
assert all(assert_ring(r,candidate_edges) for r in (west,east,temple_ring))
world_exits=lambda rows:sorted(r['source'] for r in rows if r['target']==WORLD)
assert world_exits(current)==sorted([GATE,DOCKS])
assert world_exits(candidate)==[GATE]
ledger={'status':'PINNED_CURRENT_EIGHT_EXTERNAL_FIELDS_PORTALS_AND_ROOT_APPROVED_DESIGN_SUCCESSOR_NOT_RUNTIME','ready':False,
 'parent_stage':gate['parent_stage'],'parent_deployment':gate['parent_deployment'],'current_edges':current,
 'current_world_exits':world_exits(current),'candidate_changes':changes,'candidate_edges':candidate,
 'candidate_world_exits':world_exits(candidate),'candidate_rings':[{'id':'west_civic_working_loop','scenes':west},{'id':'east_estate_riverside_loop','scenes':east},{'id':'temple_east_branch_loop','scenes':temple_ring}],
 'main_axis':[WORLD,GATE,YAMEN,MARKET], 'graph_adjacency_only_not_PIP_or_Physics_or_travel_pass':True,
 'new_required_consumers':['Docks exact public portal projection, no B/native-record edit','C precise route authority/source-arrival for new city pairs','Family quarter connection header + Artisan true native outgoing portal','Temple successor_portals + successor_hotspots same two final feet','Market incoming target authored Temple foot same new west gate','Field existing portal materialization from effective source only'],
 'source_pins':source_pins,'no_world24d_river_reuse_claim':True,'engine_calls':0,'collector_calls':0}

common={k:copy.deepcopy(gate[k]) for k in ['schema_version','status','ready','parent_stage','parent_deployment','parent_guard','old_OWNED_members','old_proof_count','history_depth_limit','unified_final_source_stage_only','old_native_and_failures_immutable','engine_calls','collector_calls','canonical_writes']}
adjacent={**common,'group_id':'04_adjacent_finish_domains_keep_passed_cores','reuse_library':gate['reuse_library'],'scenes':[
 {'scene_id':MARKET,'purpose':'客栈后勤—西街候歇形成连续背街；原45与两作业院不再重排',
  'placements':[placement('finish_i_market_inn_supply_gallery','open_gallery',[560,880],.36,'客栈补给/马料候歇廊；不增加假客房门')],
  'ground_purpose_rows':[{'id':'inn_supply_court','rect_xywh':[220,900,620,260],'surface':'existing courtyard stone with earth shoulder','use':'马料车/手推补给与旅人等候分边，前院与药铺前庭间保144支巷'}],
  'provisional_changed_domains_xywh':[[200,620,720,560]],'preserve':['all45 render rows and true bodies','6 doors + two outer + remembered return','all current task and4 discover/offer interactions','25f materials outside new court'], 'npc_migrations':[]},
 {'scene_id':ESTATE,'purpose':'西南安静家祠侧庭与东南仆役灶洗庭分工，不复制主厅当祠堂',
  'placements':[placement('finish_i_estate_family_ancestral_wing','plain_wing',[650,1710],.44,'完整祭祀侧屋外观；须现有祭案/香炉陈设与家族职责绑定，不冒新室内')],
  'new_asset_lots':[{'asset_id':'new_plain_kitchen_rear_house','foot_px':[2520,1640],'lot_xywh':[2140,1150,720,660],'max_A1_size_px':[606,390],'closed_exterior_only':True,'final_uniform_scale':'derive from same fixed ART complete raw door>=145; do not refit canvas'}],
  'purpose_courts':[{'id':'ancestral_quiet_forecourt','rect_xywh':[320,1730,750,170],'purpose':'族人祭扫/存书，不置商摊，祭器来源缺口明确待配'},{'id':'servants_wash_dry','rect_xywh':[2180,1660,680,160],'purpose':'柴灶/洗晒同一后勤院，门口留144，保东南外通路'}],
  'provisional_changed_domains_xywh':[[240,1300,900,600],[2100,1150,820,700]],'preserve':['Estate111/48 whole parent','main axis1536 and hall1536544','south exit15361940','Garden portal29441840','old2corridors and flowering courts'], 'npc_migrations':[]},
 {'scene_id':GARDEN,'purpose':'只补桥以外两岸石草肩/茶楼庭/植物组团，不动25h真实桥两端与水物理',
  'ground_purpose_rows':[{'id':'west_bank_pavilion_soft_path','polyline_world_px':[[520,1520],[760,1420],[860,1260],[1000,1160]],'clear_width_px':144,'surface':'existing fine earth + irregular gravel shoulders','edges':'flower groups outside walking strip, no opaque river carpet'},
   {'id':'east_tea_garden_curve','polyline_world_px':[[2280,1120],[2440,1180],[2680,1340],[2780,1520]],'clear_width_px':144,'surface':'existing fine earth, stone forecourt only at tea-house use'}],
  'plant_groups':[{'id':'west_flower_group','center_world_px':[680,1300],'max_A1_size_px':[220,180],'purpose':'低花丛非顶高树挡桥头','asset_authority':'exact existing adopted Garden plant donor needed before final pin','new_solid_if_any':'true original base only, no alpha silhouette collision'},
   {'id':'east_teacourt_shade','center_world_px':[2670,1520],'max_A1_size_px':[220,230],'purpose':'茶楼外休憩树阴，不冒茶楼新室内','asset_authority':'exact current plant source needed before final pin'}],
  'provisional_changed_domains_xywh':[[400,1180,720,430],[2160,1080,760,530]],'preserve':['bridge/water pieces and entire deck880976..2192976','pavilion760760/tea2520650','4 authored NPC full approach','2 south public portals'], 'npc_migrations':[]},
 {'scene_id':DOCKS,'purpose':'沿岸三种货务连续序列：记货—称量—短储，与原仓/两铺接路而非添无用楼',
  'placements':[placement('finish_i_docks_weighing_gallery','open_gallery',[1850,1780],.36,'称量/封包荫廊，两侧保车货144通道，四真实柱脚')],
  'work_bays':[{'id':'shore_tally_bay','rect_xywh':[1060,1100,460,260],'purpose':'船货记数与验货停步，现船工路线之外'},{'id':'weighing_pack_bay','rect_xywh':[1550,1570,650,300],'purpose':'称量/封包/少量秤案，依现货路连仓外短储'},{'id':'temporary_covered_storage','rect_xywh':[2320,1540,450,310],'purpose':'既有粮袋/木车的有序短储，不占Garden/Temple支路'}],
  'provisional_changed_domains_xywh':[[1040,1050,560,340],[1480,1500,790,350],[2290,1480,520,400]],
  'preserve':['three current frontage bodies/doors145/warehouse638610','39NAV35solids before exact new bases','stage-gated canal mud and all task flags','old shore/water native immutable'], 'npc_migrations':[]}
 ],'not_finished_until':['actual same-parent roof/body/NPC/door clearance negative controls','new domain independent retained-primitive mask union and outside inverse','exact existing resource tuples + any ART new3 approved files','limited whole-street GPU review; current coordinates are source design not passed ART'],
 'new_asset_gaps':['plain kitchen shared with Artisan only after exact new ART dimension fit','ancestral altar/incense source identity and plant source templates still require exact fixed donor measurement']}

files=[out('author_gate_yamen_axis02_NOTREADY.json',gate),out('author_artisan_residential_block02_NOTREADY.json',craft),out('author_temple_courts_loop02_NOTREADY.json',temple),out('current_portal_ledger_and_structural_delta01_NOTREADY.json',ledger),out('author_adjacent_four_fields01_NOTREADY.json',adjacent)]
index={'status':'EIGHT_FIELDS_DESIGN_AUTHORS_TWO_STRUCTURAL_RINGS_NOT_PUBLICATION','ready':False,'parent_stage':gate['parent_stage'],'files':files,
 'eight_external_fields':[GATE,YAMEN,DOCKS,MARKET,ARTISAN,ESTATE,GARDEN,TEMPLE],
 'one_final_source_stage':True,'old_OWNED':10,'old_proofs':176,'history_depth':16,
 'preserved_cores':['25h Garden bridge+services','25g45 courts','Docks31 frontage','24e Market6 shops','all12 native rooms'],
 'actual_or_geometric_pass':False,'remaining_before_freeze':['fixed3 new ART raw door/base/A1 and authorized derivatives','exact full adopted parent rows/body projection, not visual-only historic readback','independent new-domain finite prior + only affected routes/NPC approaches','runtime hooks same rendered/solid/mask lease and precise portal route ownership','single final source DAG incremental from25h actual maps']}
index_pin=out('city_finish25i_author_index02_NOTREADY.json',index)
print(json.dumps({'index':index_pin,'files':files,'static_edges':len(current),'candidate_edges':len(candidate),'current_world_exit_fields':world_exits(current),'candidate_world_exit_fields':world_exits(candidate),'canonical_writes':0,'engine_calls':0,'collector_calls':0},ensure_ascii=False))
