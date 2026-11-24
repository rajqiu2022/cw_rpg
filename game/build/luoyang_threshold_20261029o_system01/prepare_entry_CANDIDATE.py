"""Two exact Entry candidate hunks; no canonical writes."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PATH='res://build/luoyang_regions_20261027d_source01/region_entry.gd'
before=(GAME/PATH[6:]).read_bytes()
changes=[
 ('const Alias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")','const Alias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")\nconst ThresholdRestore = preload("res://build/luoyang_threshold_20261029o_system01/threshold_restore.gd")'),
 ('\tvar entry: Dictionary = Alias.arrive(compiled, String(id), point, version, extension)\n','\tvar entry: Dictionary = Alias.arrive(compiled, String(id), point, version, extension)\n\tif entry.get("ok") != true and entry.get("error") == "REGION_SAVED_FOOT_BLOCKED":\n\t\tentry = ThresholdRestore.arrive(compiled, String(id), extension, entry)\n')]
after=before
for old,new in changes:
 assert after.count(old.encode())==1
 after=after.replace(old.encode(),new.encode(),1)
inverse=after
for old,new in reversed(changes):inverse=inverse.replace(new.encode(),old.encode(),1)
assert inverse==before
with (BASE/'region_entry_READY.gd').open('xb')as f:f.write(after)
sha=lambda b:hashlib.sha256(b).hexdigest()
record={'targets':[{'target':'game/'+PATH[6:],'candidate':'game/build/luoyang_threshold_20261029o_system01/region_entry_READY.gd','old_sha256':sha(before),'new_sha256':sha(after),'replacements':[{'old':o,'new':n}for o,n in changes]}]}
with (BASE/'runtime_hunks_READY.json').open('xb')as f:f.write((json.dumps(record,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'entry_candidate_sha256':sha(after),'canonical_writes':0}))
