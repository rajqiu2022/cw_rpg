"""Source design and implementation self-check, never independent prior/PNG/Physics.
Reads fixed old source expressions; does not decode packets or run Godot.
"""
from pathlib import Path
import copy, hashlib, json, math, struct
N=Path(__file__).resolve().parent
G=N.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
 b=p.read_bytes();assert sha(b)==h,(str(p),sha(b));return json.loads(b)
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def vec(q):return [f(x) for x in q]
def add(a,b):return [f(a[i]+b[i]) for i in range(2)]
def sub(a,b):return [f(a[i]-b[i]) for i in range(2)]
def mul(a,s):return [f(x*s) for x in a]
def point(q,foot,anchor,s):return add(vec(foot),mul(sub(vec(q),vec(anchor)),s))
A=read(N/'author_artisan_residential_block04_ground_NOTREADY.json','812e93ca8909f02307a7ea511379cd2613bbab5edda28b5842d059d132fc6b23')
P=read(G/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json','1dd5a3949e36ecbada0b4a73f2c109cc1561572b64e3cd8a3e49fa4e2c21df09')
L=read(G/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json','03f0a7fd0b71b2657fa783b253d86001813897f0f16e44793f866d09cce7a9f4')
MOVES=[{'id':'ap_carpentry_cart_v2','old_foot_px':[430,1535],'new_foot_px':[1200,1760],'reason':'Keep same parked cart outside the newly authored full forge silhouette; no scale/body/action change'},
 {'id':'ap_cloth_rack_v2','old_foot_px':[2470,1446],'new_foot_px':[2470,1330],'reason':'Retain dye-front drying work but remove old rack/complete pottery roof overlap; no scale/body/action change'}]
ROUTES=[
 ('entry_to_working_cross_street',[[2816,1740],[2860,1740],[2860,1280],[1536,1280],[128,1280],[128,1300]]),
 ('west_residence_new_threshold',[[1536,1280],[1100,1280],[1100,540],[590,540],[590,504]]),
 ('east_residence_new_threshold',[[1536,1280],[2040,1280],[2040,540],[2460,540],[2460,504]]),
 ('central_shop_new_threshold',[[1536,1280],[1740,1280],[1740,960],[1536,960],[1536,924]]),
 ('kitchen_closed_front',[[1100,540],[1536,540],[1536,470]]),
 ('woodworker_front',[[128,1280],[760,1280],[820,1280],[820,1424],[760,1424]]),
 ('dye_worker_front',[[2860,1280],[2040,1280],[2040,1424],[1990,1424]]),
 ('timber_trader_approach',[[1100,1280],[1100,968],[1040,968]]),
 ('neighbour_vendor_approach',[[1160,1280],[1160,1108]]),
 ('forge_open_floor',[[128,1280],[128,1920],[480,1920],[480,1840]]),
 ('pottery_open_floor',[[2860,1740],[2860,1920],[2190,1920],[2190,1840]]),
]
def ground(placement):
 asset=P['assets'][placement['asset']];s=placement['width']/asset['used_rect'][2];foot=placement['foot'];anchor=asset['ground_anchor'];rows=[]
 for r in asset.get('solid_rects',[]):
  low=point(r[:2],foot,anchor,s);high=add(low,mul(vec(r[2:]),s))
  rows.append([low,[high[0],low[1]],high,[low[0],high[1]]])
 for raw in asset.get('solid_polygons',[]):rows.append([point(q,foot,anchor,s) for q in raw])
 return rows
next_placements=copy.deepcopy(P['scenes'][0]['placements']);changes=A['building_migrations']+MOVES
for change in changes:
 row=next(r for r in next_placements if r['id']==change['id']);assert row['foot']==change['old_foot_px'];row['foot']=change['new_foot_px']
rows=[]
for placement in next_placements:
 for poly in ground(placement):rows.append((placement['id'],poly))
assert len(rows)==27
for placement in L['placements']:
 for raw in placement['source_ground_solid_polygons_px']:
  rows.append((placement['id'],[point(q,placement['foot_px'],placement['source_ground_anchor_px'],placement['uniform_scale']) for q in raw]))
for lot in A['new_asset_lots']:
 for row in lot['new_ground_primitive_rows_f32']:rows.append((lot['asset_id']+'/'+row['id'],row['points_world_f32']))
assert len(rows)==44
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def on(a,b,p):return cross(a,b,p)==0 and min(a[0],b[0])<=p[0]<=max(a[0],b[0]) and min(a[1],b[1])<=p[1]<=max(a[1],b[1])
def touch(a,b,c,d):
 v=[cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)]
 return ((v[0]>0)!=(v[1]>0) and (v[2]>0)!=(v[3]>0)) or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)
def inside(p,poly):
 result=False
 for a,b in zip(poly,poly[1:]+poly[:1]):
  if on(a,b,p):return True
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:result=not result
 return result
def overlap(p,poly,half=(17,12)):
 box=[[f(p[0]-half[0]),f(p[1]-half[1])],[f(p[0]+half[0]),f(p[1]-half[1])],[f(p[0]+half[0]),f(p[1]+half[1])],[f(p[0]-half[0]),f(p[1]+half[1])]]
 if max(q[0] for q in poly)<box[0][0] or min(q[0] for q in poly)>box[1][0] or max(q[1] for q in poly)<box[0][1] or min(q[1] for q in poly)>box[2][1]:return False
 return any(inside(q,poly) for q in box) or any(inside(q,box) for q in poly) or any(touch(a,b,c,d) for a,b in zip(box,box[1:]+box[:1]) for c,d in zip(poly,poly[1:]+poly[:1]))
checks=[]
for id,points in ROUTES:
 count=0;errors=[]
 for a,b in zip(points,points[1:]):
  steps=max(1,math.ceil(math.dist(a,b)/4))
  for i in range(steps+1):
   p=add(vec(a),mul(sub(vec(b),vec(a)),i/steps));count+=1
   for owner,poly in rows:
    if overlap(p,poly):errors.append({'at':p,'body':owner});break
   if not errors:
    for npc in A['current_NPC_source_rows']:
     if abs(p[0]-npc['foot_px'][0])<=34 and abs(p[1]-npc['foot_px'][1])<=27:errors.append({'at':p,'NPC':npc['npc_id']});break
   if errors:break
  if errors:break
 checks.append({'id':id,'source_samples':count,'errors':errors})
print(json.dumps({'implementation_source_body_self_check_not_QA_or_mask':True,'checks':checks}))
if any(c['errors'] for c in checks):raise SystemExit(1)
for npc in A['current_NPC_source_rows']:
 assert not any(overlap(npc['foot_px'],poly,(17,15)) for _,poly in rows),npc['npc_id']
 assert not any(overlap(npc['approach_px'],poly) for _,poly in rows),npc['npc_id']
def emit(name,value):
 raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
 with (N/name).open('xb') as stream:stream.write(raw)
 return {'path':'res://build/luoyang_city_finish_20261025i_source01/'+name,'sha256':sha(raw),'bytes':len(raw)}
old=copy.deepcopy(A)
A['low_prop_migrations']=MOVES
A['new_source_routes']=[{'id':id,'points_px':points,'player_body_px':[34,24],'maximum_source_sample_step_px':4,'not_old_route_replay':True} for id,points in ROUTES]
A['new_route_design_status']='EXPLICIT_NEW_SHORT_ROUTE_SOURCE_CANDIDATE_PENDING_INDEPENDENT_QA'
A['npc_migrations']=[]
A['current_NPC_movement_contract']={'source':'res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd','selector':'defs_exact','movement_mode':'idle','patrol_distance':0.0,'source_rows':'current_NPC_source_rows','body34x30':'conservative independent QA envelope, not forced NPCNode size'}
A['root_design_admission']='Root approved cart4301535->12001760 and rack24701446->24701330; preserve four NPCs and all task/action/reward identity; eight-pixel eave gap is not a public alley'
A['service_clearance_contract']={'entry_lane_x':[2784,2960],'entry_lane_clear_width_px':176,'west_forge_outer_lane_x':[96,224],'west_forge_lane_claim_px':128,'not_claimed_144_lane':True,'forge_front_y':[1880,2024],'pottery_front_y':[1880,2024],'cloth_rack_to_dye_visual_gap_not_public_lane':True,'new_cart_is_parking_not_a_walk_lane':True}
A['implementation_self_check_only']={'primitive_count':44,'routes':checks,'NPC4_full34x30_and_approaches48_clear_of_source_bodies':True,'PNG_mask_Physics_or_independent_QA_credit':False}
for lot in A['new_asset_lots']:
 lot['local_processing_authorization_and_execution']='Root executed user-authorized exact local cleanup/padding; AD7F08D6 receipt, unchanged source pixel-scale. Main import remains separately pending.'
pin=emit('author_artisan_residential_block05_routes_props_NOTREADY.json',A)
back=copy.deepcopy(A)
for key in set(A)-set(old):del back[key]
for key in ['new_route_design_status','new_asset_lots']:back[key]=copy.deepcopy(old[key])
assert back==old
proof=emit('artisan_routes_props05_typed_inverse_BUILD.json',{'status':'SOURCE_DESIGN_SUCCESSOR_NOT_RUNTIME_OR_INDEPENDENT_QA','parent':{'path':'res://build/luoyang_city_finish_20261025i_source01/author_artisan_residential_block04_ground_NOTREADY.json','sha256':'812e93ca8909f02307a7ea511379cd2613bbab5edda28b5842d059d132fc6b23'},'candidate':pin,'new_fields':sorted(set(A)-set(old)),'replaced_fields':['new_route_design_status','new_asset_lots[*].local_processing_authorization_and_execution'],'typed_whole_inverse':True,'old_raw_sha256_unchanged':True,'engine_calls':0,'collector_calls':0})
print(json.dumps({'author':pin,'proof':proof}))
