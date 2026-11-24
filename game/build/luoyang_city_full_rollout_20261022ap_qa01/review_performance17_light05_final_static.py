"""Final one-entry AP13 performance05 static freeze/source recipe audit."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def pin(row):
    b=res(row['path']).read_bytes();assert sha(b)==row['sha256'];return b
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
hp=SF/'performance17_yamen_light05_ROOT21/handoff_ROOT21_READY_NOT_RUN.json';hb=hp.read_bytes();assert sha(hb)=='776f1d0ee9e37ce1eb4532febbd26c922aa614c12e6cbff6f30e65cde139496c';h=json.loads(hb)
key=pin(h['script']);f=json.loads(pin(h['fixture']));pending=pin(h['pending_key']);parent=pin(h['parent_key'])
ph=json.loads((SF/'performance16_yamen_light05/handoff_PENDING_ROOT_NOT_RUN.json').read_bytes())
def inverse(raw,rows):
    t=raw.decode()
    for row in reversed(rows):assert t.count(row['new'])==1;t=t.replace(row['new'],row['old'],1)
    return t.encode()
assert inverse(key,h['mechanical_ready_key_hunks_only'])==pending and inverse(pending,ph['hunks'])==parent
owner=json.loads(pin(h['actual_independent_owner']));stage=json.loads(pin(h['actual_source_stage']));guard=json.loads(pin(h['actual_Root_deployment_guard']));cp=json.loads(pin(h['actual_Root_deployment_copy']))
assert guard['passed']and guard['exact_unchanged']==2095 and guard['save_count']==15 and guard['unexpected_change_count']==0 and len(guard['all_changes'])==22
assert cp['all22_exact']and cp['JSON_exact_copy_count']==13 and cp['GD_apply_patch_count']==9
oldfp=SF/'performance10_yamen_light04_ROOT18/yamen_performance04_fixture_ROOT18_READY.json';oldraw=oldfp.read_bytes();assert sha(oldraw)=='1e8926959c79c2819253da70befac4d64ad619770eab838a1f2b1b88e01d97c5';old=json.loads(oldraw)
yamen=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen');assert len(yamen['source_sha256'])==1223 and same(yamen['source_sha256'],f['expected_city_source_sha256'])
guard_expected=copy.deepcopy(old['source_sha256'])
for p,v in owner['core_source_sha256'].items():
    if p in guard_expected:guard_expected[p]=v
guard_expected.update(yamen['source_sha256'])
oldparent='res://tests/test_luoyang_ap_yamen_performance03_LIGHT_ROOT16_READY_20261023.gd'
remove=[oldparent]+[old['authority'][k]['path']for k in ('independent_owner','actual_source_stage','actual_Root_deployment_guard','actual_Root_deployment_copy')]
assert len(set(remove))==5
for p in remove:assert p in guard_expected;del guard_expected[p]
for row in [h['parent_key'],h['actual_independent_owner'],h['actual_source_stage'],h['actual_Root_deployment_guard'],h['actual_Root_deployment_copy']]:
    assert row['path']not in guard_expected;guard_expected[row['path']]=row['sha256']
assert len(guard_expected)==1246 and same(guard_expected,f['source_sha256'])
assert f['ready']and f['blockers']==[] and f['whole_ms']==60000 and f['max_pictures']==0 and f['public_requests']==1 and f['firstdraw_target_usec']==10000000
for k in ['scene_path','layout_path','owner_path','measurement','natural_receipt_rule','scope','district_timing_rule']:assert same(f[k],old[k])
assert all(f['source_sha256'][p]==v for p,v in f['expected_city_source_sha256'].items())
text=key.decode();pt=parent.decode()
def func(t,name):
    start=t.index('func '+name+'(');end=t.find('\nfunc ',start+1);return t[start:end if end>=0 else len(t)]
for name in ['clock_fact','observe_readonly','post_draw_readonly','district_timing_once_after_frozen_draw']:
    assert func(text,name)==func(pt,name).replace('PERF04_','PERF05_')
assert text.count('district.call("loading_timing_state")')==1 and text.count('call("go_field_smart",ID,null)')==1
assert text.index('var owner_ok: bool=natural_receipt_only()')<text.index('var timing_ok: bool=district_timing_once_after_frozen_draw() if owner_ok else false')
for bad in ['.resident_receipt(','.resident_matches(','.source_paths(','.validation_begin(','.validation_finish(','.resolve(','.compile(','.get_image(','.capture(']:assert bad not in text
for row in h['diffs'].values():pin(row)
out=QA/'performance17_light05_ROOT21_independent_final_static_admission_READY.json'
r={'status':'INDEPENDENT_AP13_PERFORMANCE05_ONE_YAMEN_STATIC_NO_BLOCKER_NOT_RUN','key_sha256':sha(key),'fixture_sha256':h['fixture']['sha256'],'whole_pending_and_parent51FDD_byte_inverse':True,'expected1223_map_exact_independent5050':True,'sourceguard1246_reconstructed_from_fixedROOT18_plus5050core_and_map_and_five_authority_replacements':True,'Root21_guard22_authorized2095same15save_exact':True,'observer_draw_clock_DT_getter_functions_inherited_except_labels':True,'DT_single_getter_after_draw_and_natural_receipt':True,'same_owner_and_token_no_freshcredit_checks_retained':True,'scope':{'whole_ms':60000,'public_default_null_requests':1,'input':0,'pictures':0,'geometry':0,'collector':0},'QA_engine_parse_Stage_or_large_source_scan':False,'blocking_findings':[],'Root_next':'May execute exactly once after external full key/fixture hashes; preserve separate functional/performance/real-exit outcomes. Not all-city or clean-exit approval.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
