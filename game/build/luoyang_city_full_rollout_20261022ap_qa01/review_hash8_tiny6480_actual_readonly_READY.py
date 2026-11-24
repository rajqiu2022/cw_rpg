"""Read already executed tiny report only; no new hash benchmark/engine."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_system01/hash_lanes8_epoch02'
def sha(b):return hashlib.sha256(b).hexdigest()
rp=BASE/'output/6480_90/result.json';raw=rp.read_bytes()
assert sha(raw)=='43835554c27bf901cbc512413999ff8b26f7b3739d661c0d962717d61fa2db05'
r=json.loads(raw);assert r['passed'] is True and r['checks']==76 and not r['failures'] and r['elapsed_ms']==34
assert r['source_first']==r['source_final'] and len(r['source_first'])==14
for p,f in r['source_first'].items():
    q=BASE/p[6:] if p.startswith('res://') else Path(p)
    b=q.read_bytes();assert f['exists'] is True and sha(b)==f['sha256'] and len(b)==f['bytes'] and int(q.stat().st_mtime)==f['mtime_seconds']
cases={x['case']:x for x in r['cases']};default=cases['default8_full_fresh_tiny_files']['debug']
assert default['complete'] is True and default['children_started']==default['children_joined']==default['peak_children']==8
assert default['read_bytes']==2098267 and default['read_chunks']==10 and default['completed_files']==9
for key,row in cases.items():
    if key=='deterministic_lane_1MiB_boundary_cancel':continue
    d=row['debug'];assert d['children_started']==d['children_joined'] and d['active_children']==0 and d['running'] is False and d['children_started']<=8
    if key in ['pre_cancel','external_cancel','missing_file','duplicate_path','invalid_limit','second_run_refused']:assert row['hash_count']==0 and d['complete'] is False
cancel=cases['external_cancel']['debug'];assert cancel['cancelled'] is True and cancel['children_started']==5
boundary=cases['deterministic_lane_1MiB_boundary_cancel'];assert boundary['polls']==4 and boundary['read_chunks']==1 and boundary['read_bytes']==1048576 and boundary['hash_empty'] is True
processpath=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration17/hash8_tiny_once_process_receipt.json'
process=json.loads(processpath.read_bytes());assert process['actual_natural_console_exit_code']==0 and process['exit_code_from_retained_process_WaitForExit'] is True
stderr=Path(process['stderr_path']).read_bytes();assert stderr==b'' and sha(stderr)==process['stderr_sha256']
assert sha(Path(process['stdout_path']).read_bytes())==process['stdout_sha256']
out=QA/'hash8_tiny6480_independent_actual_readonly_review_READY.json'
result={'status':'INDEPENDENT_ACTUAL_TINY_HASH8_FUNCTIONAL_ONLY_PASS_NOT_THROUGHPUT_OR_CITY','actual_report':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':sha(raw),'passed':True,'checks':76,'elapsed_ms':34},'actual_console_exit':0,'stderr_empty':True,'process_receipt_sha256':sha(processpath.read_bytes()),'source_first_final_current_SHA_bytes_seconds_exact':14,'default8':default,'external_cancel_actual_started_and_joined':5,'deterministic_direct_lane_boundary':boundary,'all_case_started_children_joined_and_zero_active':True,'failed_cancelled_singleuse_results_empty':True,'not_proven':['Actual FIRSTFINAL city integration','Any3GiB source set','Disk-throughput or speedup','OS thread-start failure injection','Read-error/short-read/file-mutation injection'],'review_engine_or_new_benchmark_calls':0,'canonical_or_save_writes':0}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
