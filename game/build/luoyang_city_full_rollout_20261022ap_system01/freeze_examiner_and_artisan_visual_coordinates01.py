"""Static declared pose handoff; no product safe_body, engine or raster rebuild."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def row(p):return {'path':'res://'+str(p.relative_to(GAME)).replace('\\','/'),'sha256':sha(p)}
fixture=ROOT.parent/'luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v5_author_anchors_READY.json'
data=json.loads(fixture.read_text(encoding='utf-8'))
market=next(s for s in data['scenes'] if s['id']=='ch4_s3_luoyang_market')
artisan=next(s for s in data['scenes'] if s['id']=='luoyang_artisan_residential_20261022ap')
def aabb(points):
 return [min(p[0] for p in points),min(p[1] for p in points),max(p[0] for p in points),max(p[1] for p in points)]
def overlaps(a,b):return not(a[2]<=b[0] or b[2]<=a[0] or a[3]<=b[1] or b[3]<=a[1])
approach=[[1170,892],[1170,868]]
sweep=[1153,856,1187,904]
hits=[]
for solid in market['geometry']['solids']:
 points=solid.get('points_px')
 if points is None:
  x,y,w,h=solid['rect_px'];points=[[x,y],[x+w,y+h]]
 if overlaps(sweep,aabb(points)):hits.append(solid['id'])
assert hits==[],hits
original=GAME/'art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json'
original_data=json.loads(original.read_text(encoding='utf-8'))
def find_slots(value):
 if isinstance(value,dict):
  if value.get('source_id')=='spar_luoyang_examiner':yield value
  for v in value.values():yield from find_slots(v)
 elif isinstance(value,list):
  for v in value:yield from find_slots(v)
slots=list(find_slots(original_data));assert len(slots)==1 and slots[0]['foot_px']==[1170,820]
proposal=ROOT/'artisan_ground_union_boundary_visual_proposal_READY.json'
proposal_data=json.loads(proposal.read_text(encoding='utf-8'))
assert len(proposal_data['preserved_nine_sections'])==9 and len(proposal_data['exterior_union_segments_only'])==32
image=ROOT.parent/'luoyang_city_full_rollout_20261022ap_qa01/bounded_actual_C/31780_2912/luoyang_artisan_residential_20261022ap.png'
assert sha(image)=='711900043660f4bba1116f60706e1464daa46dd75dc392859361d12536e73b8c'
assert artisan['input_points']==[[2816.0,1740.0],[2816.0,1716.0]]
receipt={'status':'STATIC_SOURCE_POSES_ONLY_NO_RUNTIME_OR_GEOMETRY_CREDIT','fixture':row(fixture),'examiner':{'scene':'ch4_s3_luoyang_market','npc_id':'spar_luoyang_examiner','original_author_slot':slots[0],'author_slot_source':row(original),'final_foot_world':[1170,820],'south48_interact_foot':[1170,868],'near_setup_foot':[1170,892],'normal_input':approach,'body_sweep_aabb34x24':sweep,'conservative_raw_solid_aabb_hits':hits,'raw_geometry_source':'Market geometry in fixed v5 fixture (not product safe_body)','position_inheritance':'Original base applies gameplay_slots.npcs foot. AP market native_inverse only visual/portal/mask fields; NPC array unchanged. NPC presentation compose_exact permits sprite_path/portrait_path only. New Field A148 only exact portrait path; no NPC position delta.','position_inheritance_sources':[row(GAME/'scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd'),row(ROOT/'market_layout_successor2/market_transform.gd'),row(ROOT.parent/'luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd')],'not_claimed':'NPC interaction real Space/dialogue is pending; QA original raw oracle/mask and current ID check remain mandatory.'},'artisan_same_camera':{'scene':'luoyang_artisan_residential_20261022ap','original_image':row(image),'original_setup_spawn':[2816,1740],'original_INPUT':artisan['input_points'],'capture_player_foot':[2816,1716],'viewport':[1920,1080],'camera_zoom':1.0,'camera_position_smoothing':False,'camera_limits':[0,0,3072,2048],'capture_rule':'Original ordinary tracking camera after exactly same INPUT endpoint; no private zoom/position/frame all; use actual Camera2D state rather than inferred center. Only finite same-view C visual comparison, do not repeat rooms/Physics/whole C.','source_compiler':row(ROOT/'artisan_revision4/quarters_compiler.gd'),'source_scene_defaults':row(GAME/'scripts/domain/scene_script.gd'),'source_camera':row(GAME/'scripts/field/field_walkable_controller.gd'),'original_test':row(GAME/'tests/test_luoyang_city_full_rollout_bounded_groups_author_anchor_returns_READY_20261022ap.gd'),'original_capture_primitive':row(GAME/'tests/test_luoyang_t_yamen_hall_return_retry1_ready_20261019u.gd'),'union_oracle':row(proposal),'source_sections':proposal_data['preserved_nine_sections'],'union_exterior_segments':proposal_data['exterior_union_segments_only'],'native_ground_tiles':62,'core_opacity':1.0,'exterior_feather_world':32,'no_internal_tile_or_section_feather':True},'no_engine_canonical_or_image_processing':True}
p=ROOT/'examiner_and_artisan_visual_coordinates_READY.json';assert not p.exists();p.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(row(p),indent=2))
