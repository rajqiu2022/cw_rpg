"""One typed-probe report/log audit; no packet/JSON-parent decoding or rerun."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';IP=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration23'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b)
r=load(SF/'performance18_numeric_leaf_candidate01/output/123820_7116249/result.json','2ace053f086a705e557e5b7d2f7d0976285e5cc55ff2af07d635149b32475e2e')
p=load(IP/'typed_packet_once_process_receipt.json','7ce44ee6cd880748a55598508586a2eca33ccbb8606c800f8792984773859671')
g=load(IP/'final_guard.json','07fc222a09b5af48fef751e5005c6e1626f380b674f4105f9cc05f442ee784ca')
assert r['passed']and r['checks']==33 and r['errors']==[]and len(r['rows'])==9 and r['binary_packet_decodes']==1 and r['Field_Scene_ResourceLoader_geometry_image_collector_calls']==0
assert all(x['old_wire']==x['deployed7123']==x['numeric_candidate']for x in r['rows'])
a,b=r['rows'][-2:];assert a['old_wire']and b['old_wire']and not a['numeric_leaf_whole_success']and not b['numeric_leaf_whole_success']
assert a['first_deployed_strict_rejection']=={'depth':0,'key_type':21,'left_type':27,'path':[],'reason':'RIGHT_NONSTRING_KEY','right_type':27}
reject=b['first_deployed_strict_rejection'];assert reject['depth']==5 and reject['reason']=='FINITE_FLOAT_VALUE_VARIANT'and reject['old_numeric_leaf_wire_equal']and reject['left_type']==reject['right_type']==3
assert reject['path']==['material_binding_evidence','native_geometry_owner_uniforms','actual_parameters','rock_arm','actual_instance_id']
assert [a[k]for k in ['old_wire_wall_usec','deployed_wall_usec','numeric_candidate_wall_usec']]==[637948,617226,614067]
assert [b[k]for k in ['old_wire_wall_usec','deployed_wall_usec','numeric_candidate_wall_usec']]==[616308,661270,764957]
assert p['actual_natural_console_exit_code']==0 and p['exit_code_from_retained_process_WaitForExit']and not p['process_stopped_by_tool']and p['headless']
assert p['script_sha256']==p['script_after_sha256']=='2e0fa343608c9f183dc23e2baf11e3d94caa7f38188b9bc921fa8f0502764f17'
for k in ['stdout','stderr']:assert sha(Path(p[k+'_path']).read_bytes())==p[k+'_sha256']
log=Path(p['stderr_path']).read_text();assert len(re.findall(r'^WARNING:',log,re.M))==8 and log.count('WARNING: Exponent too high')==8 and not re.search(r'^(ERROR:|SCRIPT ERROR:)',log,re.M)
assert g['passed']and g['checked']==g['exact_unchanged']==2117 and g['save_count']==15 and g['save_change_count']==g['unexpected_change_count']==0 and g['all_changes']==[]
fixture=load(SF/'performance19_typed_pair_key01/typed_packet_comparison_fixture_ROOT23_READY.json','61e2d643a4a66bb18299bf5e3c86ad1ca59c84c63efa107639d8fee727911b08')
for path in [fixture['old_bundle_path'],fixture['candidate_path']]:assert sha((ROOT/path[6:]).read_bytes())==fixture['source_sha256'][path]
assert sha((ROOT/p['script'][6:]).read_bytes())==p['script_sha256']
assert sha((ROOT/'scripts/city/luoyang_precomputed_bundle_20261018r.gd').read_bytes())=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
out=QA/'typed_probe123820_independent_actual_representation_review_READY.json'
result={'status':'TYPED_PROBE_FUNCTIONAL_COMPARISON_PASSED_NUMERIC_CANDIDATE_FAST_DOMAIN_MISSED_NOT_ADMITTED','result_sha256':'2ace053f086a705e557e5b7d2f7d0976285e5cc55ff2af07d635149b32475e2e','checks':33,'failures':0,'three_predicates_all9_results_equal':True,'both_actual_old_baselines_accept':True,'true_console_exit':0,'Root23_guard2117_including15save_exactticks':True,'runtime_four_fixed_source_before_after_checks_passed':True,'source_payloads_rehashed_or_decoded_by_QA':False,'pair1':{'strict_first_rejection':a['first_deployed_strict_rejection'],'numeric_whole_success':False,'old_deployed_candidate_usec':[637948,617226,614067]},'pair2':{'strict_first_rejection':reject,'numeric_whole_success':False,'old_deployed_candidate_usec':[616308,661270,764957],'candidate_slower_than_old_usec':148649,'candidate_slower_than_deployed_usec':103687},'important_unobserved':'The report records first DEPLOYED STRICT rejection only, not first numeric-helper rejection. The accepted old-wire numeric leaf at rock_arm does not explain the later whole numeric failure. No unseen path/type/obstacle is inferred.','nonclean_logs':{'Exponent_warnings_from_deliberate_INF_case':8,'ERROR':0,'SCRIPT_ERROR':0},'Root_decision_preserved':'3F002 not promoted; no stage/reprobe/public-entry replay. Deployed B remains7123.','limitations':['Single fixed-order typed representation diagnostic. No stable speedup or Field/loading/all-city credit.','Pair2 candidate is measurably slower in this one observation; retain rather than hiding with another run.','Runtime source checks are covered by fixed33/0 key plus Root guard, not full source/mtime tables in the report.'],'QA_engine_collector_packet_decode_parentJSONparse_canonical_write':0}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
