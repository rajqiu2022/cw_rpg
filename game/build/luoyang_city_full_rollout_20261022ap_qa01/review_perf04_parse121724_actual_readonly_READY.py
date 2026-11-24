"""One parse-only actual audit, no new engine or source compiler."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
rp=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/performance04_parse/121724_1738/result.json'
b=rp.read_bytes();assert sha(b)=='b28212fdcbb9e2047cfd591baab953cffb211bda6101b5b8994b4bd6f9375ae3';r=json.loads(b)
assert r['complete'] is True and r['checks']==19 and r['failures']==0 and r['elapsed_ms']==91
assert r['source_before']==r['source_after'] and len(r['source_before'])==8
for p,f in r['source_before'].items():
    q=ROOT/p[6:];data=q.read_bytes();assert f['exists'] and sha(data)==f['sha256'] and len(data)==f['bytes'] and int(q.stat().st_mtime)==f['mtime']
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
savedir=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for p,f in r['players_before'].items():
    q=savedir/p[7:];assert q.exists()==f['exists']
    if q.exists():assert sha(q.read_bytes())==f['sha256'] and q.stat().st_size==f['bytes'] and int(q.stat().st_mtime)==f['mtime']
pp=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration18/performance04_parse_once_process_receipt.json';raw=pp.read_bytes();process=json.loads(raw)
assert sha(raw).startswith('944c5cef') and process['actual_natural_console_exit_code']==0 and process['exit_code_from_retained_process_WaitForExit'] is True
assert process['script_sha256']==process['script_after_sha256']=='2644c2fbb1f7026b3ca192994c3d7c7e83961cdc51bfd636c9c748e503f839e2'
stderr=Path(process['stderr_path']).read_bytes();assert not stderr and sha(stderr)==process['stderr_sha256']
assert sha(Path(process['stdout_path']).read_bytes())==process['stdout_sha256']
out=QA/'performance04_parse121724_independent_actual_readonly_review_READY.json'
result={'status':'INDEPENDENT_ACTUAL_THREE_CANDIDATE_PARSE_DECLARATIONS_ONLY_PASS','actual_result':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':sha(b),'complete':True,'checks':19,'failures':0,'elapsed_ms':91},'actual_console_exit':0,'stderr_empty':True,'process_receipt_sha256':sha(raw),'script_full_before_after_SHA_exact':process['script_sha256'],'small_source_first_final_current_SHA_bytes_seconds_exact':8,'save_first_final_current_SHA_bytes_seconds_exact':15,'credit':'Fixed2644 key loads three candidate GDScripts in mainautoload domain, can_instantiate and declarations/default8 constants. No candidate instances or candidate methods, Field, geometry, collector or runtime source checks.','not_credit':['Source DAG/static metadata correctness','Actual city throughput or loading improvement','FIRSTFINAL integration','Deployment authorization'],'QA_engine_calls':0,'canonical_writes':0,'next':'Await new performance driver/input; do not assume prior A2 registry frozen. This epoch requires exact five-room DT registry successor within26targets.'}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
