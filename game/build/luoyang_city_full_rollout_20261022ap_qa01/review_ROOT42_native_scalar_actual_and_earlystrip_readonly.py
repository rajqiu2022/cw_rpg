"""Read one completed small native proof; no packet read/decode by this audit."""
from pathlib import Path
import hashlib
import json

Q=Path(__file__).resolve().parent
G=Q.parents[1]
D=G/'build/luoyang_city_full_rollout_20261022ap_system01/market_parent_receipts_native_isolate_epoch01'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration42'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'project/output/96812_82086/result.json'
assert sha(rp)=='ccb89b6147e77e0fab6bf4f1a56daa902fcc88ef650354c3363e85a464e556aa'
r=rd(rp)
assert r['complete'] and r['checks']==35 and r['failures']==[] and r['elapsed_usec']==179979
assert r['limit_ms']==15000 and r['native_packet_decodes']==1 and r['autoload_children']==0
for key in ['Scene_Field_collector_geometry_materialize_media_import_calls','packet_record_walk_copies_or_rebuilds','save_opens_or_writes','formal_writes']:
    assert r[key]==0
mp=D/'ROOT42_READY_mechanical_inverse.json'
assert sha(mp)=='5d405154919d506b57c23b973f4ac01312642885420d0e0fc997c8024b35f898'
m=rd(mp)
kp=D/'project/probe_ROOT42_READY.gd'
fp=D/'project/fixture_ROOT42_READY.json'
assert sha(kp)==r['key_sha256']==m['key']['sha256'].lower()=='dba24bc55b389d7fe87d9fb25a4dafaeadcd9c3529f687ecf4c40fb565e55456'
assert sha(fp)==r['fixture_sha256']==m['fixture']['sha256'].lower()=='4022ccbbecc9d2b031ee68db9ff79b787d47b660551e6e357f8b4323663efbb2'
back=kp.read_bytes()
for old,new in reversed(m['key']['only_replacements']):
    assert back.count(new.encode())==1
    back=back.replace(new.encode(),old.encode())
assert back==(D/'project/probe_NOTREADY.gd').read_bytes()
assert fp.read_bytes().replace(b'"ready": true',b'"ready": false')==(D/'project/fixture_NOTREADY.json').read_bytes()
f=rd(fp)
assert r['source_first']==r['source_final']==f['source_sha256'] and len(r['source_first'])==4
for path,digest in r['source_final'].items():
    assert Path(path).stat().st_size<1048576 and sha(Path(path))==digest
assert r['binding_first']==r['binding_final']==f['binding_sha256']==sha(Path(f['binding_path']))
assert r['packet']['actual_sha256']==r['packet']['declared_sha256']==f['packet_sha256']
assert r['packet']['bytes']==26355440 and r['packet']['whole_SHA_checked_before_decode']
assert list(sorted(r['record_projections']))==['ap_parent_record','record','t_parent_record']
for name,count in [('record',64),('ap_parent_record',63),('t_parent_record',61)]:
    row=r['record_projections'][name]
    assert row['type']=='Dictionary' and row['field_count']==count
    assert row['receipts']=={
        'assembled_runtime_binding_sha':{'present':True,'type':'String','value':'0eefe2fcf873bd9e237bc474c2db6603d916f93dec2e9d513a464345a070f8e9'},
        'assembled_parent_task_semantics_preserved':{'present':True,'type':'bool','value':True}}
pp=R/'parent_receipts_once_process_receipt.json'
assert sha(pp)=='a48d4e98de223c89f93446ac7813911a287232c1c0f68057c7aab2f24c83c5ce'
pr=rd(pp)
assert pr['actual_natural_console_exit_code']==0 and pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
assert pr['script_sha256']==pr['script_after_sha256']==sha(kp)
ep,op=R/'parent_receipts_once_stderr.log',R/'parent_receipts_once_stdout.log'
assert ep.read_bytes()==b'' and sha(ep)==pr['stderr_sha256'] and sha(op)==pr['stdout_sha256']
gp,bp=R/'final_guard.json',R/'guard_before.json'
assert sha(gp)=='67aa5ff5174c2e8d512f12b93297468994863a37fb5eac6a0e282ddaf9e48ae0'
g,b=rd(gp),rd(bp)
assert g['passed'] and g['checked']==g['exact_unchanged']==2118 and g['save_count']==15
assert g['authorized_change_count']==g['unexpected_change_count']==g['save_change_count']==0
assert g['facts']==b['facts']
cp=Q/'market41_early_runtime_receipt_strip_conditional_source_proof_NOT_IMPLEMENTATION.json'
assert sha(cp)=='644015d57f23fecb43a99c58affb8ddec09eb52396a4e239b19d935601cc6086'
c=rd(cp)
for path,digest in c['source_sha256'].items():
    assert Path(path).stat().st_size<1048576 and sha(Path(path))==digest
out=Q/'ROOT42_96812_native_scalar_actual_and_earlystrip_causal_closure_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'FIXED_PARENT_NATIVE_SCALAR_PROOF_PASSED_SOURCE_EARLY_STRIP_CAUSE_CLOSED_NOT_RUNTIME_REPAIR',
    'actual':{'report_sha256':sha(rp),'checks':35,'failures':0,'elapsed_usec':179979,
        'one_packet_fullSHA_then_native_decode_recorded':True,'packet_bytes':26355440,'packet_SHA':r['packet']['actual_sha256'],
        'record_projections':r['record_projections'],'no_other_record_or_walk_content_read_by_QA':True},
    'mechanical_READY':{'three_key_literal_inverse_exact':True,'one_fixture_bool_inverse_exact':True,'project_unchanged':True,'proof_sha256':sha(mp)},
    'protection':{'four_source_FIRSTFINAL_expected_and_current_SHA_exact':True,'binding_FIRSTFINAL_current_SHA_exact':True,
        'Root2118facts_and_15save_exactticks_beforeafter':True,'Root_final_guard_sha256':sha(gp),
        'no_large_packet_or_media_rehash_by_QA':True},
    'exit':{'true_console':0,'empty_stderr':True,'process_receipt_sha256':sha(pp),'wall_ms':pr['elapsed_wall_ms'],
        'clean_only_for_this_isolated_scalar_probe':True},
    'causal_closure':{'conditional_source_proof_sha256':sha(cp),'fixed_AP_parent_record_contains_both_runtime_receipts':True,
        'fixed_AP_record_also_contains_both':True,'fixed_T_parent_also_contains_both':True,
        'source_proven_strip_before_AP_complete_inverse_is_a_deterministic_refusal':True,
        'ROOT41_did_not_capture_inner_B_gate_so_not_an_observed_branch_trace':True,
        'no_fixed_expectation_filled_from_this_output':True},
    'constraints':['ROOT41 wholeFAIL and C0000005 remain','Custom stream FAIL19828 remains',
        'Do not skip AP/AO inverse, either independent final pair, whole_bound, token/owner or FIRSTFINAL',
        'Repair must preserve complete frozen AP proof copy and separate stripped runtime current domain',
        'No runtime repair/ART/fullcity/sourceDAG approval from this scalar proof'],
    'operations':{'engine':0,'packet_decode':0,'collector':0,'newGUIkey':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'true_exit':0,'causal_source_condition_closed':True}))
