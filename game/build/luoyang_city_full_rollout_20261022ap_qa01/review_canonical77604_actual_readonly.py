"""Unique ROOT24 report audit, no packet decode or benchmark replay."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';IP=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration24'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b)
r=load(SF/'performance23_canonical_ROOT24_READY/output/77604_7681498/result.json','1da1625e74275c5dad8e62a4e894b0d783934a8254b0e33ae608a73e465cb424')
p=load(IP/'canonical_typed_once_process_receipt.json','962fcbd41b28b566729f666452fe733a8680ac0cce4e92bb15e713b7d4049c8a')
g=load(IP/'final_guard.json','9c9cbba122d7fd51a1cc4f867e830294e117ca5cb78b4b6baa46512fcf0ba09b')
assert r['passed']and r['checks']==59 and r['errors']==[]and r['binary_packet_decodes']==1 and r['Field_Scene_ResourceLoader_geometry_image_collector_calls']==0
comparisons=[x for x in r['rows']if 'old_wire'in x];assert len(comparisons)==13 and all(x['old_wire']==x['deployed7123']==x['canonical_candidate']for x in comparisons)
a,b=[x for x in comparisons if x['label'].startswith('actual pair')]
for x in [a,b]:
    assert x['old_wire']and x['deployed7123']and x['canonical_candidate']and x['canonical_keys_whole_success']and x['canonical_full_rejection_domains']=={} and not x['numeric_leaf_whole_success']and not x['deployed_strict_success']
    assert x['diagnostic_scans_excluded_from_timed_wall']and x['rejection_counts_are_domain_occurrences_not_executed_branch_counts']
assert set(a['numeric_full_rejection_domains'])=={'LEFT_NONSTRING_KEY:21:21','RIGHT_NONSTRING_KEY:21:21'}
assert set(b['numeric_full_rejection_domains'])=={'LEFT_NONSTRING_KEY:21:21'}
for x in [a,b]:
    for v in x['numeric_full_rejection_domains'].values():assert v['count']==6 and v['first_path']==['ground_capture_path']and v['first_depth']==0
assert [a[k]for k in ['old_wire_wall_usec','deployed_wall_usec','canonical_candidate_wall_usec']]==[635813,625144,195593]
assert [b[k]for k in ['old_wire_wall_usec','deployed_wall_usec','canonical_candidate_wall_usec']]==[609117,666141,205924]
collision=next(x for x in r['rows']if x['label']=='canonical collision construction boundary');assert collision['ordinary_Dictionary_merged_String_StringName_keys']and not collision['collision_runtime_coverage_claim']
mixed=next(x for x in r['rows']if x['label']=='mixed badkey and valid Vector subtree coverage')
for name in ['numeric_rejections','canonical_rejections']:
    assert mixed[name]['UNSUPPORTED_VARIANT:5:5']['first_path']==['good']and mixed[name]['UNSUPPORTED_VARIANT:5:5']['count']==1
    bad=[v for k,v in mixed[name].items()if k!='UNSUPPORTED_VARIANT:5:5'];assert len(bad)==2 and all(v['first_path']==['42']and v['count']==1 for v in bad)
synthetic=next(x for x in r['rows']if x['label']=='synthetic canonical-index collision exclusion helper coverage')
assert synthetic['synthetic_index_unit_only_not_actual_Dictionary_collision_credit']and len(synthetic['rejections'])==1 and synthetic['rejections']['UNSUPPORTED_VARIANT:5:5']['first_path']==['good']
assert p['actual_natural_console_exit_code']==0 and p['exit_code_from_retained_process_WaitForExit']and not p['process_stopped_by_tool']and p['headless']and p['elapsed_wall_ms']==9442
assert p['script_sha256']==p['script_after_sha256']=='b150ce3b8119a77b2c8cfb69efe030f4f62f5c0c045eaa5278f7ff81ffe4ce93'
for k in ['stdout','stderr']:assert sha(Path(p[k+'_path']).read_bytes())==p[k+'_sha256']
log=Path(p['stderr_path']).read_text();assert len(re.findall(r'^WARNING:',log,re.M))==8 and log.count('WARNING: Exponent too high')==8 and not re.search(r'^(ERROR:|SCRIPT ERROR:)',log,re.M)
assert g['passed']and g['checked']==g['exact_unchanged']==2117 and g['save_count']==15 and g['save_change_count']==g['unexpected_change_count']==0 and g['all_changes']==[]
fixture=load(SF/'performance23_canonical_ROOT24_READY/typed_packet_comparison_fixture_ROOT24_READY.json','87deef397b7f8e5c5f667368b77383d087faffece95bdbeff4cfe10556b5cddb')
for path in [fixture['old_bundle_path'],fixture['candidate_path']]:assert sha((ROOT/path[6:]).read_bytes())==fixture['source_sha256'][path]
assert sha((ROOT/p['script'][6:]).read_bytes())==p['script_sha256']
assert sha((ROOT/'scripts/city/luoyang_precomputed_bundle_20261018r.gd').read_bytes())=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
out=QA/'canonical77604_independent_actual_fastdomain_review_READY.json'
result={'status':'ONE_TYPED_RECORD_PROBE_SEMANTICS_AND_COMPLETE_FAST_HITS_PASSED_NOT_DEPLOYMENT_OR_FIELD_SPEED','result_sha256':'1da1625e74275c5dad8e62a4e894b0d783934a8254b0e33ae608a73e465cb424','checks':59,'errors':0,'true_console_exit':0,'actual_process_wall_ms':9442,'all13_old_deployed_new_semantics_equal':True,'both_actual_old_baselines_accept_and_canonical_whole_fast_true':True,'canonical_actual_rejection_domains_empty':True,'numeric_actual_rejection_domains':{'pair1_left_StringName_keys':6,'pair1_right_StringName_keys':6,'pair2_left_StringName_keys':6,'first_path':['ground_capture_path']},'pair1_old_deployed_canonical_usec':[635813,625144,195593],'pair2_old_deployed_canonical_usec':[609117,666141,205924],'mixed_badkey_does_not_mask_unique_Vector_sibling_actual':True,'synthetic_collision_exclusion_unit_actual':True,'ordinary_Dictionary_String_StringName_collision_merged_no_collision_runtime_credit':True,'warnings':{'deliberate_INF_Exponent':8,'ERROR':0,'SCRIPT_ERROR':0},'Root24_2117_including15save_exactticks_same':True,'runtime_four_source_before_after_checks_passed_not_payload_rehashed_by_QA':True,'current_small_candidate_key_fixture_pins_same':True,'deployed_formal_B_still7123':True,'limitations':['One fixed-order old/deployed/new pair observation, diagnostics and extra helper reads excluded from compared timers. No stable/SSD-cold/all-city/Field-loading benefit or savings multiplication.','The report stores full rejecting-domain summaries for eligible unambiguous child pairs, not runtime branch counts. Unknown/ambiguous mappings intentionally skipped; array size mismatch reported at container.','Only dictionary merge-boundary observation and synthetic index exclusion are available for collisions; no actual ordinary dictionary duplicate-key collision coverage is claimed.','9D5B remains build-only. No source stage or formal promotion authority is implied; previous3F002 rejection and123820 slow observation remain.'],'QA_engine_packetdecode_parentJSONparse_collector_or_formal_write':0}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
