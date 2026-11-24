"""One bounded nine-candidate autoload parse entry for Root; never run Godot."""
import hashlib,json,re
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
P='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s):
 b=(G/p[6:]).read_bytes();assert sha(b)==s;return b
hand=json.loads(read(P+'finite_adapter_production08/handoff_PRODUCTION_PROPOSAL.json','8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c'))
base=read('res://tests/test_luoyang_ap_remaining_three_autoload_parse_READY_20261022ap.gd','e141570275c81d1020176451bce8d1aa8f47ead0747cd7d4ab14b96b8ab4f6b0').decode()
rows=[];sources={hand['ground_shader']['path']:hand['ground_shader']['sha256'],hand['binding']['path']:hand['binding']['sha256']}
for d in [hand['adapter']]+[r['candidate'] for r in hand['consumers']]:
 raw=read(d['path'],d['sha256']);methods=re.findall(rb'^(?:static )?func ([A-Za-z0-9_]+)\(',raw,re.M)
 assert methods;rows.append({'path':d['path'],'sha256':d['sha256'],'methods':[methods[0].decode()]})
assert len(rows)==9
fixture={'status':'AP_FINITE08_NINE_SCRIPTS_AUTOLOAD_PARSE_ONLY','limit_ms':15000,'rows':rows,'source_sha256':sources,'shaders_declared_bytes_only_not_loaded_or_compiled':[hand['ground_shader']]}
folder=H/'finite08_parse';assert not folder.exists()
fix=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode()
repls=[('res://build/luoyang_city_full_rollout_20261022ap_qa01/remaining_three_autoload_parse_READY.json',P+'finite08_parse/fixture_READY.json'),('d65edb444f6455a41ad689d86fe7097d0d1e09d3f4cf2292bba30712eba9a193',sha(fix)),('AP_REMAINING_THREE_SCRIPTS_AUTOLOAD_PARSE_ONLY','AP_FINITE08_NINE_SCRIPTS_AUTOLOAD_PARSE_ONLY'),('fixed.rows.size()==3','fixed.rows.size()==9'),('res://build/luoyang_city_full_rollout_20261022ap_qa01/remaining_three_autoload_parse/',P+'finite08_parse/output/')]
for a,b in repls:assert base.count(a)==1;base=base.replace(a,b,1)
folder.mkdir()
for name,b in [('fixture_READY.json',fix),('parse_READY.gd',base.encode())]:
 with (folder/name).open('xb') as f:f.write(b)
print(json.dumps({'script':P+'finite08_parse/parse_READY.gd','script_sha256':sha(base.encode()),'fixture_sha256':sha(fix),'rows':9,'engine_calls':0}))
