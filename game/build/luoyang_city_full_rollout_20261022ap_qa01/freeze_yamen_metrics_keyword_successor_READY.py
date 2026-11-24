"""NEW QA-only reserved-local rename; no production source or engine use."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
oldparent=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_DRAFT_NOTREADY_20261023.gd'
parent=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_METRICS_PARENT_20261023.gd'
oldkey=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_READY_20261023.gd'
newkey=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_METRICS_READY_20261023.gd'
oldplan=QA/'yamen_three_low_props_final_fixture_READY.json'
newplan=QA/'yamen_three_low_props_metrics_fixture_READY.json'
out=QA/'yamen_metrics_keyword_successor_handoff_READY.json'
assert sha(oldparent)=='309064038050a59decb87e3c2b98bfa66336c0ec1dbb068973cc49d0ae13ddc0'
assert sha(oldkey)=='d71a887f9d8ebcf37c41d6e2853c7de01e6c686c8359002fb56d5a296bd20d5f'
assert sha(oldplan)=='99b66e39aa3b97da6728911e1537beb19a8f13246162464fa8a0b6c3d9adc754'
assert not any(p.exists() for p in [parent,newkey,newplan,out])
raw=oldparent.read_text(encoding='utf-8');fixed=raw
changes=[('var preload: Dictionary','var preload_metrics: Dictionary'),('preload.get(','preload_metrics.get('),('preload.duplicate(','preload_metrics.duplicate(')]
for old,new in changes:assert fixed.count(old)==1;fixed=fixed.replace(old,new)
back=fixed
for old,new in reversed(changes):back=back.replace(new,old)
assert back.encode()==oldparent.read_bytes()
parent.write_text(fixed,encoding='utf-8',newline='\n')
fixture=json.loads(oldplan.read_bytes())
fixture['source_sha256'][key(parent)]=sha(parent)
fixture['qa_keyword_successor_only']='Reserved local preload renamed preload_metrics; original parent and failedD71 remain. No production/endpoint/budget/source-owner expectation changes.'
newplan.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
body=oldkey.read_text(encoding='utf-8')
child_changes=[(key(oldparent),key(parent)),(key(oldplan),key(newplan)),(sha(oldplan),sha(newplan)),('yamen_three_low_props_final/%d_%d','yamen_three_low_props_metrics/%d_%d')]
for old,new in child_changes:assert body.count(old)==1;body=body.replace(old,new)
back=body
for old,new in reversed(child_changes):back=back.replace(new,old)
assert back.encode()==oldkey.read_bytes()
newkey.write_text(body,encoding='utf-8',newline='\n')
result={'status':'NEW_QA_RESERVED_LOCAL_SUCCESSOR_NOT_ACTUAL','parent':{'path':key(parent),'sha256':sha(parent),'lines':len(fixed.splitlines())},'script':{'path':key(newkey),'sha256':sha(newkey),'lines':len(body.splitlines())},'fixture':{'path':key(newplan),'sha256':sha(newplan)},'parent_exact_three_local_rename_whole_byte_inverse':True,'child_exact_four_header_output_literal_whole_byte_inverse':True,'old_D71_110148_no_Field_parse_failure_preserved':True,'production_expected1211_identical':fixture['expected_city_source_sha256']==json.loads(oldplan.read_bytes())['expected_city_source_sha256'],'budgets_stations_oracles_identical':True,'engine_or_parse_runs':0,'canonical_writes':0}
out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':result['script'],'fixture':result['fixture'],'parent':result['parent'],'handoff_sha256':sha(out)}))
