"""Source-only conditional causal proof. No packet decode or production calls."""
from pathlib import Path
import hashlib
import json

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
paths = {
    'DT': GAME/'scripts/city/luoyang_district_life_20261016f.gd',
    'B': GAME/'scripts/city/luoyang_precomputed_bundle_20261018r.gd',
    'adapter': GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd',
    'AP': GAME/'build/luoyang_city_full_rollout_20261022ap_system01/market_alpha_pin_retry6/market_transform.gd',
    'assembled_runtime': GAME/'scripts/city/luoyang_city_assembled_runtime_20261016b.gd'
}
text = {k:p.read_text(encoding='utf-8-sig') for k,p in paths.items()}
assert 'current.erase(key)' in text['DT']
assert text['DT'].index('current.erase(key)') < text['DT'].index('if current.is_empty(): return _reject("T_COMPLETE_REVERSIBLE_PARENT_RECORD")')
assert 'if not current.has(key): parent.erase(key)' in text['adapter']
assert 'return _copy_parent_pair(parent,domain)' in text['adapter']
assert '"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)' in text['adapter']
assert text['B'].index('_ap().inverse_record(child,data.ap_parent_record,spec)') < text['B'].index('if not current.has(key): child.erase(key)', text['B'].index('static func restore_parent_record('))
assert 'var out: Dictionary=parent.duplicate(true);var count: Dictionary={}' in text['AP']
assert 'if expected.is_empty() or not same(child,expected): return {}' in text['AP']
assert text['AP'].count('assembled_runtime_binding_sha') == 0
assert 'packet_data.record["assembled_runtime_binding_sha"]=BIND_SHA' in text['assembled_runtime']
assert 'packet_data.record["assembled_parent_task_semantics_preserved"]=true' in text['assembled_runtime']
out = QA/'market41_early_runtime_receipt_strip_conditional_source_proof_NOT_IMPLEMENTATION.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'SOURCE_ONLY_CONDITIONAL_EARLY_STRIP_CAUSAL_PROOF_NO_ACTUAL_INNER_GATE_SNAPSHOT',
    'source_sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths.values()},
    'chain':[
        'DT validates then strips exactly two assembled runtime receipt keys from current before B.restore_parent_record.',
        'Adapter validates stripped current against matching stripped child, then strips its frozen AP parent copy using the same missing-key condition.',
        'Two independent mapped AP record copies therefore both lack those keys.',
        'B tests complete AP inverse against data.ap_parent_record before its final pair-domain runtime-receipt stripping.',
        'AP._record deep-clones parent and never removes these generic extra receipt keys; inverse_record first requires strict complete child==derived expected.',
        'IF fixed data.ap_parent_record contains the two receipt keys, mapped child lacks both and that AP inverse must refuse.'
    ],
    'evidence_boundary':{
        'runtime_assembled_code_sets_two_keys':True,
        'fixed_actual_parent_packet_presence_requires_System_small_proof':True,
        'actual53100_only_reports_B_restore_empty_not_inner_gate':True,
        'no_packet_decode_or_live_record_snapshot_used':True
    },
    'repair_constraints_not_implementation':[
        'Keep complete publication AP/AO inverse proof domain separate from the DT runtime-receipt-stripped final pair domain.',
        'Retain source-bound frozen parent origins; never form expected from actual current.',
        'No skip or relaxation of AP inverse, AO inverse, whole_bound, independent current/child and prior/expected pair checks, or FIRST/FINAL.',
        'Retain independent deep-copy/noalias contract and exact approved receipt values.'
    ],
    'operations':{'engine':0,'collector':0,'packet_decode':0,'new_test':0,'canonical':0,'candidate':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}))
