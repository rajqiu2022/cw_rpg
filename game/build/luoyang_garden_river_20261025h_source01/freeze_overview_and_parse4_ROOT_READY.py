"""Root-approved mechanical readiness and Group4 load-only key; no engine."""
from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent;R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def out(n,b):
 p=P/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+n,sha256=sha(b),bytes=len(b))
old_fixture=(P/'overview01_NOTREADY/fixture_NOTREADY.json').read_bytes();assert sha(old_fixture)=='7f31a9f94d79c0b7bd76d8aa46f0aca8df08b579e81ac837e6e9008d04a3a1b7'
v=json.loads(old_fixture);assert v['ready']is False;v['ready']=True
fixture=out('overview02_ROOT_READY/fixture_ROOT_READY.json',enc(v))
old=(P/'overview01_NOTREADY/overview_pinned_NOTREADY.gd').read_bytes();assert sha(old)=='d1269b07ef2e57fb3535795cc8f20a0f801519b04c712c006a4c7aee96948bd9'
changes=[('const READY: bool=false','const READY: bool=true'),(R+'overview01_NOTREADY/fixture_NOTREADY.json',fixture['path']),('7f31a9f94d79c0b7bd76d8aa46f0aca8df08b579e81ac837e6e9008d04a3a1b7',fixture['sha256']),(R+'overview01_NOTREADY/output',R+'overview02_ROOT_READY/output')]
b=old
for a,c in changes:assert b.count(a.encode())==1;b=b.replace(a.encode(),c.encode(),1)
inv=b
for a,c in reversed(changes):assert inv.count(c.encode())==1;inv=inv.replace(c.encode(),a.encode(),1)
assert inv==old
key=out('overview02_ROOT_READY/overview_ROOT_READY.gd',b)
paths=['runtime01_NOTREADY/Family_garden_river_CANDIDATE.gd','runtime01_NOTREADY/NativeGeometry_garden_river_CANDIDATE.gd','garden_river_visual_NOTREADY.gd','overview02_ROOT_READY/overview_ROOT_READY.gd']
rows=[dict(path=R+n,sha256=sha((P/n).read_bytes()),bytes=(P/n).stat().st_size)for n in paths]
pf=out('parse4_ROOT_READY/input_ROOT_READY.json',enc(dict(status='ROOT_READY_GARDEN_FAMILY_NATIVE_VISUAL_OVERVIEW_LOAD_ONLY',ready=True,rows=rows)))
oldparse=(P/'ROOT_READY/parse_garden_ROOT_READY.gd').read_bytes();new=oldparse
for a,c in [(R+'ROOT_READY/parse_input_ROOT_READY.json',pf['path']),('acd1ce8623dcfb2ccdcf133fdd835ffa5a57c7ef7be2a5a661e30323038f3c49',pf['sha256']),('GARDEN_COMPILER_PUBLISHER_LOAD_ONLY_NOT_EXECUTED','GARDEN_FAMILY_NATIVE_VISUAL_OVERVIEW_LOAD_ONLY_NOT_EXECUTED'),(R+'ROOT_READY/parse_output/',R+'parse4_ROOT_READY/output/')]:
 assert new.count(a.encode())==1;new=new.replace(a.encode(),c.encode(),1)
parse=out('parse4_ROOT_READY/parse_ROOT_READY.gd',new)
proof=out('overview02_ROOT_READY/mechanical_freeze_full_inverse_READY.json',enc(dict(status='ROOT_AUTHORIZED_MECHANICAL_READY_NOT_EXECUTED',parent_fixture_sha256=sha(old_fixture),fixture=fixture,parent_key_sha256=sha(old),key=key,changes=[dict(old=a,new=c)for a,c in changes],whole_byte_key_inverse=True,whole_typed_fixture_inverse=True,parse_input=pf,parse= parse,candidate_method_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(overview=key,fixture=fixture,parse=parse,parse_input=pf,proof=proof)))
