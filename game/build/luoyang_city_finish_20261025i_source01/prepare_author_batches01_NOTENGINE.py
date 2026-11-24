"""Read fixed adopted sources; create NEW author drafts only. No engine or collectors."""
from pathlib import Path
import json, hashlib, struct, re

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
S='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b): return hashlib.sha256(b).hexdigest()
def res(p): return GAME/p[6:] if p.startswith('res://') else Path(p)
def fixed(p,h):
    raw=res(p).read_bytes(); assert sha(raw)==h,('FIXED_SOURCE_DIFFERENT',p)
    return json.loads(raw)
def f(x): return struct.unpack('<f',struct.pack('<f',float(x)))[0]
def point(foot,p,anchor,scale):
    return [f(f(foot[i])+f(f(f(p[i])-f(anchor[i]))*f(scale))) for i in range(2)]
def output(name,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    p=HERE/name
    with p.open('xb') as stream: stream.write(raw)
    return {'path':NS+name,'sha256':sha(raw),'bytes':len(raw)}

STAGE={'path':S+'outputs/root_services_garden_exact28_stage05/receipt.json','sha256':'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'}
DEP={'path':'res://build/luoyang_city_revision_20261025h_root01/service_garden28_deployed_actual.json','sha256':'7761350ba5a49ebeb94789fcc104d7310c204f28674a499bd9f6b4d2f9ad98ac'}
GUARD={'path':S+'guard_service_garden28_after_Field_READONLY.json','sha256':'66d2557bf6078b4b39e87648c37b79bdfbc8523657b275c10686e2d117076146'}
stage=fixed(STAGE['path'],STAGE['sha256']);dep=fixed(DEP['path'],DEP['sha256']);guard=fixed(GUARD['path'],GUARD['sha256'])
assert dep['passed'] and guard['passed'] and guard['full_backup_count']==176
authority={}
for name,row in stage['nodes'].items():
    if not name.startswith('expected_'): continue
    for p,h in row['value']['source_sha256'].items():
        if p in authority: assert authority[p]==h,('INDEPENDENT_MAP_CONFLICT',p)
        authority[p]=h
for row in stage['targets']: authority[row['target']]=row['candidate_sha256']
reads=[]
def source_json(p,explicit=None):
    h=explicit or authority[p]
    value=fixed(p,h); reads.append({'path':p,'sha256':h,'purpose':'Read adopted declaration; not a live collector or output-derived expected value'})
    return value
def code_pin(p):
    h=authority[p];raw=res(p).read_bytes();assert sha(raw)==h
    return {'path':p,'sha256':h}

readback=source_json('res://build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json','a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c')
assert readback['complete'] and readback['failures']==0
dg=source_json('res://data/maps/luoyang_district_life_20261016f/author.json')
artisan=source_json('res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json')
people=source_json('res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json')
temple=source_json('res://data/maps/luoyang_temple_assembly_20261016/author.json')
gallery_author=source_json('res://build/luoyang_market_courtyard_links_20261025g_system01/author_courtyard_links02_NOTREADY.json')
estate_components=source_json('res://build/luoyang_estate_courtyard_20261021ak_system01/author_READY.json','c21097071d8a13ee9e427309a9203fe74ae28250eb36d067c2a101e08185de55')
quarter=source_json('res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json')
estate=source_json('res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json')

def npc_ids(p):
    pin=code_pin(p);text=res(p).read_text(encoding='utf-8')
    return {'source':pin,'base_ids_only_not_runtime_total':re.findall(r'"npc_id"\s*:\s*"([^"]+)"',text)}
base_npcs={sid:npc_ids('res://data/scenes/'+sid+'.tres') for sid in ('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')}
base_npcs['ch4_s4_ancient_temple']=npc_ids('res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres')

def asset(texture,size,anchor,polys=None,rects=None,alpha=None,door=None,donor=None):
    result={'texture':texture,'source_sha256':authority.get(texture),'source_size_px':size,'source_ground_anchor_px':anchor,'source_solid_polygons_px':polys or [],'source_solid_rects_px':rects or [],'alpha_bbox_xywh':alpha,'door_clear_source_px':door,'donor':donor,'no_rotate_mirror_crop_or_pixel_edit':True}
    assert result['source_sha256'],('NO_FIXED_EXISTING_ASSET_PIN',texture)
    return result
annex=dg['assets']['official_service_annex_v1']
wing=next(a for a in estate_components['assets'] if a['id']=='wing')
corridor=gallery_author['assets']['corridor']
assets={
 'official_annex':asset(annex['texture'],annex['size_px'],annex['source_ground_anchor_px'],annex['ground_solid_polygons_px'],door=300,donor='DG source + Root24c manual closed-leaf reference, not transparent doorway'),
 'plain_wing':asset('res://art/modules/luoyang_estate_components_20261021am/wing.png',wing['source_size'],wing['ground_anchor'],rects=wing['solid_rects_px'],alpha=wing['alpha_rect_px'],door=wing['door_clear_px'],donor='C210 whole wing source; source image hash must equal canonical whole copy'),
 'open_gallery':asset(corridor['texture'],corridor['source_size_px'],corridor['source_ground_anchor_px'],rects=corridor['ground_solid_rects_xywh_px'],alpha=[436,163,1743,649],donor='25g approved four-post complete gallery; no full roof rectangle solid'),
}
for key in ('vertical_wall','low_wall'):
    a=gallery_author['assets'][key]
    assets[key]=dict(a)
    assets[key]['source_sha256']=authority[a['texture']]

def placement(id,kind,foot,scale,purpose):
    a=assets[kind];polys=[]
    for p in a.get('source_solid_polygons_px',[]): polys.append([point(foot,q,a['source_ground_anchor_px'],scale) for q in p])
    for x,y,w,h in a.get('source_solid_rects_px',[]):
        polys.append([point(foot,q,a['source_ground_anchor_px'],scale) for q in ([x,y],[x+w,y],[x+w,y+h],[x,y+h])])
    box=a.get('alpha_bbox_xywh') or [0,0,*a['source_size_px']]
    x,y,w,h=box;lo=point(foot,[x,y],a['source_ground_anchor_px'],scale);hi=point(foot,[x+w,y+h],a['source_ground_anchor_px'],scale)
    return {'id':id,'asset_id':kind,'foot_px':foot,'scale':scale,'purpose':purpose,'source_derived_new_ground_polygons_f32':polys,'source_derived_bound_xyxy_f32':[*lo,*hi],'bound_kind':'A1_FROM_FIXED_DONOR' if a.get('alpha_bbox_xywh') else 'CONSERVATIVE_FULL_CANVAS_NOT_MEASURED_ALPHA','door_visible_height_px_before_scene_conversion':None if not a.get('door_clear_source_px') else a['door_clear_source_px']*scale,'polygon_PIP_Physics_or_mask_credit':False,'enters_new_room':False}

common={'schema_version':1,'status':'ROOT_APPROVED_DESIGN_AUTHOR_DRAFT_NOT_RUNTIME','ready':False,'parent_stage':STAGE,'parent_deployment':DEP,'parent_guard':GUARD,'old_OWNED_members':10,'old_proof_count':176,'history_depth_limit':16,'unified_final_source_stage_only':True,'old_native_and_failures_immutable':True,'engine_calls':0,'collector_calls':0,'canonical_writes':0}

gate={**common,'group_id':'01_gate_yamen_main_axis','design_size_px':[3072,2048],'scenes':[
 {'scene_id':'ch4_s0_luoyang_gate','consumer_chain':['C/B fixed Gate native28','DT/DG existing source projection','new exact terminal frontage projection and same lease mask','Field sprites/NAV/C.safe_body same geometry'],
  'retire_exact_visual_ids':['west_street_front','east_street_front'],
  'retirement_note':'These are the old native700x467 street_row fronts, not the refined gate/towers/bridge. Exact prior bodies must be read from fixed parent record; never infer blockers from roof bounds.',
  'placements':[placement('finish_i_gate_west_inspection','official_annex',[650,1300],.5,'军籍核验屋及候检西院，不是普通商店'),placement('finish_i_gate_east_supply','official_annex',[2490,1300],.5,'军需与车货核验东院'),placement('finish_i_gate_west_waiting_gallery','open_gallery',[650,1730],.28,'与核验前庭成组的候检荫廊，四真实柱脚'),placement('finish_i_gate_east_cart_gallery','open_gallery',[2490,1730],.28,'车夫与脚夫等候的东侧作业廊')],
  'main_street':{'id':'gate_ceremonial_axis','rect_xywh':[1380,1020,312,960],'purpose':'桥头到城内的直视主轴；保门吏和既有桥/出口，不放摊位'},
  'courts':[{'id':'west_queue','rect_xywh':[220,1390,900,500],'purpose':'候检/行李与旅人分边；不把箱子散在主轴'},{'id':'east_carrier','rect_xywh':[2020,1390,900,500],'purpose':'车货卸检/军需补给，保144宽转运支巷'}],
  'object_migrations':[{'id':'notice_pavilion','old_foot_px':[700,1400],'new_foot_px':[1120,1490]},{'id':'district_luoyang_gate_stock_goods_0','old_foot_px':[1120,1420],'new_foot_px':[650,1670]}],
  'preserve':['north_court_boundary','gate_tower_140','gate_tower_2932','gate_bridge_deck','all gate_bridge_rail_*','gate_moat_blocker_0','gate_moat_blocker_1','all portal targets and authored arrival feet','luoyang_gate_sergeant'],
  'affected_domains_provisional_xywh':[[240,0,920,620],[1940,0,920,620],[128,830,1020,1060],[1980,830,1020,1060]],'domain_status':'CONSERVATIVE_PLANNING_ONLY_REQUIRES_EXACT_OLD_AND_NEW_BODY_UNION'},
 {'scene_id':'ch4_s1_luoyang_yamen','consumer_chain':['C finite native27','DT/DG official annex replacement','24c courts source lease combined ground40','new adjacent archive/barracks court projection'],
  'preserve_actual_annexes':[{'id':'assembled_west_service_annex','foot_px':[590,1000],'scale':.5},{'id':'assembled_east_service_annex','foot_px':[2664,1050],'scale':.5}],
  'placements':[placement('finish_i_yamen_west_archive','official_annex',[590,620],.5,'书吏/档案后体，与西现役附楼构成用途连续的侧院'),placement('finish_i_yamen_east_runner_house','official_annex',[2664,620],.5,'差役/兵房后体，不占仪式轴线')],
  'main_street':{'id':'yamen_ritual_axis','rect_xywh':[1386,700,300,1120],'purpose':'正堂1536,660—仪门1536,1700礼制轴，保既有真实入堂/柱后组件'},
  'side_courts':[{'id':'west_petition_archive','rect_xywh':[350,1120,900,470],'purpose':'候审长凳/代书桌/告示形成可读边庭，原notice5501180不动'},{'id':'east_runner_supplies','rect_xywh':[2200,1150,700,470],'purpose':'差役作业与军需短庭，真实侧巷不缩入主轴'}],
  'npc_migrations':[],'preserve':['magistrate_hall','all original active room/outer portals','24c exact two annex bodies and effective mask outside new domains','all current task/culture NPC identities'],
  'affected_domains_provisional_xywh':[[120,150,840,1030],[2180,150,840,1030]],'domain_status':'EXACT_NEW_BODY_AND_RETAINED_PRIMITIVE_UNION_PENDING; 24c two old patches inherited not recompiled'}]}

craft_scene=artisan['scenes'][0]
craft_moves=[('ap_courtyard_home_west',[590,480]),('ap_courtyard_home_east',[2460,480]),('ap_woodwork_court_west_chinese_v3',[560,1150]),('ap_cloth_dye_workshop_east',[2530,1150]),('ap_carpentry_general_shop_south',[1536,900])]
old={r['id']:r for r in craft_scene['placements']}
craft={**common,'group_id':'02_artisan_residential_complete_block','scene_id':craft_scene['scene_id'],'design_size_px':[3072,2048],
 'consumer_chain':['Family old A2 + life136/31 immutable four-artifact binding','new native source-bounded child or strict whole-parent overlay; final selection after prior','Family/NativeGeometry/material runtime all consume same child','G three same room ID return scalars'],
 'old_current_native_visual_count':136,'old_current_solid_count':31,'preserve_four_low_life_props':True,
 'building_migrations':[{'id':id,'old_foot_px':old[id]['foot'],'new_foot_px':new,'old_A1_width_px':old[id]['width'],'new_A1_width_px':old[id]['width'],'asset_id':old[id]['asset'],'purpose':'北住宅—中木染—南铁陶三层完整坊巷，不靠随机空地加楼'} for id,new in craft_moves],
 'new_asset_lots':[{'asset_id':'new_open_forge','lot_xywh':[128,1420,884,600],'foot_px':[560,1850],'max_A1_size_px':[760,430],'front_court_depth_px':144,'primary_door_height_min_px':145,'primary_door_width_min_px':170,'source_asset_and_solid_polygons':None},{'asset_id':'new_pottery_kiln_workshop','lot_xywh':[1980,1420,780,600],'foot_px':[2370,1850],'max_A1_size_px':[720,430],'front_court_depth_px':144,'primary_door_height_min_px':145,'primary_door_width_min_px':170,'source_asset_and_solid_polygons':None},{'asset_id':'new_plain_kitchen_rear_house','lot_xywh':[1220,16,680,560],'foot_px':[1536,360],'max_A1_size_px':[560,330],'primary_door_height_min_px':145,'source_asset_and_solid_polygons':None}],
 'street_hierarchy':[{'id':'craft_working_cross_street','rect_xywh':[180,1190,2730,220],'purpose':'南铁陶屋顶之前的主横街，不再原y1664穿新屋'},{'id':'east_entry_lane','rect_xywh':[2784,1410,176,550],'purpose':'原2816,1740门户到主街，陶坊A1不得侵入'},{'id':'central_well_court','rect_xywh':[1180,940,700,248],'purpose':'共享井及邻里交谈，不是第二官署广场'}],
 'preserve_outer_portal':next(p for p in craft_scene['portals'] if p['id']=='craft_to_market'),
 'same_room_migrations':[{'room_id':p['target_scene'],'exterior_object_id':id,'old_portal_foot_px':p['foot'],'new_portal_foot_px':[new[0],new[1]+24],'new_return_fallback_foot_px':[new[0],new[1]+24],'room_native_or_geometry_change':False} for id,new in craft_moves for p in craft_scene['portals'] if p['id']=='ap_enter_'+id],
 'old_routes':craft_scene['routes'],'new_route_design_status':'ONLY_TOUCHING_SEGMENTS_TO_BE_REPLACED_AFTER_NEW_ASSET_BASES; no old875x17 replay',
 'current_NPC_source_rows':[r for r in people['people'] if r['scene_id']==craft_scene['scene_id']], 'npc_migrations':[],
 'pending_exact_checks':['existing central well/notice/tree and four low props versus new full-alpha bounds','three same-room threshold/return projection + six exterior NPC/task consumer gates','NPC full34x30 and source approach48, not merely player34x24','f32 full-A1 scale preserving new door145','old/new closed primitive union and unchanged outside inverse'],
 'required_assets_not_fabricated':True,'all_three_new_building_resources_pending':True}

temple_group={**common,'group_id':'03_temple_front_courts_and_loop','scene_id':'ch4_s4_ancient_temple','source_design_size_px':[1536,1024],'actual_world_size_px':[1920,1280],'coordinate_scale_source_to_world':1.25,
 'consumer_chain':['Temple existing current source-bound whole storage prepare','strict old author and all values restored first','new exact author delta from same source + Field physical geometry','C two source portals only local pos changes; old targets retained'],
 'placements':[placement('finish_i_temple_west_monks_house','plain_wing',[360,884],.33,'西前侧僧舍外观与前庭，非新增可进入室内'),placement('finish_i_temple_east_sutra_house','plain_wing',[1050,884],.33,'东前侧经务房外观，完整屋身与前庭；无虚假room门')],
 'same_object_migrations':[{'id':'temple_broken_wall','old_foot_px':[450,760],'old_scale':.2,'new_foot_px':[120,950],'new_scale':.1,'purpose':'降为西南院口残墙收边，不保一片碎墙在新屋里'},{'id':'temple_ancient_bell','old_foot_px':[1320,620],'new_foot_px':[1320,570],'old_scale':.2,'new_scale':.2}],
 'same_interaction_migrations':[{'id':'legacy_hotspot_5','old_foot_px':[1320,670],'new_foot_px':[1320,620],'action_flags_rewards_unchanged':True}],
 'portal_local_position_migrations':[{'old_local_source_foot_px':[153.6,819.2],'new_local_source_foot_px':[170,980],'target_action_flags_unchanged':True},{'old_local_source_foot_px':[337.92,819.2],'new_local_source_foot_px':[350,980],'target_action_flags_unchanged':True}],
 'new_routes_source_px':[{'id':'central_forecourt_to_south_ring','points_px':[[768,737.28],[768,960],[170,960],[170,980]]},{'id':'south_ring_to_second_portal','points_px':[[170,960],[350,960],[350,980]]},{'id':'bell_front_relocated','points_px':[[920,620],[1080,620],[1320,620]]}],
 'preserved_default_source_foot_px':[768,737.28], 'preserved_NPC_source_feet':[[600,900],[936,900]],
 'preserve':['temple_main_hall foot768520 scale.56 exact source and screen roof fit','broken Buddha stone mechanism/paper hint/cave and ambush identities','all original action/flags/quest/reward data','all existing room geometry','all old routes not intersecting new union'],
 'landscape_purpose_bands':[{'rect_xywh':[16,80,160,650],'purpose':'旧竹林外缘接西调查支路，留草土肩而非围成死墙'},{'rect_xywh':[1360,80,160,650],'purpose':'钟院东竹径与后绕线，保940/430机关接近支路'},{'rect_xywh':[560,900,620,108],'purpose':'香客停留/两僧前庭，原两僧不新造剧情；新香客身份由System/ART另给'}],
 'door_height_world_source_expression':{'expression':'355 * 0.33 * 1.25','value':355*.33*1.25,'not_transparent_doorway_or_Field_credit':True},
 'closed_domain_budget_source_xywh':[[170,590,520,315],[860,590,520,315],[35,900,190,100],[1200,520,250,180],[120,940,690,68]],
 'domain_status':'CONSERVATIVE_CANDIDATE; merge by closed integer intersection after exact old/new primitives, only new/changed routes sampled'}

regions=[
 {'scene_id':'ch4_s0_luoyang_gate','label':'南门/主街南段','adopted':['C Gate native28','DT stock11 additions','Field refined Gate/moat/bridge configure'],'NPC':base_npcs['ch4_s0_luoyang_gate'],'door_state':'已有World/Gate等连接保持；不是没有桥。主楼/角楼/护城河保，撤错误街楼原型而不是盲放大','ground':'旧真实官道/桥石与地面层，候检两院和主街边界尚断续','gap':'军需/候检真实侧院与两侧街墙、车货排队、普通旅人职业生活，非补几个箱子','batch':'01_gate_yamen_main_axis'},
 {'scene_id':'ch4_s1_luoyang_yamen','label':'府衙/主街北段','adopted':['C finite native27','DT original10 delta rows','24c courts40 combined-ground (not visual count)','two actual official annexes .5 and G mainhall'],'NPC':{'base':base_npcs['ch4_s1_luoyang_yamen'],'district_crowd':dg['districts']['ch4_s1_luoyang_yamen']['crowd']},'door_state':'1536,660正堂与1536,1700仪门等保持，柱后/橙箭头不重做','ground':'礼制轴与两侧服务院仍断开，现有候审凳/代书桌已有真实用途','gap':'书吏档案房—差役院后体和回廊关联，生活与办事前庭，不再大灰广场','batch':'01_gate_yamen_main_axis'},
 {'scene_id':'ch4_s2_canal_docks','label':'码头','adopted':['B/AA/AC native29 restored first','DT frontage39 NAV /35solid same mask lease','shore and worker layer existing'],'NPC':{'base':base_npcs['ch4_s2_canal_docks'],'note':'另有harbour role/crowd layer，不用原Scene的3人冒最终总数'},'door_state':'两铺145门/仓638610真实进返已过，保三body/door，不重测','ground':'湿石/木板/货路有限层已采用；岸线整体装卸序列未完成','gap':'沿现货路外侧补记货—卸货—短储三连续工作湾与岸肩，保中央运输环','adjacent_finish':{'planning_domains_world_xywh':[[1040,1050,760,750],[1800,1480,900,440]],'purpose':'复用仓架/粮袋/手推车/低棚，连接既有码头任务货位；不得挡船工路线/三门','new_geometry':'only added true post/low-prop bases and union mask domains; shore native not rebaked'}},
 {'scene_id':'ch4_s3_luoyang_market','label':'南市','adopted':['24b full two shop native25 + strict worker four facts','24e whole37→43','25g whole43→45 child lease','25f six ground materials','25h four indoor services share G'],'NPC':{'base':base_npcs['ch4_s3_luoyang_market'],'note':'真实末端还经Culture/25e migrations/25g preserved interactions；不把旧DG10脚直接当当前脚'},'door_state':'六铺与两外门、remembered阈值/12室内保；服务已真实通过，不重做','ground':'五用途/cleanbase已正式，但局部后体/铺边硬接仍未整体ART准','gap':'连接客栈及两后院北界/西街门庭，让后街为工作巷而非孤楼背面','adjacent_finish':{'planning_domains_world_xywh':[[80,230,950,930],[80,1440,860,520]],'purpose':'客栈后勤/马料与街沿后体的用途连接，只相邻缺域；东两作业院45原值全保','protected_interactions':['armory_old_record','paper_birdseal','xuantong_note','zhao_medicine_parcel']}},
 {'scene_id':'luoyang_artisan_residential_20261022ap','label':'百工＋民居同一外场','adopted':['Family A2_CBC3 and life_FF97 child136/31','five full building rows (not136 houses)','four source-bound real quarter people'],'NPC':[r for r in people['people'] if r['scene_id']=='luoyang_artisan_residential_20261022ap'],'door_state':'三旧住宅/木作room ID保；本作者明确迁三门和冷返脚，不重编室内','ground':'118ground tiles主要全屏同石；锅灶/水井/木染/铁陶应分职业前庭','gap':'完整三层复合街坊，真实铁作/陶坊/灶屋身份缺口，环形主支巷与生活庭院','batch':'02_artisan_residential_complete_block'},
 {'scene_id':'luoyang_estate_riverside_20261021ai','label':'宅园','adopted':['Estate formal manifest/family and111visual48solid','独立宅门/正厅/两厢/两廊/AN白墙/双牡丹花床'],'NPC':'必须从Estate当前Scene/族人overlay分别核，不把原native111视觉表当人口；无本轮活人数声明','door_state':'南市26101860→宅园→主厅1536544与南出口15361940保','ground':'前庭/镜像重复与草地尚空；已过宅门/廊不得重编','gap':'外东南仆役作业院、家祠职责与主人/仆人空间区分，不凭新楼贴家祠名牌','adjacent_finish':{'planning_domains_world_xywh':[[1850,1300,1080,610],[180,1300,900,610]],'purpose':'厨灶/洗晒仆役院与安静祭祀廊侧庭；保1536中轴与两真实开放回廊','resource_gap':'家祠须有明确祭祀陈设/源身份，现main_hall不能复制两栋就冒家祠完成'}},
 {'scene_id':'luoyang_riverside_garden_20261022ap','label':'沿河园林','adopted':['Family garden_river ready binding7ECB','new56visual16solid /2ports /4NPC','complete stone bridge ground layer + exact original Atlas front rail'],'NPC':[r for r in people['people'] if r['scene_id']=='luoyang_riverside_garden_20261022ap'],'door_state':'桥880976→2192976和两水负控已过，保两南门/桥/亭760760/茶楼2520650','ground':'河岸/硬T路与大片草地仍待，不能用216/0冒整园林完成','gap':'两岸草石肩、曲径和树花组团通向现亭/茶楼，老人游人停留而非四人孤立','adjacent_finish':{'planning_domains_world_xywh':[[400,1180,720,430],[2160,900,760,600]],'purpose':'不侵新water pieces/完整deck的两岸软过渡与茶楼前庭，保原桥域；新花木若solid独立记树脚','bridge_or_native_replay':False}},
 {'scene_id':'ch4_s4_ancient_temple','label':'城外古寺','adopted':['Temple FORMAL_ENABLED source-bound assembly21 placements','source1536×1024 to world1920×1280','current two task monks and six interactions'],'NPC':base_npcs['ch4_s4_ancient_temple'],'door_state':'原两外连接local foot本批允许源式迁；target/flags/actions不动；没有新殿内景','ground':'同一庭砖+稀疏边竹；须前院/僧舍/钟院/调查林径明确层级','gap':'本作者两完整成人僧舍/经务外观+前庭环路，另连竹径/香客停留，不授加两楼即完成','batch':'03_temple_front_courts_and_loop'}]

audit={**common,'status':'CURRENT_ADOPTED_EIGHT_FIELDS_AND_REMAINING_WORK_READONLY','regions':regions,'eight_fields_not_ten_scenes':True,'native_projection_limit':'24b readback only authoritative for unchanged parent packets; current terminal Market/Docks/Yamen/Garden overrides stated separately, never overwrite historical table','fixed_sources_read':reads,'formal_consumers':[code_pin('res://scripts/field/field_walkable_controller.gd'),code_pin('res://scripts/city/luoyang_assembled_interiors_20261016g.gd'),code_pin('res://scripts/city/luoyang_quarters_family_20261022ap.gd'),code_pin('res://scripts/city/luoyang_temple_assembly_20261016.gd'),code_pin('res://scripts/city/luoyang_district_life_20261016f.gd')],'all_regions_whole_ART_pass':False,'resource_gaps':['open Chinese forge/repair working building','pottery kiln and complete workshop','ordinary kitchen/residential rear body'],'not_asset_existence_as_adoption':True}
rules={'A1_transparent_margin_each_side_min_fraction':.10,'light':'match current Luoyang upper-left daylight, neutral grey tiles; no separate night/fire-only global light','view':'complete front-biased25D slight top-down, full roof/sidewalls/base; no sprite people/text/extra framing','source_measurements_required':['source size','A1 exact bounds including detached nonzero alpha','front ground anchor','door rectangle/threshold (not stair toe)','complete visible plinth polygons','separate kiln/forge post/body polygons'],'no_fit_canvas_shrink':True,'no_stretch_rotate_mirror_or_pixel_clean_without_user_authorization':True,'all_runtime_and_ART_credit':False}
art_lots={**common,'status':'THREE_COMPLETE_MODULE_ART_CONSTRAINTS_NOT_ASSET_ADMISSION','shared':rules,'three':craft['new_asset_lots']}
assets_pin=output('reuse_asset_library01_SOURCE_ONLY.json',{'status':'EXISTING_WHOLE_MODULE_SOURCE_CONTRACTS_NOT_NEW_LAYOUT_PASS','assets':assets,'fixed_source_reads':reads})
for a in (gate,craft,temple_group): a['reuse_library']=assets_pin
results=[assets_pin,output('current_eight_fields_remaining_READONLY.json',audit),output('author_gate_yamen_axis01_NOTREADY.json',gate),output('author_artisan_residential_block01_NOTREADY.json',craft),output('author_temple_courts_loop01_NOTREADY.json',temple_group),output('art_three_complete_modules01_NOTREADY.json',art_lots)]
index={'status':'EIGHT_FIELD_FINISH_PLAN_PRIORITY_THREE_AUTHORS_NOT_PUBLICATION','ready':False,'parent_stage':STAGE,'parent_guard':GUARD,'files':results,'deployment_policy':'One final source phase after independent new-domain priors/publication/media/limited overview, not one28successor per courtyard','geometry_validation_credit':False,'old_875x17_room_bridge_service_replay':False,'necessary_future_consumers':['C/DT/Field/G only if exact new physical lease/scalars require','Family/NativeGeometry/material runtime for Artisan new native','Temple source-bound complete author successor and two local portal feet','ENV only new-purpose drawing selector/pins, no generic opacity bypass','System final NPC/portrait/dialog mapper source list; no task changes'],'blockers':['Root/ART new three actual complete sources and correct source-ground/door metadata','Gate exact old retired body primitives from fixed parent record (readback visual-only is insufficient)','new-domain union/prior/retained-primitive inverse and NPC full bodies','three same room return scalars/two Temple local portals exact functional mapping','remaining five adjacent-domain authors before final acceptance; no zone declared done']}
pin=output('city_finish25i_author_index_NOTREADY.json',index)
print(json.dumps({'index':pin,'files':results,'canonical_writes':0,'engine_calls':0,'collector_calls':0},ensure_ascii=False))
