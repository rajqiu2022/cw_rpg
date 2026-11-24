"""One Estate overlay dispatch after the unchanged surface renderer."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
PATH='res://build/luoyang_regions_20261027d_source01/region_field.gd'
before=(GAME/PATH[6:]).read_bytes()
changes=[('const HallBoundary = preload("res://build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd")','const HallBoundary = preload("res://build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd")\nconst GardenVisual = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_visual.gd")'),('\t\tfloor.uv = uv; floor.z_index = -1000; _visual_layer.add_child(floor)\n\treturn true\n\nfunc _draw_region_underlay()', '\t\tfloor.uv = uv; floor.z_index = -1000; _visual_layer.add_child(floor)\n\tif GardenVisual.handles(_region): return GardenVisual.install(self, _region_owner, _region)\n\treturn true\n\nfunc _draw_region_underlay()')]
after=before
for old,new in changes:
 assert after.count(old.encode())==1
 after=after.replace(old.encode(),new.encode(),1)
inverse=after
for old,new in reversed(changes):inverse=inverse.replace(new.encode(),old.encode(),1)
assert inverse==before
with (BASE/'region_field_READY.gd').open('xb')as f:f.write(after)
sha=lambda b:hashlib.sha256(b).hexdigest()
path=BASE/'runtime_hunks_READY.json';prior=json.loads(path.read_bytes())
prior['targets'].append({'target':'game/'+PATH[6:],'candidate':'game/build/luoyang_estate_garden_20261029q_system01/region_field_READY.gd','old_sha256':sha(before),'new_sha256':sha(after),'replacements':[{'old':o,'new':n}for o,n in changes]})
with path.open('wb')as f:f.write((json.dumps(prior,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'field_candidate_sha256':sha(after),'canonical_writes':0}))
