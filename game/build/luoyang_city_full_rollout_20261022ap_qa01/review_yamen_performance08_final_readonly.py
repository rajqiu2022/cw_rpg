"""Static final08 provenance/body audit only, no Godot parse or runtime call."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
SF=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=QA/'yamen_performance08_ROOT32_FINAL_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(s):return GAME/s.removeprefix('res://')
hp=D/'handoff_ROOT32_READY_NOT_RUN.json';h=rd(hp)
k=res(h['key']['path']);fp=res(h['fixture']['path'])
assert sha(k)==h['key']['sha256']=='01e9e50b94aa4cf9b97d4f224938c5e1a98ad8c4328ea7128d9ccd4174d445b3'
assert sha(fp)==h['fixture']['sha256']=='1c113244799813688f0c95fa3775e8867486b92baebcf8134d4a2313646667f0'
oldk=res(h['parent07']['path']);assert sha(oldk)=='85e3d80b8c97d156a0db71764cb8010a85b0149b6949b0e8f6c3d9065caf3f7e'
v=k.read_bytes().decode().replace('PERF08','PERF07')
for x in reversed(h['only_hunks_before_PERF07_to08_label_change']):
    assert v.count(x['new'])==1;v=v.replace(x['new'],x['old'],1)
assert v.encode()==oldk.read_bytes()
f=rd(fp);old=rd(QA/'yamen_performance07_ROOT30_READY/yamen_performance07_fixture_ROOT30_READY.json')
owner=rd(res(h['owner_expected1239']['path']));assert sha(res(h['owner_expected1239']['path']))=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'
y=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
assert f['expected_city_source_sha256']==y['source_sha256']==y['receipt_source_sha256']and len(y['source_sha256'])==1239
assert f['owner_path']==old['owner_path']==y['owner_path']=='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
skip={'status','source_sha256','expected_city_source_sha256','authority','expected_source_count_recipe','guard_derivation'}
assert {a:b for a,b in f.items()if a not in skip}=={a:b for a,b in old.items()if a not in skip}
t=dict(old['source_sha256'])
for p,s in owner['core_source_sha256'].items():
    if p in t:t[p]=s
t.update(y['source_sha256'])
for a,b in h['authority_replacements']:
    assert t.pop(a['path'])==a['sha256']and b['path']not in t;t[b['path']]=b['sha256']
oldancestor='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance28_yamen_light06_ROOT26/test_yamen_performance06_ROOT26_READY.gd'
assert t.pop(oldancestor)=='6b5989d7401425ad138a8bdbc9b0fd7d8ce7b6e07b225a2566cae3d32ec053d5'
t[h['parent07']['path']]=h['parent07']['sha256']
assert t==f['source_sha256']and len(t)==1263
for label,expected in [('Root31_guard','7df6333fbc54d5d4f7bbcc276f9a770554e34996a188567cfac51f73b279538b'),('Root31_copy','859daf7aaa5100981bd95271befff02929cad5e6b8e7498e75b8cfee50bf2086'),('Root32_before','b1b1e9b1d2ef32bba56f80e616014da0a13e28f3602bcd8042406487dc1ed878')]:
    assert h[label]['sha256']==sha(res(h[label]['path']))==expected
assert sha(QA/'yamen_performance07_ROOT30_READY/output/120460_2690/result.json')=='09c768372a8afa6f0efcd86a8c75f7139b3f3b9b5a84c5946008b27d3547e87e'
assert f['whole_ms']==60000 and f['max_pictures']==0 and f['public_requests']==1 and len(f['required_DT_projection_children'])==6
b=k.read_bytes();assert b.count(b'district.call("loading_timing_state")')==1 and b.count(b'go_field_smart')==1
out=D/'independent_final_body_fixture_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT32_FINAL08_STATIC_NO_BLOCKER_FOR_ROOT_SINGLE_ACTUAL_NOT_EXECUTED_BY_QA','key':h['key'],'fixture':h['fixture'],'handoff_sha256':sha(hp),'whole_byte_reverse_to_immutable07':True,'expected_Yamen1239_fixed_owner5448':True,'source_guard1263_independent_recipe_not_currentfill':True,'runtime_owner_path_C_unchanged':True,'same_six_DT_subspans_drawfirst_naturalproof_getter1_60s_noINPUT_picture_geometry_collector':True,'actual24_deployed_before_freeze_Root31guard_copy_and32fresh_pinned':True,'old07FAIL_key_report_retained':True,'preparation_history':['Initial preparer expected nonexistent C-owner scene_path field; zero outputs, retained','NEWretry1 froze unused owner_path as source-table location; not offered for execution, retained','NEWretry2 preserves owner_path runtime C and inherited native identities by fixed source-map declarations; only FINAL_READY is admitted'],'engine_parse_Stage_collector_formal_calls':0},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out)}))
