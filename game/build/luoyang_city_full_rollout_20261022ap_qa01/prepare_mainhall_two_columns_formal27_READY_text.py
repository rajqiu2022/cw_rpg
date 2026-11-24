"""Root-authorized NEW text freeze only. No engine, Scene decode or collector."""
from pathlib import Path
import hashlib,json,copy,difflib
GAME=Path('F:/Code/RPG_GAME/game');Q=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01'
OLD=Q/'mainhall_two_columns_runtime_NOTREADY';NEW=Q/'mainhall_two_columns_formal27_READY'
assert not NEW.exists()
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):return GAME/p[6:]
def js(x):return (json.dumps(x,ensure_ascii=False,indent=2)+'\n').encode('utf8')
def resource(p):return 'res://'+p.relative_to(GAME).as_posix()
def emit(p,b):
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
    return {'path':resource(p),'sha256':sha(b),'bytes':len(b)}
oldkey=(OLD/'test_NOTREADY.gd').read_bytes();oldfix=(OLD/'fixture_NOTREADY.json').read_bytes()
assert sha(oldkey)=='47c658986cd329538034490b49a35cf62d4e29f5b767850a3701392e19d862b6'
assert sha(oldfix)=='b297a313fad2fb198031194d6f550fd2bfade77ade487b1ba24df8b0e5ebd62f'
owner_path='res://build/luoyang_hall_portal_fix_20261024a_source01/yamen_runtime_expected_READONLY.json'
owner_sha='f71f35915a27fc952faa2d3bbb51c6980d199ba16b3a67e86894db989aa5c912'
assert sha(path(owner_path).read_bytes())==owner_sha
owner=json.loads(path(owner_path).read_bytes());expected=owner['complete_expected_map']
assert owner['expected_count']==1262 and owner['independent_derived_dictionary_matches_Stage_expected_wholetyped']
assert sha(path(expected['path']).read_bytes())==expected['sha256']
expected_map=json.loads(path(expected['path']).read_bytes())['source_sha256'];assert len(expected_map)==1262
f=json.loads(oldfix);f.update(ready=True,status='ROOT_FORMAL27_FROZEN_ONE_YAMEN_REALSPACE_HALL_COLUMNS_READY_NOT_RUN',blockers=[],owner={'path':owner_path,'sha256':owner_sha},expected_city_source_count=1262,hall_scene_path=owner['hall_scene_path'],hall_layout_path=owner['hall_layout_path'],formal_portal_shader_path='res://build/luoyang_hall_portal_fix_20261024a_system01/portal_interaction_outline_CANDIDATE.gdshader')
f['expected_city_map']=expected;f['full_natural_city_dictionary_comparison_once_after_draw']=True
# Native .res/storage identities are source-fixed paths/session proof, NOT
# additional QA large-file hashes. Shader/portal remain separate from C keys.
f['source_sha256']={p:h for p,h in owner['fixed_small_pins'].items() if not p.endswith(('.res','.bin'))}
extra={
 owner_path:owner_sha,expected['path']:expected['sha256'],
 'res://build/luoyang_hall_portal_fix_20261024a_root01/deployment_actual.json':'3021f982d202c259c56e4a6596ab32853522c850ba6f2ba4b4db1d80284814ed',
 'res://build/luoyang_hall_portal_fix_20261024a_root01/after.json':'1fa50fcc9a4746827c2e21116e045de1e9d91e466cbf96aa9dcb8dcfafd855d3',
 'res://build/luoyang_city_full_rollout_20261022ap_qa01/hall_roundtrip_ROOT37_READY/test_hall_roundtrip_ROOT37_READY.gd':'7bff48b256b092179ac3a1046f3698f9c24f5813e18f268e9ae3dd0e6bf65976',
 'res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd':'a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895',
 'res://tests/helpers/v15_input_driver.gd':'a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7',
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd':'1dbd8c1357608a96c04a602f2c0a3c5f4478928bbc969c43963c6f430ef2c2b7',
 'res://scripts/world/v14_modular_overlap.gd':'92f80ed076d90be292c848cb9743130b465b71e06250e8867d24e01f02090dab',
 'res://scripts/field/player.gd':'9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419',
 'res://scenes/exit_zone.tscn':'6f2c45dd86aaa8eb4d8f2250473eff5425744da2236a943d4dc4a6d42ec921f9',
 'res://scripts/field/exit_zone.gd':'bf0ee27eacdb592dc977e378e9e4b7fbe1c6e695f9101cd9415a303747e22bc5',
 'res://scripts/field/luoyang_v3_exit_zone.gd':'a18b3fd92cc0a186912d7fbfa2d6f73bc212b62cc24cc023e0b2f27845f65061',
 'res://art/ui/field_hud/portal_arrow_amber_v2.png':'1c9ec8e624d5b7e93af2007c44962d780b47c02c9253bcb8c57e0dc628899e01'
}
f['source_sha256'].update(extra)
assert len(f['source_sha256'])==20
for p,h in f['source_sha256'].items():assert sha(path(p).read_bytes())==h,('SMALL_FROZEN_SOURCE_CHANGED',p)
deployment=json.loads(path('res://build/luoyang_hall_portal_fix_20261024a_root01/deployment_actual.json').read_bytes())
assert len(deployment['targets'])==27
for row in deployment['targets']:assert sha(path(row['target']).read_bytes())==row['sha256']
guard=json.loads(path('res://build/luoyang_hall_portal_fix_20261024a_root01/after.json').read_bytes())
assert guard['passed'] and len(guard['save_paths'])==15
newfix=js(f);fixpath=NEW/'fixture_READY.json'
changes=[
 (b'const DELTA_READY=false',b'const DELTA_READY=true'),
 (resource(OLD/'fixture_NOTREADY.json').encode(),resource(fixpath).encode()),
 (b'PENDING_FORMAL27_AND_ROOT_FREEZE',sha(newfix).encode()),
 (b'/mainhall_two_columns_runtime_NOTREADY/output_NOTREADY/',b'/mainhall_two_columns_formal27_READY/output_READY/'),
 (b'var pillar_positive_observations:=0',b'var pillar_positive_observations:=0\nvar expected_city_sources: Dictionary={}'),
 (b'\thall_author=author\n\treturn true',b'\thall_author=author\n\tvar source_map: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture.expected_city_map.path))\n\tif not check(source_map is Dictionary and source_map.get("source_sha256",{}).size()==1262,"Fixed independent Source Yamen1262 map, never observed backfill"): return false\n\texpected_city_sources=source_map.source_sha256\n\treturn true'),
 (b'natural.get("sources",{}).size()==int(fixture.expected_city_source_count),"Natural finalized same Yamen owner/count only; no full payload collector"',b'natural.get("sources",{}).size()==int(fixture.expected_city_source_count) and natural.get("sources",{})==expected_city_sources,"Natural finalized same Yamen1262 exact independent full dictionary once after draw; no collector/current fill"')
]
newkey=oldkey
for old,new in changes:assert newkey.count(old)==1,(old,newkey.count(old));newkey=newkey.replace(old,new)
back=newkey
for old,new in reversed(changes):assert back.count(new)==1;back=back.replace(new,old)
assert back==oldkey
inverse=copy.deepcopy(f)
for k in ['ready','status','blockers','owner','source_sha256','expected_city_source_count','hall_scene_path','hall_layout_path','formal_portal_shader_path']:inverse[k]=json.loads(oldfix)[k]
del inverse['expected_city_map'];del inverse['full_natural_city_dictionary_comparison_once_after_draw']
assert inverse==json.loads(oldfix)
files=[emit(fixpath,newfix),emit(NEW/'test_READY.gd',newkey)]
for name,before,after in [('key',oldkey,newkey),('fixture',oldfix,newfix)]:
    d=''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name+'_NOTREADY',tofile=name+'_READY'))
    files.append(emit(NEW/(name+'_complete.diff'),d.encode()))
handoff={'status':'FORMAL27_ONE_REAL_DOORWAY_AND_FINITE_COLUMN_FIELD_READY_NOT_RUN','files':files,'key_inverse':'4 readiness/path/hash/output literals plus3 precisely listed Root-approved natural1262 dictionary-comparison hunks; fullbytes including EOF reverse to47C658','fixture_inverse':'Exactly listed filled pending fields plus expected_city_map/toggle; all source coordinates/routes/60s20s budgets/no-fade/alpha policy unchanged','production_current27_match':True,'Root_formal_actual_sha256':extra['res://build/luoyang_hall_portal_fix_20261024a_root01/deployment_actual.json'],'Root_formal_guard_sha256':extra['res://build/luoyang_hall_portal_fix_20261024a_root01/after.json'],'Root_guard_checked':2120,'small_source_guard_count':20,'expected_natural_C_sources':1262,'collector':0,'engine_runs_by_QA':0,'single_root_run_command':f"& 'F:/Code/RPG_GAME/game/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1' -ScriptResPath '{resource(NEW/'test_READY.gd')}' -ScriptSHA '{sha(newkey)}' -LogStem '{NEW.as_posix()}/field_once'",'scope':'one explicit Yamen doornear/public + realSpacehall, one Root-authorized QA-only actor pose450525, two short INPUT legs/two static base negatives/one original-cameraPNG; no return/defaultperformance or oldroutes; no ghost positive count guessed'}
meta=emit(NEW/'handoff_READY_NOT_RUN.json',js(handoff))
print(json.dumps({'handoff':meta,'fixture':files[0],'key':files[1],'runtime_expectation_owner_sha256':owner_sha}))
