"""Write NEW fixture/proof data and emit a NEW-code apply_patch; no engine."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def resource(p):return 'res://'+p.relative_to(ROOT).as_posix()
def read(p,s):
    b=p.read_bytes();assert sha(b)==s;return json.loads(b)
template=ROOT/'tests/test_luoyang_ap_artisan_A2_finite_Field_TEMPLATE_NOTREADY_20261023.gd'
original=template.read_bytes();assert sha(original)=='8ab1abb147d6693e02f41c0d9da5c98408c0ffca0cc51bb94340e2ad050f324b'
ft=QA/'artisan_A2_finite_Field_fixture_TEMPLATE_NOTREADY.json'
fixture=read(ft,'7964648a1045e043e5b1d9203a3cede3dffeca7fd83a2205caf0a7b6c14f57a3')
ownerpath=SF/'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json'
ownerhash='12924be9ea2c6a081b4865354d40075caa10e3804ad6c942e972f0270bd5219a'
owner=read(ownerpath,ownerhash)
guardpath=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration16/final_guard.json'
guardhash='0dbf473bb55c75612b9f903dc37da2a8203f2080285e335cedade906cf8245f9'
guard=read(guardpath,guardhash)
assert guard['passed'] is True and guard['checked']==2117 and guard['authorized_change_count']==28 and guard['exact_unchanged']==2089
assert guard['unexpected_change_count']==0 and guard['save_change_count']==0 and guard['save_count']==15
stagepath=SF/'outputs/root_artisan_A2_source_stage01/receipt.json'
stagehash='4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c'
stage=read(stagepath,stagehash)
for row in stage['targets']:
    assert sha((ROOT/row['target'][6:]).read_bytes())==row['candidate_sha256']
assert owner['actual_stage_receipt']=={'path':resource(stagepath),'sha256':stagehash}
quarter=next(r for r in owner['scenes'] if r['id']=='luoyang_artisan_residential_20261022ap')
assert len(quarter['receipt_source_sha256'])==270 and len(quarter['source_sha256'])==272
assert quarter['scene_path']==fixture['scene_path'] and quarter['layout_path']==fixture['layout_path']
fixture['status']='READY_FIXED_ROOT16_DEPLOYMENT_AND_INDEPENDENT_OWNER1292_FINITE_FIELD_ONLY'
fixture['ready']=True
fixture['expected_family_receipt_source_sha256']=copy.deepcopy(quarter['receipt_source_sha256'])
fixture['pending_owner_rule']='Frozen from independent Source owner1292 receipt270, not collector272; Root16 actual4688 deployment guarded0DBF. No current-disk or live collector fill.'
sources=copy.deepcopy(fixture['source_sha256'])
for src in [owner['core_source_sha256'],quarter['source_sha256'],{resource(ownerpath):ownerhash,resource(guardpath):guardhash,resource(stagepath):stagehash}]:
    for p,s in src.items():assert p not in sources or sources[p]==s;sources[p]=s
fixture['source_sha256']=sources
fixture['final_frozen_authorities']={'independent_owner':{'path':resource(ownerpath),'sha256':ownerhash},'actual_Root_deployment_guard':{'path':resource(guardpath),'sha256':guardhash},'actual_source_stage':{'path':resource(stagepath),'sha256':stagehash},'Family_receipt_count':270,'Family_collector_count_not_receipt':272,'core_count':45,'current_target_SHA_checks_not_expected_source_derivation':28,'source_expected_derivation':'Fixed independent owner1292 core +Quarter collector + original8QA leaves; no live collector/currentcrawl fill.','no_actual_Field_or_loading_PASS_preclaimed':True}
fp=QA/'artisan_A2_finite_Field_fixture_ROOT16_READY.json'
data=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode();assert not fp.exists()
with fp.open('xb') as f:f.write(data)
codepath=ROOT/'tests/test_luoyang_ap_artisan_A2_finite_Field_ROOT16_READY_20261023.gd'
assert not codepath.exists()
text=original.decode();changes=[('const ACTUAL_READY: bool=false','const ACTUAL_READY: bool=true'),('const PLAN="PENDING_FINAL_INDEPENDENT_OWNER_AND_DEPLOYMENT_FIXTURE"','const PLAN="'+resource(fp)+'"'),('const PLAN_SHA=""','const PLAN_SHA="'+sha(data)+'"'),('artisan_A2_finite_Field_TEMPLATE_NOTREADY/%d_%d','artisan_A2_finite_Field_ROOT16_READY/%d_%d')]
for old,new in changes:assert text.count(old)==1;text=text.replace(old,new,1)
back=text
for old,new in reversed(changes):assert back.count(new)==1;back=back.replace(new,old,1)
assert back.encode()==original
keybytes=text.encode();patch='*** Begin Patch\n*** Add File: '+codepath.as_posix()+'\n'+''.join('+'+x for x in text.splitlines(keepends=True))+'*** End Patch\n'
handoff={'status':'ROOT16_FROZEN_FINITE_ARTISAN_FIELD_READY_NOT_EXECUTED','script':{'path':resource(codepath),'sha256':sha(keybytes),'lines':len(text.splitlines()),'external_Root_hash_check_required':True},'fixture':{'path':resource(fp),'sha256':sha(data),'source_guard_count':len(sources),'expected_Family_receipt_count':270,'not_Family_collector272':True},'headers_only_whole_byte_inverse':{'parent':resource(template),'parent_sha256':sha(original),'exact_changes':changes,'full_inverse_exact_bytes':True,'methods_scope_assertions_or_endpoints_changed':False},'budget':{'whole_ms':60000,'max_images':2,'public_default_null_Quarter_requests':1,'test_only_explicit_inspection_starts':7,'no_connected_journey_credit':True},'actual_authorities':fixture['final_frozen_authorities'],'not_run':{'parse':True,'engine':True,'collector':True,'geometry':True},'command_note':'Root ordinary GUI project --script res://tests/test_luoyang_ap_artisan_A2_finite_Field_ROOT16_READY_20261023.gd, no user args; retain Process.WaitForExit console code.'}
hp=QA/'artisan_A2_finite_Field_ROOT16_READY_handoff.json';assert not hp.exists()
with hp.open('x',encoding='utf-8') as f:json.dump(handoff,f,ensure_ascii=False,indent=2);f.write('\n')
print(json.dumps({'patch':patch,'handoff_path':str(hp),'handoff_sha256':sha(hp.read_bytes()),'script_sha256':sha(keybytes),'fixture_sha256':sha(data),'source_guard_count':len(sources)},ensure_ascii=False))
