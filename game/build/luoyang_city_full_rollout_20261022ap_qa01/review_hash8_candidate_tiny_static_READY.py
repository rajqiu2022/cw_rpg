"""Independent bytes/lifecycle/tiny-scope review; no Godot or helper execution."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_system01/hash_lanes8_epoch02'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,s):
    b=p.read_bytes();assert sha(b)==s;return json.loads(b)
h=load(BASE/'handoff_READY_NOT_EXECUTED.json','9caf6919acc1d5697f4d3b39b39afde04df5ead7fb0d3cb7230827319ae0c159')
original=Path(h['parent']['path']).read_bytes();candidate=Path(h['candidate']['path']).read_bytes()
assert sha(original)==h['parent']['sha256'] and sha(candidate)==h['candidate']['sha256']
proof=load(BASE/'whole_byte_inverse_READY.json','ddf3412680711c86388dfb1ba62512eb678fabe1b1dcb27246172ee1b052eeec')
oldlines=original.decode().splitlines(keepends=True);newlines=candidate.decode().splitlines(keepends=True)
rebuilt=[];cursor=0
for x in proof['hunks']:
    lo,hi=x['old_line_range'];nlo,nhi=x['new_line_range']
    assert ''.join(oldlines[lo:hi])==x['old'] and ''.join(newlines[nlo:nhi])==x['new']
    assert lo>=cursor;rebuilt+=oldlines[cursor:lo]+[x['new']];cursor=hi
rebuilt+=oldlines[cursor:];assert ''.join(rebuilt).encode()==candidate
restored=[];cursor=0
for x in proof['hunks']:
    lo,hi=x['new_line_range'];assert lo>=cursor;restored+=newlines[cursor:lo]+[x['old']];cursor=hi
restored+=newlines[cursor:];assert ''.join(restored).encode()==original
text=candidate.decode()
assert 'const DEFAULT_WORKER_LIMIT := 8' in text and 'const ALLOWED_WORKER_LIMITS := [1,2,4,8]' in text
assert 'mini(worker_limit,_queue.size())' in text
assert text.index('thread.wait_to_finish()')<text.index('_joined_lane_counters(lanes)')
start=text.index('for thread: Thread in threads:');join=text.index('_joined_lane_counters(lanes)',start)
assert 'return' not in text[start:join]
oldfn=original.decode().split('\tfunc _file_sha(path: String) -> String:\n',1)[1].split('\tfunc run() -> void:',1)[0]
newfn=text.split('\tfunc _file_sha(path: String) -> String:\n',1)[1].split('\tfunc run() -> void:',1)[0]
newfn=newfn.replace('\t\t\tread_chunks += 1\n\t\t\tread_bytes += bytes.size()\n','\t\t\tcoordinator._chunk_read(bytes.size())\n')
assert newfn==oldfn,'Every complete-file and1MiB cancel/read/digest guard byte-unchanged'
assert text.count('_joined_lane_counters(lanes)')==1 and 'if _is_cancelled():\n\t\thashes = {}' in text
assert 'WorkerThreadPool' not in text and 'Thread.new()' in text
tiny=load(BASE/'tiny_input_READY.json','f8c82e1a77283abde0cc4a4258d7d85e665779593e34d3ccb7ac4c79773329d6')
assert tiny['limit_ms']==15000 and len(tiny['files'])==9
total=0
for x in tiny['files']:
    b=(BASE/x['path'][6:]).read_bytes();assert sha(b)==x['sha256'] and len(b)==x['bytes']
    assert x['chunks_1MiB']==(len(b)+1048575)//1048576;total+=len(b)
assert total==2098267
for p,s in tiny['source_sha256'].items():
    q=BASE/p[6:] if p.startswith('res://') else Path(p)
    assert sha(q.read_bytes())==s
key=Path(h['tiny_key']['path']).read_bytes();assert sha(key)==h['tiny_key']['sha256']
test=key.decode();assert 'root.get_child_count()==0' in test and 'not_multithread_race_byte_credit' in test and 'speedup_claimed' in test
assert 'FileAccess.get_sha256' in test and 'spec.source_sha256' in test
c=(ROOT/'scripts/city/luoyang_enclosure_v11_candidate_contract.gd').read_text(encoding='utf-8')
assert 'parallel.paths = paths.duplicate()' in c and 'parallel.external_cancel = _is_cancelled' in c and 'parallel.worker_limit' not in c
out=QA/'hash8_candidate85A7_tiny4AE0_independent_static_admission_READY.json'
r={'status':'INDEPENDENT_STATIC_NO_BLOCKER_ROOT_UNIQUE_TINY_FUNCTIONAL_RUN_ONLY','candidate_sha256':sha(candidate),'parent_sha256':sha(original),'whole_bytes_forward_and_inverse_independently_exact':True,'hunks':len(proof['hunks']),'full_file_loop_except_counter_increment_wholebytes_unchanged':True,'max_children':8,'cancel_join_contract':['Independent Thread children, no parent WorkerThreadPool starvation dependency.','Every successfully started child wait_to_finish before joined lane read counters/results.','Every1MiB pre/post cancellation, full length/position/read error/digest checks preserved.','Failed/cancelled/singleuse/latecancel exposes no partial or prior hashes.','Lane-owned counters read only after all joins, not live-progress claims.'],'FIRST_FINAL_or_C_caller_changed':False,'tiny':{'key_sha256':sha(key),'input_sha256':'f8c82e1a77283abde0cc4a4258d7d85e665779593e34d3ccb7ac4c79773329d6','fixed_files':9,'unique_payload_bytes':total,'whole_limit_ms':15000,'scope':'Only fresh tinySHA/functionality/cancel/join; no3GiB/throughput/runtime source validation or city credit.'},'static_uncovered':['OS thread start failure injection','short-read/file mutation/error injection','runtime FIRSTFINAL integration','actual measured speedup'],'blocking_findings':[],'review_engine_collector_or_candidate_calls':0,'canonical_writes':0}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
