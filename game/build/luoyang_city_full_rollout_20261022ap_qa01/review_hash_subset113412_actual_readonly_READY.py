"""Review small actual output and small tools only; no big-file reread/stat."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_system01/hash_subset_8then4_epoch01'
def sha(b):return hashlib.sha256(b).hexdigest()
rp=BASE/'output/113412_81/result.json';raw=rp.read_bytes();assert sha(raw)=='1ff1ae22f32ca6936176c78114d0c95db042c643db580b8f805d0d227c22003a'
r=json.loads(raw);assert r['passed'] is True and r['checks']==63 and not r['failures'] and r['elapsed_ms']==478
assert r['small_source_first']==r['small_source_final'] and len(r['small_source_first'])==6
for p,f in r['small_source_first'].items():
    q=BASE/p[6:] if p.startswith('res://') else Path(p);b=q.read_bytes()
    assert f['exists'] and sha(b)==f['sha256'] and len(b)==f['bytes'] and int(q.stat().st_mtime)==f['mtime_seconds']
spec=json.loads((BASE/'subset_input_READY.json').read_bytes());expected={x['absolute_path']:x['sha256'] for x in spec['files']}
observations=r['observations'];assert len(observations)==3
for row,limit,elapsed in zip(observations[:2],[8,4],[162166,298963]):
    assert row['worker_limit']==limit and row['wall_usec_only_job_run']==elapsed and row['payload_bytes']==472516560 and row['fixed_SHA_exact'] is True
    assert row['fresh_sha_map']==expected and row['finished_usec']-row['started_usec']==elapsed
    d=row['debug_after_join'];assert d['children_started']==d['children_joined']==limit and d['active_children']==0 and not d['running'] and d['complete']
    assert d['read_bytes']==472516560 and d['read_chunks']==460 and d['completed_files']==16
metadata=observations[2];assert metadata['source_before']==metadata['source_after'] and metadata['big_files_pre_or_post_hashed_outside_jobs'] is False
processpath=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration17/hash8_subset_once_process_receipt.json'
pr=processpath.read_bytes();assert sha(pr)=='0684846ac34743c20dde43274fad84218fbd734ced06c3560b9ee65b445b6d3e';process=json.loads(pr)
assert process['actual_natural_console_exit_code']==0 and process['exit_code_from_retained_process_WaitForExit'] is True
stderr=Path(process['stderr_path']).read_bytes();assert stderr==b'' and sha(stderr)==process['stderr_sha256']
assert sha(Path(process['stdout_path']).read_bytes())==process['stdout_sha256']
out=QA/'hash_subset113412_independent_actual_observation_review_READY.json'
result={'status':'INDEPENDENT_ACTUAL_FIXED_SUBSET_FUNCTIONAL_AND_ELAPSED_OBSERVATION_ONLY','actual_report':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':sha(raw),'checks':63,'elapsed_ms':478,'passed':True},'actual_console_exit':0,'stderr_empty':True,'small_source_first_final_current_SHA_bytes_seconds_exact':6,'fixed_subset_files':16,'payload_bytes_each_pass':472516560,'chunks_each_pass':460,'two_full_fresh_SHA_maps_equal_fixed120012':True,'all_started_children_joined_no_active':True,'observed_job_run_usec':{'first8':162166,'second4':298963},'big_metadata_first_final_exact_seconds':True,'review_bigfiles_hashed_or_opened_or_statted':0,'limits':['8-first/4-second, one observation, uncontrolled OS page cache/scheduling.','All16ctex, some distinct paths identical historical payload; not representative complete1217.','No statistical/causal speedup, SSDcold, city loading target, wholeFIRSTFINAL integration or deployment admission.'],'review_new_engine_collector_or_benchmark_calls':0,'canonical_save_writes':0}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
