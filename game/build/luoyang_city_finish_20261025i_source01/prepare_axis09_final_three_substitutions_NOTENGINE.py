"""Root-approved last three bodies; independent source-f32 construction only.
Keep prior49/44 evidence as a parent, not acceptance for the new three domains.
"""
from pathlib import Path
import copy,hashlib,json,math,struct
N=Path(__file__).resolve().parent;G=N.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(path,expected):
 b=path.read_bytes();assert sha(b)==expected,(path,sha(b));return json.loads(b)
def emit(name,a):
 b=(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def point(p,foot,anchor,scale):return [f(f(foot[i])+f(f(f(p[i])-f(anchor[i]))*f(scale))) for i in range(2)]
def bits(polys):return b''.join(struct.pack('<ff',*p) for poly in polys for p in poly)
parent_name='author_gate_yamen_axis08_low_courts_NOTREADY.json'
parent=read(N/parent_name,'5baa93dc833b5f33c2bcdba96fff64365c7aca7454bb90f5f6e790e9603bdbba')
oldlibrary=read(N/'axis_infill_asset_library04_SOURCE_ONLY.json','bc816c689cb310e033bdf55da5b1b0245c9f29a5349869c82c39b0b72f2fb613')
art_path=G/'build/luoyang_city_finish_20261025i_art01/three_final_body_substitutions_ground03_ROOT_APPROVED_NOT_QA.json'
art=read(art_path,'d75071437ff0c6c615bc9e625bf8dc6004ca74f73166d6be1f527364361b8b09')
a=copy.deepcopy(parent);library=copy.deepcopy(oldlibrary);changes=[]
for source in art['rows']:
 scene=next(s for s in a['scenes'] if s['scene_id']==source['scene_id'])
 row=next(p for p in scene['placements'] if p['id']==source['id'])
 old=copy.deepcopy(row);assert row==source['old_complete_placement']
 new=source['new_complete_placement'];ratio=new['uniform_source_expression']['numerator']/new['uniform_source_expression']['denominator']
 polys=[[point(p,new['foot_px'],new['source_ground_anchor_px'],ratio) for p in raw] for raw in new['source_ground_polygons_px']]
 assert bits(polys)==bits(new['source_ground_polygons_world_f32_ART_model'])
 asset_id=new['asset_id']
 if asset_id not in library['assets']:
  library['assets'][asset_id]={'texture':new['texture'],'source_sha256':new['PNG_sha256'],'source_size_px':new['source_size_px'],'source_ground_anchor_px':new['source_ground_anchor_px'],'source_solid_polygons_px':new['source_ground_polygons_px'],'source_solid_rects_px':[],'alpha_bbox_xywh':[new['source_complete_A1_xyxy'][0],new['source_complete_A1_xyxy'][1],new['source_complete_A1_xyxy'][2]-new['source_complete_A1_xyxy'][0],new['source_complete_A1_xyxy'][3]-new['source_complete_A1_xyxy'][1]],'door_clear_source_px':294,'donor':new['source_origin'],'no_rotate_mirror_crop_or_pixel_edit':True}
 else:
  asset=library['assets'][asset_id]
  assert asset['texture']==new['texture'] and asset['source_sha256']==new['PNG_sha256']
 row.update({'asset_id':asset_id,'foot_px':new['foot_px'],'scale':ratio,'purpose':new['purpose'],'source_derived_new_ground_polygons_f32':polys})
 source_size=new['source_size_px'];anchor=new['source_ground_anchor_px'];foot=new['foot_px']
 row['source_derived_bound_xyxy_f32']=[*point([0,0],foot,anchor,ratio),*point(source_size,foot,anchor,ratio)]
 row['door_visible_height_px_before_scene_conversion']=f(new['door_visible_height_world_f32_ART_model'])
 old_ground=old['source_derived_new_ground_polygons_f32']
 coords=[p for poly in old_ground+polys for p in poly]
 domain=[math.floor(min(p[0] for p in coords))-1,math.floor(min(p[1] for p in coords))-1,math.ceil(max(p[0] for p in coords))+1,math.ceil(max(p[1] for p in coords))+1]
 assert domain==source['conservative_old_new_ground_union_closed_domain_xyxy_ART_model']
 replacements=[{'id':row['id']+'_poly_'+str(i),'owner_id':row['id'],'kind':'NEW_SOURCE_AUTHORED_GROUND_POLYGON','points_px':p} for i,p in enumerate(polys)]
 for field in ['new_asset_primitive_rows','new_all_primitive_rows_source_model']:
  original=scene[field];indices=[i for i,r in enumerate(original) if r['owner_id']==row['id']]
  assert len(indices)==len(old_ground) and indices==list(range(indices[0],indices[0]+len(indices)))
  scene[field]=original[:indices[0]]+copy.deepcopy(replacements)+original[indices[-1]+1:]
 scene['new_primitive_count']=len(scene['new_all_primitive_rows_source_model'])
 changes.append({'scene_id':scene['scene_id'],'id':row['id'],'old_complete_placement':old,'new_complete_placement':copy.deepcopy(row),'retired_parent_rows':[{'id':row['id']+'_poly_'+str(i),'owner_id':row['id'],'kind':'NEW_SOURCE_AUTHORED_GROUND_POLYGON','points_px':p} for i,p in enumerate(old_ground)],'new_primitive_rows':replacements,'source_derived_new_closed_domain_xyxy':domain,'visited_domain_pixels':(domain[2]-domain[0]+1)*(domain[3]-domain[1]+1),'source_formula':'Vector2(foot)+(Vector2(source_point)-Vector2(padded_anchor))*uniform; every Vector2 operation binary32; no A1 collision','ART_ground_source':new['source_origin']})
for scene in a['scenes']:
 selected=[c for c in changes if c['scene_id']==scene['scene_id']]
 scene['final_three_body_delta']={'parent_primitive_count':next(s for s in parent['scenes'] if s['scene_id']==scene['scene_id'])['new_primitive_count'],'new_primitive_count':scene['new_primitive_count'],'changes':selected,'new_closed_domains_xyxy':[c['source_derived_new_closed_domain_xyxy'] for c in selected],'independent_prior_status':'PENDING_NEW_THREE_DOMAINS_ONLY_NOT_49_44_REPLAY','old_proven_geometry_retained_except_exact_three_owner_rows':True}
scene_by_id={s['scene_id']:s for s in a['scenes']}
scene_by_id['ch4_s0_luoyang_gate']['final_three_body_delta']['new_short_approach_routes']=[{'id':'new_wing_source_front_approach','points_px':[[2490,1390],[2380,1390],[2380,1348]]}]
scene_by_id['ch4_s1_luoyang_yamen']['final_three_body_delta']['new_short_approach_routes']=[{'id':'new_kitchen_source_front_approach','points_px':[[590,680],[540,680],[540,668]]},{'id':'new_runner_wing_source_front_approach','points_px':[[2664,680],[2530,680],[2530,668]]}]
library_pin=emit('axis_infill_asset_library05_processed_kitchen_SOURCE_ONLY.json',library)
a['reuse_library']=library_pin
a['final_three_body_substitution_contract']={'fixed_parent':{'path':NS+parent_name,'sha256':'5baa93dc833b5f33c2bcdba96fff64365c7aca7454bb90f5f6e790e9603bdbba'},'Root_ART_author_path':'res://build/luoyang_city_finish_20261025i_art01/'+art_path.name,'Root_ART_author_sha256':'d75071437ff0c6c615bc9e625bf8dc6004ca74f73166d6be1f527364361b8b09','three_changes_only':changes,'six_proposed_extra_low_walls_not_authorized_not_adopted':True,'old_Gate_two_low_walls_148_opening_exactly_unchanged':True,'doors_NPC_rooms_Router_unchanged':True,'not_independent_QA_or_Runtime':True}
pin=emit('author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json',a)
back=copy.deepcopy(a)
for scene in back['scenes']:
 oldscene=next(s for s in parent['scenes'] if s['scene_id']==scene['scene_id'])
 for c in changes:
  if c['scene_id']==scene['scene_id']:
   index=next(i for i,p in enumerate(scene['placements']) if p['id']==c['id']);scene['placements'][index]=c['old_complete_placement']
 for field in ['new_asset_primitive_rows','new_all_primitive_rows_source_model','new_primitive_count']:scene[field]=copy.deepcopy(oldscene[field])
 del scene['final_three_body_delta']
back['reuse_library']=parent['reuse_library'];del back['final_three_body_substitution_contract']
assert back==parent
proof=emit('axis09_three_body_full_typed_inverse_AND_source_domains_BUILD.json',{'status':'ROOT_APPROVED_THREE_BODY_SOURCE_DELTA_NOT_INDEPENDENT_PRIOR','author':pin,'library':library_pin,'changes':changes,'full_typed_inverse_to_fixed08':True,'inverse_exact_fields':['placements3','new_asset_primitive_rows','new_all_primitive_rows_source_model','new_primitive_count','reuse_library','new_delta_contract_fields'],'new_count_by_scene':{s['scene_id']:s['new_primitive_count'] for s in a['scenes']},'Root_six_extra_walls_rejected':True,'engine_calls':0,'canonical_writes':0})
print(json.dumps({'author':pin,'library':library_pin,'proof':proof,'counts':{s['scene_id']:s['new_primitive_count'] for s in a['scenes']}}))
