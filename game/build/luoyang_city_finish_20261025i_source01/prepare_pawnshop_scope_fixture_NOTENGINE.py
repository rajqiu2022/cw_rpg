"""Static pawn service scope expression only; no collector/engine or current-disk expected fill."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1]
P='res://build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/'
A='res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json'
AH='44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e'
R=P+'unified22_READY01/services_runtime_READY.gd';RH='4c8371436aac631ea36523626a2696e1871f0a29e9db5fb5e1a64116fcb706e8'
ID='luoyang_functional_pawnshop_candidate_20261016'
sha=lambda b:hashlib.sha256(b).hexdigest()
raw=(G/A[6:]).read_bytes();assert sha(raw)==AH
a=json.loads(raw);assert sha((G/R[6:]).read_bytes())==RH
paths=a['room_source_scopes'][ID];assert len(paths)==len(set(paths))
expected={R:RH,A:AH}
for p in paths:assert p not in expected and p in a['source_sha256'];expected[p]=a['source_sha256'][p]
old=json.loads((G/'build/luoyang_indoor_services_20261025h_system01/services_author05_CANDIDATE.json').read_text(encoding='utf-8'))
for rid,v in old['rooms'].items():
    if rid!=ID:assert a['rooms'][rid]==v and a['room_source_scopes'][rid]==old['room_source_scopes'][rid]
assert all(a['source_sha256'].get(p)==h for p,h in old['source_sha256'].items())
out=dict(status='PAWN_ONLY_STATIC_SERVICE_FIRST_FINAL_EXPECTATION_NOT_OBSERVATION',room_id=ID,runtime=dict(path=R,sha256=RH),author=dict(path=A,sha256=AH),G=dict(path=P+'unified22_READY01/G_READY.gd',sha256='c96b399e0cfe4497c871ab1d450e09d44603f88510195597b024e5f04bd8fd84'),expected_service_sources=expected,count=len(expected),formula='services.scope_paths(pawn): SELF+AUTHOR+author.room_source_scopes[pawn]; values are fixed author.source_sha256, not observed Field hashes.',keeper=a['rooms'][ID],ambient=a['pawn_ambient'],original_three_service_rooms_and_scopes_whole_equal=True,original195_source_values_all_preserved=True,no_original_Scene_layout_registry_or_shop_changes=True,engine_calls=0,collector_calls=0,canonical_writes=0)
b=(json.dumps(out,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8');p=N/'pawnshop_only_repair01/expected_pawn_service_scope_READONLY.json';assert not p.exists()
with p.open('xb')as f:f.write(b)
print(json.dumps(dict(path='res://'+p.relative_to(G).as_posix(),sha256=sha(b),count=len(expected))))
