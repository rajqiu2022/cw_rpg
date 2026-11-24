from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
sp=N/'runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json';sh=sha(sp.read_bytes())
text=(N/'prepare_finish8_code_execution01_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [('code_execution_READY01','code_execution_READY03'),('runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json','runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json'),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sh)]:assert a in text;text=text.replace(a,b)
a="ordinary_layer(AA,C,'C','AA_READY.gd');ordinary_layer(AC,AA,'AA','AC_READY.gd')"
b="""fixed_ordinary=load(dict(path=NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'))
for p in [AA,AC]:record(p,fixed_ordinary['records'][p]['candidate'])
ordinary=copy.deepcopy(fixed_ordinary['ordinary'])"""
assert text.count(a)==1;text=text.replace(a,b)
exec(compile(text,str(N/'prepare_finish8_code_execution03_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_finish8_code_execution03_DERIVED_NOTENGINE.py')})
cp=N/'code_execution_READY03/code_execution_all_whole_inverse_NOT_STAGE.json';ch=sha(cp.read_bytes())
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [('unified32_READY01','unified32_READY03'),('code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json','code_execution_READY03/code_execution_all_whole_inverse_NOT_STAGE.json'),('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',ch),('runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json','runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json'),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sh),("meta('estate_final');meta('quarter_final')","meta('estate_final')"),("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:")]:assert a in text,(a,'missing');text=text.replace(a,b)
exec(compile(text,str(N/'prepare_finish8_metadata32_03_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_finish8_metadata32_03_DERIVED_NOTENGINE.py')})
# Three necessary parse rows only; AA/AC retain already parsed exact old candidate pins.
code=json.loads(cp.read_bytes());old=json.loads((N/'parse12_ROOT_READY/input_ROOT_READY.json').read_bytes());suffix=['field_walkable_controller.gd','luoyang_cultural_sidequests_coordinator_20261019x.gd','luoyang_temple_assembly_20261016.gd'];pins=[next(r['candidate']for p,r in code['records'].items()if p.endswith(s))for s in suffix]
OUT=N/'parse3_enable_ROOT_READY';P=NS+OUT.name+'/'
spec={**old,'status':'ROOT_ONLY_THREE_NECESSARY_FIELD_FLAG_DEPENDENTS','scripts':pins,'source_proof':dict(path=NS+'code_execution_READY03/code_execution_all_whole_inverse_NOT_STAGE.json',sha256=ch),'output_prefix':P+'output/'};ib=enc(spec);parent=(N/'parse12_ROOT_READY/parse_ROOT_READY.gd').read_bytes();text=parent.decode();ops=[]
for a,b in [(NS+'parse12_ROOT_READY/input_ROOT_READY.json',P+'input_ROOT_READY.json'),('3933e48919b30ceec187d9f6866768aa89356804c44052689128a1bd3e23ebdb',sha(ib)),('raw.get("scripts",[]).size()==12','raw.get("scripts",[]).size()==3'),('"EXACT_TWELVE_SCRIPTS_FIFTEEN_SAVE_FACTS"','"EXACT_THREE_SCRIPTS_FIFTEEN_SAVE_FACTS"'),('collect all12 results.','collect all3 necessary results.'),('check(rows.size()==12,"ALL_TWELVE_RESULTS_WITHOUT_EARLY_BREAK")','check(rows.size()==3,"ALL_THREE_RESULTS_WITHOUT_EARLY_BREAK")')]:assert text.count(a)==1;text=text.replace(a,b);ops.append(dict(old=a,new=b))
back=text
for op in reversed(ops):back=back.replace(op['new'],op['old'])
assert back.encode()==parent;kb=text.encode();rp=dict(status='MECHANICAL_PARSE3_READY_NOT_EXECUTED',input=dict(path=P+'input_ROOT_READY.json',sha256=sha(ib)),key=dict(path=P+'parse_ROOT_READY.gd',sha256=sha(kb)),hunks=ops,whole_byte_inverse=True)
assert not OUT.exists();OUT.mkdir()
for name,b in [('input_ROOT_READY.json',ib),('parse_ROOT_READY.gd',kb),('mechanical_full_inverse_ROOT_READY.json',enc(rp))]:
 with (OUT/name).open('xb')as f:f.write(b)
print(json.dumps(rp)[:500])
