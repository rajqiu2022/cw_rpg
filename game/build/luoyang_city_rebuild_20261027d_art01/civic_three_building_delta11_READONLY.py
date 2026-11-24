"""Only native three-building affected bounds; no engine, pixels, or file writes."""
from pathlib import Path
import json,hashlib,math,struct
import numpy as np
B=Path(__file__).resolve().parent;G=B.parents[1];N=G/'build/luoyang_regions_20261027d_source01'
def fixed(path,pin):
    raw=path.read_bytes();assert hashlib.sha256(raw).hexdigest()==pin
    return json.loads(raw.decode('utf-8-sig'))
P=fixed(N/'civic_parent_BFA4_decoded_READONLY.json','0492c15e4ee4c0ff12a6adf7f08d17128767ff1858b5a7c625e0e5f314b7c5ad')
A=fixed(N/'regions_author06_native_buildings_BUILD.json','773e00411e878bd703bb22bdbf4ba7860de6de01b49bc891831d92bacf0cffab')
I=fixed(N/'civic_three_building_delta_input_ROOT_READY01.json','c061c9ca802e4b0b1b07c7d27c8093bdac5901866b864c5aea7b767be8675c6d')
D=A['regions']['luoyang_civic_market_region_27d']
old=fixed(N/'regions_author05_temple_route_residual_BUILD.json','d91a022ca806cfbf4ec004966874ebaecb94464bea797d54971da45501cfa49d')['regions']['luoyang_civic_market_region_27d']
text=(G/'build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8-sig');scope={'struct':struct}
exec(text[text.index('class FrozenVariant:'):text.index('binding_pin=')],scope)
bindings=A['terminal_bindings'];removed=[]
# Only original two retired-front polygons; do not reconstruct old geometry.
for logical,district in [(d['logical_id'],d) for d in old['districts'] if d['logical_id']=='ch4_s3_luoyang_market']:
    pin=bindings[logical];raw=(G/pin['path'][6:]).read_bytes();assert hashlib.sha256(raw).hexdigest()==pin['sha256']
    v=scope['FrozenVariant'](raw);terminal=v.value();assert v.p==len(raw)
    for owner in ['shop','north_market_front']:
        plot,=[p for p in district['plots'] if owner in p['owners']]
        delta=np.array(plot['target_anchor_px'],dtype=np.float32)-np.array(plot['source_anchor_px'],dtype=np.float32)
        for s in terminal['solids']:
            if s['owner_id']==owner:removed.append((np.array(s['points_px'],dtype=np.float32)+delta).tolist())
solids=[poly for poly in P['solids'] if poly not in removed]
assert len(P['solids'])-len(solids)==len(removed)
helper=(B/'two_outdoor_residuals07_READONLY.py').read_text(encoding='utf-8')
exec(helper[helper.index('def clip('):helper.index('def inspect(')])
ground={'ground':[{'rect':[[r[0],r[1]],[r[2],r[3]]]} for r in P['floor_rects']]}
def area(p):
    if len(p)<3:return 0
    o=p[0];q=[[x-o[0],y-o[1]] for x,y in p]
    return abs(sum(q[i][0]*q[(i+1)%len(q)][1]-q[(i+1)%len(q)][0]*q[i][1] for i in range(len(q))))/2
def convex_clip(poly,boundary):
    sign=1 if sum(boundary[i][0]*boundary[(i+1)%len(boundary)][1]-boundary[(i+1)%len(boundary)][0]*boundary[i][1] for i in range(len(boundary)))>=0 else -1
    for j,c in enumerate(boundary):
        d=boundary[(j+1)%len(boundary)];out=[]
        def distance(p):return sign*((d[0]-c[0])*(p[1]-c[1])-(d[1]-c[1])*(p[0]-c[0]))
        for k,a in enumerate(poly):
            b=poly[(k+1)%len(poly)];da,db=distance(a),distance(b)
            if da>=0:out.append(a)
            if (da>=0)!=(db>=0):
                t=da/(da-db);out.append([a[i]+t*(b[i]-a[i]) for i in range(2)])
        poly=out
        if not poly:break
    return poly
new=[];bounds=[]
for b in D['pending_buildings']:
    a=b['asset_binding'];anchor=np.array(a['native_ground_anchor_px'],dtype=np.float32);foot=np.array(b['target_foot_px'],dtype=np.float32)
    def world(raw):return (foot+(np.array(raw,dtype=np.float32)-anchor)*np.float32(a['world_scale'])).tolist()
    closed=world(a['native_closed_ground_polygon_px']);channel=world(a['native_front_walk_channel_px'])
    new.append((b['id'],closed,channel));bounds.append([min(x for x,y in closed)-32,min(y for x,y in closed)-32,max(x for x,y in closed)+32,max(y for x,y in closed)+32])
def intersects(a,b):return a[0]<b[2] and a[2]>b[0] and a[1]<b[3] and a[3]>b[1]
def affected(p):return any(r[0]<=p[0]<r[2] and r[1]<=p[1]<r[3] for r in bounds)
def route_affected(points):return any(intersects([min(a[0],b[0])-18,min(a[1],b[1])-18,max(a[0],b[0])+18,max(a[1],b[1])+18],r) for a,b in zip(points,points[1:]) for r in bounds)
def body(foot,half=(17,12),NPC=True):
    rect=[foot[0]-half[0],foot[1]-half[1],foot[0]+half[0],foot[1]+half[1]]
    hits=[{'inherited_solid_index_after_retirement':i,'overlap':overlap(poly,rect)} for i,poly in enumerate(solids) if overlap(poly,rect)>1e-6]
    for id,closed,channel in new:
        poly=closed
        for axis,edge,greater in [(0,rect[0],True),(0,rect[2],False),(1,rect[1],True),(1,rect[3],False)]:
            if poly:poly=clip(poly,axis,edge,greater)
        hit=area(poly)-area(convex_clip(poly,channel)) if poly else 0
        if hit>1e-6:hits.append({'new_building':id,'closed_minus_channel_overlap':hit})
    npcs=[]
    if NPC:
        for actor in P['npcs']:
            f=actor['foot'];h=actor['half_body'];o=actor.get('body_offset_px',[0,0]);d=actor['data'];axis=d.get('patrol_axis',[1,0]);dist=d.get('patrol_distance',0) if d.get('movement_mode')=='patrol' else 0
            sweep=[f[0]+o[0]-h[0]-abs(axis[0]*dist),f[1]+o[1]-h[1]-abs(axis[1]*dist),f[0]+o[0]+h[0]+abs(axis[0]*dist),f[1]+o[1]+h[1]+abs(axis[1]*dist)]
            if intersects(rect,sweep):npcs.append({'id':d['npc_id'],'sweep_rect_xyxy':sweep})
    return {'foot':foot,'body_rect_xyxy':rect,'ground_covers':ground_covers(ground,rect),'solid_hits':hits,'NPC_sweep_hits':npcs}
def route(points,half=(17,12),NPC=True):
    failures=[];count=0
    for si,(a,b) in enumerate(zip(points,points[1:])):
        steps=max(1,math.ceil(math.dist(a,b)))
        for j in range(steps+1):
            foot=[a[i]+(b[i]-a[i])*j/steps for i in range(2)];r=body(foot,half,NPC);count+=1
            if not r['ground_covers'] or r['solid_hits'] or r['NPC_sweep_hits']:
                failures.append({'segment':si,'step':j,'detail':r});break
    return {'passed':not failures,'samples_until_firstbad_per_segment':count,'firstbad_per_segment':failures}
new_routes={r['id']:route(r['points_px']) for r in I['new_door_routes']}
old_routes={r['id']:route(r['points_px']) for r in old['routes'] if route_affected(r['points_px'])}
doors={r['key']:{'activation':body(r['foot']),'return':body(r['return_foot'])} for r in P['portals'] if affected(r['foot']) or affected(r['return_foot'])}
actors={}
for a in P['npcs']:
    d=a['data'];f=a['foot'];axis=d.get('patrol_axis',[1,0]);dist=d.get('patrol_distance',0) if d.get('movement_mode')=='patrol' else 0
    points=[[f[i]-axis[i]*dist for i in range(2)],[f[i]+axis[i]*dist for i in range(2)]]
    if route_affected(points):actors[d['npc_id']]=route(points,a['half_body'],False)
migrations=[]
for logical,d in P['districts'].items():
    for version,rows in [('current',d['migrations'])]+list(d.get('legacy_version_migrations',{}).items()):
        for row in rows:
            p=row['target_foot_px']
            if affected(p):migrations.append({'logical':logical,'version':version,'reason':row['reason'],'check':body(p)})
proposal=[[3072,3224],[3072,3200],[2520,3200],[2520,3160]]
print(json.dumps({'new_routes':new_routes,'affected_old_routes':old_routes,'affected_doors':doors,'affected_actor_sweeps':actors,'affected_migrations':migrations,'unique_east_proposal':{'points_px':proposal,'check':route(proposal)},'scope':'Only native three-building delta AABBs+32 and intersecting old route sweeps+18. Original nine components not recompiled. Convex closed-minus-channel diagnostic with source-f32 transformed vertices; Source Godot clip remains authoritative.'},ensure_ascii=False,indent=2))
