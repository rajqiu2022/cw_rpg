"""Implementation self-check only: three detours against 47 source bodies/11 swept stations.
No PNG/mask, engine, independent-QA, old route or Physics credit.
"""
from pathlib import Path
import json,math,struct
N=Path(__file__).resolve().parent
A=json.loads((N/'author_gate_yamen_axis06_source_routes_NOTREADY.json').read_text(encoding='utf8'))['scenes'][0]
f=lambda x:struct.unpack('<f',struct.pack('<f',x))[0]
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def on(a,b,p):return cross(a,b,p)==0 and min(a[0],b[0])<=p[0]<=max(a[0],b[0]) and min(a[1],b[1])<=p[1]<=max(a[1],b[1])
def touch(a,b,c,d):
 v=[cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)]
 return ((v[0]>0)!=(v[1]>0) and (v[2]>0)!=(v[3]>0)) or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)
def inside(p,poly):
 yes=False
 for a,b in zip(poly,poly[1:]+poly[:1]):
  if on(a,b,p):return True
  if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:yes=not yes
 return yes
def overlap(p,poly):
 body=[[f(p[0]-17),f(p[1]-12)],[f(p[0]+17),f(p[1]-12)],[f(p[0]+17),f(p[1]+12)],[f(p[0]-17),f(p[1]+12)]]
 if max(q[0] for q in poly)<body[0][0] or min(q[0] for q in poly)>body[1][0] or max(q[1] for q in poly)<body[0][1] or min(q[1] for q in poly)>body[2][1]:return False
 return any(inside(q,poly) for q in body) or any(inside(q,body) for q in poly) or any(touch(a,b,c,d) for a,b in zip(body,body[1:]+body[:1]) for c,d in zip(poly,poly[1:]+poly[:1]))
NPC=[('sergeant',1740,1540,0),('merchantA',750,1600,70),('carrierA',1120,1720,70),('patrolW',2010,1700,70),('merchantB',2440,1640,60),('patrolE',2370,1870,110),('carrierB',680,1880,120),('travellerA',1020,1480,0),('travellerB',1940,1450,0),('supply',2400,1450,0),('assistant',1840,1600,0)]
routes=[r for r in A['new_source_routes'] if r['id'] in ['west_gallery_clear_side_to_front','east_inspection_front']]+[{'id':'replacement_public_loop','points_px':A['affected_old_route_replacements'][0]['new_points_px']}]
report=[]
for route in routes:
 errors=[];npoints=0
 for a,b in zip(route['points_px'],route['points_px'][1:]):
  n=max(1,math.ceil(math.dist(a,b)/4))
  for i in range(n+1):
   p=[f(a[k]+f((b[k]-a[k])*(i/n))) for k in range(2)];npoints+=1
   for primitive in A['new_all_primitive_rows_source_model']:
    if overlap(p,primitive['points_px']):errors.append({'point':p,'body':primitive['owner_id']});break
   if not errors:
    for name,x,y,d in NPC:
     if abs(p[0]-x)<=d+34 and abs(p[1]-y)<=27:errors.append({'point':p,'NPC_swept':name});break
   if errors:break
  if errors:break
 report.append({'id':route['id'],'source_samples':npoints,'errors':errors})
print(json.dumps({'implementation_self_check_only_no_mask_or_independent_credit':True,'routes':report}))
assert not any(row['errors'] for row in report)
