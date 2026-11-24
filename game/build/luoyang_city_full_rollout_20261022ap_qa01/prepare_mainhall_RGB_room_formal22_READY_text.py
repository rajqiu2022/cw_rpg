"""Mechanical Root-authorized remaining-only text freeze. No engine/Stage."""
from pathlib import Path
import json,hashlib,copy,difflib
GAME=Path('F:/Code/RPG_GAME/game');Q=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01'
OLD=Q/'mainhall_RGB_room_residual_NOTREADY';NEW=Q/'mainhall_RGB_room_formal22_READY'
assert not NEW.exists()
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return GAME/p[6:]
def rp(p):return 'res://'+p.relative_to(GAME).as_posix()
def js(x):return (json.dumps(x,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
def emit(p,b):
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return {'path':rp(p),'sha256':sha(b),'bytes':len(b)}
oldkey=(OLD/'test_NOTREADY.gd').read_bytes();oldfix=(OLD/'fixture_NOTREADY.json').read_bytes()
assert sha(oldkey)=='f8b682946d4f0ea29aa72b2396534895588462c0cca1fdf409f4874f735ae686'
assert sha(oldfix)=='4046874e5849f23b9cbbe8d4e66ac4d9261036e37e468bbad2b8ccb11f2e0896'
root='res://build/luoyang_hall_portal_fix_20261024a_root01/rgb01/'
docpins={
 root+'deployment_plan.json':'6f225c814b8d76572aedbe667e074e4ade337143b8ff62c0d5c0706650c76307',
 root+'deployment_actual.json':'849675514e8e1801eda838cd6b7983ea7aa9a9aea07356d8c3826d1b8b82cb46',
 root+'current_before_room.json':'a8f16fd00e91054bcf941804b70e9e6f33d1cf05d8785af472b38f399fb53f84'
}
for p,h in docpins.items():assert sha(res(p).read_bytes())==h,p
actual=json.loads(res(root+'deployment_actual.json').read_bytes());assert len(actual['targets'])==22
for row in actual['targets']:assert sha(res(row['target']).read_bytes())==row['sha256']
guard=json.loads(res(root+'current_before_room.json').read_bytes());assert guard['passed'] and len(guard['save_paths'])==15
owner='res://build/luoyang_hall_portal_fix_20261024a_source01/yamen_runtime_expected_READONLY.json'
owner_sha='f71f35915a27fc952faa2d3bbb51c6980d199ba16b3a67e86894db989aa5c912'
assert sha(res(owner).read_bytes())==owner_sha
native=json.loads(res(owner).read_bytes())
f=json.loads(oldfix);f.update(ready=True,status='FORMAL_RGB22_FROZEN_NEW_ROOM_ONLY_RESIDUAL_READY_NOT_RUN',blockers=[],owner={'path':owner,'sha256':owner_sha,'scope':'Only immutable hall Scene/layout/author identities inherited; not prior G runtime hash/current Yamen count or new complete owner'})
assert f['hall_scene_path']==native['hall_scene_path'] and f['hall_layout_path']==native['hall_layout_path'] and f['hall_author_sha256']==native['fixed_small_pins'][f['hall_author_path']]
f['source_sha256']={
 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd':'7874c128dcfaf67c151498e4aaaa9151037150d0cd4c2b1d120223617db728ec',
 'res://scripts/field/field_walkable_controller.gd':'93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0',
 'res://build/luoyang_hall_portal_fix_20261024a_system01/rgb8_successor01/mainhall_fixed_columns_RGB8_CANDIDATE.gd':'7d678b06099335c5df142632cad6f9e98f1ea7b574c7cb08b13d391dd770711b',
 owner:owner_sha,
 'res://build/luoyang_city_full_rollout_20261022ap_qa01/mainhall_two_columns_formal27_READY/test_READY.gd':'b52eacd2a68357b438be14967382d147eb5bf7837631438674ae0807c9e81831',
 'res://build/luoyang_city_full_rollout_20261022ap_qa01/hall_roundtrip_ROOT37_READY/test_hall_roundtrip_ROOT37_READY.gd':'7bff48b256b092179ac3a1046f3698f9c24f5813e18f268e9ae3dd0e6bf65976',
 'res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd':'a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895',
 'res://tests/helpers/v15_input_driver.gd':'a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7',
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd':'1dbd8c1357608a96c04a602f2c0a3c5f4478928bbc969c43963c6f430ef2c2b7',
 'res://scripts/world/v14_modular_overlap.gd':'92f80ed076d90be292c848cb9743130b465b71e06250e8867d24e01f02090dab',
 'res://scripts/field/player.gd':'9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419',
 f['hall_author_path']:f['hall_author_sha256'],**docpins
}
assert len(f['source_sha256'])==15
for p,h in f['source_sha256'].items():assert sha(res(p).read_bytes())==h,p
f['formal_RGB22_stage']={'path':'res://build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_RGBhelper_exact22_stage01/receipt.json','sha256':'8032000e55acbee409f67461eead2f73f07f982d6faa665c5dd5fe2a93928d2c','large_Stage_receipt_not_rehashed_in_runtime':True}
fixture_bytes=js(f);fixture_path=NEW/'fixture_READY.json'
changes=[(b'const ROOM_READY=false',b'const ROOM_READY=true'),(rp(OLD/'fixture_NOTREADY.json').encode(),rp(fixture_path).encode()),(b'PENDING_RGB22_FORMAL_ROOT_FREEZE',sha(fixture_bytes).encode()),(b'/mainhall_RGB_room_residual_NOTREADY/output_NOTREADY/',b'/mainhall_RGB_room_formal22_READY/output_READY/')]
key=oldkey
for a,b in changes:assert key.count(a)==1;key=key.replace(a,b)
back=key
for a,b in reversed(changes):assert back.count(b)==1;back=back.replace(b,a)
assert back==oldkey
inverse=copy.deepcopy(f)
for k in ['ready','status','blockers','owner','source_sha256']:inverse[k]=json.loads(oldfix)[k]
del inverse['formal_RGB22_stage'];assert inverse==json.loads(oldfix)
files=[emit(fixture_path,fixture_bytes),emit(NEW/'test_READY.gd',key)]
for name,a,b in [('key',oldkey,key),('fixture',oldfix,fixture_bytes)]:
    d=''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=name+'_NOTREADY',tofile=name+'_READY'))
    files.append(emit(NEW/(name+'_complete.diff'),d.encode()))
handoff={'status':'FORMAL_RGB22_NEW_ROOM_ONLY_RESIDUAL_READY_NOT_RUN','files':files,'key_whole_byte_inverse':'exact4 readiness/path/hash/output literals including original EOF; all functions unchanged','fixture_inverse':'Only ready/status/blockers/owner/15smallsource guard plus declared Stage pointer. All paths/routes/20s60s/onepose/onePNG/format observations unchanged.','formal22_current_candidate_sha_equal':True,'prior_failed_result_preserved':'c53620c4877e1439fb94eb32cb938891a2535dbcd4340811d24777b9e223e949','no_completed_prefix_repeated':True,'budget_whole_ms':60000,'budget_room_entry_ms':20000,'Yamen_requests':0,'Space':0,'collector':0,'new_game_or_save_calls':0,'engine_by_QA':0,'command':f"& 'F:/Code/RPG_GAME/game/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1' -ScriptResPath '{rp(NEW/'test_READY.gd')}' -ScriptSHA '{sha(key)}' -LogStem '{NEW.as_posix()}/room_once'"}
meta=emit(NEW/'handoff_READY_NOT_RUN.json',js(handoff))
print(json.dumps({'key':files[1],'fixture':files[0],'handoff':meta,'small_source_count':15}))
