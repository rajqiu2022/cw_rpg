"""Root authorized readiness-only freeze; never invokes engine."""
from pathlib import Path
import copy,hashlib,json
B=Path(__file__).resolve().parent
OLD=B/'market_prior01_NOTREADY';NEW=B/'market_prior01_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(name,h):
    b=(OLD/name).read_bytes();assert sha(b)==h;return b
def put(name,b):
    p=NEW/name;assert not p.exists(),p
    p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
    return dict(path=p.as_posix(),sha256=sha(b),bytes=len(b))
oldf=fixed('fixture_NOTREADY.json','952623ef6dbadfa0362e09a21c79469cf86ee2e6e304510287ad3fcfd81bf939')
fixture=json.loads(oldf);saved=copy.deepcopy(fixture)
fixture.update(ready=True,status='ROOT_APPROVED_SINGLE_INDEPENDENT24E_CPU_PRIOR_READY',blockers=[],output_path=(NEW/'output/result.json').as_posix())
fb=(json.dumps(fixture,ensure_ascii=True,indent=2)+'\n').encode('ascii')
f=put('fixture_READY.json',fb)
inverse=copy.deepcopy(fixture)
for key in ['ready','status','blockers','output_path']:inverse[key]=saved[key]
assert (json.dumps(inverse,ensure_ascii=True,indent=2)+'\n').encode('ascii')==oldf
key=fixed('oracle_NOTREADY.gd','0a9adcd4f070a49a70123d862d98dc26859d6b127add64093d8f2329bdff7261')
operations=[(b'const READY=false',b'const READY=true'),((OLD/'fixture_NOTREADY.json').as_posix().encode(),f['path'].encode()),(sha(oldf).encode(),f['sha256'].encode())]
original=key
for before,after in operations:assert key.count(before)==1;key=key.replace(before,after,1)
back=key
for before,after in reversed(operations):assert back.count(after)==1;back=back.replace(after,before,1)
assert back==original
k=put('oracle_READY.gd',key)
p=put('project.godot',(OLD/'project.godot').read_bytes())
report=dict(status='ROOT_APPROVED_READY_FREEZE_ONLY_NOT_EXECUTED',key=k,fixture=f,project=p,
 model=dict(path=(OLD/'independent_f32_model_NOT_PIP.json').as_posix(),sha256='9f5a7707f8c92e18b6cb3516dbf2dcc9c471811ec0a4134d456fd23ec341fda5'),
 key_replacements=[dict(before=a.decode(),after=b.decode()) for a,b in operations],fixture_changed_fields=['ready','status','blockers','output_path'],
 key_wholebyte_inverse=True,fixture_serialized_wholebyte_inverse=True,project_unchanged=True,
 native25_matches_F484_child25_wholetyped=True,raw_domains=62,merged_domains=27,union_visited_pixels=1000516,
 geometry_scope_author='author_market_block04_NOTREADY.json697397F2',new_broker05='NPC-only later inheritance must prove all other author fields identical; no pixel replay',
 engine_calls=0,canonical_writes=0,packet_decodes=0,PNG_decodes=0)
h=put('readiness_whole_inverse_NOT_RUN.json',(json.dumps(report,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
print(json.dumps(dict(key=k,fixture=f,project=p,inverse=h)))
