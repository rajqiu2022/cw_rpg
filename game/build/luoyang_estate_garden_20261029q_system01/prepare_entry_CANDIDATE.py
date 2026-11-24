"""Append this garden's exact restore case after the unchanged 29o case."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PATH='res://build/luoyang_regions_20261027d_source01/region_entry.gd'
before=(GAME/PATH[6:]).read_bytes()
changes=[
 ('const ThresholdRestore = preload("res://build/luoyang_threshold_20261029o_system01/threshold_restore.gd")','const ThresholdRestore = preload("res://build/luoyang_threshold_20261029o_system01/threshold_restore.gd")\nconst GardenRestore = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_restore.gd")'),
 ('\t\tentry = ThresholdRestore.arrive(compiled, String(id), extension, entry)\n','\t\tentry = ThresholdRestore.arrive(compiled, String(id), extension, entry)\n\tif entry.get("ok") != true and entry.get("error") == "REGION_SAVED_FOOT_BLOCKED":\n\t\tentry = GardenRestore.arrive(compiled, String(id), extension, entry)\n')]
after=before
for old,new in changes:
 assert after.count(old.encode())==1
 after=after.replace(old.encode(),new.encode(),1)
inverse=after
for old,new in reversed(changes):inverse=inverse.replace(new.encode(),old.encode(),1)
assert inverse==before
with (BASE/'region_entry_READY.gd').open('xb')as f:f.write(after)
sha=lambda b:hashlib.sha256(b).hexdigest()
record={'targets':[{'target':'game/'+PATH[6:],'candidate':'game/build/luoyang_estate_garden_20261029q_system01/region_entry_READY.gd','old_sha256':sha(before),'new_sha256':sha(after),'replacements':[{'old':o,'new':n}for o,n in changes]}]}
with (BASE/'runtime_hunks_READY.json').open('xb')as f:f.write((json.dumps(record,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'entry_candidate_sha256':sha(after),'canonical_writes':0}))
