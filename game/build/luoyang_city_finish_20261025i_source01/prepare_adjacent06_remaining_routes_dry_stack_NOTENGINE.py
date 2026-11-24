"""Root-approved four route residuals, one unpublished dry-bank stack migration.
Adds the separately consumed Estate kitchen source contact to the QA contract.
"""
from pathlib import Path
import copy,hashlib,json,math,struct
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def p(q,foot,anchor,ratio):return [f(f(foot[i])+f(f(f(q[i])-f(anchor[i]))*f(ratio))) for i in range(2)]
def emit(name,a):
 b=(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
 with (N/name).open('xb') as s:s.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
raw=(N/'author_adjacent_four_fields05_routes_NOTREADY.json').read_bytes()
assert sha(raw)=='8b1825f064a2b7287e70329c30000db6daaf2ce5afccb688676b563c84817377'
parent=json.loads(raw);a=copy.deepcopy(parent);changes=[]
replacements={'inn_work_court_to_traveller_approach':[[560,880],[560,800],[712,800]],'west_bank_soft_path':[[520,1520],[640,1520],[640,1420],[740,1360],[740,1160],[860,1160]],'booking_to_cargo_lane':[[1180,1348],[1280,1348],[1280,1540],[1430,1540],[1430,1910]],'short_storage_front':[[2060,1910],[2060,1960],[2140,1960]]}
for scene in a['scenes']:
 for route in scene['new_source_routes']:
  if route['id'] in replacements:
   changes.append({'scene_id':scene['scene_id'],'route_id':route['id'],'old':copy.deepcopy(route)})
   route['points_px']=replacements[route['id']]
   route['scope']='Root-approved remaining-only source route after concrete wall/tree/notice/dry-bank failures; independent result PENDING. Original wholeFAIL retained.'
   changes[-1]['new']=copy.deepcopy(route)
library=json.loads((N/'adjacent_adopted_asset_library03_SOURCE_ONLY.json').read_text(encoding='utf8'))
docks=next(s for s in a['scenes'] if s['scene_id']=='ch4_s2_canal_docks')
matches=[r for r in docks['placements'] if r['foot_px']==[2490,1680]];assert len(matches)==1
stack=matches[0];oldstack=copy.deepcopy(stack);asset=library['assets'][stack['asset_id']]
newfoot=[2140,1910];polys=[]
for rawpoly in asset.get('source_solid_polygons_px',[]):polys.append([p(q,newfoot,asset['source_ground_anchor_px'],stack['scale']) for q in rawpoly])
for rawpoly in asset.get('donor_ground_polygons_px',[]):polys.append([p(q,newfoot,asset['donor_foot_px'],stack['scale']/asset['donor_scale']) for q in rawpoly])
assert len(polys)==len(stack['source_derived_new_ground_polygons_f32'])==1
stack['foot_px']=newfoot;stack['source_derived_new_ground_polygons_f32']=polys
if 'source_derived_bound_xyxy_f32' in stack:
 stack['source_derived_bound_xyxy_f32']=[*p([0,0],newfoot,asset['source_ground_anchor_px'],stack['scale']),*p(asset['source_size_px'],newfoot,asset['source_ground_anchor_px'],stack['scale'])]
stack_change={'old':oldstack,'new':copy.deepcopy(stack),'reason':'Unpublished old24901680 lies beyond existing dry-bank support; no original water mask, NPC or existing structure modified','old_polygons':oldstack['source_derived_new_ground_polygons_f32'],'new_polygons':polys,'source_expression':'Original donor ground + unchanged scale; only foot24901680->21401910, never oldworldpoly+delta'}
def domain(shapes):
 pts=[q for poly in shapes for q in poly]
 return [math.floor(min(q[0] for q in pts))-1,math.floor(min(q[1] for q in pts))-1,math.ceil(max(q[0] for q in pts))+1,math.ceil(max(q[1] for q in pts))+1]
stack_change['old_new_closed_domain_xyxy']=domain(stack_change['old_polygons']+polys)
stack_change['separate_changed_shape_domains']=[domain(stack_change['old_polygons']),domain(polys)]
# A separate consumer appends this building. Do not duplicate it in placements.
ground_path=G/'build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json'
declaration_path=G/'build/luoyang_city_finish_20261025i_art01/three_buildings_processed_source_declarations01_CANDIDATE.json'
assert sha(ground_path.read_bytes())=='662fffe926e72d4579947e12615e17e5300d2ea05ad823172f5d83213b214576'
assert sha(declaration_path.read_bytes())=='5d60e295a201a7f5be85572c47ae76357b8a81c18740802636e5206ebaa2288b'
art=json.loads((G/'build/luoyang_city_finish_20261025i_art01/three_final_body_substitutions_ground03_ROOT_APPROVED_NOT_QA.json').read_text(encoding='utf8'))
kitchen=art['rows'][0]['new_complete_placement']
kp=[[p(q,[2520,1640],kitchen['source_ground_anchor_px'],145/294) for q in poly] for poly in kitchen['source_ground_polygons_px']]
a['remaining06_contract']={'fixed_parent':{'path':NS+'author_adjacent_four_fields05_routes_NOTREADY.json','sha256':sha(raw)},'four_route_changes':changes,'unpublished_stack_only_spatial_change':stack_change,'Estate_extra_kitchen_geometry':{'id':'finish_i_estate_kitchen_rear_house','consumed_separately_by':'adjacent.derive(new_kitchen) after placements; do NOT append second visual','foot_px':[2520,1640],'source_ground_anchor_px':[864,893],'uniform_numerator_denominator':[145,294],'processed_raw_polygons_px':kitchen['source_ground_polygons_px'],'source_derived_world_polygons_f32':kp,'new_closed_domain_xyxy':domain(kp),'independent_source_ground_path':'res://build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json','independent_source_ground_sha256':'662fffe926e72d4579947e12615e17e5300d2ea05ad823172f5d83213b214576','processed_declaration_path':'res://build/luoyang_city_finish_20261025i_art01/three_buildings_processed_source_declarations01_CANDIDATE.json','processed_declaration_sha256':'5d60e295a201a7f5be85572c47ae76357b8a81c18740802636e5206ebaa2288b'},'old22_polygons_pass_inherited_except_exact_unpublished_stack_replacement':True,'old_four_RGBA_pixel_inverse_components_preserved':True,'new_actor_or_original_NPC_movement':False,'independent_prior_status':'PENDING_FOUR_ROUTES_AND_EXPLICIT_STACK_KITCHEN_SMALL_DOMAINS_ONLY'}
pin=emit('author_adjacent_four_fields06_remaining_routes_dry_stack_NOTREADY.json',a)
back=copy.deepcopy(a)
for scene in back['scenes']:
 for c in changes:
  if c['scene_id']==scene['scene_id']:
   index=next(i for i,r in enumerate(scene['new_source_routes']) if r['id']==c['route_id']);scene['new_source_routes'][index]=c['old']
 if scene['scene_id']=='ch4_s2_canal_docks':
  index=next(i for i,r in enumerate(scene['placements']) if r['id']==oldstack['id']);scene['placements'][index]=oldstack
del back['remaining06_contract'];assert back==parent
proof=emit('adjacent06_remaining_routes_stack_kitchen_typed_inverse_BUILD.json',{'status':'ROOT_APPROVED_SOURCE_RESIDUAL_NOT_INDEPENDENT_PASS','author':pin,'full_typed_inverse_to_fixed05':True,'route_changes':changes,'stack_change':stack_change,'Estate_extra_kitchen':a['remaining06_contract']['Estate_extra_kitchen_geometry'],'engine_calls':0,'canonical_writes':0})
print(json.dumps({'author':pin,'proof':proof,'stack_domains':stack_change['separate_changed_shape_domains'],'kitchen_domain':domain(kp)}))
