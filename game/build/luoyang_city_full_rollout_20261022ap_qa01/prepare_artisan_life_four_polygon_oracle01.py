"""BUILD-only preparation. No Godot, PNG decode, packet, or publisher invocation.

The Python f32 model is explicitly NOT a certified Geometry2D/PIP oracle.
Only a later Root-authorized native run may produce the admitting pixel prior.
"""
import hashlib
import json
import math
import struct
from fractions import Fraction
from pathlib import Path

Q = Path(__file__).resolve().parent
G = Q.parents[1]
Y = 'res://build/luoyang_city_full_rollout_20261022ap_system01/'
R = 'res://build/luoyang_city_full_rollout_20261022ap_root01/'
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT = Q / 'artisan_life_four_polygon_native_oracle01'
PINS = {
    R+'artisan_two_clusters_BUILD_scope_20261024.json': '9499fe95a429601d1360f74ce03b677ecbae453662e360bc10578ef14e87206f',
    Y+'artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json': '03f0a7fd0b71b2657fa783b253d86001813897f0f16e44793f866d09cce7a9f4',
    Y+'artisan_life_delta_publication_epoch01/input_NOTREADY.json': 'dfc8e7367e25b70c77f41ee8df48833b5d773ad2d710d0a567d43eda8bf4b37e',
    Y+'artisan_life_delta_publication_epoch01/publisher_NOTRUN.gd': '7916bf28eba031751fc2e8709513a0dc5a246bee5523dd4f989b71badf1ba707',
    S+'performance81_artisan_two_clusters_independent_A2_parent_prior_BUILD_ONLY.json': 'cf4531be0e3e7879da3dae2bad63b95c8e022bbe01c62c90a04f16b78861887b',
}
def sha(raw): return hashlib.sha256(raw).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return G / p[6:]
def read(p, expected):
    raw = path(p).read_bytes()
    assert sha(raw) == expected.lower(), p
    return raw
def f(v): return struct.unpack('<f', struct.pack('<f', v))[0]
def vector(raw): return [f(x) for x in raw]
def add(a,b): return [f(x+y) for x,y in zip(a,b)]
def sub(a,b): return [f(x-y) for x,y in zip(a,b)]
def mul(a,s): return [f(x*f(s)) for x in a]
def dump(p,d):
    assert not p.exists(), p
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

assert OUT.is_dir(), 'Create the isolated text project by apply_patch first'
first = {p:sha(read(p,h)) for p,h in PINS.items()}
spec_path = Y+'artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json'
cfg_path = Y+'artisan_life_delta_publication_epoch01/input_NOTREADY.json'
spec = json.loads(read(spec_path,PINS[spec_path]))
cfg = json.loads(read(cfg_path,PINS[cfg_path]))
assert not spec['ready'] and not cfg['ready'] and not cfg['independent_prior_ready']
assert len(spec['placements']) == 4 and len(cfg['local_domains_closed']) == 4
native_sources = {}
models = []
union = set()
for raw,declared in zip(spec['placements'],cfg['local_domains_closed']):
    src = raw['source_author']
    source_raw = read(src['path'],src['sha256'])
    native_sources[src['path']] = src['sha256']
    old = json.loads(source_raw)
    matches = [r for r in old['furniture'] if r.get(src['selector_field']) == src['selector_value']]
    assert len(matches) == 1
    row = matches[0]
    assert row['source_sha256'].lower() == raw['source_png_sha256'].lower()
    for a,b in [('texture','texture'),
                ('source_size_px','source_size_px'),('source_ground_anchor_px','source_ground_anchor_px')]:
        assert row[a] == raw[b], (raw['id'],a)
    assert row[src['polygon_field']] == raw['source_ground_solid_polygons_px']
    assert len(raw['source_ground_solid_polygons_px']) == 1
    points = [add(vector(raw['foot_px']),mul(sub(vector(p),vector(raw['source_ground_anchor_px'])),raw['uniform_scale']))
              for p in raw['source_ground_solid_polygons_px'][0]]
    lo = [min(p[j] for p in points) for j in (0,1)]
    hi = [max(p[j] for p in points) for j in (0,1)]
    # Rect2 stores low and f32(high-low), and .end performs the f32 addition.
    end = add(lo,sub(hi,lo))
    closed = [math.floor(lo[0]),math.floor(lo[1]),math.ceil(end[0]),math.ceil(end[1])]
    assert closed == declared
    edge_points = []
    for y in range(closed[1],closed[3]+1):
        for x in range(closed[0],closed[2]+1):
            assert (x,y) not in union
            union.add((x,y))
            for a,b in zip(points,points[1:]+points[:1]):
                ax,ay,bx,by = map(Fraction,[*a,*b])
                if (Fraction(x)-ax)*(by-ay)-(Fraction(y)-ay)*(bx-ax) == 0 and min(ax,bx)<=x<=max(ax,bx) and min(ay,by)<=y<=max(ay,by):
                    edge_points.append([x,y]);break
    models.append({'id':raw['id'],'source_author':src,'source_foot':raw['foot_px'],
                   'source_anchor':raw['source_ground_anchor_px'],'source_uniform_scalar':raw['uniform_scale'],
                   'model_points':points,'model_f32_bytes_hex':[struct.pack('<ff',*p).hex() for p in points],
                   'closed':closed,'integer_boundary_point_count':len(edge_points),
                   'first16_exact_mathematical_boundary_points':edge_points[:16]})
assert len(union) == 8714
parent = cfg['parent']['walk']
assert parent['sha256'] == '9d6edceee42e4d075f920fc1d1cffb388cb8ffc66b5c223084e671a70aff852c'
prior_path = S+'performance81_artisan_two_clusters_independent_A2_parent_prior_BUILD_ONLY.json'
parent_prior = json.loads(read(prior_path,PINS[prior_path]))
assert parent_prior['parent_artifacts'][parent['path']] == parent['sha256']
assert parent_prior['parent_walk_RGBA_sha256'] == cfg['parent_rgba_sha256']
sources = {p:{'path':str(path(p)).replace('\\','/'),'sha256':h} for p,h in {**PINS,**native_sources}.items()}
sources[parent['path']] = {'path':str(path(parent['path'])).replace('\\','/'),'sha256':parent['sha256']}
native_input = {'status':'ARTISAN_LIFE_INDEPENDENT_NATIVE_ORACLE_PREPARATION_NOTREADY','ready':False,
                'limit_usec':5000000,'sources':sources,'spec_key':spec_path,
                'parent_png_key':parent['path'],'parent_rgba_sha256':cfg['parent_rgba_sha256'],
                'domains_closed':cfg['local_domains_closed'],'union_visited_pixels':8714}
dump(OUT/'input_NOTREADY.json',native_input)
gap = {'status':'INDEPENDENT_ARTISAN_LIFE_SOURCE_F32_MODEL_AND_PIP_GAP_NOTREADY','ready':False,
       'not_consumable_as_publisher_prior':True,'source_first':first,
       'four_source_f32_models':models,'domains_closed':cfg['local_domains_closed'],'union_visited_pixels':8714,
       'source_expression':'Vector2(foot)+(Vector2(source_point)-Vector2(anchor))*GDScript_float(scale); native real_t/f32 conversion at each vector operation.',
       'model_boundary':'Python IEEE binary32 per-vector-operation model only; NOT newly validated native ABI or Geometry2D equivalence.',
       'gap':'Previous closed-edge/raycast Python model failed one old rack pixel. Existing native ABI prior is for different polygons; it cannot certify the four new PIP domains. No locally verified Geometry2D implementation source was found. Exact integer edge points exist, so assuming generic closed polygon containment would invent boundary behavior.',
       'expected_child_RGBA_sha256':None,'changed_pixels':None,'whole_inverse_parent_RGBA_sha256':None,
       'parent_rgba_sha256':cfg['parent_rgba_sha256'],
       'proposed_resolution':'Prepared isolated false native key executes original Vector2/Geometry2D expressions over ONLY these8714 new points, one fixed parent PNG decode, no publisher/packet/old27 replay. Root must separately authorize and freeze before execution.',
       'QA_actions':{'engine':0,'PNG_decode':0,'packet_reads':0,'PIP_calls':0,'old_geometry_route_replay':0,'production_writes':0,'future_publisher_output_reads':0},
       'source_final':{p:sha(read(p,h)) for p,h in PINS.items()}}
assert gap['source_first'] == gap['source_final']
dump(OUT/'source_f32_and_boundary_gap_NOTREADY.json',gap)
print(json.dumps({'status':gap['status'],'domains':4,'visited':len(union),
                  'integer_boundary_counts':[m['integer_boundary_point_count'] for m in models],
                  'input_sha256':sha((OUT/'input_NOTREADY.json').read_bytes()),
                  'gap_sha256':sha((OUT/'source_f32_and_boundary_gap_NOTREADY.json').read_bytes()),
                  'PNG_decode':0,'engine':0}))
