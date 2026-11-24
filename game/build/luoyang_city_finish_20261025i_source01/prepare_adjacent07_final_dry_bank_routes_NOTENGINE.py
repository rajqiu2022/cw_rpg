from pathlib import Path
import copy,hashlib,json,math,struct
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def point(q,foot,anchor,ratio):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(ratio))) for i in range(2)]
def emit(name,a):
 b=(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def domain(polys):
 points=[p for poly in polys for p in poly]
 return [math.floor(min(p[0] for p in points))-1,math.floor(min(p[1] for p in points))-1,math.ceil(max(p[0] for p in points))+1,math.ceil(max(p[1] for p in points))+1]
raw=(N/'author_adjacent_four_fields06_remaining_routes_dry_stack_NOTREADY.json').read_bytes()
assert sha(raw)=='bf8b725ea92e82657d07c0563f4f77b3483cfb23f31c4c93134f707b69cb3c13'
parent=json.loads(raw);a=copy.deepcopy(parent);library=json.loads((N/'adjacent_adopted_asset_library03_SOURCE_ONLY.json').read_text(encoding='utf8'))
docks=next(s for s in a['scenes'] if s['scene_id']=='ch4_s2_canal_docks')
routes={r['id']:r for r in docks['new_source_routes']}
routes['booking_to_cargo_lane']['points_px']=[[1180,1348],[1280,1348],[1280,1910],[1430,1910]]
routes['short_storage_front']['points_px']=[[2060,1910],[2000,1910],[2000,2000],[2120,2000]]
row=next(r for r in docks['placements'] if r['id']=='finish_i_docks_short_storage_sacks');asset=library['assets'][row['asset_id']]
row['foot_px']=[2120,1960];polys=[]
for poly in asset.get('source_solid_polygons_px',[]):polys.append([point(p,row['foot_px'],asset['source_ground_anchor_px'],row['scale']) for p in poly])
for poly in asset.get('donor_ground_polygons_px',[]):polys.append([point(p,row['foot_px'],asset['donor_foot_px'],row['scale']/asset['donor_scale']) for p in poly])
row['source_derived_new_ground_polygons_f32']=polys
if 'source_derived_bound_xyxy_f32' in row:row['source_derived_bound_xyxy_f32']=[*point([0,0],row['foot_px'],asset['source_ground_anchor_px'],row['scale']),*point(asset['source_size_px'],row['foot_px'],asset['source_ground_anchor_px'],row['scale'])]
contract=a.pop('remaining06_contract');a['remaining07_contract']=contract
contract['superseded06']={'path':NS+'author_adjacent_four_fields06_remaining_routes_dry_stack_NOTREADY.json','sha256':sha(raw),'retained_not_used_for_new_independent_expected':True}
for change in contract['four_route_changes']:
 scene=next(s for s in a['scenes'] if s['scene_id']==change['scene_id']);change['new']=copy.deepcopy(next(r for r in scene['new_source_routes'] if r['id']==change['route_id']))
stack=contract['unpublished_stack_only_spatial_change'];stack['new']=copy.deepcopy(row);stack['new_polygons']=polys;stack['old_new_closed_domain_xyxy']=domain(stack['old_polygons']+polys);stack['separate_changed_shape_domains']=[domain(stack['old_polygons']),domain(polys)]
stack['reason']='Root-approved21201960 fully dry-bank candidate, keeping original packing endpoint20601910 clear. Old21401910 proposal retained06 but not used.'
stack['source_expression']='Original donor source polygon unchanged scale; final foot21201960, not oldworldpoly+delta'
# Recheck intersection classification for the four original passed routes, not replay.
fixed05=json.loads((N/'author_adjacent_four_fields05_routes_NOTREADY.json').read_text(encoding='utf8'))
passed={'ancestral_keeper_approach','wash_court_worker_approach','east_bank_soft_path','packing_attendant_approach'}
inheritance=[]
for scene in a['scenes']:
 oldscene=next(s for s in fixed05['scenes'] if s['scene_id']==scene['scene_id'])
 for route in scene['new_source_routes']:
  if route['id'] not in passed:continue
  old=next(r for r in oldscene['new_source_routes'] if r['id']==route['id']);assert route==old
  points=route['points_px'];bbox=[min(p[0] for p in points)-17,min(p[1] for p in points)-12,max(p[0] for p in points)+17,max(p[1] for p in points)+12]
  affected=[]
  candidate_domains=[]
  if scene['scene_id']=='ch4_s2_canal_docks':candidate_domains=stack['separate_changed_shape_domains']
  elif scene['scene_id']=='luoyang_estate_riverside_20261021ai':candidate_domains=[contract['Estate_extra_kitchen_geometry']['new_closed_domain_xyxy']]
  for d in candidate_domains:
   if bbox[0]<=d[2] and bbox[2]>=d[0] and bbox[1]<=d[3] and bbox[3]>=d[1]:affected.append(d)
  assert not affected,(route['id'],bbox,affected)
  inheritance.append({'scene_id':scene['scene_id'],'route_id':route['id'],'exact_whole_row_equal_to_passed05':True,'swept_body_bbox_xyxy':bbox,'new_static_delta_domains_tested':candidate_domains,'intersects_new_static_delta':False,'route_geometry_or_NPC_replay':False})
assert len(inheritance)==4
contract['original_passed_four_route_inheritance']=inheritance
pin=emit('author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json',a)
back=copy.deepcopy(a);back['remaining06_contract']=copy.deepcopy(parent['remaining06_contract']);del back['remaining07_contract']
old_docks=next(s for s in parent['scenes'] if s['scene_id']=='ch4_s2_canal_docks')
back_docks=next(s for s in back['scenes'] if s['scene_id']=='ch4_s2_canal_docks');back_docks['new_source_routes']=copy.deepcopy(old_docks['new_source_routes']);back_docks['placements']=copy.deepcopy(old_docks['placements'])
assert back==parent
proof=emit('adjacent07_final_dry_bank_routes_full_inverse_BUILD.json',{'status':'ROOT_APPROVED_SOURCE_RESIDUAL_PENDING_INDEPENDENT_QA','author':pin,'full_typed_inverse_to06':True,'old_all_four_passed_routes_retained_exact':inheritance,'new_stack':stack,'four_remaining_routes':[c['new'] for c in contract['four_route_changes']],'Estate_kitchen':contract['Estate_extra_kitchen_geometry'],'no_early_publication_or_independent_pass_claim':True,'engine_calls':0,'canonical_writes':0})
print(json.dumps({'author':pin,'proof':proof,'stack_domains':stack['separate_changed_shape_domains']}))
