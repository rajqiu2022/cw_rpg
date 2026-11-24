from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
pub=json.loads((P/'ROOT_READY/publication_input_ROOT_READY.json').read_bytes())
report=json.loads((P/'metadata_array04/ROOT_READY/reports/115844/result.json').read_bytes())
assert report['passed'] and report['published']
sources=dict(pub['sources']);sources.update(report['artifacts'])
helper=R+'garden_river_visual_NOTREADY.gd';shader=R+'river_shore_native16.gdshader'
for p in [helper,shader]:sources[p]=sha((G/p[6:]).read_bytes())
scene=R+'publication01/output/native/luoyang_riverside_garden_20261022ap/scene.res'
fixture=dict(status='GARDEN_NEW56_RIVER_BRIDGE_TEA_PURE_OVERVIEW_NOT_FIELD_OR_ART',ready=False,max_images=1,scene_path=scene,visual_helper=helper,bundle_api='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd',sources=sources,scope='No packet/Field/player/NPC/Physics/PIP/route/raster/collector. One visual image only. Real bridge walk/occlusion remains future Field test.')
f=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode();p=P/'overview01_NOTREADY/fixture_NOTREADY.json'
with p.open('xb')as stream:stream.write(f)
old=(P/'overview01_NOTREADY/overview_NOTREADY.gd').read_bytes();assert old.count(b'PENDING_FIXTURE_SHA')==1
script=old.replace(b'PENDING_FIXTURE_SHA',sha(f).encode());dest=P/'overview01_NOTREADY/overview_pinned_NOTREADY.gd'
with dest.open('xb')as stream:stream.write(script)
print(json.dumps(dict(fixture_path=R+'overview01_NOTREADY/fixture_NOTREADY.json',fixture_sha256=sha(f),key_path=R+'overview01_NOTREADY/overview_pinned_NOTREADY.gd',key_sha256=sha(script),source_count=len(sources),ready=False)))
