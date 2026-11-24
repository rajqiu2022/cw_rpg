"""Explicit receipt-derived after pins. Stdout only; no engine or production writes."""
from pathlib import Path
import hashlib,json
ROOT=Path('F:/Code/RPG_GAME');QA=ROOT/'game/build/world_cities_20261031d_qa01'
def canon(s):
    s=s.replace('\\','/')
    if s.startswith('res://'):return ROOT/'game'/s[6:]
    p=Path(s)
    return p if p.is_absolute() else ROOT/p
def rel(s):return canon(s).relative_to(ROOT).as_posix()
def fact(s,expected=None):
    p=canon(s);data=p.read_bytes();sha=hashlib.sha256(data).hexdigest()
    if expected is not None:assert sha==expected,(s,sha,expected)
    return {'sha256':sha,'bytes':len(data)}
def read(s,sha):fact(s,sha);return json.loads(canon(s).read_text(encoding='utf-8-sig'))
baseline=read('game/build/world_cities_20261031d_qa01/baseline_NOW_ACTUAL.json','4df3ece41c552cb279866283a39bf8c020e035d749b8f6018e9991533570b4ed')
system_path='game/build/environment_residual_20261031d_system01/replacement_receipt_READY.json'
jx_path='game/build/city_neighborhoods_20261031d/jx_manifest_READY02.json'
jx03_path='game/build/city_neighborhoods_20261031d/jx_manifest_READY03.json'
ly_path='game/build/city_neighborhoods_20261031d/closure_READY/receipt_READY.json'
ly02_path='game/build/city_neighborhoods_20261031d/closure_READY02/receipt_READY.json'
receipt_pins={system_path:'c2df2556e8c2b292bdd07d792bd7bd2551e84d53986d41133e596fb61ccf2076',jx_path:'40dc8fddfdfc8ccbf2d25e8c20d9b239417f3bc56c10b57f4dd930cc432dd06e',jx03_path:'cfbf90c81d4e6855d13af8959a25740cb5fe0b690c70de9c3c8551fb85a8ce2b',ly_path:'49b038c2045901367bba63a0869d7ff6f94f2f0c8d7829f2ee551836f5c7603c',ly02_path:'e487b20d07d9cd09362bffa602f919b9bc61f0cf5a8c5c7aa75ec1738eec7115'}
receipts={p:read(p,s) for p,s in receipt_pins.items()}
out={'schema_version':1,'status':'ROOT_MUST_REVIEW_EXPLICIT_FINAL_SHA_NO_AUTO_CURRENT_ACCEPT','baseline_sha256':'4df3ece41c552cb279866283a39bf8c020e035d749b8f6018e9991533570b4ed','baseline_source_count':2317,'save_count':171,'expected_absent_count':9,'allowed_old_targets':{},'new_runtime_pins':{},'evidence_pins':{},'native_manifest':'game/build/three_towns_world_20261029j_system01/native_sources.json','native_count':226,'successful_World_H_actual':{'pid':136304,'checks':29,'errors':0,'inputs':0,'hero_RGB_matching':[2432,2458],'old_gray_pixels_filled':27000},'retained_failures':['first X unqualified rect_polygon candidate unexecuted','first LY Xuantong approach omission despite publisher165 success','LY residual02 typed-array scope FAIL','initial JX finite audit4 conflicts before data03'],'engine_runs':0,'save_content_reads':0,'successful_old_matrices_not_repeated':True}
def add_old(target,sha,size,evidence):
    path=rel(target);absolute=canon(target).as_posix();prior=baseline['facts'][absolute]
    assert prior['exists']
    now=fact(target,sha);assert now['bytes']==size
    out['allowed_old_targets'][path]={'before_sha256':prior['sha256'],'before_bytes':prior['bytes'],'after_sha256':sha,'after_bytes':size,'evidence_chain':evidence}
def evidence(path,sha=None):out['evidence_pins'][rel(path)]=fact(path,sha)
def new(path,sha):out['new_runtime_pins'][rel(path)]=fact(path,sha)
for p,s in receipt_pins.items():evidence(p,s)
for row in receipts[jx_path]['targets']:
    prior=baseline['facts'][canon(row['target']).as_posix()]
    assert prior['sha256']==row['old_sha256'] and prior['bytes']==row['before_bytes']
    evidence(row['candidate'],row['new_sha256']);evidence(row['before'],row['old_sha256'])
    add_old(row['target'],row['new_sha256'],row['bytes'],[{'receipt':jx_path,'old_sha256':row['old_sha256'],'new_sha256':row['new_sha256'],'before':row['before'],'candidate':row['candidate']}])
first={r['target']:r for r in receipts[ly_path]['targets']}
for row in receipts[ly02_path]['targets']:
    initial=first[row['target']];prior=baseline['facts'][canon(row['target']).as_posix()]
    assert prior['sha256']==initial['old_sha256'] and prior['bytes']==initial['before_bytes']
    assert initial['new_sha256']==row['old_sha256']
    chain=[]
    for r,p in [(initial,ly_path),(row,ly02_path)]:
        evidence(r['candidate'],r['new_sha256']);evidence(r['before'],r['old_sha256'])
        chain.append({'receipt':p,'old_sha256':r['old_sha256'],'new_sha256':r['new_sha256'],'before':r['before'],'candidate':r['candidate']})
    add_old(row['target'],row['new_sha256'],row['bytes'],chain)
system=receipts[system_path]
for key in ['world_watcher','huashan_scene']:
    r=system[key];prior=baseline['facts'][canon(r['path']).as_posix()]
    assert prior['sha256']==r['before_sha256']
    after=fact(r['path'],r['after_sha256'])
    add_old(r['path'],r['after_sha256'],after['bytes'],[{'receipt':system_path,'old_sha256':r['before_sha256'],'new_sha256':r['after_sha256'],'inverse_proof':'game/build/environment_residual_20261031d_system01/scene_and_world_inverse_READONLY.py'}])
for p,s in system['new_native_source_keys'].items():new(p,s)
# These three writes were Root's explicitly reported integration heads.
for p,s in {
'game/build/three_towns_world_20261029j_system01/native_sources.json':'f2b49c6726887b70ed954e482f5b934c36b56835b613a21bd695a5d07325263f',
'game/build/three_towns_world_20261029j_system01/town_registry.gd':'7ff4ce7c46d684aa5598d9f5a0b629fb8e6610c10b58fffc90e798eae4aafbc5',
'prompts/tasks.yaml':'426942f6fefd2727e9618edce3fe59a434fbddb92c9f2fd5cf468c0311803de3'}.items():
    f=fact(p,s);add_old(p,s,f['bytes'],[{'receipt':'ROOT_EXPLICIT_INTEGRATION_HEAD_OR_SINGLE_BUILTIN_TASK_APPEND','new_sha256':s}])
assert len(out['allowed_old_targets'])==18
jx03=receipts[jx03_path]
new(jx03['runtime_helper']['path'],jx03['runtime_helper']['sha256']);new(jx03['data']['path'],jx03['data']['sha256'])
for r in [receipts[ly_path],receipts[ly02_path]]:
    for p,v in r['new_runtime_sources'].items():new(p,v['sha256'])
    snap=r['required_router_snapshot'];new(snap['target'],snap['sha256'])
for p in [
'game/build/environment_residual_20261031d_system01/scene_and_world_inverse_READONLY.py',
'game/build/city_neighborhoods_20261031d/jx_inverse_proof_READY02.json',
'game/build/city_neighborhoods_20261031d/audit_final_scope_READONLY.json',
'game/build/city_neighborhoods_20261031d/audit_final_scope03_READONLY.json',
'game/build/city_neighborhoods_20261031d/ly_cases_READONLY.json',
'game/build/city_neighborhoods_20261031d/HANDOFF_FINAL03.md',
'game/build/world_cities_20261031d_qa01/visual_actual/136304/result.json',
'game/build/world_cities_20261031d_qa01/cities_ROOT_ONLY.gd',
'game/build/world_cities_20261031d_qa01/cities_inputs_READY.json',
'game/build/world_cities_20261031d_qa01/visual_residual_ROOT_ONLY.gd',
'game/build/world_cities_20261031d_qa01/visual_residual_inputs_READY.json',
'game/build/world_cities_20261031d_qa01/final_guard_ROOT_ONLY.ps1',
'assets/raw/environment_residual_20261031d/huashan_valley_backdrop_v1.meta.json',
'assets/raw/environment_residual_20261031d/huashan_valley_backdrop_v1.png',
'game/build/city_neighborhoods_20261031d/luoyang_output/134988/report.json',
'game/build/city_neighborhoods_20261031d/luoyang_output/117136/report.json',
'game/build/world_cities_20261031d_root01/visual01_ACTUAL_process_receipt.json',
'game/build/world_cities_20261031d_root01/civic_publish01_ACTUAL_process_receipt.json',
'game/build/world_cities_20261031d_root01/civic_residual02_ACTUAL_process_receipt.json',
'game/build/world_cities_20261031d_root01/civic_residual03_ACTUAL_process_receipt.json']:
    evidence(p)
print(json.dumps(out,ensure_ascii=False,indent=2))
