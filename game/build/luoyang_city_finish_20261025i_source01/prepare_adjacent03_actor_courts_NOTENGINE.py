"""ROOT-approved actual-use actors and wash/dry tools; no pixel modification."""
from pathlib import Path
import copy,hashlib,json,struct
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,p
 return json.loads(b)
def emit(n,v):
 b=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with (N/n).open('xb') as stream:stream.write(b)
 return {'path':NS+n,'sha256':sha(b),'bytes':len(b)}
def f(x):return struct.unpack('<f',struct.pack('<f',float(x)))[0]
lib=load(NS+'adjacent_adopted_asset_library02_SOURCE_ONLY.json','9a8813fe467f343aba834656da556212fcaca29aba3749412274b353b29f3452')
author=load(NS+'author_adjacent_four_fields02_fixed_donors_NOTREADY.json','3925708313117f9716183f77e88558513d6daddf679f1cf7750abfecc8fef3dc')
a2p='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json';a2h='1dd5a3949e36ecbada0b4a73f2c109cc1561572b64e3cd8a3e49fa4e2c21df09';a2=load(a2p,a2h)
lp='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json';lh='03f0a7fd0b71b2657fa783b253d86001813897f0f16e44793f866d09cce7a9f4';life=load(lp,lh)
for key,row in lib['assets'].items():
 if 'ground_solid_polygons_px' in row:row['source_solid_polygons_px']=copy.deepcopy(row['ground_solid_polygons_px'])
tub=next(x for x in life['placements'] if x['id']=='ap_life_dye_rinse_tub_a')
lib['assets']['wood_wash_tub']={'texture':tub['texture'],'source_sha256':tub['source_png_sha256'],'source_size_px':tub['source_size_px'],'source_ground_anchor_px':tub['source_ground_anchor_px'],'source_solid_polygons_px':tub['source_ground_solid_polygons_px'],'source_solid_rects_px':[],'donor':{'path':lp,'sha256':lh},'purpose':'Existing wooden open rinse tub reused for household washing, not a new forge'}
rack=a2['assets']['cloth_rack']
lib['assets']['household_drying_rack']={'texture':rack['texture'],'source_size_px':rack['source_size'],'source_ground_anchor_px':rack['ground_anchor'],'source_solid_polygons_px':rack.get('solid_polygons',[]),'source_solid_rects_px':rack['solid_rects'],'alpha_bbox_xywh':rack['used_rect'],'source_rect_transform_order':'low_then_scaled_size_high','donor':{'path':a2p,'sha256':a2h},'purpose':'Existing whole drying rack, not an invented laundry service'}
# Source value for the rack is inherited from the fixed A2 source table, never current-file fill.
lib['assets']['household_drying_rack']['source_sha256']=a2['source_sha256'][rack['texture']]
bench=next(x for x in life['placements'] if x['id']=='ap_life_well_wait_bench')
lib['assets']['garden_rest_bench']={'texture':bench['texture'],'source_sha256':bench['source_png_sha256'],'source_size_px':bench['source_size_px'],'source_ground_anchor_px':bench['source_ground_anchor_px'],'source_solid_polygons_px':bench['source_ground_solid_polygons_px'],'source_solid_rects_px':[],'donor':{'path':lp,'sha256':lh},'purpose':'Existing low rest bench at tea-garden shade'}
resident=load(NS+'estate_two_residents_lore02_hero_first_NOTREADY.json','11a51cab1c53a25eeec5cd8fdbb528f7d7ad44187d8fcdffe2b3d8d3ca6d8a14')
def add(id,asset,foot,scale,purpose):return {'id':id,'asset_id':asset,'foot_px':foot,'scale':scale,'purpose':purpose,'enters_new_room':False}
def domain(foot):return [foot[0]-24,foot[1]-24,foot[0]+24,foot[1]+64]
def migration(id,old,new):
 return {'npc_id':id,'old_source_origin_px':old,'new_source_origin_px':new,'same_identity_dialog_task_action_body_scale_speed_mode_and_patrol_distance':True,'old_dynamic_NPC_guard_domain_xyxy':domain(old),'new_dynamic_NPC_guard_domain_xyxy':domain(new),'domain_kind':'Conservative footprint-query/swept-actor review domain, NOT a static mask hole or an asserted actual collider','static_mask_raster_change_from_NPC_itself':False,'actual_final_consumer':'Normal + warm final NPC rows after all historic overrides, immediately before spawn/refresh'}
for s in author['scenes']:
 sid=s['scene_id'];s.pop('purpose_station_source_points',None)
 if sid=='ch4_s3_luoyang_market':
  s['placements']=[p for p in s['placements'] if p['id']!='finish_i_market_inn_supply_gallery']
  next(p for p in s['placements'] if p['id']=='finish_i_inn_supplies_sacks')['foot_px']=[420,740]
  next(p for p in s['placements'] if p['id']=='finish_i_inn_service_handcart')['foot_px']=[710,750]
  s['placements'] += [add('finish_i_inn_low_boundary_west','low_wall',[330,855],.5,'Low courtyard edge; central145px opening'),add('finish_i_inn_low_boundary_east','low_wall',[790,855],.5,'Low courtyard edge; do not intrude on main street')]
  s['npc_migrations']=[migration('market_traveller',[2260,1880],[760,800])]
  s['ground_purpose_rows']=[{'id':'inn_delivery_court','rect_xywh':[180,640,770,232],'texture_role':'Existing courtyard stone with narrow earth service shoulder','use':'Real grain/cart and waiting traveller, not an undersized standing gallery'}]
  s['source_clearance_basis']={'inn_A1_bottom':624.18,'apothecary_A1_top':894.8262195121952,'available_vertical':270.6462195121952,'unpublished_gallery_removed_not_shrunk':True,'low_wall_real_clear_opening_px':145}
 elif sid=='luoyang_estate_riverside_20261021ai':
  s['placements'] += [add('finish_i_servants_wash_tub','wood_wash_tub',[2600,1740],.085,'Real wooden washing tub in servants court'),add('finish_i_servants_drying_rack','household_drying_rack',[2760,1760],270/float(rack['used_rect'][2]),'Actual drying rack paired with basin and kitchen')]
  s['new_NPC_rows']=copy.deepcopy(resident['rows']);s['new_NPC_lore_author']={'path':NS+'estate_two_residents_lore02_hero_first_NOTREADY.json','sha256':'11a51cab1c53a25eeec5cd8fdbb528f7d7ad44187d8fcdffe2b3d8d3ca6d8a14'}
  s['new_NPC_count']=2;s['old_NPC_count']=0
  for row in s['new_NPC_rows']:row['new_dynamic_NPC_guard_domain_xyxy']=domain(row['foot_px'])
 elif sid=='luoyang_riverside_garden_20261022ap':
  s['placements'] += [add('finish_i_teacourt_low_bench','garden_rest_bench',[2520,1600],float(bench['uniform_scale']),'Actual low bench on tea-garden side, outside bridge and four existing NPC approaches')]
 elif sid=='ch4_s2_canal_docks':
  s['npc_migrations']=[migration('harbour_life_docks_booking_attendant',[2010,1900],[1180,1300]),migration('harbour_life_docks_loading_attendant',[2000,1430],[2060,1840])]
  s['work_bays'][0]['actual_assigned_existing_npc']='harbour_life_docks_booking_attendant'
  s['work_bays'][1]['actual_assigned_existing_npc']='harbour_life_docks_loading_attendant'
 for p in s['placements']:
  a=lib['assets'][p['asset_id']];foot=p['foot_px'];scale=float(p['scale']);polys=[]
  def project(q):return [f(f(foot[i])+f(f(f(q[i])-f(a['source_ground_anchor_px'][i]))*scale)) for i in range(2)]
  for raw in a.get('source_solid_polygons_px',[]):polys.append([project(q) for q in raw])
  for x,y,w,h in a.get('source_solid_rects_px',[]):
   if a.get('source_rect_transform_order')=='low_then_scaled_size_high':
    low=project([x,y]);high=[f(low[i]+f([w,h][i]*scale)) for i in range(2)];polys.append([low,[high[0],low[1]],high,[low[0],high[1]]])
   else:polys.append([project(q) for q in [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]])
  for raw in a.get('donor_ground_polygons_px',[]):polys.append([[f(f(foot[i])+f(f(f(q[i])-f(a['donor_foot_px'][i]))*(scale/float(a['donor_scale'])))) for i in range(2)] for q in raw])
  p['source_derived_new_ground_polygons_f32']=polys;p['polygon_PIP_Physics_or_mask_credit']=False
 s['purpose_rects_are_not_claimed_materialized']=True;s['actual_purpose_material_renderer_pending']=True
author['reuse_library']=emit('adjacent_adopted_asset_library03_SOURCE_ONLY.json',lib)
author['same_id_NPC_migration_and_new_Estate_NPC_acceptance']='Independent old/new dynamic body, final consumer and affected approaches required; no silent move/resize, no static-mask holes'
print(json.dumps({'library':author['reuse_library'],'author':emit('author_adjacent_four_fields03_actual_courts_NPC_NOTREADY.json',author)},ensure_ascii=False))
