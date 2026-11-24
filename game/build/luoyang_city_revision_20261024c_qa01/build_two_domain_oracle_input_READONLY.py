"""Independent source-only model; no PNG/packet/Godot access. NEW JSON artifacts only."""
import hashlib, json, struct
from fractions import Fraction as F
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / 'two_domain_native_oracle_READY'
def path(res): return ROOT / res.removeprefix('res://')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(res, expected):
    p = path(res)
    assert sha(p) == expected, res
    return json.loads(p.read_text(encoding='utf-8'))
AUTHOR='res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json'
ASHA='51582b8d281876b08989acef6d16e9216022bad34640cb7bf1c872f0cc2cf429'
OLD='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/input_READY.json'
OSHA='3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7'
LOW='res://build/luoyang_city_full_rollout_20261022ap_system01/yamen_waiting_cluster_epoch01_retry1/author_delta_READY.json'
LSHA='5295d53977f3773bd2861d384aad2f64a5b14b0c56461e3a67bdbd15d6d6505b'
HELP='res://build/luoyang_yamen_courts_20261024c_system01/retired_order02/courts_projection_CANDIDATE.gd'
HSHA='2e7799040e0a29abda1f485e901f0b2df0615b58cd7fae4fe1280eedb1f23897'
RAW='res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/raw_walk.png'
PARENT='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen/walk.png'
def f32(v): return struct.unpack('<f', struct.pack('<f',v))[0]
def qp(points): return [[f32(x),f32(y)] for x,y in points]
def orient(a,b,c): return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
def on(a,b,p): return orient(a,b,p)==0 and min(a[0],b[0])<=p[0]<=max(a[0],b[0]) and min(a[1],b[1])<=p[1]<=max(a[1],b[1])
def touch(a,b,c,d):
    return (orient(a,b,c)*orient(a,b,d)<0 and orient(c,d,a)*orient(c,d,b)<0) or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)
def inside(p,poly):
    parity=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if on(a,b,p): return True
        if (a[1]>p[1]) != (b[1]>p[1]):
            if p[0] < a[0]+(p[1]-a[1])*(b[0]-a[0])/(b[1]-a[1]): parity=not parity
    return parity
def hit(rect, points):
    x0,y0,x1,y1=map(F,rect); body=[(x0,y0),(x1,y0),(x1,y1),(x0,y1)]
    poly=[tuple(map(F,p)) for p in points]
    if any(inside(p,poly) for p in body) or any(x0<=p[0]<=x1 and y0<=p[1]<=y1 for p in poly): return True
    return any(touch(a,b,c,d) for a,b in zip(body,body[1:]+body[:1]) for c,d in zip(poly,poly[1:]+poly[:1]))
def dump(name,obj):
    p=OUT/name; assert not p.exists(),p
    p.write_bytes((json.dumps(obj,ensure_ascii=True,indent=2)+'\n').encode())
    return {'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size}

def main():
    a=load(AUTHOR,ASHA); old=load(OLD,OSHA); low=load(LOW,LSHA)
    assert sha(path(HELP))==HSHA
    first39=old['yamen']['raw_geometry']['solids']
    assert len(first39)==39 and first39==a['original_combined_geometry'][:39]
    final3=[]
    for source,row in zip(low['new_solids'],a['original_combined_geometry'][39:]):
        assert row['id']==source['id'] and qp(source['points_px'])==row['points_px']
        final3.append(dict(id=source['id'],kind='NEW_PUBLISHED_LOW_PROP_POLYGON',points_px=qp(source['points_px'])))
    before=first39+final3
    retired=[x for x in a['retired_primitive_ids']]
    assert len(retired)==4 and len(set(retired))==4
    assert all(sum(r['id']==rid for r in before)==1 for rid in retired)
    anchor=a['asset']['source_ground_anchor_px']; source=a['asset']['ground_solid_polygons_px'][0]
    new=[]
    for change in a['annex_changes']:
        assert change['new_uniform_scale']==0.5
        foot=change['new_foot_px']
        pts=[[f32(f32(foot[i])+f32(f32(f32(p[i])-f32(anchor[i]))*f32(.5))) for i in range(2)] for p in source]
        assert pts==change['new_primitive']['points_px']
        new.append(dict(id=change['new_primitive']['id'],kind='SOURCE_PROJECTED_OFFICIAL_BASE',points_px=pts))
    child=[r for r in before if r['id'] not in retired]+new
    assert child==a['new_combined_geometry'] and len(child)==40
    native=[r for r in before if r['kind']!='ADDITIVE_NATIVE_BASE']; assert len(native)==32
    domains=[r['closed'] for r in a['local_mask_domains']]
    assert domains==[[249,943,765,1111],[2297,993,2839,1211]]
    visited=sum((c[2]-c[0]+1)*(c[3]-c[1]+1) for c in domains);assert visited==206290
    route_rows=[]
    for route in a['proposed_short_routes']:
        for i,(p,q) in enumerate(zip(route['points_px'],route['points_px'][1:])):
            assert p[0]==q[0] or p[1]==q[1]
            box=[min(p[0],q[0])-17,min(p[1],q[1])-12,max(p[0],q[0])+17,max(p[1],q[1])+12]
            hits=[r['id'] for r in child if hit(box,r['points_px'])]
            assert not hits,(route['id'],i,hits)
            # Source navigation occupancy sweep only, NOT npc_node's offset Physics collider.
            npc=[]
            for n in a['preserved']['all_original_npcs']:
                x,y=n['foot_px'];d=n.get('distance_px',0)
                nb=[x-d-17,y-15,x+d+17,y+15]
                if not (box[2]<nb[0] or nb[2]<box[0] or box[3]<nb[1] or nb[3]<box[1]): npc.append(n.get('id',n.get('source_id')))
            assert not npc,(route['id'],i,npc)
            route_rows.append(dict(id=route['id'],segment=i,sweep_closed=box,solid_hits=hits,npc_nav_sweep_hits=npc))
    assert len(route_rows)==11
    OUT.mkdir(exist_ok=True)
    proof=dict(status='SOURCE_MODEL_EXACT_F32_AND_CONTINUOUS_POLYGON_SWEEPS_NOT_NATIVE_RASTER',passed=True,
        original39_exact=True,low3_source_f32_exact=True,new2_source_expression_f32_exact=True,
        retired4=retired,native_before_count=32,child_combined_count=40,domains_closed=domains,union_visited_pixels=visited,
        continuous_body_px=[34,24],routes=route_rows,npc_nav_envelope_px=[34,30],
        limitations=['NPC nav sweep is not actual offset npc_node Physics collider; runtime remains pending.',
            'No PNG decoded and no pixel prior computed by Python; Geometry2D native ABI remains required.',
            'No old 875 routes/packet/Field/Scene/collector replay.'])
    pp=dump('source_projection_and_continuous_sweeps_READONLY.json',proof)
    inp=dict(status='ROOT_ONLY_INDEPENDENT_TWO_DOMAIN_NATIVE_ABI_ORACLE_READY',ready=True,limit_ms=15000,
        author_path=str(path(AUTHOR)),parent_walk=str(path(PARENT)),raw_walk=str(path(RAW)),
        source_pins={str(path(p)):s for p,s in [(AUTHOR,ASHA),(OLD,OSHA),(LOW,LSHA),(HELP,HSHA),
            (RAW,'0dc78a4affde8a13d1d2f58385b4ac5da102b1718f8e5b48d12dd066b0dedcfa'),
            (PARENT,'8ff4e56df43d6eb166b8859467eb3f2a400d67ca8c9c40b3034f8cf644bb7c10')]},
        old_native_rows=native,child_combined_rows=child,new_source_polygons=source,source_anchor=anchor,
        new_feet=[c['new_foot_px'] for c in a['annex_changes']],new_expected_rows=new,domains_closed=domains,
        expected_visited=visited,parent_RGBA_sha256='3b9cf5b43231a2ac4f8c3f6f53e4307a2c2adf7aeca77f3d9d17d4f12dcc7874',
        source_model_proof=pp,
        output_dir=str(OUT/'project'/'output_READY'),
        scope='Two PNG decodes only; no helper invocation/packet/Scene/Field/collector/PNG output. Native bbox-bounded PIP old32 exact parent then child40 only two domains. Root owns execution.')
    print(json.dumps({'source_proof':pp,'input':dump('input_READY.json',inp)}))

if __name__=='__main__': main()
