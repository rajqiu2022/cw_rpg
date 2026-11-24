"""Preserve READY01; repair only missed Field enable literal, then exact dependency propagation."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def emit(p,b):
 assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=NS+p.relative_to(N).as_posix(),sha256=sha(b),bytes=len(b))
oldproof=(N/'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json').read_bytes();assert sha(oldproof)=='bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa'
proof=json.loads(oldproof);old=(N/'runtime_READY01/Field_READY.gd').read_bytes();assert sha(old)=='27687d0bc62f083e250fafc0ca9fe4038a0626f8770362987ff20cf440cb1f15'
a,b=b'const FINISH25I_ENABLED := false',b'const FINISH25I_ENABLED := true';assert old.count(a)==1
new=old.replace(a,b,1);assert new.replace(b,a,1)==old
field=emit(N/'runtime_READY02/Field_READY.gd',new);proof['Field']=field;proof['mechanical'].append(dict(parent=dict(path=NS+'runtime_READY01/Field_READY.gd',sha256=sha(old),bytes=len(old)),candidate=field,hunks=[dict(old=a.decode(),new=b.decode())],whole_byte_inverse=True));proof['status']='ROOT_READY_FIELD_MISSED_ENABLE_LITERAL_CORRECTED_NOT_STAGE'
sp=emit(N/'runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(proof))
text=(N/'prepare_finish8_code_execution01_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [('code_execution_READY01','code_execution_READY02'),('runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json','runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json'),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sp['sha256'])]:assert a in text;text=text.replace(a,b)
exec(compile(text,str(N/'prepare_finish8_code_execution02_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_finish8_code_execution02_DERIVED_NOTENGINE.py')})
cp=N/'code_execution_READY02/code_execution_all_whole_inverse_NOT_STAGE.json';ch=sha(cp.read_bytes())
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [('unified32_READY01','unified32_READY02'),('code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json','code_execution_READY02/code_execution_all_whole_inverse_NOT_STAGE.json'),('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',ch),('runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json','runtime_READY02/runtime_consumers_mechanical_seal_whole_inverse_READY.json'),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sp['sha256']),('meta(\'estate_final\');meta(\'quarter_final\')','meta(\'estate_final\')'),("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:")]:
 assert a in text,(a,'missing');text=text.replace(a,b)
exec(compile(text,str(N/'prepare_finish8_metadata32_02_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_finish8_metadata32_02_DERIVED_NOTENGINE.py')})
emit(N/'runtime_READY02/missed_Field_flag_source_successor_explanation.json',enc(dict(status='ONE_MISSED_FIELD_FLAG_CORRECTION_WITH_EXACT_REQUIRED_DEPENDENTS',old_Field_sha256=sha(old),Field=field,seal=sp,code_proof=dict(path=NS+'code_execution_READY02/code_execution_all_whole_inverse_NOT_STAGE.json',sha256=ch),metadata_order_correction='Quarter after execution index; old legacy manifests do not inherit entire new Quarter/Estate flat group. AP Market and finite/C map own those existing paths.',engine_calls=0,Stage_calls=0,canonical_writes=0)))
