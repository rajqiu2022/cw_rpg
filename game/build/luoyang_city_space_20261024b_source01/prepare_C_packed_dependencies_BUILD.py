"""C-only culture source value and three Temple values; no Field successor."""
from pathlib import Path
import json,hashlib,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
OUT=HERE/'packed_dependencies04';OUT.mkdir(exist_ok=False)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;assert b'tokens truncated' not in b;return b
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1;return b.replace(a,c,1)
def output(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    return dict(path=S+'packed_dependencies04/'+name,sha256=sha(b),bytes=len(b))
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
old=json.loads(read(S+'worker_facts_dependencies03/dependency_literal_inverse_BUILD.json','cc9ea6a8ee0089b4d04e5d12133ef83c2014f837e93d3c0a40fa58f1a214b98e'))
parent=old['contract']['candidate'];before=read(parent['path'],parent['sha256']);typed=json.loads(before);new=copy.deepcopy(typed)
oldC='b4af3c839ce383634af4c72f407a88dedbbc6559018375465164edc09dc23708';newC='b9b68f2e1daddc7dd8f19c683bd932048fda3b547e475001c854d23bfd7965b5'
assert typed['source_sha256'][C]==oldC
raw=exact(before,oldC,newC);new['source_sha256'][C]=newC;assert json.loads(raw)==new and exact(raw,newC,oldC)==before
contract=output('runtime_contract_C_only_CANDIDATE.json',raw)
pc=old['coordinator']['candidate'];ac=exact(read(pc['path'],pc['sha256']),parent['sha256'],contract['sha256']);coord=output('Coordinator_CANDIDATE.gd',ac)
pb=old['temple_binding']['candidate'];bb=read(pb['path'],pb['sha256']);binding=json.loads(bb);original=copy.deepcopy(binding);ab=bb
for p,h in [(C,newC),(COORD,coord['sha256']),(CONTRACT,contract['sha256'])]:
    ab=exact(ab,binding['source_delta'][p],h);binding['source_delta'][p]=h
assert json.loads(ab)==binding and binding['source_delta'].keys()==original['source_delta'].keys()
inv=ab
for p in [C,COORD,CONTRACT]:inv=exact(inv,binding['source_delta'][p],original['source_delta'][p])
assert inv==bb
bind=output('temple_binding_C_Coord_contract_CANDIDATE.json',ab)
pt=old['temple']['candidate'];at=exact(exact(read(pt['path'],pt['sha256']),pb['path'],bind['path']),pb['sha256'],bind['sha256']);temple=output('Temple_CANDIDATE.gd',at)
value=dict(status='C_PACKED_DECODER_DEPENDENCY_LITERAL_ONLY_NOT_STAGE',ready=False,
    contract=dict(target=CONTRACT,parent=parent,candidate=contract,changed={C:dict(old_sha256=oldC,new_sha256=newC)},wholebyte_and_typed_inverse=True),
    coordinator=dict(target=COORD,parent=pc,candidate=coord,replacements=[dict(old=parent['sha256'],new=contract['sha256'])]),
    temple_binding=dict(parent=pb,candidate=bind,changed_existing=[C,COORD,CONTRACT],merged_count_unchanged=194,no_new_source_keys=True,wholebyte_and_typed_inverse=True),
    temple=dict(target=TEMPLE,parent=pt,candidate=temple,replacements=[dict(old=pb['path'],new=bind['path']),dict(old=pb['sha256'],new=bind['sha256'])]),
    Field_source_value_unchanged=True,all_other_UTF8_EOL_sourcevalues_unchanged=True,engine_calls=0,collector_calls=0,canonical_writes=0)
proof=output('dependency_literal_inverse_BUILD.json',enc(value));print(json.dumps(dict(proof=proof,contract=contract,coordinator=coord,binding=bind,temple=temple)))
