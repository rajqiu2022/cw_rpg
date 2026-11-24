"""Exact deployed516C two culture values and four Temple values, no new keys."""
from pathlib import Path
import hashlib
import json
import copy
GAME=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
OUT=HERE/'worker_facts_dependencies03';OUT.mkdir(exist_ok=False)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;assert b'tokens truncated' not in b;return b
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert b.count(a)==1 and a!=c;return b.replace(a,c,1)
def output(name,b):
    with (OUT/name).open('xb') as stream:stream.write(b)
    return dict(path=S+'worker_facts_dependencies03/'+name,sha256=sha(b),bytes=len(b))
code=json.loads(read(S+'worker_facts03/literal_candidates_and_four_facts_inverse_BUILD.json','e9c703aefb6de7290fdc8f66688399a1b3685d769a6356a835207eb8c52adbfb'))['records']
old=json.loads(read(S+'runtime_dependencies_READY02/culture_temple_dependency_inverse_NOT_STAGE.json','36a42c3dd6b2f6f2c207a55c244b901a38417ed5ac721d739f08633ebb7f815f'))
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
FIELD='res://scripts/field/field_walkable_controller.gd'
COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
parent=old['contract']['candidate'];before=read(parent['path'],parent['sha256']);typed=json.loads(before);new=copy.deepcopy(typed);raw=before;changes={}
for p,k in [(C,'C'),(FIELD,'Field')]:
    assert typed['source_sha256'][p]==code[k]['parent']['sha256']
    h=code[k]['candidate']['sha256'];raw=exact(raw,typed['source_sha256'][p],h);new['source_sha256'][p]=h
    changes[p]=dict(old_sha256=typed['source_sha256'][p],new_sha256=h)
assert json.loads(raw)==new
inverse=raw
for p,c in changes.items():inverse=exact(inverse,c['new_sha256'],c['old_sha256'])
assert inverse==before
contract=output('runtime_contract_C_Field_READY.json',raw)
parentcoord=old['coordinator']['candidate'];beforecoord=read(parentcoord['path'],parentcoord['sha256']);aftercoord=exact(beforecoord,parent['sha256'],contract['sha256'])
coord=output('Coordinator_CANDIDATE.gd',aftercoord)
parentbind=old['temple_binding']['candidate'];beforebind=read(parentbind['path'],parentbind['sha256']);bind=json.loads(beforebind);original=copy.deepcopy(bind);bindbytes=beforebind
for p,h in [(C,code['C']['candidate']['sha256']),(FIELD,code['Field']['candidate']['sha256']),(COORD,coord['sha256']),(CONTRACT,contract['sha256'])]:
    previous=bind['source_delta'][p];bind['source_delta'][p]=h;bindbytes=exact(bindbytes,previous,h)
assert json.loads(bindbytes)==bind and set(bind['source_delta'])==set(original['source_delta'])
inverse=bindbytes
for p in [C,FIELD,COORD,CONTRACT]:inverse=exact(inverse,bind['source_delta'][p],original['source_delta'][p])
assert inverse==beforebind
binding=output('temple_binding_C_Field_Coord_contract_CANDIDATE.json',bindbytes)
parenttemple=old['temple']['candidate'];beforetemple=read(parenttemple['path'],parenttemple['sha256']);aftertemple=exact(exact(beforetemple,parentbind['path'],binding['path']),parentbind['sha256'],binding['sha256'])
temple=output('Temple_CANDIDATE.gd',aftertemple)
result=dict(status='WORKER_FACTS_EXACT_DEPENDENCY_LITERALS_NOT_STAGE',ready=False,
    contract=dict(target=CONTRACT,parent=parent,candidate=contract,changed=changes,wholebyte_and_typed_inverse=True),
    coordinator=dict(target=COORD,parent=parentcoord,candidate=coord,replacements=[dict(old=parent['sha256'],new=contract['sha256'])]),
    temple_binding=dict(parent=parentbind,candidate=binding,changed_existing=[C,FIELD,COORD,CONTRACT],merged_count_unchanged=194,no_new_source_keys=True,wholebyte_and_typed_inverse=True),
    temple=dict(target=TEMPLE,parent=parenttemple,candidate=temple,replacements=[dict(old=parentbind['path'],new=binding['path']),dict(old=parentbind['sha256'],new=binding['sha256'])]),
    original_UTF8_EOL_and_all_other_fields_preserved=True,engine_calls=0,collector_calls=0,canonical_writes=0)
proof=output('dependency_literal_inverse_BUILD.json',encode(result))
print(json.dumps(dict(proof=proof,contract=contract,coordinator=coord,binding=binding,temple=temple)))
