"""Final one-entry performance key static audit; no parse/engine/collector."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';QA=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def pinned(row):
    b=res(row['path']).read_bytes();assert sha(b)==row['sha256'];return b
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
hp=SF/'performance10_yamen_light04_ROOT18/handoff_ROOT18_READY_NOT_RUN.json';hb=hp.read_bytes()
assert sha(hb)=='a8dbeda581ed2e1e5ddad5a826972d6d2fab2f8b5ec978e0d4fa0620704a45e7';h=json.loads(hb)
key=pinned(h['script']);fixture_raw=pinned(h['fixture']);f=json.loads(fixture_raw)
pending_key=pinned(h['pending_parent']['script']);pending_fixture_raw=pinned(h['pending_parent']['fixture']);pf=json.loads(pending_fixture_raw)
pending_hand=json.loads(pinned(h['pending_parent']['handoff']))
def inverse(raw,hunks):
    text=raw.decode()
    for row in reversed(hunks):assert text.count(row['new'])==1;text=text.replace(row['new'],row['old'],1)
    return text.encode()
assert inverse(key,h['mechanical_key_hunks_only'])==pending_key
parent=pinned(pending_hand['parent_script']);assert inverse(pending_key,pending_hand['hunks'])==parent
guard_raw=pinned(h['actual_Root_deployment_guard']);guard=json.loads(guard_raw);copy_raw=pinned(h['actual_Root_deployment_copy']);cp=json.loads(copy_raw)
assert guard['passed']and guard['unexpected_change_count']==0 and guard['exact_unchanged']==2091 and guard['save_count']==15
assert len(guard['all_changes'])==26 and cp['all26_exact'] and cp['JSON_exact_copy_count']==14 and cp['GD_apply_patch_count']==12
assert f['ready'] is True and f['blockers']==[] and f['whole_ms']==60000 and f['max_pictures']==0 and f['public_requests']==1 and f['firstdraw_target_usec']==10000000
assert len(f['source_sha256'])==1244 and len(pf['source_sha256'])==1242
added=set(f['source_sha256'])-set(pf['source_sha256']);assert added=={h['actual_Root_deployment_guard']['path'],h['actual_Root_deployment_copy']['path']}
assert all(f['source_sha256'][p]==v for p,v in pf['source_sha256'].items())
for row in [h['actual_Root_deployment_guard'],h['actual_Root_deployment_copy']]:assert f['source_sha256'][row['path']]==row['sha256']
owner=json.loads(pinned(f['authority']['independent_owner']));yamen=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
assert len(f['expected_city_source_sha256'])==1221 and same(f['expected_city_source_sha256'],yamen['source_sha256']) and same(f['expected_city_source_sha256'],pf['expected_city_source_sha256'])
assert all(f['source_sha256'][p]==v for p,v in yamen['source_sha256'].items())
back=copy.deepcopy(f)
back['status']=pf['status'];back['ready']=pf['ready'];back['blockers']=pf['blockers'];back['pending_authority_not_in_source_guard_until_real_freeze']=pf['pending_authority_not_in_source_guard_until_real_freeze']
for p in added:del back['source_sha256'][p]
back['authority']['actual_Root_deployment_guard']=pf['authority']['actual_Root_deployment_guard'];del back['authority']['actual_Root_deployment_copy']
assert same(back,pf)and (json.dumps(back,indent=2)+'\n').encode()==pending_fixture_raw
text=key.decode()
def function(raw,name):
    start=raw.index('func '+name+'(');end=raw.find('\nfunc ',start+1);return raw[start:end if end>=0 else len(raw)]
for name in ['clock_fact','observe_readonly','post_draw_readonly']:
    before=function(parent.decode(),name).replace('PERF03_','PERF04_');assert before==function(text,name)
assert text.count('district.call("loading_timing_state")')==1 and text.count('call("go_field_smart",ID,null)')==1
assert text.index('var owner_ok: bool=natural_receipt_only()')<text.index('var timing_ok: bool=district_timing_once_after_frozen_draw() if owner_ok else false')
assert 'WHOLE_MS=60000'in text and 'district_timing_reads==0'in text and 'metrics.get("fresh_source_validation_credit")==false'in text
for forbidden in ['.resident_receipt(','.resident_matches(','.source_paths(','.validation_begin(','.validation_finish(','.resolve(','.compile(','.get_image(','.capture(']:assert forbidden not in text
assert 'players_before=saves()'in text and 'finish('in text
for row in h['diffs'].values():pinned(row)
out=QA/'performance10_light04_ROOT18_independent_static_admission_READY.json'
r={'status':'INDEPENDENT_ONE_DEFAULT_YAMEN_PERFORMANCE04_STATIC_NO_BLOCKER_NOT_RUN','key_sha256':sha(key),'fixture_sha256':sha(fixture_raw),'whole_pending_key_inverse':True,'whole_2EDD_parent_key_inverse':True,'whole_pending_fixture_serialized_inverse':True,'independent_Yamen_source_count':1221,'protected_source_count':1244,'only_two_real_deployment_guard_copy_leaves_added':True,'Root18_guard_passed_26_authorized_2091_same_15save':True,'DT_getter_once_after_frozen_draw_and_natural_owner':True,'same_Field_session_Scene_layout_positive_token_no_freshcredit_checks':True,'perframe_clock_observer_and_postdraw_functions_byte_inherited_except_label':True,'scope':{'whole_ms':60000,'public_null_requests':1,'pictures':0,'input':0,'geometry':0,'collector':0},'review_engine_parse_stage_or_source_guard_recrawl':False,'blocking_findings':[],'limitations':['Root alone may execute exactly once after full key SHA lock. No performance/functional/clean-exit pass is asserted.','Functional completion and first-under10 metric remain separate; slow/failed/crashed result must be preserved.']}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
