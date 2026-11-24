"""Fixed report-derived subset source review, not a big-file read/benchmark."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_system01/hash_subset_8then4_epoch01'
def sha(b):return hashlib.sha256(b).hexdigest()
key=(BASE/'subset_READY.gd').read_bytes();assert sha(key)=='b34c206599c748093c017c592953f95cd13990c941a16948bb802e0e5005c15e'
raw=(BASE/'subset_input_READY.json').read_bytes();assert sha(raw)=='cff4f003c3567bc297f84e5fc584b0e5cf4161adeea1aa17874327a0068c07ce'
s=json.loads(raw);reportpath=Path(s['expected_origin']['report']);b=reportpath.read_bytes();assert sha(b)==s['expected_origin']['sha256'];r=json.loads(b)
proof=next(x for x in r['records'] if x['kind']=='PERF03_NATURAL_C_RECEIPT_SELECTIVE_READ')
eligible=[]
for p,digest in proof['sources'].items():
    fact=r['source_before'][p];assert fact==r['source_after'][p] and digest==fact['sha256']
    if 0<fact['bytes']<=32*1024*1024:eligible.append((p,fact['bytes'],digest))
expected=sorted(eligible,key=lambda x:(-x[1],x[0]))[:16]
assert len(s['files'])==len(expected)==16 and s['worker_order']==[8,4] and s['limit_ms']==15000
for row,(p,size,digest) in zip(s['files'],expected):
    assert row['source_res_path']==p and row['bytes']==size and row['sha256']==digest
    assert row['absolute_path']==(ROOT/p[6:]).as_posix() and row['chunks_1MiB']==(size+1048575)//1048576
assert s['total_bytes']==sum(x[1] for x in expected)==472516560<=536870912
assert s['total_chunks_1MiB']==sum(x['chunks_1MiB'] for x in s['files'])==460
for p,digest in s['small_source_sha256'].items():
    q=BASE/p[6:] if p.startswith('res://') else Path(p);assert sha(q.read_bytes())==digest
assert sha((BASE/'parallel_source_hash_lanes8_CANDIDATE.gd').read_bytes())=='85a7b0b86ca201679b227b1f39c7315bb7196b4d0943befa5397ce569fe650e1'
text=key.decode();assert 'for limit: int in [8,4]:' in text
timed=text.split('var started_usec: int=Time.get_ticks_usec()',1)[1].split('var finished_usec: int=Time.get_ticks_usec()',1)[0]
assert timed.strip()=='job.run()'
assert 'job.external_cancel=gate.expired' in text and 'gate.deadline_msec=began+LIMIT_MS' in text
assert 'state.children_started==limit and state.children_joined==limit' in text and 'state.active_children==0' in text
assert 'actual==expected' in text and 'job.hashes.duplicate()' in text
assert 'stat_only(row.absolute_path)' in text and 'FileAccess.get_sha256(row.absolute_path)' not in text
out=QA/'hash_subset_B34C_fixed16_independent_static_prior_READY.json'
result={'status':'INDEPENDENT_STATIC_NO_BLOCKER_ROOT_ONCE_SUBSET_OBSERVATION_ONLY','key_sha256':sha(key),'input_sha256':sha(raw),'expected_source':'Fixed577410 naturalC1217 +matching sourcebefore/after facts; descending positive<=32MiB byte length then path first16, independently reconstructed.','files':16,'all_ctex_paths':all(p.endswith('.ctex') for p,_,_ in expected),'per_pass_bytes':472516560,'total_chunks_per_pass':460,'per_pass_below512MiB':True,'order':[8,4],'whole_limit_ms':15000,'measured_span':'Only job.run; includes thread start/join/poll/full reads. Construction/debug/mapcomparison outside.','freshhash_both_passes_required':True,'deadline_1MiB_cancel_and_alljoin_preserved':True,'known_biases':['8 first,4 second; uncontrolled OS cache/scheduling.','ctex-only, largest<=32MiB; not representative complete1217.','Distinct historical paths may have identical payload SHA; all paths still reread.','One paired observation, not a causal/statistical speedup or SSDcold claim.'],'review_big_files_opened_hashed_or_statted':0,'review_engine_benchmark_or_collector_calls':0,'canonical_writes':0,'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
