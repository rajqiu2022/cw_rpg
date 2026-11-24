"""Finite new-route implementation design check, not independent QA or engine.
Uses only immutable original masks/donor sources plus proposed new source contacts.
"""
import inspect_adjacent_route_source06_NOTENGINE as m
import math,json
from PIL import Image
def load_pin(pin):
 b=m.path(pin['path']).read_bytes();assert m.sha(b)==pin['sha256'];return json.loads(b)
donors={k:load_pin(v) for k,v in m.cfg['donors'].items()}
def people(scene):
 sid=scene['scene_id'];out=[]
 if sid=='ch4_s2_canal_docks':out=[dict(r) for r in m.cfg['docks_original_people']]
 elif sid=='ch4_s3_luoyang_market':
  for row in donors['DG']['districts'][sid]['crowd']:
   foot=row['foot_px'];distance=row['distance_px']
   for move in donors['low_wall']['npc_migrations']:
    if move['id']==row['id']:foot=move['foot_px'];distance=move.get('distance_px',distance)
   out.append({'id':'district_life_'+row['id'],'foot':foot,'distance':distance})
 elif sid=='luoyang_riverside_garden_20261022ap':
  out=[{'id':r['npc_id'],'foot':r['foot_px'],'distance':0} for r in donors['people']['people'] if r['scene_id']==sid]
 for move in scene['npc_migrations']:
  row=next(r for r in out if r['id']==move['npc_id']);assert row['foot']==move['old_source_origin_px'];row['foot']=move['new_source_origin_px']
 return out
def segment_touch(a,b,c,d):
 def cross(p,q,r):return (q[0]-p[0])*(r[1]-p[1])-(q[1]-p[1])*(r[0]-p[0])
 def on(p,q,r):return cross(p,q,r)==0 and min(p[0],q[0])<=r[0]<=max(p[0],q[0]) and min(p[1],q[1])<=r[1]<=max(p[1],q[1])
 return cross(a,b,c)*cross(a,b,d)<0 and cross(c,d,a)*cross(c,d,b)<0 or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)
def poly_body(poly,foot):
 x,y=foot;body=[[x-17,y-12],[x+17,y-12],[x+17,y+12],[x-17,y+12]]
 return any(m.contains(poly,p) for p in body) or any(x-17<=p[0]<=x+17 and y-12<=p[1]<=y+12 for p in poly) or any(segment_touch(a,b,c,d) for a,b in zip(poly,poly[1:]+poly[:1]) for c,d in zip(body,body[1:]+body[:1]))
def checker(scene):
 source=m.cfg['sources'][scene['scene_id']];pin=source['mask'];b=m.path(pin['path']).read_bytes();assert m.sha(b)==pin['sha256'];im=Image.open(m.path(pin['path'])).convert('RGBA')
 rows=m.newpolys(scene);npcs=people(scene)
 old=m.source_geometry(source['geometry']) if 'geometry' in source and source['geometry']['path'].endswith('.bin') else []
 def safe(foot):
  x,y=foot
  if any(abs(y-r['foot'][1])<=27 and abs(x-r['foot'][0])<=34+r['distance'] for r in npcs):return False,'NPC_swept'
  for row in old+rows:
   if poly_body(row['points_px'],foot):return False,row['id']
  for dx in range(-17,18):
   for dy in [-12,12]:
    if im.getpixel((int(math.floor(x+dx+.5)),int(math.floor(y+dy+.5))))[0]<128:return False,'parent_mask'
  for dy in range(-12,13):
   for dx in [-17,17]:
    if im.getpixel((int(math.floor(x+dx+.5)),int(math.floor(y+dy+.5))))[0]<128:return False,'parent_mask'
  return True,''
 return safe
if __name__=='__main__':
 a=m.load(m.N/'author_adjacent_four_fields06_remaining_routes_dry_stack_NOTREADY.json')
 target={'inn_work_court_to_traveller_approach','west_bank_soft_path','booking_to_cargo_lane','short_storage_front','packing_attendant_approach'}
 for scene in a['scenes']:
  if scene['scene_id']=='luoyang_estate_riverside_20261021ai':continue
  safe=checker(scene)
  for route in scene['new_source_routes']:
   if route['id'] not in target:continue
   result={'id':route['id'],'new_design_check_not_QA':True,'clear':True}
   for lo,hi in zip(route['points_px'],route['points_px'][1:]):
    steps=max(1,math.ceil(math.dist(lo,hi)/4))
    for i in range(steps+1):
     foot=[m.f(lo[j]+(hi[j]-lo[j])*i/steps) for j in range(2)];okay,reason=safe(foot)
     if not okay:result.update(clear=False,first_blocked=foot,source_reason=reason);break
    if not result['clear']:break
   print(json.dumps(result))
