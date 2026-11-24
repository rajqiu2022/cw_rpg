"""NEW read-only evidence review + NOTREADY text fixture. No Godot/media decode."""
from pathlib import Path
import copy, hashlib, json, re

ROOT=Path(__file__).resolve().parents[2]
Q=Path(__file__).resolve().parent
def local(res):
    assert res.startswith('res://')
    return ROOT/res[6:]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def emit(path,value):
    assert not path.exists(), str(path)
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    return sha(path)
def load(path): return json.loads(path.read_bytes())
def res(path): return 'res://'+path.relative_to(ROOT).as_posix()

parent=Q/'mainhall_RGB_room_formal22_READY'
actual=parent/'output_READY/124716_2789/result.json'
assert sha(actual)=='b0139179e2b95c06d1c9821d0f8f3c6fcc7cf9d8fe60d9d14633ded258ce6930'
data=load(actual)
process=parent/'room_once_process_receipt.json'
assert sha(process)=='0c002d2137b7c3e6cc09b064af625129a976235f232ccafec4af71109bbf3447'
proc=load(process)
stderr=Path(proc['stderr_path']);stdout=Path(proc['stdout_path'])
assert sha(stderr)==proc['stderr_sha256'] and sha(stdout)==proc['stdout_sha256']
log=stderr.read_text(encoding='utf-8')
assert data['complete'] is False and (data['checks'],data['failures'],data['elapsed_ms'])==(48,2,4761)
assert data['source_before']==data['source_after'] and len(data['source_before'])==16
assert data['players_before']==data['players_after'] and len(data['players_before'])==15
assert proc['actual_natural_console_exit_code']==1 and proc['exit_code_from_retained_process_WaitForExit'] is True
kinds=[r['kind'] for r in data['records']]
assert kinds.count('HALL_REAL_INPUT')==1 and kinds.count('ACTUAL_TRUE_COLUMN_BASE_STATIC_NEGATIVE')==2
assert not any('IMAGE' in k for k in kinds)
clock=next(r for r in data['records'] if r['kind']=='HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')
assert clock['draw']['elapsed_usec']==4269214
obs=next(r for r in data['records'] if r['kind']=='CURRENT_FRAME_COLUMN_ALPHA_OBSERVATION')
assert obs['active'] is False and obs['pixels']==0

sys=ROOT/'build/luoyang_hall_portal_fix_20261024a_system01'
proof=sys/'parent_successor02/parent_only_inverse_and_handoff_BUILD.json'
assert sha(proof).startswith('2ff77fcd') # Full current pin is emitted below; supplied prefix checked independently.
pr=load(proof)
helper_old=local(pr['helper']['parent']['path']);helper_new=local(pr['helper']['candidate']['path'])
gbefore=local(pr['G']['parent']['path']);gafter=local(pr['G']['candidate']['path'])
for path,row in [(helper_old,pr['helper']['parent']),(helper_new,pr['helper']['candidate']),(gbefore,pr['G']['parent']),(gafter,pr['G']['candidate'])]:
    assert sha(path)==row['sha256'].lower() and path.stat().st_size==row['bytes']
value=helper_old.read_bytes()
for op in pr['helper']['operations']:
    old,new=op['old'].encode(),op['new'].encode()
    # JSON proof text has logical LF; physical candidate preserves parent's CRLF.
    if b'\r\n' in value: old,new=old.replace(b'\n',b'\r\n'),new.replace(b'\n',b'\r\n')
    assert value.count(old)==1
    value=value.replace(old,new,1)
assert value==helper_new.read_bytes()
old,new=pr['G']['literal_old'].encode(),pr['G']['literal_new'].encode()
assert gbefore.read_bytes().count(old)==2 and gbefore.read_bytes().replace(old,new)==gafter.read_bytes()
native=ROOT/'scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd'
assert 'elif node.get_parent() != shared_parent: return' in native.read_text(encoding='utf-8')
field=ROOT/'scripts/field/field_walkable_controller.gd'
assert sha(field)=='93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0'
fieldtext=field.read_text(encoding='utf-8')
assert 'world_container.scale = Vector2.ONE * _camera_zoom' in fieldtext
assert 'return design_size.x > _viewport_size.x * 1.05 or design_size.y > _viewport_size.y * 1.05' in fieldtext

review={
 'status':'ACTUAL124716_WHOLE_FAIL_PRESERVED_AND_PARENT_ONLY_STATIC_REVIEW_NOT_RUNTIME',
 'actual':{'path':res(actual),'sha256':sha(actual),'checks':48,'failures':2,'elapsed_ms':4761,'complete':False,'room_hidden_operable_draw_usec':4269214,'not_default_world_or_performance_credit':True},
 'process':{'path':res(process),'sha256':sha(process),'natural_console_exit':1,'retained_WaitForExit':True,'stopped':False,'stderr_ERROR_lines':len(re.findall(r'^ERROR:',log,re.M)),'stderr_WARNING_lines':len(re.findall(r'^WARNING:',log,re.M)),'stderr_SCRIPT_ERROR_lines':len(re.findall(r'^SCRIPT ERROR:',log,re.M)),'QA_FAIL_lines':len(re.findall(r'^CITY_LIFE_QA_FAIL',log,re.M)),'nonclean':True},
 'source_save':{'source_count':16,'source_first_final_same':True,'save15_same':True,'runtime_mtime_precision':'Godot whole seconds; not an external exact-ticks claim'},
 'completed_components':['natural finalized hall and6compiled solids/removed2visual exclusions','both existing clips RGBA8/original sizes','two true-base actual Physics negatives','one explicit450,525 QA pose','real INPUT450,525 to637.5525,525'],
 'not_completed':['PNG','midpoint-to812.5 forward','reverse','final owner assertion','positive column ghost credit'],
 'two_distinct_findings':{
   'QA_camera_predicate':'Field1443-1468 and859-873 define fixed1536x1024 hall in1920x1080 viewport; noWorldCamera is correct. Failed aggregate requiredCamera2D incorrectly.',
   'production_ghost_parent':'Original helper7D67 placed overlays on WorldContainer while Player and original props areActorLayer children. Unchanged NativeDepth43-55 shared-parent predicate necessarily invalidates entire snapshot. Old selected debug omitted invalid reasons; zero cannot be treated as valid no-hit evidence.'},
 'parent_successor_static':{'proof':res(proof),'proof_sha256':sha(proof),'helper_sha256':sha(helper_new),'G_sha256':sha(gafter),'helper3hunks_and_G2literals_fullbyte_forward_exact':True,'same_shared_parent_guard_not_weakened':True,'clip_geometry_alpha_depth_unchanged':True,'not_deployed_or_executed_by_QA':True},
 'scope_limits':'No engine, decode, collector, old875, PNG or production write; all originalFAIL/results preserved.'}
reviewpath=Q/'mainhall_RGB124716_FAIL_and_ActorLayer_static_review_READY.json'
print('review',emit(reviewpath,review))

target=Q/'mainhall_ActorLayer_fixed_viewport_suffix_NOTREADY'
key=target/'test_NOTREADY.gd'
fixture=copy.deepcopy(load(parent/'fixture_READY.json'))
fixture.update(ready=False,status='ACTORLAYER_SUFFIX_BUILD_NOTREADY_PENDING_FORMAL_SOURCE_AND_ROOT_FREEZE',blockers=['ActorLayer-only G22 successor must be formally deployed and exact Root current deployment/guard facts pinned; Root alone may freeze/run.'])
fixture['source_sha256']['res://scripts/city/luoyang_assembled_interiors_20261016g.gd']=sha(gafter)
fixture['source_sha256'].pop(pr['helper']['parent']['path'])
fixture['source_sha256'][pr['helper']['candidate']['path']]=sha(helper_new)
fixture['source_sha256'][res(parent/'test_READY.gd')]=sha(parent/'test_READY.gd')
fixture['source_sha256'][res(proof)]=sha(proof)
fixture['source_sha256'][res(native)]=sha(native)
for name in ['luoyang_enclosure_building_fade_preview_20261010.gd','luoyang_enclosure_building_fade_runtime_20261010.gd']:
    path=ROOT/'scripts/city'/name
    fixture['source_sha256'][res(path)]=sha(path)
for path in list(fixture['source_sha256']):
    if '/rgb01/deployment_' in path or path.endswith('/rgb01/current_before_room.json'): fixture['source_sha256'].pop(path)
fixture['inspection_start_world']=[637.5,525]
fixture['remaining_path_world']=[[637.5,525],[812.5,525],[450,525]]
for keyname in ['forward_world','reverse_world','base_negative_world','formal_RGB22_stage']: fixture.pop(keyname)
fixture['formal_ActorLayer_successor']={'deployment_actual':None,'current_guard':None,'large_stage_receipt_not_rehashed_in_runtime':True}
fixture['fixed_viewport_source_contract']={'Field_sha256':sha(field),'lines':'859-873,1443-1468,1511-1514','source_size':[1536,1024],'design_size':[1536,1024],'viewport_size':[1920,1080],'world_size':[1920,1280],'zoom':'maxf(1.0,scene.camera_zoom), original native scene operand','origin':'(viewport-world_size*zoom)*0.5','Camera2D':'must be null in fixed mode, never created or moved by QA'}
fixture['scope']='NEW remaining-only midpoint inspection/photo, natural valid ActorLayer current-frame depth/ghost, real637.5->812.5->450 INPUT. No Yamen/Space/compile/clipformat/base/firstleg/default performance/fullsource replay; old wholeFAIL preserved.'
fxpath=target/'fixture_NOTREADY.json'
fxsha=emit(fxpath,fixture)
original=key.read_bytes();token=b'PENDING_EXACT_FIXTURE_SHA'
assert original.count(token)==1
key.write_bytes(original.replace(token,fxsha.encode()))
assert key.read_bytes().replace(fxsha.encode(),token)==original
handoff={'status':'NOTREADY_NO_ENGINE_OR_DEPLOYMENT','key':{'path':res(key),'sha256':sha(key)},'fixture':{'path':res(fxpath),'sha256':fxsha},'actual_review':{'path':res(reviewpath),'sha256':sha(reviewpath)},'candidate_pins':{'helper':sha(helper_new),'G':sha(gafter)},'fixed_scope':'60swhole20sentry/one direct-room/one637.5,525 inspection pose/one fixedviewportPNG/realremainingINPUT812.5then450','no_ghost_pixel_expected_in_advance':True,'invalid_depth_snapshot_must_fail_not_be_accepted_as_zero_hits':True,'full_debug_entry_serializer':'all entries and types incl reasons; int64decimal strings; Image/TextureObject class/id only, no data reads','functions_new':'small precheck/run/directroomidentity/fixedviewport capture/full debug+sharedparent; inherit exact original Input driver/clearance/onepose/save guard','ROOT_action_required':'Read complete new key/fixture; only after formalActorLayer source and currentRootfacts, mechanically freeze NEW READY with exact paths/SHA/status; ROOT uniquely runs using retained launcher.','engine_by_QA':0,'collector':0,'production_writes':0}
print('fixture',fxsha,'key',sha(key))
print('handoff',emit(target/'handoff_NOTREADY.json',handoff))
