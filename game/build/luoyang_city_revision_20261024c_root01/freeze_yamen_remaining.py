"""Mechanical Root freeze of the two explicitly approved remaining inspections."""
from pathlib import Path
import hashlib,json,copy
GAME=Path(__file__).resolve().parents[2]
BASE=GAME/'build/luoyang_city_revision_20261024c_qa01'
OLD=BASE/'finite_Field_remaining_NOTREADY'
OUT=BASE/'finite_Field_remaining_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def locked(p,h):
 b=p.read_bytes();assert sha(b)==h;return b
def serial(v):return (json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode()
assert not OUT.exists()
old=locked(OLD/'fixture_NOTREADY.json','663046d17b9bec92730135d9d0bcc963aab8e8944609de06a56525860d35ad30')
v=json.loads(old);assert serial(v)==old and not v['ready']
# No game-source writes occurred after this full guard: only QA outputs and docs.
guard=GAME/'build/luoyang_city_revision_20261024c_root01/pre_Field30_guard_actual.json'
assert json.loads(locked(guard,'55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1'))['passed'] is True
v.update(ready=True,status='ROOT_APPROVED_YAMEN_REMAINING_ONLY_READY',blockers=[])
v['fresh_guard']={'path':res(guard),'sha256':'55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1'}
before=json.loads(old)
restored=copy.deepcopy(v)
for k in ['ready','status','blockers','fresh_guard']:
 if k in before:restored[k]=before[k]
 else:restored.pop(k,None)
assert serial(restored)==old
fb=serial(v);fh=sha(fb)
key=locked(OLD/'yamen_remaining_NOTREADY.gd','022bb7cd4a8e7ec7c04805e9c6409e4d78e00d22d28f01ee7d4caede02a801ff')
replacements=[
 ('const REMAINING_READY=false','const REMAINING_READY=true'),
 ('const REMAINING_FIXTURE="res://build/luoyang_city_revision_20261024c_qa01/finite_Field_remaining_NOTREADY/fixture_NOTREADY.json"','const REMAINING_FIXTURE="'+res(OUT/'fixture_READY.json')+'"'),
 ('const REMAINING_FIXTURE_SHA="PENDING_FIXED_REMAINING_FIXTURE"','const REMAINING_FIXTURE_SHA="'+fh+'"'),
 ('const REMAINING_OUTPUT="res://build/luoyang_city_revision_20261024c_qa01/finite_Field_remaining_NOTREADY/output_NOTREADY"','const REMAINING_OUTPUT="'+res(OUT/'output_READY')+'"')]
new=key
for a,b in replacements:
 assert new.count(a.encode())==1;new=new.replace(a.encode(),b.encode())
inverse=new
for a,b in reversed(replacements):
 assert inverse.count(b.encode())==1;inverse=inverse.replace(b.encode(),a.encode())
assert inverse==key
OUT.mkdir()
for name,data in [('fixture_READY.json',fb),('test_READY.gd',new)]:
 with (OUT/name).open('xb') as stream:stream.write(data)
print(json.dumps({'fixture_sha256':fh,'key_path':res(OUT/'test_READY.gd'),'key_sha256':sha(new),'four_literal_inverse':True,'fixture_limited_inverse':True,'production_writes':0}))
