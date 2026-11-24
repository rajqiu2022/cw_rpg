"""Only Root actual import tuple, trial admission and three Family header literals."""
from pathlib import Path
import json,hashlib,copy,difflib
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_garden_river_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def checked(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
def out(n,b):
 p=P/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+n,sha256=sha(b),bytes=len(b))
trial=dict(path='res://build/luoyang_city_revision_20261025h_root01/garden_finite_trial_authorization.json',sha256='2b897810f0bf7f93c155882ada5e4276f6b2a8ff57204622170ee441c07ec52c')
t=json.loads(checked(trial['path'],trial['sha256']));assert t['status']=='ROOT_AUTHORIZED_FINITE_GARDEN_FIELD_TRIAL_NOT_FIELD_PASS'and t['approved_by_root']is True and t['actual_Field_pass']is False
old=(P/'runtime01_NOTREADY/garden_river_binding_NOTREADY.json').read_bytes();assert sha(old)=='e1fcfd5e113b7b2ee245978f0c22a6498047e6be673640bddeb21541a4a5f958'
base=json.loads(old);v=copy.deepcopy(base)
png=base['child']['walk.png']['path'];ctex='res://.godot/imported/walk.png-'+hashlib.md5(png.encode()).hexdigest()+'.ctex'
tuplepins={png+'.import':'4a66e534166b112a45d9dde614a95ad58e7b724a2159169396f9f0d8d05edd55',ctex:'9e18a07e0a29668a1cd7a3bbea4cf23f3832b12388e153bc665b539464ef21c6'}
for p,h in tuplepins.items():checked(p,h);assert p not in v['required_sources'];v['required_sources'][p]=h
v['required_sources'][trial['path']]=trial['sha256']
v.update(status='ROOT_READY_GARDEN_RIVER_NATIVE_BINDING',ready=True,mask_import_and_direct_ctex=tuplepins,limited_Field_trial_admission=trial,blocking=None)
v['whole_city_or_ART_or_performance_credit']=False
binding=out('runtime02_READY/garden_river_binding_READY.json',enc(v))
body=(P/'runtime01_NOTREADY/Family_garden_river_CANDIDATE.gd').read_bytes();assert sha(body)=='7111f8c9dfe656fed84fc4e5fed1b5e7ab3e12b82139fb0fc5892be9e4b4add1'
changes=[('const GARDEN_RIVER_READY=false','const GARDEN_RIVER_READY=true'),('const GARDEN_RIVER_BINDING="'+R+'runtime01_NOTREADY/garden_river_binding_NOTREADY.json"','const GARDEN_RIVER_BINDING="'+binding['path']+'"'),('const GARDEN_RIVER_BINDING_SHA=""','const GARDEN_RIVER_BINDING_SHA="'+binding['sha256']+'"')]
new=body
for a,b in changes:assert new.count(a.encode())==1;new=new.replace(a.encode(),b.encode(),1)
inv=new
for a,b in reversed(changes):assert inv.count(b.encode())==1;inv=inv.replace(b.encode(),a.encode(),1)
assert inv==body
family=out('runtime02_READY/Family_garden_river_READY.gd',new)
parent=(P/'parents/luoyang_quarters_family_20261022ap.gd').read_bytes();al,bl=parent.decode().splitlines(keepends=True),new.decode().splitlines(keepends=True);hunks=[]
for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):hunks.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
f,b=parent,new
for r in hunks:assert f.count(r['old'].encode())==1;f=f.replace(r['old'].encode(),r['new'].encode(),1)
for r in reversed(hunks):assert b.count(r['new'].encode())==1;b=b.replace(r['new'].encode(),r['old'].encode(),1)
assert f==new and b==parent
restored=copy.deepcopy(v)
for p in [*tuplepins,trial['path']]:del restored['required_sources'][p]
for k in ['status','ready','mask_import_and_direct_ctex','limited_Field_trial_admission','blocking']:restored[k]=base[k]
assert restored==base and enc(restored)==old
proof=out('runtime02_READY/family_binding_mechanical_full_inverse_READY.json',enc(dict(status='ROOT_READY_GARDEN_TRIAL_SOURCE_NOT_ACTUAL_FIELD_PASS',Family=family,binding=binding,NativeGeometry=dict(path=R+'runtime01_NOTREADY/NativeGeometry_garden_river_CANDIDATE.gd',sha256='1d11051c4ed6f90d4555518449d496234efa032d0b43e33b5051e7b58fe0edc5'),family_direct_parent=dict(path=R+'parents/luoyang_quarters_family_20261022ap.gd',sha256=sha(parent),bytes=len(parent)),family_hunks=hunks,mechanical_literals=[dict(old=a,new=b)for a,b in changes],mechanical_byte_inverse=True,full_parent_byte_inverse=True,binding_whole_typed_serialized_inverse=True,only_new_source_pins={**tuplepins,trial['path']:trial['sha256']},trial_not_actual_Field_pass=True,no_geometry_or_pixel_or_native_change=True,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(Family=family,binding=binding,proof=proof,required_sources=len(v['required_sources']))))
