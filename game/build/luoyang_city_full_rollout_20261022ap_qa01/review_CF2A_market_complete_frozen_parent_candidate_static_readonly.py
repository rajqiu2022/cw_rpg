"""Full byte inverse and proof-domain review only; no parser/engine/packet."""
from pathlib import Path
import hashlib
import json

Q=Path(__file__).resolve().parent
G=Q.parents[1]
D=G/'build/luoyang_city_full_rollout_20261022ap_system01/market_parent_receipt_fix_candidate_epoch01'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))
pp=D/'whole_function_inverse_AUTHOR_NOTREADY.json'
hp=D/'cause_and_candidate_handoff_AUTHOR_READY_NOT_RUNTIME.json'
assert sha(pp)=='8d24b5152cb0700662b9592b95dea1fbafddbe09b660d555d5f9cd8cd454138b'
assert sha(hp)=='bd29b028c250012d8fe71ca238b6a7ec143685ddd2bec04c4158f0e882ae144a'
p,h=rd(pp),rd(hp)
cp=G/p['candidate']['path'][6:]
bp=G/p['parent']['path'][6:]
child,parent=cp.read_bytes(),bp.read_bytes()
assert len(child)==31206 and len(parent)==30746
assert sha(cp)=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
assert sha(bp)=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84'
assert not child.endswith(b'\n') and not parent.endswith(b'\n') and b'\r' not in child+parent
assert len(p['hunks'])==1
old,new=(p['hunks'][0][k].encode() for k in ['old','new'])
assert parent.count(old)==1 and child.count(new)==1
assert parent.replace(old,new)==child and child.replace(new,old)==parent
branch=b'''\tif domain=="market":
\t\t# AP/AO inverse consumes the complete frozen parent before B strips
\t\t# the already-verified runtime receipts for its final two comparisons.
\t\tvar pair: Dictionary=_copy_parent_pair(parent,domain)
\t\tfor key: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
\t\t\tif not current.has(key): pair.current_ap_record.erase(key)
\t\treturn pair
'''
assert new.count(branch)==1 and new.replace(branch,b'')==old
assert new.index(b'if not _same(current,child): return {}') < new.index(branch)
assert new.count(b'pair.current_ap_record.erase(key)')==1
assert b'pair.frozen_ap_record.erase' not in new
assert h['AUTHOR_READY'] is True and h['runtime_or_deployment_ready'] is False
for path,digest in h['small_source_proof'].items():
    path=G/path[6:]
    assert path.stat().st_size<1048576 and sha(path)==digest.lower()
parent_text=parent.decode()
copyfun=parent_text[parent_text.index('static func _copy_parent_pair('):parent_text.index('static func _map_parent(')]
assert '"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)' in copyfun
assert '"current_t_record":parent.duplicate(true),"frozen_t_record":parent.duplicate(true)' in copyfun
B=(G/'scripts/city/luoyang_precomputed_bundle_20261018r.gd').read_text(encoding='utf-8-sig')
restore=B[B.index('static func restore_parent_record('):B.index('static func ap_district_projection(')]
apcheck='_ap().inverse_record(child,data.ap_parent_record,spec)'
aocheck='_ao(scene.scene_id).inverse_record(data.ap_parent_record,data.ao_parent_record,ao_spec)'
strip='if not current.has(key): child.erase(key)'
double='if not _symmetric_record_wire_equal(current,child) or not _symmetric_record_wire_equal(prior,expected): return {}'
assert restore.index('child=restored_ap.frozen_ap_record') < restore.index(apcheck) < restore.index(aocheck) < restore.index(strip) < restore.index(double)
assert restore.count(double)==1
prior=Q/'ROOT42_96812_native_scalar_actual_and_earlystrip_causal_closure_READY.json'
assert sha(prior)=='1329f93b01ecfc4b58d2c6475053322bf0103a7d68a77030eea74ed6cbf7cdda'
out=Q/'CF2A_market_only_complete_frozen_parent_static_admission_NOT_RUNTIME_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_FOR_MARKET_ONLY_COMPLETE_FROZEN_AP_COPY_SOURCE_PREPARATION_NOT_RUNTIME_READY',
    'pins':{'candidate':sha(cp),'parent':sha(bp),'whole_function_inverse':sha(pp),'author_handoff':sha(hp),'fixed_actual_cause_review':sha(prior)},
    'wholebyte':{'single_map_parent_function_positive_and_inverse_exact':True,'exact_only_added_market_branch_restores_old_function':True,
        'parent30746_child31206_CR0_no_finalLF_preserved':True,'all_other_functions_and_Yamen_old_loop_byteidentical':True,
        'no_StringName22ECA_branch_or_other_runtime_source_change':True},
    'semantic':{'domain_state_token_owner_packet_full_current_child_gates_before_added_branch_unchanged':True,
        'complete_frozen_parent_origin_not_current_or_expected_fill':True,'two_independent_deepcopies_from_original_copy_parent_pair':True,
        'only_current_ap_record_strips_original_four_list_when_absent_in_current':True,
        'frozen_ap_record_remains_complete_for_original_AP_whole_inverse':True,
        'original_AO_inverse_still_follows_and_is_independent':True,
        'only_after_whole_inverses_original_B_final_strip_reconciles_final_comparison_domains':True,
        'current_child_and_prior_expected_symmetric_checks_both_preserved':True,
        'DT_exact_receipt_value_checks_and_original_removal_unchanged':True,
        'Yamen_original_path_no_new_semantic_or_copy_change':True,
        'whole_bound_FRESHFIRSTFINAL_native_mask_geometry_doors_NPC_unchanged':True},
    'acceptance_boundary':['No static blocker to Root exact30 source preparation',
        'No Stage/deployment/parse/runtime entrance approval from static review',
        'Original no-finalLF transport requires lossless source/deploy handling, not silent normalization',
        'ROOT41 failure and C0000005 remain; no successful Market draw/ART claim',
        'Original AUTHOR_NOTREADY inverse is historical; new BD29 binds Root42 scalar existence only'],
    'operations':{'engine':0,'parse':0,'packet_decode':0,'collector':0,'Stage':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'static_blocker':False,'runtime_ready':False}))
