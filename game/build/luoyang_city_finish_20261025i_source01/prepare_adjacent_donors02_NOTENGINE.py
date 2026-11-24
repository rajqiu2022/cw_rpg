"""Fix adopted-use donor contracts and small adjacent additions; no pixels/engine."""
from pathlib import Path
import copy,hashlib,json,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,p
 return json.loads(b)
def emit(n,v):
 b=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with (HERE/n).open('xb') as stream:stream.write(b)
 return {'path':NS+n,'sha256':sha(b),'bytes':len(b)}
def f(x):return struct.unpack('<f',struct.pack('<f',float(x)))[0]
stage=read('res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json','ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
auth={}
for key,row in stage['nodes'].items():
 if key.startswith('expected_'):
  for path,h in row['value']['source_sha256'].items():
   assert path not in auth or auth[path]==h;auth[path]=h
for row in stage['targets']:auth[row['target']]=row['candidate_sha256']
def fixed(p):return read(p,auth[p])
def pin(p):return {'path':p,'sha256':auth[p]}
lib=read(NS+'reuse_asset_library01_SOURCE_ONLY.json','17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d')
lib=copy.deepcopy(lib);lib['parent_library']={'path':NS+'reuse_asset_library01_SOURCE_ONLY.json','sha256':'17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d'}
roomp='res://data/maps/luoyang_layout_rooms_20261018t/luoyang_canal_warehouse_interior_20261016/author.json';room=fixed(roomp)
for asset in ['grain_sack_stack_v1','wood_handcart_v1','writing_desk_v1']:
 donor=next(x for x in room['furniture'] if x['asset_id']==asset)
 assert auth[donor['texture']]==donor['source_sha256']
 lib['assets'][asset]={'texture':donor['texture'],'source_sha256':donor['source_sha256'],
  'source_size_px':donor['source_size_px'],'source_ground_anchor_px':donor['source_ground_anchor_px'],
  'source_solid_polygons_px':donor['source_ground_solid_polygons_px'],'source_solid_rects_px':[],
  'donor':pin(roomp),'donor_selector':{'furniture_asset_id':asset},'no_rotate_mirror_crop_or_pixel_edit':True}
gp='res://build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/author_READY.json';garden=fixed(gp)
for asset in ['tree','flowerbed']:
 donor=garden['assets'][asset];lib['assets']['garden_'+asset]={'texture':donor['texture'],'source_sha256':auth[donor['texture']],
  'source_size_px':donor['source_size'],'source_ground_anchor_px':donor['ground_anchor'],
  'source_solid_polygons_px':donor.get('solid_polygons',[]),'source_solid_rects_px':donor['solid_rects'],
  'alpha_bbox_xywh':donor['used_rect'],'donor':pin(gp),'donor_selector':['assets',asset],
  'no_rotate_mirror_crop_or_pixel_edit':True}
tp='res://data/maps/luoyang_temple_assembly_20261016/author.json';temple=fixed(tp)
altar=next(x for x in temple['assets'] if x['id']=='altar')
old=next(x for x in temple['placements'] if x['asset_id']=='altar')
bases=[x['ground_polygon_px'] for x in temple['geometry']['furniture_bases'] if x['id']==old['id']]
assert len(bases)==1 and auth[altar['texture']]==altar['source_sha256']
lib['assets']['ancestral_incense_altar']={'texture':altar['texture'],'source_sha256':altar['source_sha256'],
 'source_size_px':altar['size_px'],'source_ground_anchor_px':altar['source_ground_anchor_px'],
 'source_solid_polygons_px':[],'source_solid_rects_px':[],
 'donor_ground_polygons_px':bases,'donor_foot_px':old['foot_px'],'donor_scale':old['scale'],
 'donor':pin(tp),'donor_selector':['geometry','furniture_bases',old['id']],
 'purpose':'Existing low incense stone table, no deity/statue or new interior service',
 'no_rotate_mirror_crop_or_pixel_edit':True}
lp=emit('adjacent_adopted_asset_library02_SOURCE_ONLY.json',lib)
author=read(NS+'author_adjacent_four_fields01_NOTREADY.json','508c99a587d1edb25f9d9ccab5f1b50fd9d420979ecd342fc069ece7aafd6f15')
author['reuse_library']=lp
def place(id,asset,foot,scale,purpose):
 return {'id':id,'asset_id':asset,'foot_px':foot,'scale':scale,'purpose':purpose,'enters_new_room':False}
for s in author['scenes']:
 sid=s['scene_id'];s.setdefault('placements',[])
 if sid=='ch4_s3_luoyang_market':
  s['placements'] += [place('finish_i_inn_supplies_sacks','grain_sack_stack_v1',[420,840],.12,'Inn grain/forage stores inside rear-service gallery'),place('finish_i_inn_service_handcart','wood_handcart_v1',[710,840],.14,'Inn delivery handcart, not a new quest reward')]
  s['purpose_station_source_points']=[{'id':'inn_delivery_wait','foot_px':[560,930],'existing_NPC_migrated':False,'purpose':'Short delivery pause/check point, no invented interactive NPC'}]
 elif sid=='luoyang_estate_riverside_20261021ai':
  s['placements'] += [place('finish_i_ancestral_incense_table','ancestral_incense_altar',[650,1810],.15,'Family incense forecourt; existing actual low altar'),place('finish_i_servants_supply_cart','wood_handcart_v1',[2390,1730],.14,'Servants kitchen/wash courtyard supply tool')]
  s['purpose_courts'][0]['purpose']='Family incense/commemoration forecourt with source-bound existing incense table; no new room or service'
  s['purpose_station_source_points']=[{'id':'family_commemoration_front','foot_px':[650,1860],'existing_NPC_migrated':False},{'id':'servants_supply_front','foot_px':[2520,1780],'existing_NPC_migrated':False}]
 elif sid=='luoyang_riverside_garden_20261022ap':
  s['placements'] += [place('finish_i_west_bank_peonies_a','garden_flowerbed',[620,1310],.14,'Low adopted peony bed beside path, not on bridge deck'),place('finish_i_west_bank_peonies_b','garden_flowerbed',[800,1450],.14,'Second bank flower grouping outside walking strip'),place('finish_i_teacourt_shade_tree','garden_tree',[2670,1520],.8,'Adopted tree with original small trunk footprint')]
  s.pop('plant_groups',None)
 elif sid=='ch4_s2_canal_docks':
  s['placements'] += [place('finish_i_docks_tally_desk','writing_desk_v1',[1180,1240],.16,'Cargo manifest/tally desk, not a weighing-scale asset'),place('finish_i_docks_pack_sacks','grain_sack_stack_v1',[1810,1700],.12,'Packing stock under existing open gallery'),place('finish_i_docks_pack_handcart','wood_handcart_v1',[2050,1700],.14,'Covered packing/loading handcart'),place('finish_i_docks_short_storage_sacks','grain_sack_stack_v1',[2490,1680],.14,'Small ordered dry temporary goods stack')]
  s['purpose']='Connected cargo tally, packing and short-storage courts; do not mislabel a desk as an actual scale'
  s['work_bays'][1]['purpose']='Cargo packing/tally before weighing; no physical scale claimed'
  s['purpose_station_source_points']=[{'id':'cargo_tally_front','foot_px':[1180,1300],'existing_NPC_migrated':False},{'id':'packing_gallery_front','foot_px':[1850,1830],'existing_NPC_migrated':False},{'id':'short_storage_front','foot_px':[2490,1780],'existing_NPC_migrated':False}]
 for p in s['placements']:
  a=lib['assets'][p['asset_id']];foot=p['foot_px'];scale=float(p['scale']);polys=[]
  for raw in a.get('source_solid_polygons_px',[]):polys.append([[f(f(foot[i])+f(f(f(q[i])-f(a['source_ground_anchor_px'][i]))*scale)) for i in range(2)] for q in raw])
  for x,y,w,h in a.get('source_solid_rects_px',[]):
   polys.append([[f(f(foot[i])+f(f(f(q[i])-f(a['source_ground_anchor_px'][i]))*scale)) for i in range(2)] for q in [[x,y],[x+w,y],[x+w,y+h],[x,y+h]]])
  for raw in a.get('donor_ground_polygons_px',[]):polys.append([[f(f(foot[i])+f(f(f(q[i])-f(a['donor_foot_px'][i]))*(scale/float(a['donor_scale'])))) for i in range(2)] for q in raw])
  p['source_derived_new_ground_polygons_f32']=polys;p['polygon_PIP_Physics_or_mask_credit']=False
 s['new_domain_status']='Source donor and f32 contact expression fixed; parent-exact local domains and independent QA pending'
author['new_asset_gaps']=['Exact visible weighing-scale asset not found among adopted modules; this batch claims cargo tally/packing only','Kitchen processed PNG permission/import pending, raw data not prematurely published']
print(json.dumps({'library':lp,'author':emit('author_adjacent_four_fields02_fixed_donors_NOTREADY.json',author)},ensure_ascii=False))
