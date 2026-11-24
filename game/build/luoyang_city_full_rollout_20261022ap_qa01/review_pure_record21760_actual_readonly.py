"""Small report/log/source checks only; no record payload decode or replay."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01';IP=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration20'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b)
r=load(D/'output/21760_3205761/result.json','c3bb211e56d11f0947a060d678d8755063fbbcc2ebdf6246e2965ef9aa0ba3a1')
p=load(IP/'pure_record_once_process_receipt.json','b600d2f62c97ab2d673df7911578524355779364ca429b0497ba17ece3160402')
g=load(IP/'final_guard.json','f6b3de044977a04f3b32ef6dfbb52941b2c9c08dc6ea32ffc60770fd06dc786f')
assert r['passed']and r['checks']==30 and r['errors']==[] and len(r['rows'])==9
assert all(x['new']==x['old']for x in r['rows'])
assert [x['strict_success']for x in r['rows']]==[True]+[False]*7+[True]
assert r['Field_requests']==r['collector_calls']==r['geometry_calls']==r['native_decode_calls']==0
big=r['rows'][-1];assert big['old_wall_usec']==644576 and big['new_wall_usec']==137563
assert p['actual_natural_console_exit_code']==0 and p['exit_code_from_retained_process_WaitForExit']and not p['process_stopped_by_tool']and p['headless']
assert p['script_sha256']==p['script_after_sha256']=='38d22bca5f88023cf919632967048df645df688dbb4de656a6d681373c9f06dc'
for k in ['stdout','stderr']:assert sha(Path(p[k+'_path']).read_bytes())==p[k+'_sha256']
log=Path(p['stderr_path']).read_text();assert len(re.findall(r'^WARNING:',log,re.M))==5 and log.count('WARNING: Exponent too high')==4 and not re.search(r'^(ERROR:|SCRIPT ERROR:)',log,re.M)
assert g['passed']and g['exact_unchanged']==g['checked']==2117 and g['save_count']==15 and g['save_change_count']==g['unexpected_change_count']==0 and g['all_changes']==[]
fixture=load(D/'pure_record_comparison_fixture_ROOT20_READY.json','5351b756f22860ef7e73a8f0c8fd6eff071df02ef8f4deded6f2b962ee823925')
current={}
for path,h in fixture['source_sha256'].items():
    if path==fixture['parent_manifest_path']:continue
    b=(ROOT/path[6:]).read_bytes();assert sha(b)==h;current[path]=h
key=(ROOT/p['script'][6:]).read_bytes();assert sha(key)==p['script_sha256']
out=QA/'pure_record21760_independent_actual_readonly_review_READY.json'
result={'status':'ONE_FIXED_RECORD_COMPARISON_PASSED_NOT_FIELD_LOADING_OR_DEPLOYMENT','result_sha256':'c3bb211e56d11f0947a060d678d8755063fbbcc2ebdf6246e2965ef9aa0ba3a1','checks':30,'errors':0,'true_console_exit':0,'tiny_cases':8,'strict_depth63_64_checks_in_fixed_key':True,'one_big_pair_usec':{'old_first':644576,'candidate_second':137563},'all9_old_new_results_equal':True,'strict_domain_branch_results_match':True,'current_small_B_candidate_key_fixture_pins_checked':True,'runtime_fixed_parent_manifest_SHA_before_after_checks_passed_not_rehashed_by_QA':True,'Root20_guard_exact2117_including15save_exactticks':True,'nonclean_warnings':{'Exponent_from_deliberate_INF_old_two_wires_and_new_fallback_two_wires':4,'ObjectDB_exit':1,'ERROR_or_SCRIPT':0},'scope_counters_zero':['Field','collector','geometry','native_decode'],'limitations':['Single fixed record pair, old first then candidate, order/cache biased. No whole-city/loading percentage, startup time or measured Field saving.','Actual purekey source checks pass under 30/0; the report does not contain full source facts/mtime tables. Root guard supplies unchanged formal/save evidence.','Candidate remains undeployed; no parse/replay/engine/parent JSON decode by QA.']}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
