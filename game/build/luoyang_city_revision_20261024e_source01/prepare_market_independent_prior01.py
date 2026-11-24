"""BUILD only: fixed-source float32 model and hardfalse native pixel oracle.
No PNG/packet/Resource decode, engine, collector or canonical writes.
"""
from pathlib import Path
import copy, hashlib, json, math, struct

GAME = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = HERE / 'market_prior01_NOTREADY'
SYS = GAME / 'build/luoyang_city_blocks_20261024e_system01'
OLD = GAME / 'build/luoyang_city_space_20261024b_source01'
pins = {}

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def fixed(p, h):
    assert sha(p) == h, (str(p), sha(p), h)
    pins[p.as_posix()] = h
    return json.loads(p.read_bytes())
def emit(name, value):
    p = OUT / name
    data=(json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii')
    if p.exists():
        assert p.read_bytes()==data, ('PRESERVE_EXISTING_BUILD',p)
        return p,sha(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(data)
    return p, sha(p)
def f(n): return struct.unpack('<f', struct.pack('<f', float(n)))[0]
def v(p):
    if isinstance(p, dict): p = p['xy']
    assert len(p) == 2 and all(math.isfinite(x) for x in p)
    return [f(x) for x in p]
def add(a, b): return [f(x+y) for x,y in zip(a,b)]
def sub(a, b): return [f(x-y) for x,y in zip(a,b)]
def mul(a, n): return [f(x*f(n)) for x in a]
def world(raw, anchor, foot, scale):
    return [add(v(foot), mul(sub(v(p), v(anchor)), scale)) for p in raw]
def bits(p): return struct.pack('<ff', *v(p)).hex()

a = fixed(SYS/'author_market_block04_NOTREADY.json', '697397f26fdf0b8c83d1cabbacd4c2a12ff235f455ae07b95522f2c01c5df318')
inp = fixed(SYS/'publication_input01_NOTREADY.json', 'c27b4d7fa5b0fe157118182a2429f0ae2dca66927ed5111ec5f31a3fc0f72f9b')
prior = fixed(OLD/'author_space_delta_route_detours_successor06_NOTREADY.json', '7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f')
model = fixed(GAME/'build/luoyang_city_revision_20261024b_qa01/market_mask_prior26_NOTREADY/independent_f32_source_model_NOT_PIP.json', 'f4843526445d6ba40ae2a6358a5786c83b2fcd4544413190390fc71bfc8c4eb3')
fb = fixed(OLD/'current_market_native_projection_ROOT_ACTUAL.json', 'fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a')
proved = fixed(GAME/'build/luoyang_city_revision_20261024b_root01/market_prior_bits_READY/output/result.json', 'f6da34fe376826c66f5ea56e697df681d628375f6efcff057ac623084a71e7f9')
assert proved['complete'] and proved['failures'] == 0

# Re-derive old25 from the immutable source23 and prior06, not publisher output.
old23 = {}
for row in fb['record']['objects']:
    old23[row['id']] = dict(id=row['id'], foot=v(row['world_foot_px']), center=v(row.get('physical_center_px',row['world_foot_px'])), size=v(row.get('collision_size_px',[0,0])), polygons=[[v(p) for p in poly] for poly in row.get('solid_polygons_px',[])])
replacement = {}
for place in prior['complete_buildings']:
    asset=prior['assets'][place['asset_id']]
    replacement[place['id']]=dict(id=place['id'],foot=v(place['foot_px']),center=v(place['foot_px']),size=v([0,0]),polygons=[world(p,asset['source_ground_anchor_px'],place['foot_px'],place['uniform_scale']) for p in asset['ground_solid_polygons_px']])
moves={r['id']:r for r in prior['native_object_moves']}
native=[]
for old in old23.values():
    if old['id'] in prior['retire_closed_stall_ids']: continue
    if old['id'] in replacement: native.append(replacement[old['id']]);continue
    row=copy.deepcopy(old)
    if old['id'] in moves:
        move=moves[old['id']]; assert old['foot']==v(move['old_foot_px'])
        d=sub(v(move['new_foot_px']),v(move['old_foot_px']))
        row['foot']=v(move['new_foot_px']);row['center']=add(old['center'],d)
        row['polygons']=[[add(p,d) for p in poly] for poly in old['polygons']]
    native.append(row)
for place in prior['low_wall_components']:
    asset=prior['low_wall_asset']
    native.append(dict(id=place['id'],foot=v(place['foot_px']),center=v(place['foot_px']),size=v([0,0]),polygons=[world(p,asset['source_ground_anchor_px'],place['foot_px'],place['uniform_scale']) for p in asset['ground_solid_polygons_px']]))
assert [{k:r[k] for k in ['id','center','size','polygons']} for r in native] == model['child']
assert len(native)==25

# DG source expressions, not a call to its executable API. Replacement appends
# DG polygon to the existing medicine row, exactly original apply_render.
before=copy.deepcopy(native)
for place in prior['runtime_district']['placements']:
    asset=prior['district_assets'][place['asset_id']]
    polys=[world(p,asset['source_ground_anchor_px'],place['foot_px'],place['scale']) for p in asset['ground_solid_polygons_px']]
    if place.get('replaces'):
        rows=[r for r in before if r['id']==place['id']];assert len(rows)==1
        rows[0]['polygons'] += polys
    else:
        assert place['id'] not in [r['id'] for r in before]
        before.append(dict(id=place['id'],foot=v(place['foot_px']),center=v(place['foot_px']),size=v([0,0]),polygons=polys))
assert len(before)==37
after=copy.deepcopy(before); changed=[]
for group in ['building_changes','wall_changes','native_prop_moves','district_moves']:
    for change in a[group]:
        rows=[r for r in after if r['id']==change['id']];assert len(rows)==1
        row=rows[0];assert row['foot']==v(change['old_foot_px']), change['id']
        d=sub(v(change['foot_px']),v(change['old_foot_px']))
        row['foot']=v(change['foot_px']);row['center']=add(row['center'],d)
        row['polygons']=[[add(p,d) for p in poly] for poly in row['polygons']]
        if group=='wall_changes' or change.get('rebuild_source_plinths'):
            asset=a['assets'][change['asset_id']]
            row['polygons']=[world(p,asset['source_ground_anchor_px'],change['foot_px'],change['scale']) for p in asset['ground_solid_polygons_px']]
        changed.append(change['id'])
for place in a['new_components']:
    asset=a['assets'][place['asset_id']]
    assert place['id'] not in [r['id'] for r in after]
    after.append(dict(id=place['id'],foot=v(place['foot_px']),center=v(place['foot_px']),size=v([0,0]),polygons=[world(p,asset['source_ground_anchor_px'],place['foot_px'],place['scale']) for p in asset['ground_solid_polygons_px']]))
assert len(after)==43

def row_rects(row):
    out=[]
    for poly in row['polygons']:
        low=[min(p[i] for p in poly) for i in range(2)];high=[max(p[i] for p in poly) for i in range(2)]
        end=add(low,sub(high,low)) # native Rect2(low,high-low).end
        out.append([math.floor(low[0])-1,math.floor(low[1])-1,math.ceil(end[0])+2,math.ceil(end[1])+2])
    if all(n>0 for n in row['size']):
        low=sub(row['center'],mul(row['size'],.5));end=add(low,row['size'])
        out.append([math.floor(low[0])-1,math.floor(low[1])-1,math.ceil(end[0])+2,math.ceil(end[1])+2])
    return out
# Half-open integer domains. Mirror only the declared conservative closure rule,
# never Python PIP. All touching boxes merge by their bounding union.
affected_old=[r for ident in changed for r in before if r['id']==ident]
affected_new=[r for ident in changed for r in after if r['id']==ident]+after[37:]
raw_domains=[box for r in affected_old+affected_new for box in row_rects(r)]
merged=[]
for box in raw_domains:
    box=[max(0,box[0]),max(0,box[1]),min(3072,box[2]),min(2048,box[3])]
    assert box[2]>box[0] and box[3]>box[1]
    again=True
    while again:
        again=False
        for i,old in enumerate(merged):
            if box[0]<=old[2] and old[0]<=box[2] and box[1]<=old[3] and old[1]<=box[3]:
                box=[min(box[0],old[0]),min(box[1],old[1]),max(box[2],old[2]),max(box[3],old[3])]
                merged.pop(i);again=True;break
    merged.append(box)
area=sum((b[2]-b[0])*(b[3]-b[1]) for b in merged)
assert area<=inp['pixel_visit_limit'], (area, inp['pixel_visit_limit'])
def encoded(rows):
    return [dict(id=r['id'],foot=r['foot'],center=r['center'],size=r['size'],polygons=r['polygons'],foot_bits=bits(r['foot']),center_bits=bits(r['center']),size_bits=bits(r['size']),polygon_bits=[[bits(p) for p in poly] for poly in r['polygons']]) for r in rows]
model_doc=dict(status='INDEPENDENT24E_SOURCE_F32_NOT_PIXEL_PRIOR',ready=False,native25=encoded(native),before37=encoded(before),after43=encoded(after),changed_ids=changed,added_ids=[r['id'] for r in after[37:]],raw_half_open_domains=raw_domains,merged_half_open_domains=merged,union_visited_pixels=area,source_expression='Vector2 constructor -> f32; subtraction -> f32; scalar -> f32 then multiplication -> f32; addition -> f32. No fused reassociation, epsilon, Python PIP or publisher output.',parent25_exact_F484=True,parent_native_packet_decodes=0,source_sha256=pins.copy())
mp,mh=emit('independent_f32_model_NOT_PIP.json',model_doc)
pins[mp.as_posix()]=mh
for res,h in inp['source_pins'].items():
    # Declare fixed pins; actual oracle verifies. No asset decode or mediahash here.
    pins[(GAME/res[6:]).as_posix()]=h
for p in [SYS/'publish_market_block01_NOTREADY.gd',SYS/'market_block_projection03_NOTREADY.gd']:
    pins[p.as_posix()]=sha(p)
fresh=fixed(HERE/'fresh_24e_current_observation_READONLY.json','63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85')
saves=[r['path'].replace('\\','/') for r in fresh['current_save_protection_start']]
assert len(saves)==15
fixture=dict(ready=False,status='ROOT_READ_APPROVAL_REQUIRED_INDEPENDENT24E_CPU_PRIOR',blockers=['Root must read and mechanically freeze ready literals; no engine run by Source.'],whole_ms=60000,model_path=mp.as_posix(),model_sha256=mh,author_path=(SYS/'author_market_block04_NOTREADY.json').as_posix(),parent_author_path=(OLD/'author_space_delta_route_detours_successor06_NOTREADY.json').as_posix(),parent_walk_path=(GAME/inp['walk_path'][6:]).as_posix(),raw_walk_path=(GAME/inp['raw_walk_path'][6:]).as_posix(),parent_RGBA_sha256=a['parent']['walk_RGBA_sha256'],source_sha256=pins,save_paths=saves,union_visited_pixels=area,merged_domain_count=len(merged),output_path=(OUT/'output_NOTREADY/result.json').as_posix(),scope='Exactly parent/raw PNG2; no assetPNG/packet/Resource/helper/publisher/Scene/Field/Physics/collector calls. Source-f32 model first; native PIP local domains only. No PNG write. Current saves observed at execution, never restored. Pixel child SHA/changed count UNKNOWN before Root oracle.')
fp,fh=emit('fixture_NOTREADY.json',fixture)
key_template=(HERE/'market_prior_oracle_template01.gd').read_bytes()
key=key_template.replace(b'PENDING_FIXTURE_PATH',fp.as_posix().encode()).replace(b'PENDING_FIXTURE_SHA',fh.encode())
assert b'PENDING_' not in key
kp=OUT/'oracle_NOTREADY.gd';assert not kp.exists();kp.write_bytes(key)
project=OUT/'project.godot';assert not project.exists();project.write_bytes(b'config_version=5\n[application]\nconfig/name="24e independent CPU prior"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
hp,hh=emit('handoff_NOTREADY.json',dict(status='BUILD_ONLY_NOT_RUN',key=dict(path=kp.as_posix(),sha256=sha(kp)),fixture=dict(path=fp.as_posix(),sha256=fh),model=dict(path=mp.as_posix(),sha256=mh),project=dict(path=project.as_posix(),sha256=sha(project)),raw_domains=len(raw_domains),merged_domains=len(merged),union_visited_pixels=area,packet_decodes=0,images_planned=2,changed_pixels='UNKNOWN',child_RGBA_sha256='UNKNOWN',future_publisher_required_prior_fields=['ready','parent_RGBA_sha256','expected_child_RGBA_sha256','changed_pixels','union_visited_pixels'],not_engine_authorization=True))
print(json.dumps(dict(key_sha256=sha(kp),fixture_sha256=fh,model_sha256=mh,handoff_sha256=hh,raw_domains=len(raw_domains),merged_domains=len(merged),union_pixels=area)))
