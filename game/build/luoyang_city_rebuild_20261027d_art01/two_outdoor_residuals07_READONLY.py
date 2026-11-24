"""Fixed two residuals only; no engine, writes, search, or source compilation."""
from pathlib import Path
import hashlib, json, math, struct

G = Path(__file__).resolve().parents[2]
N = G / 'build/luoyang_regions_20261027d_source01'
P = N / 'regions_author03_three_real_rooms_BUILD.json'
assert hashlib.sha256(P.read_bytes()).hexdigest() == '2eae38353fea2b0f2326cd8d3ff6aaa7f2391dc3708d746637978f574c977eda'
A = json.loads(P.read_text(encoding='utf-8-sig'))
source = (G / 'build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8-sig')
scope = {'struct': struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')], scope)
T = {}
for k in ['luoyang_estate_riverside_20261021ai', 'ch4_s4_ancient_temple']:
    pin = A['terminal_bindings'][k]
    raw = (G / pin['path'][6:]).read_bytes()
    assert len(raw) == pin['bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    v = scope['FrozenVariant'](raw); T[k] = v.value(); assert v.p == len(raw)

def shift(poly, delta):
    return [[x + delta[0], y + delta[1]] for x, y in poly]

def geometry(region):
    rows = []
    for d in region['districts']:
        old = T[d['logical_id']]
        assignment = {o: [p['target_anchor_px'][i] - p['source_anchor_px'][i] for i in range(2)] for p in d['plots'] for o in p['owners']}
        for s in old['solids']:
            if s['owner_id'] not in d['retired_owners']:
                rows.append((s['id'], s['owner_id'], shift(s['points_px'], assignment[s['owner_id']])))
        rows += [(s['id'], s['id'], s['points_px']) for s in d.get('new_solids', [])]
    for instance in region.get('reused_instances', []):
        old = T[instance['donor_logical_id']]
        owner = instance['donor_owner_id']
        r, = [r for r in old['render'] if r['owner_id'] == owner]
        delta = [instance['target_foot_px'][i] - r['foot_px'][i] for i in range(2)]
        rows += [(instance['id'] + '/' + s['id'], instance['id'], shift(s['points_px'], delta)) for s in old['solids'] if s['owner_id'] == owner]
    return rows

def clip(poly, axis, edge, greater):
    result = []
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        inside_a = a[axis] >= edge if greater else a[axis] <= edge
        inside_b = b[axis] >= edge if greater else b[axis] <= edge
        if inside_a: result.append(a)
        if inside_a != inside_b:
            t = (edge - a[axis]) / (b[axis] - a[axis])
            result.append([a[j] + t * (b[j] - a[j]) for j in range(2)])
    return result

def overlap(poly, rect):
    for axis, edge, greater in [(0, rect[0], True), (0, rect[2], False), (1, rect[1], True), (1, rect[3], False)]:
        if not poly: return 0.0
        poly = clip(poly, axis, edge, greater)
    return abs(sum(p[0] * poly[(i+1)%len(poly)][1] - poly[(i+1)%len(poly)][0] * p[1] for i,p in enumerate(poly))) / 2 if poly else 0.0

def ground_covers(region, body):
    rects = [[*g['rect'][0], g['rect'][0][0]+g['rect'][1][0], g['rect'][0][1]+g['rect'][1][1]] for g in region['ground']]
    ys = sorted(set([body[1], body[3]] + [y for r in rects for y in [r[1],r[3]] if body[1]<y<body[3]]))
    for low, high in zip(ys,ys[1:]):
        y=(low+high)/2; covered=body[0]
        for left,right in sorted((r[0],r[2]) for r in rects if r[1]<=y<=r[3]):
            if left>covered: break
            covered=max(covered,right)
        if covered<body[2]: return False
    return True

def inspect(region, solids, foot):
    body=[foot[0]-17, foot[1]-12, foot[0]+17,foot[1]+12]
    hits=[{'id':id,'owner':owner,'polygon':poly,'overlap_area':overlap(poly,body)} for id,owner,poly in solids if overlap(poly,body)>1e-6]
    npc_hits=[]
    for d in region['districts']:
        for row in T[d['logical_id']]['npcs']:
            id=row['data']['npc_id']
            if id not in d['actors']: continue  # explicit resident moved indoors
            f=d['actors'][id]; off=row.get('body_offset_px',[0,0]); h=row.get('half_body',[17,15])
            data=row['data']; axis=data.get('patrol_axis',[1,0]); distance=data.get('patrol_distance',0) if data.get('movement_mode')=='patrol' else 0
            bounds=[f[0]+off[0]-h[0]-abs(axis[0]*distance),f[1]+off[1]-h[1]-abs(axis[1]*distance),f[0]+off[0]+h[0]+abs(axis[0]*distance),f[1]+off[1]+h[1]+abs(axis[1]*distance)]
            if body[0]<bounds[2] and body[2]>bounds[0] and body[1]<bounds[3] and body[3]>bounds[1]: npc_hits.append(id)
    return {'foot':foot,'body':body,'ground_covers':ground_covers(region,body),'solid_hits':hits,'NPC_hits':npc_hits}

E=A['regions']['luoyang_estate_region_27d']; ES=geometry(E)
M=A['regions']['luoyang_temple_region_27d']; MS=geometry(M)
old=next(r['points_px'] for r in M['routes'] if r['id']=='temple_ambush_search')
new=[[1536,3100],[1840,3100],[1840,2210],[1800,2210]]
def route(route):
    count=0
    for a,b in zip(route,route[1:]):
        steps=max(1,math.ceil(math.dist(a,b)))
        for j in range(steps+1):
            p=[a[i]+(b[i]-a[i])*j/steps for i in range(2)]; count+=1
            d=inspect(M,MS,p)
            if not d['ground_covers'] or d['solid_hits'] or d['NPC_hits']: return {'passed':False,'sample':count,'first_failure':d}
    return {'passed':True,'samples':count}
print(json.dumps({'Estate_old':inspect(E,ES,[2740,3480]),'Estate_unique_new':inspect(E,ES,[2740,3540]),'Temple_old':route(old),'Temple_unique_new':route(new),'note':'Independent offline double-precision body/ground diagnostic only. Root source compiler remains authoritative; no engine calls.'},ensure_ascii=False,indent=2))
