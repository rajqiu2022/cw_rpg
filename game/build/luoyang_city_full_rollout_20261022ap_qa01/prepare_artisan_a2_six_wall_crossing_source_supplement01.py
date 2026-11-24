"""Finite continuous body sweep from fixed independent 48360 source vectors.

No mask/ABI/875 replay. Primitive AABBs are broad phase only: the preserved
handcart's true polygon, not its full visual/AABB, decides exact source contact.
"""
import hashlib,json,struct
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
PRIOR=QA/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json'
OUT=QA/'artisan_a2_six_wall_crossing_source_supplement01_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def f(v):return struct.unpack('<f',struct.pack('<f',v))[0]
assert not OUT.exists()
assert sha(PRIOR)=='d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e'
p=json.loads(PRIOR.read_bytes())
for q,h in p['independent_source_sha256'].items():assert sha(Path(q))==h
solids=p['expected27_source_solids'];assert len(solids)==27
people=p['exact_4_people_and_approaches'];assert len(people)==4
def boxpoly(b):
    x0,y0,x1,y1=b;return [[x0,y0],[x1,y0],[x1,y1],[x0,y1]]
def poly(row):
    if 'polygon_px' in row:return row['polygon_px']
    x,y,w,h=row['rect_px'];return boxpoly([x,y,f(x+w),f(y+h)])
def bounds(poly):return [min(q[0] for q in poly),min(q[1] for q in poly),max(q[0] for q in poly),max(q[1] for q in poly)]
def aabb(a,b):return a[0]<=b[2] and b[0]<=a[2] and a[1]<=b[3] and b[1]<=a[3]
def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def on(a,b,c):return cross(a,b,c)==0 and min(a[0],b[0])<=c[0]<=max(a[0],b[0]) and min(a[1],b[1])<=c[1]<=max(a[1],b[1])
def edgehit(a,b,c,d):
    x,y,z,w=cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)
    if ((x<0<y) or (y<0<x)) and ((z<0<w) or (w<0<z)):return True
    return (x==0 and on(a,b,c)) or (y==0 and on(a,b,d)) or (z==0 and on(c,d,a)) or (w==0 and on(c,d,b))
def inside(q,ps):
    yes=False
    for a,b in zip(ps,ps[1:]+ps[:1]):
        if on(a,b,q):return True
        if (a[1]>q[1])!=(b[1]>q[1]) and q[0]<a[0]+(q[1]-a[1])*(b[0]-a[0])/(b[1]-a[1]):yes=not yes
    return yes
def polygons_hit(a,b):
    if not aabb(bounds(a),bounds(b)):return False
    if any(inside(q,b) for q in a) or any(inside(q,a) for q in b):return True
    return any(edgehit(x,y,z,w) for x,y in zip(a,a[1:]+a[:1]) for z,w in zip(b,b[1:]+b[:1]))
def evaluate(x):
    sweep=[x-17,1404-12,x+17,1446+12];shape=boxpoly(sweep)
    broad=[r['id'] for r in solids if aabb(sweep,bounds(poly(r)))]
    exact=[r['id'] for r in solids if polygons_hit(shape,poly(r))]
    actors=[]
    for npc in people:
        nx,ny=npc['foot_px'];body=[nx-17,ny-15,nx+17,ny+15]
        if aabb(sweep,body):actors.append(npc['npc_id'])
    old_walls=[r['id'] for r in p['old33_source_solids'] if '_wall_' in r['id'] and polygons_hit(shape,poly(r))]
    return {'from':[x,1404],'to':[x,1446],'continuous_Player34x24_sweep_closed':sweep,
        'retained_solid_AABB_candidates_not_automatic_reject':broad,
        'retained_true_source_primitive_contacts':exact,'four_idle_NPC34x30_contacts':actors,
        'original_retired_wall_contacts':old_walls,'source_continuous_clear_only':not exact and not actors,
        'mask_or87517_Physics_credit':False}
initial=evaluate(400)
assert initial['retained_true_source_primitive_contacts']==['ap_carpentry_cart_v2_hull_0']
axes=[470,560,880,1840,2160,2320]
rows=[evaluate(x) for x in axes]
assert all(x['source_continuous_clear_only'] and len(x['original_retired_wall_contacts'])==1 for x in rows)
assert set(x['original_retired_wall_contacts'][0] for x in rows)==set(p['only_geometry_delta']['retired_six_wall_solids'])
out={'status':'SOURCE_ONLY_CONTINUOUS_SIX_RETIRED_WALL_CROSSING_SUPPLEMENT_NOT_MASK_OR_RUNTIME_ADMISSION',
 'parent_independent_prior':{'path':'res://'+PRIOR.relative_to(GAME).as_posix(),'sha256':sha(PRIOR)},
 'RGBA_prior_unchanged':p['prior_mask'],'source_expression_authority':'Independent 48360 frozen native Vector2 source expressions, not publisher/native actual; all four frozen source hashes rechecked.',
 'fixed_body':[34,24],'body_sweep':'For each vertical straight segment, the complete closed axis-aligned swept rectangle is exact union of all full34x24 body positions. Intersection uses retained source polygons/rectangles and original4 idle NPC34x30; no expanded epsilon. AABB only selects candidate primitives.',
 'rejected_original_x400':initial,'six_proposed_paths':rows,
 'x470_boundary':'Source-safe proposed axis within original smith_w1 horizontal footprint. It is not a sprite/A1 visibility exemption and remains subject to Root actual finite87517/ART. No cart/tree/source move.',
 'original_rack_front_and_negative_unchanged':p['source_only_new_targets_not_yet_runtime_admitted'],
 'required_next':'System NEW input replaces three repeated stand witnesses with these six true continuous crossing paths after Root authorization; same D0D5 RGBA/27 solids/4 NPC/7 routes/4 portals. Original C0A unexecuted unchanged.',
 'PNG_decode':0,'ABI_runs':0,'engine_runs':0,'87517_samples':0,'Physics_queries':0,'publisher_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'supplement':str(OUT),'sha256':sha(OUT),'rejected400':initial['retained_true_source_primitive_contacts'],
 'six_axes':axes,'all_source_sweeps_clear':True,'RGBA_unchanged':True,'engine':0}))
