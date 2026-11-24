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
hp=SF/'performance28_yamen_light06_ROOT26/handoff_ROOT26_READY_NOT_RUN.json';hb=hp.read_bytes();assert sha(hb)=='f132074209a5710e303c2854fe2d675d37c6f04e5efecc79a91f0fd7d9024866';h=json.loads(hb)
key=pin(h['script']);f=json.loads(pin(h['fixture']));pending=pin(h['pending_key']);parent=pin(h['parent_key'])
ph=json.loads((SF/'performance27_yamen_light06/handoff_PENDING_ROOT_NOT_RUN.json').read_bytes())
def inverse(raw,rows):
    t=raw.decode()
    for row in reversed(rows):assert t.count(row['new'])==1;t=t.replace(row['new'],row['old'],1)
    return t.encode()
assert inverse(key,h['mechanical_ready_key_hunks_only'])==pending and inverse(pending,ph['hunks'])==parent
owner=json.loads(pin(h['actual_independent_owner']));stage=json.loads(pin(h['actual_source_stage']));guard=json.loads(pin(h['actual_Root25_deployment_guard']));cp=json.loads(pin(h['actual_Root25_deployment_copy']))
assert guard['passed']and guard['exact_unchanged']==2095 and guard['save_count']==15 and guard['unexpected_change_count']==0 and len(guard['all_changes'])==22
assert cp['all22_exact']and cp['JSON_exact_copy_count']==13 and cp['GD_apply_patch_count']==9
oldfp=SF/'performance17_yamen_light05_ROOT21/yamen_performance05_fixture_ROOT21_READY.json';oldraw=oldfp.read_bytes();assert sha(oldraw)=='e8b1bea1a4b84f3227c1dacfffc353f2a101f5f481867765d5210e45463c27e7';old=json.loads(oldraw)
yamen=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen');assert len(yamen['source_sha256'])==1225 and same(yamen['source_sha256'],f['expected_city_source_sha256'])
guard_expected=copy.deepcopy(old['source_sha256'])
for p,v in owner['core_source_sha256'].items():
    if p in guard_expected:guard_expected[p]=v
guard_expected.update(yamen['source_sha256'])
oldparent='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance10_yamen_light04_ROOT18/test_yamen_performance04_ROOT18_READY.gd'
remove=[oldparent]+[old['authority'][k]['path']for k in ('independent_owner','actual_source_stage','actual_Root_deployment_guard','actual_Root_deployment_copy')]
assert len(set(remove))==5
for p in remove:assert p in guard_expected;del guard_expected[p]
for row in [h['parent_key'],h['actual_independent_owner'],h['actual_source_stage'],h['actual_Root25_deployment_guard'],h['actual_Root25_deployment_copy']]:
    assert row['path']not in guard_expected;guard_expected[row['path']]=row['sha256']
fresh=json.loads(pin(h['Root26_fresh_before']));guard_expected[h['Root26_fresh_before']['path']]=h['Root26_fresh_before']['sha256']
assert len(guard_expected)==1249 and same(guard_expected,f['source_sha256'])
assert f['ready']and f['blockers']==[] and f['whole_ms']==60000 and f['max_pictures']==0 and f['public_requests']==1 and f['firstdraw_target_usec']==10000000
for k in ['scene_path','layout_path','owner_path','measurement','natural_receipt_rule','scope','district_timing_rule']:assert same(f[k],old[k])
assert all(f['source_sha256'][p]==v for p,v in f['expected_city_source_sha256'].items())
pfraw=pin(h['pending_fixture']);pf=json.loads(pfraw);back=copy.deepcopy(f)
changed_fields={k for k in set(pf)|set(f)if k not in pf or k not in f or not same(pf[k],f[k])}
assert changed_fields=={'status','ready','source_sha256','expected_city_source_sha256','authority','blockers','pending_authority_not_in_source_guard_until_real_freeze','expected_source_count_recipe'}
for k in changed_fields:back[k]=pf[k]
assert same(back,pf)and(json.dumps(back,indent=2,ensure_ascii=False)+'\n').encode()==pfraw
assert h['formal_revision']=='AP14'and f['authority']['formal_revision']=='AP14'
text=key.decode();pt=parent.decode()
def func(t,name):
    start=t.index('func '+name+'(');end=t.find('\nfunc ',start+1);return t[start:end if end>=0 else len(t)]
for name in ['clock_fact','observe_readonly','post_draw_readonly','district_timing_once_after_frozen_draw']:
    assert func(text,name)==func(pt,name).replace('PERF05_','PERF06_')
assert text.count('district.call("loading_timing_state")')==1 and text.count('call("go_field_smart",ID,null)')==1
assert text.index('var owner_ok: bool=natural_receipt_only()')<text.index('var timing_ok: bool=district_timing_once_after_frozen_draw() if owner_ok else false')
for bad in ['.resident_receipt(','.resident_matches(','.source_paths(','.validation_begin(','.validation_finish(','.resolve(','.compile(','.get_image(','.capture(']:assert bad not in text
for row in h['diffs'].values():pin(row)
out=QA/'performance28_light06_ROOT26_independent_final_static_admission_READY.json'
r={'status':'INDEPENDENT_AP14_PERFORMANCE06_ONE_YAMEN_STATIC_NO_BLOCKER_NOT_RUN','key_sha256':sha(key),'fixture_sha256':h['fixture']['sha256'],'whole_pending_and_parentB88B_byte_inverse':True,'expected1225_map_exact_independent65BE':True,'sourceguard1249_fixed05_plus65BEcore_map_five_authority_replacements_and_fresh1':True,'Root25_guard22_authorized2095same15save_exact':True,'observer_draw_clock_DT_getter_functions_inherited_except_labels':True,'DT_single_getter_after_draw_and_natural_receipt':True,'same_owner_and_token_no_freshcredit_checks_retained':True,'scope':{'whole_ms':60000,'public_default_null_requests':1,'input':0,'pictures':0,'geometry':0,'collector':0},'QA_engine_parse_Stage_or_large_source_scan':False,'blocking_findings':[],'Root_next':'May execute exactly once after external full key/fixture hashes; preserve separate functional/performance/real-exit outcomes. Not all-city or clean-exit approval.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
