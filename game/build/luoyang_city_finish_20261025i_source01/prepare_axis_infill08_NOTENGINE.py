"""Append only four source-bound low objects; keep the two proven domain components separate."""
from pathlib import Path
import copy,hashlib,json,math,struct
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
parentp=NS+'author_gate_yamen_axis07_yamen_route_starts_NOTREADY.json';parenth='04d9025aeaf8439044f0421a46b6a268e06bbf1a479b10abe214a50ab0fc9c30'
parent=load(parentp,parenth);author=copy.deepcopy(parent)
lib=load(NS+'reuse_asset_library01_SOURCE_ONLY.json','17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d')
dg=load('res://data/maps/luoyang_district_life_20261016f/author.json','d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c')
stage=load('res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json','ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
authority={}
for key,row in stage['nodes'].items():
 if key.startswith('expected_'):authority.update(row['value']['source_sha256'])
wall=lib['assets']['low_wall'];wall['source_solid_polygons_px']=copy.deepcopy(wall['ground_solid_polygons_px']);wall['source_solid_rects_px']=[]
crate=dg['assets']['stock_crate'];lib['assets']['stock_crate']={'texture':crate['texture'],'source_sha256':authority[crate['texture']],'source_size_px':crate['size_px'],'source_ground_anchor_px':crate['source_ground_anchor_px'],'source_solid_polygons_px':crate['ground_solid_polygons_px'],'source_solid_rects_px':[],
 'donor':{'path':'res://data/maps/luoyang_district_life_20261016f/author.json','sha256':'d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c','selector':['assets','stock_crate']}}
libpin=emit('axis_infill_asset_library04_SOURCE_ONLY.json',lib)
newplans=[ [('finish_i_gate_queue_low_edge_west','low_wall',[500,1450],.4),('finish_i_gate_queue_low_edge_east','low_wall',[900,1450],.4)], [('finish_i_yamen_archive_case_crate','stock_crate',[940,700],.7),('finish_i_yamen_runner_case_crate','stock_crate',[2100,730],.7)] ]
summary=[]
for ordinal,s in enumerate(author['scenes']):
 base=parent['scenes'][ordinal];old_rows=copy.deepcopy(base['new_all_primitive_rows_source_model']);new_rows=[];domains=[]
 for id,asset_id,foot,scale in newplans[ordinal]:
  asset=lib['assets'][asset_id];polys=[]
  for raw in asset['source_solid_polygons_px']:
   polys.append([[f(f(foot[i])+f(f(f(p[i])-f(asset['source_ground_anchor_px'][i]))*scale)) for i in range(2)] for p in raw])
  s['placements'].append({'id':id,'asset_id':asset_id,'foot_px':foot,'scale':scale,'purpose':'Low open inspection court boundary' if asset_id=='low_wall' else 'Low temporary archive/runner document case; source-ground footprint only','source_derived_new_ground_polygons_f32':polys,'enters_new_room':False,'polygon_PIP_Physics_or_mask_credit':False})
  s['new_ordered_render_ids'].append(id)
  for i,poly in enumerate(polys):
   row={'id':id+'_poly_'+str(i),'owner_id':id,'kind':'NEW_SOURCE_AUTHORED_GROUND_POLYGON','points_px':poly};new_rows.append(row)
   lo=[min(p[k] for p in poly) for k in range(2)];hi=[max(p[k] for p in poly) for k in range(2)];domains.append([math.floor(lo[0])-1,math.floor(lo[1])-1,math.ceil(hi[0])+1,math.ceil(hi[1])+1])
 s['new_asset_primitive_rows']+=copy.deepcopy(new_rows);s['new_all_primitive_rows_source_model']+=copy.deepcopy(new_rows)
 s['new_render_count']+=2;s['new_primitive_count']+=len(new_rows)
 s['proven_base_domain_component']={'author':{'path':parentp,'sha256':parenth},'primitive_count':base['new_primitive_count'],'primitive_rows':old_rows,'domains_preserved_exact':base['local_closed_integer_domains_xyxy'],'visited_budget':base['local_domain_max_visited_pixels'],'old_wholeFAILs_retained_components_only':True,'remaining_Yamen2routes_pending':True}
 s['additional_new_primitive_rows']=new_rows;s['additional_closed_integer_domains_xyxy']=domains;s['additional_domain_visited_budget']=sum((r[2]-r[0]+1)*(r[3]-r[1]+1) for r in domains)
 for r in domains:
  for b in base['local_closed_integer_domains_xyxy']:assert r[2]<b[0] or b[2]<r[0] or r[3]<b[1] or b[3]<r[1],(s['scene_id'],r,b)
 assert s['new_all_primitive_rows_source_model'][:-len(new_rows)]==old_rows
 assert s['new_source_routes']==base['new_source_routes'] and s.get('object_migrations')==base.get('object_migrations')
 summary.append({'scene_id':s['scene_id'],'base_primitives':base['new_primitive_count'],'new_primitives':s['new_primitive_count'],'base_domains_not_rerasterized_by_QA':base['local_closed_integer_domains_xyxy'],'additional_rows':new_rows,'additional_domains_xyxy':domains,'additional_visited_budget':s['additional_domain_visited_budget']})
author['reuse_library']=libpin
author['gate_low_wall_clear_opening_source_f32']=f(f(900+f((4-319)*.4))-f(500+f((634-319)*.4)))
assert author['gate_low_wall_clear_opening_source_f32']>=145
author['composed_mask_prior_contract']='Independent old47/42 component full-RGBA proof + independent four added-domain exact bytes/geometry + whole inverse. Do not manufacture a final full-RGBA hash from an observed publisher result.'
pin=emit('author_gate_yamen_axis08_low_courts_NOTREADY.json',author)
proof={'status':'ROOT_APPROVED_FOUR_LOW_OBJECTS_ONLY_NEW_CLOSED_DOMAINS_NOT_QA_PASS','author':pin,'library':libpin,'parent':{'path':parentp,'sha256':parenth},'scenes':summary,'Gate_two_true_wall_bases_clear_opening':author['gate_low_wall_clear_opening_source_f32'],'old_routes_NPC_geometry_prefix_and_old_domains_preserved':True,'engine_calls':0,'old_domain_rasters_this_preparation':0}
print(json.dumps({'author':pin,'library':libpin,'proof':emit('axis_four_low_objects08_exact_delta_BUILD.json',proof)}))
