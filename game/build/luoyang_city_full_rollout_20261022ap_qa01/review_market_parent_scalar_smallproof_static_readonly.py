"""Review fixed single-decode scalar probe as source only, not packet decode."""
from pathlib import Path
import hashlib
import json

Q=Path(__file__).resolve().parent
G=Q.parents[1]
D=G/'build/luoyang_city_full_rollout_20261022ap_system01/market_parent_receipts_native_isolate_epoch01'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))
hp=D/'handoff_NOTREADY.json'
assert sha(hp)=='fd6014ede3a2fa85acd2b7a0667dc3cc2cdacd318caf038a21fe791a03a3dc9f'
h=rd(hp)
for name in ['key','project','fixture']:
    p=Path(h[name]['path'])
    assert sha(p)==h[name]['sha256'].lower() and p.stat().st_size==h[name]['bytes']
f=rd(Path(h['fixture']['path']))
k=Path(h['key']['path']).read_text(encoding='utf-8')
assert h['ready'] is False and f['ready'] is False and 'const READY := false' in k
assert '[autoload]' not in Path(h['project']['path']).read_text() and 'run/main_scene' not in Path(h['project']['path']).read_text()
assert f['record_fields']==['record','ap_parent_record','t_parent_record']
assert f['receipt_fields']==['assembled_runtime_binding_sha','assembled_parent_task_semantics_preserved']
assert f['whole_ms']==15000 and len(f['source_sha256'])==4
for path,digest in f['source_sha256'].items():
    p=Path(path)
    assert p.stat().st_size<1048576 and sha(p)==digest
bp=Path(f['binding_path'])
assert sha(bp)==f['binding_sha256']=='dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff'
b=rd(bp)
assert b['domains']['market']['parent_packet_path']==f['packet_res_path']
assert b['domains']['market']['parent_packet_sha256']==f['packet_sha256']=='edcb58007aff16bb5175ce3424b4e4bddfcb619aaab5ff07d0102f50c6962f80'
assert k.count('FileAccess.get_file_as_bytes(')==1
assert k.count('bytes_to_var(packet_bytes)')==1 and 'bytes_to_var_with_objects' not in k
assert k.index('actual_sha == fixture.packet_sha256') < k.index('bytes_to_var(packet_bytes)')
assert 'packet_bytes.size() <= 64 * 1024 * 1024' in k
assert '.duplicate(' not in k and 'ResourceLoader' not in k and 'preload(' not in k and 'load(' not in k
assert 'root.get_child_count() == 0' in k
assert 'typeof(value) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_BOOL, TYPE_NIL]' in k
assert 'binding_after == binding_before' in k and 'final[path] == first[path]' in k
out=Q/'market_parent_native_scalar_false_smallproof_independent_static_NOT_EXECUTED.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_FOR_FIXED_SINGLE_NATIVE_DECODE_SCALAR_PROBE_FALSE_NOT_EXECUTED',
    'pins':{'handoff':sha(hp),'key':h['key']['sha256'],'fixture':h['fixture']['sha256'],'project':h['project']['sha256'],'binding':sha(bp)},
    'scope':{'four_current_small_source_SHA_exact':True,'fixed_binding_market_parent_EDCB_relationship_exact':True,
        'only_future_one_absolute_packet_read_complete_SHA_then_one_plain_bytes_to_var':True,
        'packet_buffer_max64MiB':True,'three_root_records_two_receipt_scalar_fields_only':True,
        'observes_presence_types_counts_without_prejudging_presence':True,'no_record_clone_walk_or_objects_enabled_decode':True,
        'no_production_scriptload_or_method_call':True,'noautoload_noScene_noField_nocollector':True,
        'whole15s_includes_checks_decode_and_finalchecks':True,'source_and_binding_FIRSTFINAL':True,
        'only_result_file_written':True},
    'limits':['Requires Root NEW READY mechanical successor and external natural exit/log capture before execution',
        'No packet decoded by QA; fixed actual receipt presence remains unobserved until Root run',
        '15save protects via Root external guard, not probe opening or hashing saves',
        'No AP/AO inverse execution, runtime approval, source-DAG, geometry or ART credit',
        'Original custom stream FAIL19828 and false artifacts remain unchanged'],
    'operations':{'engine':0,'parse':0,'packet_decode':0,'collector':0,'canonical':0,'READY':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'blocker':False,'executed':False}))
