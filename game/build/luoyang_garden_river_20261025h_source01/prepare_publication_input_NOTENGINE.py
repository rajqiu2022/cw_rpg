from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1]
R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def leaf(name,expected):
 b=(P/name).read_bytes();assert sha(b)==expected
 return {'path':R+name,'sha256':expected,'bytes':len(b)}
author=leaf('author_river_bridge03_NOTREADY.json','06d873797e954a4f7b874a85b421a1b1dda87b2072170d7749eeaaf3ddc77cb6')
compiler=leaf('garden_river_compiler02_NOTREADY.gd','fcd389cdd701de07145d3248d9a9c26fb20ae2b571e2a74be554ab7aa49f4258')
publisher=leaf('publish_garden_river_NOTREADY.gd','1ab668fa9c09f62f4302ad0dcfa6b7c9fd3dc02b2fd612e7fcf8e7d1fd213220')
prior=leaf('independent_source_pixel_model02_PRIOR_PROPOSAL.json','315df3719cde0adccb4a1d226ce7c73ec657ecc71f868c18b9f2d04428d1319d')
a=json.loads((P/'author_river_bridge03_NOTREADY.json').read_bytes())
s=json.loads((G/'build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json').read_bytes())
sources=dict(a['source_sha256'])
market_fixed=s['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256']
for x in [author,compiler,publisher,prior]:sources[x['path']]=x['sha256']
for name in ['res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/domain/scene_script.gd','res://scripts/domain/walkable_map_layout.gd','res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd','res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/deepwater.res']:
 # B's closed executable snapshot is represented by the independently derived
 # map, not necessarily re-read as a canonical leaf by the Stage generator.
 sources[name]=market_fixed[name] if name=='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd' else s['source_first'][name]
parent=json.loads((P/'independent_source_pixel_model02_PRIOR_PROPOSAL.json').read_bytes())['parent_walk']
sources[parent['path']]=parent['sha256']
for name,h in sources.items():assert sha((G/name[6:]).read_bytes())==h,name
value={'status':'ROOT_REVIEW_PENDING_GARDEN_NATIVE_PUBLICATION_ONLY','ready':False,
 'scope':'GARDEN_ONLY_NO_OTHER_CITY_OR_ROOM_GEOMETRY_REPLAY',
 'author':author,'compiler':compiler,'publisher':publisher,'prior':prior,'sources':sources,
 'source_count':len(sources),'output_root':R+'publication01/output/native/',
 'report_pattern':R+'publication01/reports/<PID>/result.json','limit_ms':60000,
 'protection':{'path':'res://build/luoyang_city_revision_20261025h_source01/fresh_current25h_READONLY.json','sha256':'7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb'},
 'meaning':'New Garden native components only. No Family readiness, formal runtime, source Stage, GPU art, real Input or other quarter/city/room replay credit.'}
dest=P/'publication_input_NOTREADY.json';assert not dest.exists()
blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb') as f:f.write(blob)
out={'path':R+dest.name,'sha256':sha(blob),'sources':len(sources),'compiler':compiler,'publisher':publisher,'author':author,'prior':prior}
print(json.dumps(out))
