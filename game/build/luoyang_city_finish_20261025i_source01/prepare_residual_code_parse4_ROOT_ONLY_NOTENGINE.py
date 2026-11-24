from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/';OUT=N/'parse4_code_ROOT_READY';P=NS+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
pb=(N/'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json').read_bytes();assert sha(pb)=='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200';proof=json.loads(pb)
old=json.loads((N/'parse12_ROOT_READY/input_ROOT_READY.json').read_bytes());suffixes=['luoyang_docks_district08_20261019aa.gd','luoyang_docks_workyard_20261019ac.gd','luoyang_cultural_sidequests_coordinator_20261019x.gd','luoyang_temple_assembly_20261016.gd']
pins=[next(r['candidate']for p,r in proof['records'].items()if p.endswith(s))for s in suffixes]
spec={**old,'status':'ROOT_ONLY_EXACT4_CODE_RESIDUAL_NO_BUSINESS','scripts':pins,'source_proof':dict(path=NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256=sha(pb)),'output_prefix':P+'output/'};ib=enc(spec)
parent=(N/'parse12_ROOT_READY/parse_ROOT_READY.gd').read_bytes();text=parent.decode();ops=[]
for a,b in [(NS+'parse12_ROOT_READY/input_ROOT_READY.json',P+'input_ROOT_READY.json'),('3933e48919b30ceec187d9f6866768aa89356804c44052689128a1bd3e23ebdb',sha(ib)),('raw.get("scripts",[]).size()==12','raw.get("scripts",[]).size()==4'),('"EXACT_TWELVE_SCRIPTS_FIFTEEN_SAVE_FACTS"','"EXACT_FOUR_RESIDUAL_SCRIPTS_FIFTEEN_SAVE_FACTS"'),('collect all12 results.','collect all4 residual results.'),('check(rows.size()==12,"ALL_TWELVE_RESULTS_WITHOUT_EARLY_BREAK")','check(rows.size()==4,"ALL_FOUR_RESULTS_WITHOUT_EARLY_BREAK")')]:
 assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b);ops.append(dict(old=a,new=b))
back=text
for op in reversed(ops):back=back.replace(op['new'],op['old'])
assert back.encode()==parent;kb=text.encode();report=dict(status='ROOT_ONLY_MECHANICAL_RESIDUAL4_PARSE_NOT_EXECUTED',input=dict(path=P+'input_ROOT_READY.json',sha256=sha(ib)),key=dict(path=P+'parse_ROOT_READY.gd',sha256=sha(kb)),hunks=ops,whole_byte_inverse=True,engine_calls=0)
assert not OUT.exists();OUT.mkdir()
for name,b in [('input_ROOT_READY.json',ib),('parse_ROOT_READY.gd',kb),('mechanical_full_inverse_ROOT_READY.json',enc(report))]:
 with (OUT/name).open('xb')as f:f.write(b)
print(json.dumps(report)[:500])
