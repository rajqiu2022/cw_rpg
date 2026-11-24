"""Exact room render/camera dispatch only; current Field remains untouched."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PATH='res://build/luoyang_regions_20261027d_source01/region_field.gd'
before=(GAME/PATH[6:]).read_bytes()
changes=[
 ('const RegionCompiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")','const RegionCompiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")\nconst HallBoundary = preload("res://build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd")'),
 ('func _draw_region_surfaces() -> bool:\n','func _draw_region_surfaces() -> bool:\n\tif HallBoundary.handles(_region): return HallBoundary.floor(self, _region_owner, _region)\n'),
 ('func _draw_room_enclosure() -> bool:\n','func _draw_room_enclosure() -> bool:\n\tif HallBoundary.handles(_region): return HallBoundary.enclosure(self, _region_owner, _region)\n'),
 ('\t_setup_world_camera(); _refresh_region_chunks(true)\n','\t_setup_world_camera()\n\tif HallBoundary.handles(_region) and not HallBoundary.camera(self, _region_owner, _region, _world_camera): _region_fail("HALL29P_CAMERA"); return\n\t_refresh_region_chunks(true)\n')]
after=before
for old,new in changes:
 assert after.count(old.encode())==1
 after=after.replace(old.encode(),new.encode(),1)
inverse=after
for old,new in reversed(changes):inverse=inverse.replace(new.encode(),old.encode(),1)
assert inverse==before
with (BASE/'region_field_READY.gd').open('xb')as f:f.write(after)
sha=lambda b:hashlib.sha256(b).hexdigest()
record={'targets':[{'target':'game/'+PATH[6:],'candidate':'game/build/luoyang_hall_boundary_20261029p_system01/region_field_READY.gd','old_sha256':sha(before),'new_sha256':sha(after),'replacements':[{'old':o,'new':n}for o,n in changes]}]}
with (BASE/'runtime_hunks_READY.json').open('xb')as f:f.write((json.dumps(record,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'field_candidate_sha256':sha(after),'canonical_writes':0}))
