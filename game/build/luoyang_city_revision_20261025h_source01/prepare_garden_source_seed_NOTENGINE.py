"""Bridge render transforms from fixed author/compiler expressions, never Field observations."""
from pathlib import Path
import json,hashlib,struct
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/';N='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return b
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def mul(v,a):return [f(f(x)*f(a))for x in v]
def div(v,w):return [f(f(x)/f(y))for x,y in zip(v,w)]
def add(a,b):return [f(f(x)+f(y))for x,y in zip(a,b)]
def sub(a,b):return [f(f(x)-f(y))for x,y in zip(a,b)]
def world(v):return [f(f(x)*f(y))for x,y in zip(div(v,[3072,2048]),[3072,2048])]
a=json.loads(checked(N+'author_river_bridge03_NOTREADY.json','06d873797e954a4f7b874a85b421a1b1dda87b2072170d7749eeaaf3ddc77cb6'))
bc=a['bridge_contract'];assert bc['source_size']==[1774,887]and bc['uniform_scale']==.7 and bc['front_region_source_rect']==[200,522,1374,208]
center=bc['bridge_center'];region=bc['front_region_source_rect'];source_size=bc['source_size'];s=f(.7)
region_center=add(region[:2],mul(region[2:],.5));front_center=add(center,mul(sub(region_center,mul(source_size,.5)),s))
whole_size=mul(source_size,s);front_size=mul(region[2:],s)
def transform(pos,size,texsize):return dict(position_px=world(pos),scale=div(size,texsize),centered=True)
whole=transform(center,whole_size,source_size);front=transform(front_center,front_size,region[2:])
bindingpin=dict(path=N+'runtime02_READY/garden_river_binding_READY.json',sha256='7ecb31c6adde123f7b365ba6596dc1eed3b1e795c3b4a6baa3162992e3bf5cdf');binding=json.loads(checked(bindingpin['path'],bindingpin['sha256']))
mp=dict(path=R+'unified28_candidates01/maps/expected_Family_source_receipt.json',sha256='0d001c2b03d58a7ce9d2f2f60e8682a17c062d827946bce991cfc88f0f930c72');sources=json.loads(checked(mp['path'],mp['sha256']))['source_sha256']
v=dict(status='SOURCE_DERIVED_GARDEN_BRIDGE_FIELD_SEED_NOT_RUNTIME_OBSERVATIONS',scene_path=binding['child']['scene.res']['path'],layout_path=binding['child']['layout.res']['path'],
 scene_sha256=binding['child']['scene.res']['sha256'],layout_sha256=binding['child']['layout.res']['sha256'],family_path=N+'runtime02_READY/Family_garden_river_READY.gd',family_sha256='2e4890fe3f1c25afea01c8395d615496c36b3d581916ea24d0f465722cae63ee',
 native_geometry_path=N+'runtime01_NOTREADY/NativeGeometry_garden_river_CANDIDATE.gd',native_geometry_sha256='1d11051c4ed6f90d4555518449d496234efa032d0b43e33b5051e7b58fe0edc5',
 expected_family_sources=sources,expected_family_count=len(sources),expected_family_map=mp,
 source_approach_px=[880,976],approachUV=div([880,976],[3072,2048]),approach_position=world([880,976]),
 end_position=world([2192,976]),midpoint=world([1536,976]),water_negatives=[[1536,800],[1536,1200]],
 bridge_id='garden_stone_bridge_walkable_25h',rail_id='garden_stone_bridge_front_rail_25h',bridge_png=a['assets']['stone_bridge']['texture'],bridge_position_px=whole['position_px'],bridge_scale=whole['scale'],rail_position_px=front['position_px'],rail_scale=front['scale'],
 bridge=whole,rail=front,front_atlas=binding['front_region'],source_region=region,whole_bridge_z=-17,front_source_depth_y=bc['front_region_depth_source_y'],
 source_size_px=source_size,source_render_size_px=whole_size,front_render_size_px=front_size,source_uniform_scalar=s,
 native_visual_count=56,native_solid_count=16,portal_count=2,original_NPC_count=4,
 formula='Godot real_t float32: source Vector2 operations; scalar .7 is cast to real_t before Vector2 multiplication. Normalize by3072x2048 then Field multiply. Texture size division yields Vector2f32. No actor/Field/publisher output read.',
 engine_calls=0,packet_decode=0,PNG_decode=0,geometry_replay=0,actual_Field_pass=False)
b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();p=P/'Garden_bridge_source_seed_NOT_RUNTIME.json'
with p.open('xb')as stream:stream.write(b)
print(json.dumps(dict(path=R+p.name,sha256=sha(b),bytes=len(b),bridge=whole,rail=front)))
