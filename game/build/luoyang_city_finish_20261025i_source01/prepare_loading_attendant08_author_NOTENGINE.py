"""Mechanical NEW author-only successor, no runtime/canonical or engine action."""
from pathlib import Path
import copy,difflib,hashlib,json
N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/'
def enc(x): return (json.dumps(x,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def sha(x): return hashlib.sha256(x).hexdigest()
p=N/'author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json'
old_raw=p.read_bytes();assert sha(old_raw)=='fcbfa06b2347bf89e0c86cb4c7817be6781b6e574e01507e6098446afb419d20'
old=json.loads(old_raw);assert enc(old)==old_raw
child=copy.deepcopy(old);scene=child['scenes'][3];assert scene['scene_id']=='ch4_s2_canal_docks'
move=scene['npc_migrations'][1]
assert move['npc_id']=='harbour_life_docks_loading_attendant' and move['new_source_origin_px']==[2060,1840]
assert move['new_dynamic_NPC_guard_domain_xyxy']==[2036,1816,2084,1904]
move['new_source_origin_px']=[1940,1840]
move['new_dynamic_NPC_guard_domain_xyxy']=[1916,1816,1964,1904]
route=scene['new_source_routes'][1]
assert route['id']=='packing_attendant_approach' and route['points_px']==[[1430,1910],[2060,1910],[2060,1888]]
route['points_px']=[[1430,1910],[1940,1910],[1940,1888]]
inherit=child['remaining07_contract']['original_passed_four_route_inheritance'][3]
assert inherit['route_id']=='packing_attendant_approach' and inherit['exact_whole_row_equal_to_passed05'] is True
assert inherit['swept_body_bbox_xyxy']==[1413,1876,2077,1922] and inherit['route_geometry_or_NPC_replay'] is False
inherit['exact_whole_row_equal_to_passed05']=False
inherit['swept_body_bbox_xyxy']=[1413,1876,1957,1922]
inherit['route_geometry_or_NPC_replay']=True
child['loading_attendant08_contract']={
 'status':'ROOT_APPROVED_BUILD_ONLY_FINITE_LOCAL_CHECK_PENDING_NOT_ACTUAL_PASS',
 'parent_author':{'path':S+p.name,'sha256':sha(old_raw)},
 'changed_scene_id':'ch4_s2_canal_docks','npc_id':move['npc_id'],
 'prior_actual_failure_preserved':'D2 real Space at the valid sourceportal21401840 intercepted by this NPC at20601840; not a sourcegate failure.',
 'old_finish_foot_px':[2060,1840],'new_finish_foot_px':[1940,1840],
 'unchanged_original_pre25i_foot_px':[2000,1430],
 'only_rechecked_route_id':'packing_attendant_approach',
 'other_scenes_all_fields_and_Docks_geometry_props_portals_mask_original_NPCs_unchanged':True,
 'same_identity_body_scale_idle_patrol_dialog_task_and_speed':True,
 'no_QA_pose_or_interaction_priority_change':True,
 'new_runtime_payload_delta_only':'npc_migrations loading-attendant row; all other payload keys and geometry/mask bytes retained',
 'finite_new_check_pending':['Player34x24','NPC22.4x28.8','unchanged39solid/office and mask','packing approach','publicportal interaction separation'],
 'root_sole_engine_and_deployer':True}
back=copy.deepcopy(child);del back['loading_attendant08_contract']
back['scenes'][3]['npc_migrations'][1]=copy.deepcopy(old['scenes'][3]['npc_migrations'][1])
back['scenes'][3]['new_source_routes'][1]=copy.deepcopy(old['scenes'][3]['new_source_routes'][1])
back['remaining07_contract']['original_passed_four_route_inheritance'][3]=copy.deepcopy(old['remaining07_contract']['original_passed_four_route_inheritance'][3])
assert back==old and enc(back)==old_raw
for i in range(3): assert child['scenes'][i]==old['scenes'][i]
for key in scene:
 if key not in ['npc_migrations','new_source_routes']: assert scene[key]==old['scenes'][3][key]
assert scene['npc_migrations'][0]==old['scenes'][3]['npc_migrations'][0]
for i,r in enumerate(scene['new_source_routes']):
 if i!=1: assert r==old['scenes'][3]['new_source_routes'][i]
out=N/'author_adjacent_four_fields08_loading_clear_portal_NOTREADY.json';new_raw=enc(child)
proof=N/'loading_attendant08_author_whole_inverse_BUILD.json'
assert not out.exists() and not proof.exists()
patch=''.join(difflib.unified_diff(old_raw.decode().splitlines(True),new_raw.decode().splitlines(True),fromfile=p.name,tofile=out.name))
record={'status':'MECHANICAL_SOURCE_AUTHOR08_EXACT_INVERSE_NOT_ENGINE_NOT_NAV_PASS','parent':{'path':S+p.name,'sha256':sha(old_raw),'bytes':len(old_raw)},'candidate':{'path':S+out.name,'sha256':sha(new_raw),'bytes':len(new_raw)},'whole_raw_inverse':True,'original_geometry_and_portals_and_all_other_actors_unchanged':True,'patch':patch,'engine_calls':0,'canonical_writes':0}
with out.open('xb')as f:f.write(new_raw)
with proof.open('xb')as f:f.write(enc(record))
print(json.dumps({'candidate':record['candidate'],'proof':{'path':S+proof.name,'sha256':sha(proof.read_bytes())}}))
