"""Source expressions only: four service actors and scoped expected sources."""
from pathlib import Path
import hashlib,json,struct
P=Path(__file__).resolve().parent;G=P.parents[1]
S='res://build/luoyang_indoor_services_20261025h_system01/'
R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def vector(v):return [f32(x)for x in v]
def foot(v):return [f32(f32(f32(v[i])/n)*w)for i,(n,w)in enumerate(zip([1536,1024],[1920,1280]))]
def uv(v):return [f32(f32(v[i])/n)for i,n in enumerate([1536,1024])]
stage_path='res://build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json'
stage=json.loads(checked(stage_path,'c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'))
map_node=stage['nodes']['expected_ch4_s3_luoyang_market_true']
map_bytes=checked(map_node['path'],map_node['sha256']);mp=json.loads(map_bytes)['source_sha256']
regpath='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
registry=json.loads(checked(regpath,mp[regpath]))
author_path=S+'services_author05_CANDIDATE.json';author_sha='7706e07c00a8a318673fd496448f5a48e7005fa8998b9d16f7520615bd3effd8'
author=json.loads(checked(author_path,author_sha));runtime_path=S+'runtime_READY02/services_runtime_READY.gd'
runtime_sha='f898f4b3860dda07bdfc95d62c1b08e30889b89b93843bf9a24d808e8a433fc8'
checked(runtime_path,runtime_sha)
rows=[]
for room_id,row in author['rooms'].items():
 old=registry['rooms'][room_id];oldauthor=json.loads(checked(old['author_path'],old['author_sha256']))
 assert old['runtime_ready'] and old['door_enabled']
 expected={runtime_path:runtime_sha,author_path:author_sha}
 for p in author['room_source_scopes'][room_id]:
  assert p not in expected;expected[p]=author['source_sha256'][p]
 assert len(expected)=={'inn':8,'pawn':91,'herbal':74,'smith':104}[row['role']]
 # Existing PNG IHDR is a header fact, no pixel decode or new import.
 png=checked(row['sprite_path'],author['source_sha256'][row['sprite_path']]);assert png[:8]==b'\x89PNG\r\n\x1a\n'
 size=list(struct.unpack('>II',png[16:24]));assert size==[640,160],(row['role'],size)
 prior_count=1 if row['role']=='smith'else 0
 if prior_count==0:assert oldauthor['npc_policy']['original_npc_definition_raw']=='[]'
 else:
  raw='res://data/scenes/luoyang_assembled_rooms_20261016b/smithy_room.tres'
  original=checked(raw,mp[raw]).decode();assert original.count('"npc_id":')==1 and '"source_foot_px": Vector2(663, 448)'in original
 body=vector([160*.14,160*.18]);off=vector([0,160*.12])
 entry=dict(room_id=room_id,role=row['role'],scene_path=old['scene_path'],layout_path=old['layout_path'],
  scene_sha256=old['source_sha256'][old['scene_path']],layout_sha256=old['source_sha256'][old['layout_path']],
  room_author_path=old['author_path'],room_author_sha256=old['author_sha256'],original_npc_count=prior_count,
  projected_npc_count=1,world_size_px=[1920,1280],source_size_px=[1536,1024],
  source_approach_px=row['approach'],approach_uv=uv(row['approach']),approach_position=foot(row['approach']),
  source_npc_foot_px=row['foot'],npc_uv=uv(row['foot']),NPCposition=foot(row['foot']),npc_position=foot(row['foot']),
  npc_id=row['npc_id'],sprite_path=row['sprite_path'],portrait_path=row['portrait_path'],shop_id=row['shop_id'],
  movement_mode='idle',sprite_scale=1.0,calibrated_adult_height=140,ground_anchored=True,
  sprite_source_size_px=size,hframes=4,body_shape='RectangleShape2D',body_size=body,shape_offset=off,body_position=vector([0,-off[1]]),
  runtime_path=runtime_path,runtime_sha256=runtime_sha,expected_service_sources=expected,
  source_scope_count=len(expected),interaction_action='indoor_service25h')
 rows.append(entry)
result=dict(status='SOURCE_DERIVED_FOUR_SERVICE_ROOM_SEED_NOT_RUNTIME_OBSERVATIONS',author=dict(path=author_path,sha256=author_sha),runtime=dict(path=runtime_path,sha256=runtime_sha),
 registry=dict(path=regpath,sha256=mp[regpath]),fixed_parent_map=dict(path=map_node['path'],sha256=map_node['sha256']),
 numeric_order='Vector2f32(source)/Vector2f32(1536,1024), multiply Vector2f32(1920,1280); body scalar double products -> Vector2f32; grounded body-parent y=-shape-child y',
 rows=rows,room_scopes={r['room_id']:r['expected_service_sources']for r in rows},
 first_final_contract='Passive debug_state.source_receipt.source_first/source_final must both equal the whole fixed room dictionary. No test begin/finalize or collector.',engine_calls=0,packet_decode=0,pixel_decode=0,canonical_writes=0)
b=(json.dumps(result,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=P/'services_READY02_four_room_source_seed_NOT_RUNTIME.json'
with p.open('xb')as f:f.write(b)
print(json.dumps(dict(path=R+p.name,sha256=sha(b),bytes=len(b),scope_counts=[r['source_scope_count']for r in rows])))
