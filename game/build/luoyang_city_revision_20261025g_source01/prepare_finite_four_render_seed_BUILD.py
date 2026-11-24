"""Independent donor/source f32 expressions, no binary/image/Field observations."""
from pathlib import Path
import struct,json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def doc(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def v(x):return [f(x[0]),f(x[1])]
def add(a,b):return [f(a[i]+b[i]) for i in range(2)]
def sub(a,b):return [f(a[i]-b[i]) for i in range(2)]
def mul(a,n):return [f(x*f(n)) for x in a]
def div(a,b):return [f(a[i]/b[i]) for i in range(2)]
authorpin=dict(path='res://build/luoyang_market_courtyard_links_20261025g_system01/author_courtyard_links02_NOTREADY.json',sha256='e91631e6b5c5f44a4bbe7d67c1a2519c498ff9e403d9452e2484274dc8032cad')
a=doc(authorpin['path'],authorpin['sha256'])
priorpin=dict(path='res://build/luoyang_city_revision_20261025g_qa01/prior01_output/33724/prior.json',sha256='4fe0b510d4200243a9f7f935888c5b97e98122439de30d4aafac28d92501f8c5')
prior=doc(priorpin['path'],priorpin['sha256']);assert prior['checks']==154 and prior['failures']==0
rows=[]
for p in a['additions']+[p for p in a['changes'] if p['id'] in ['goods_stall','medicine_stall']]:
    asset=a['assets'][p['asset_id']];size=v(asset['source_size_px']);anchor=v(asset['source_ground_anchor_px']);foot=v(p['foot_px']);scale=p['scale']
    render=mul(size,scale)
    normalized=div(add(foot,mul(sub(mul(size,.5),anchor),scale)),[3072,2048])
    position=[f(normalized[0]*3072),f(normalized[1]*2048)]
    sprite_scale=[f(render[i]/size[i]) for i in range(2)]
    polygons=[]
    for poly in asset.get('ground_solid_polygons_px',[]):polygons.append([add(foot,mul(sub(v(q),anchor),scale)) for q in poly])
    for rect in asset.get('ground_solid_rects_xywh_px',[]):
        lo=v(rect[:2]);hi=add(lo,v(rect[2:]));poly=[lo,[hi[0],lo[1]],hi,[lo[0],hi[1]]]
        polygons.append([add(foot,mul(sub(q,anchor),scale)) for q in poly])
    rows.append(dict(id=p['id'],texture=asset['texture'],texture_sha256=asset['source_sha256'],centered=True,source_size_px=size,source_ground_anchor_px=anchor,authored_scale=scale,world_foot_px=foot,normalized_pos_f32=normalized,position_px=position,render_size_px=render,scale=sprite_scale,physical_polygons_px=polygons,physical_polygon_count=len(polygons),ghost_occlusion=True,whole_prop_fade=False,source_asset_id=p['asset_id']))
assert len(rows)==4 and [r['physical_polygon_count'] for r in rows]==[4,4,1,1]
# Independent runtime-native oracle values constrain the binary32 helper, not vice versa.
opening_left=rows[0]['physical_polygons_px'][1][1][0]
opening_right=rows[0]['physical_polygons_px'][2][0][0]
assert opening_left==prior['gallery_clearance']['native_f32_world_left'] and opening_right==prior['gallery_clearance']['native_f32_world_right']
d=dict(status='ROOT_REVIEW_SOURCE_DERIVED_FOUR_RENDER_SEED_NOT_FIELD_OBSERVATIONS',ready=False,author=authorpin,independent_prior=priorpin,scene_id='ch4_s3_luoyang_market',render_count=45,parent_render_count=43,expected_render4=rows,formula='Vector2 f32 source_size*.5 - anchor; f32 * scalar; f32 + foot; f32 / SIZE; Field component*SIZE -> Vector2 f32. render_size f32/source dimension float64 -> Vector2 f32. Every primitive point f32 foot + ((f32 sourcePoint - anchor) * f32 authoredscale).',same_source_donor_validated_by_prior154=True,actual_publisher_or_runtime_values_used=False,no_epsilon_or_geometry_recompile=True,Stage_calls=0,engine_calls=0,media_decodes=0,packet_decodes=0)
raw=(json.dumps(d,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=HERE/'finite_four_render_source_seed_NOTREADY.json'
with p.open('xb') as out:out.write(raw)
print(json.dumps(dict(path=S+p.name,sha256=sha(raw),bytes=len(raw),four=[dict(id=r['id'],position_px=r['position_px'],scale=r['scale']) for r in rows])))
