"""Finite retained actual review only. No Godot, collector, media decode or writes to production."""
from pathlib import Path
import hashlib,json,re
Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p): return 'res://'+p.relative_to(GAME).as_posix()
def local(p):
    assert p.startswith('res://')
    return GAME/p[6:]
def read(p): return json.loads(p.read_bytes())
def unwrap(value):
    # Decode this QA value-only tagged diagnostic format; no packet/resource decode.
    if isinstance(value,list): return [unwrap(v) for v in value]
    if not isinstance(value,dict): return value
    if value.get('type')=='int64': return int(value['decimal'])
    if value.get('type')=='StringName': return value['text']
    if value.get('type')=='Dictionary':
        rows=[(unwrap(row['key']),unwrap(row['value'])) for row in value['entries']]
        assert len({k for k,_ in rows})==len(rows), 'No diagnostic key collision may be silently dropped'
        return dict(rows)
    if 'values' in value and value.get('type') in ['Array','PackedByteArray','PackedInt32Array','PackedInt64Array','PackedFloat32Array','PackedFloat64Array','PackedStringArray','PackedVector2Array','PackedVector3Array','PackedColorArray','PackedVector4Array']:
        return [unwrap(v) for v in value['values']]
    return {k:unwrap(v) for k,v in value.items()}

base=Q/'mainhall_ActorLayer_fixed_viewport_suffix_READY'
result=base/'output_READY/98132_2903/result.json'
assert sha(result)=='dac75918acaa964eaa13dc397c2ee6c68d46b675f614214fccb7ff1665e86abc'
d=read(result)
assert (d['checks'],d['failures'],d['complete'],d['elapsed_ms'])==(51,0,True,6158)
assert len(d['source_before'])==22 and d['source_before']==d['source_after']
assert len(d['players_before'])==15 and d['players_before']==d['players_after']
fixture=read(base/'fixture_READY.json')
assert sha(base/'fixture_READY.json')=='2fe4a2547372a33086c664aaf6d0f15a8245ea457cca703ae5c7e594d102fba9'
expected=dict(fixture['source_sha256']);expected[res(base/'fixture_READY.json')]=sha(base/'fixture_READY.json')
assert set(expected)==set(d['source_before'])
for path,expected_sha in expected.items(): assert d['source_before'][path]['sha256']==expected_sha
# Only four small current scripts, no runtime complete source/city/large media scan.
current_scripts=[base/'test_READY.gd',GAME/'scripts/city/luoyang_assembled_interiors_20261016g.gd',GAME/'scripts/field/field_walkable_controller.gd',local('res://build/luoyang_hall_portal_fix_20261024a_system01/parent_successor02/mainhall_fixed_columns_ActorLayer_CANDIDATE.gd')]
scriptpins=['833beb20b7bd6e63aee66f0b47776c597bbb5e8432165a9165ce2e3220445818','1078ce7fd48ee9cdae91fd56fedfa20ff26cc80f5c3273d8ff3b0b479dd128e6','93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0','a5b024dc49a339ce56df0b236e60e009e442dc4c7453defe12989aa1e20f5ac0']
assert [sha(p) for p in current_scripts]==scriptpins

process=base/'suffix_once_process_receipt.json'
assert sha(process)=='25a721ec08ec931c98cc18fffd6f2b7941b8d4ca42d01a76e379756d6d5b288f'
p=read(process)
assert p['actual_natural_console_exit_code']==0 and p['exit_code_from_retained_process_WaitForExit'] is True and p['process_stopped_by_tool'] is False
assert p['script_sha256']==p['script_after_sha256']==scriptpins[0]
stderr=Path(p['stderr_path']);stdout=Path(p['stdout_path'])
assert sha(stderr)==p['stderr_sha256'] and sha(stdout)==p['stdout_sha256']
log=stderr.read_text(encoding='utf-8')
error_count=len(re.findall(r'^ERROR:',log,re.M));warning_count=len(re.findall(r'^WARNING:',log,re.M));script_errors=len(re.findall(r'^SCRIPT ERROR:',log,re.M))
assert (error_count,warning_count,script_errors)==(7,0,0)
assert 'CITY_LIFE_QA_FAIL' not in log

rows=d['records']
identity=[r for r in rows if r['kind']=='NATURAL_ROOM_SUFFIX_IDENTITY_ONLY']
assert len(identity)==2
idkeys=['Field','Player','Scene','layout']
assert all(identity[0][key]==identity[1][key] and isinstance(identity[0][key],str) for key in idkeys)
assert all(r['finalized'] and r['same_live_objects'] for r in identity)
draw=next(r for r in rows if r['kind']=='HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')
for key in idkeys: assert str(draw['draw'][key])==identity[0][key]
assert draw['draw']['elapsed_usec']==4276948 and draw['draw']['loading_hidden_inactive'] is True and draw['draw']['can_move'] is True
pose=[r for r in rows if r['kind']=='EXPLICIT_QA_ONLY_INSPECTION_POSE_NOT_PUBLIC_API_NOT_TRAVEL']
assert len(pose)==1 and pose[0]['writes']==1 and pose[0]['actual_after_physics']==[637.5,525]

states=[r for r in rows if r['kind']=='FULL_ACTUAL_CURRENT_FRAME_OVERLAP_AND_DEPTH']
assert len(states)==3
summary=[]
for r in states:
    debug=unwrap(r['overlap_debug_all_entries']);depth=unwrap(r['depth_state_all_entries']);fade=unwrap(r['fade_runtime_all_entries'])
    assert r['native_snapshot_valid'] is True and r['preview_valid'] is True
    assert not any(k in debug for k in ['invalid_depth_snapshot','invalid_actor_frame','fade_preview_invalid'])
    assert fade['status']=='READY_ENCLOSURE_RUNTIME' and fade['production_hooked'] is True
    assert r['ActorLayer_decimal']==r['Player_parent_decimal']
    assert len(depth)==7 and len([x for x in depth if x['id']=='Player' and x['actor']])==1
    for col in r['columns']:
        assert col['same_ActorLayer'] and col['visible'] and col['depth_row_count']==1 and col['parent_decimal']==r['ActorLayer_decimal']
        assert col['modulate']['rgba']==[1,1,1,1] and col['self_modulate']['rgba']==[1,1,1,1]
        assert col['id'] not in fade['fade_ids'] and col['id'] in fade['opaque_low_ids']
        assert len([x for x in depth if x['id']==col['id'] and not x['actor']])==1
    summary.append({'label':r['label'],'foot':r['foot']['xy'],'frame':r['actual_frame'],'native_snapshot_valid':True,'preview_valid':True,'ActorLayer_decimal':r['ActorLayer_decimal'],'column_pixels':r['column_pixels_observed_not_expected'],'all_prop_hits':debug['prop_hits'],'active':debug['active'],'ghost_visible':r['ghost_visible'],'ghost_material':r['ghost_material'],'depth_rows':len(depth),'both_columns_alpha1':True,'no_invalid_reason_present':True})
assert [r['column_pixels'] for r in summary]==[3092,0,0]
assert summary[0]['all_prop_hits']=={'mainhall_fixed_column_0_foreground':3092}
assert summary[0]['active'] and summary[0]['ghost_visible'] and summary[0]['ghost_material']
assert all(not r['active'] and not r['ghost_visible'] and not r['ghost_material'] for r in summary[1:])
assert len({r['ActorLayer_decimal'] for r in summary})==1

fixed=[r for r in rows if r['kind']=='ORIGINAL_FIXED_VIEWPORT_SOURCE_EXPRESSION']
assert len(fixed)==2 and fixed[0]['actual_world_transform']==fixed[1]['actual_world_transform']
for r in fixed:
    assert r['viewport']['xy']==[1920,1080] and r['world_size']['xy']==[1920,1280] and r['design_size']['xy']==[1536,1024]
    assert r['world_camera_null'] and r['viewport_camera_null'] and not r['camera_scroll']
    assert r['expected_max_zoom']==r['scene_zoom_operand']==1.0 and r['expected_centered_origin']['xy']==[0,-100]
walks=[r['result'] for r in rows if r['kind']=='HALL_REAL_INPUT']
assert len(walks)==2
assert walks[0]['start']==[637.5,525] and walks[0]['target']==walks[0]['actual_end']==[812.5,525]
assert walks[1]['start']==[812.5,525] and walks[1]['target']==walks[1]['actual_end']==[450,525]
assert all(r['ok'] and r['all_recorded_feet_clear'] and r['reached'] and not r['first_bad'] for r in walks)
assert [r['physics_samples'] for r in walks]==[23,46]
end=next(r for r in rows if r['kind']=='NEW_REMAINING_SUFFIX_ONLY_END')
assert end['actual_Physics_queries']==75 and end['actual_mask_points_when_present']==0
assert end['collectors']==0 and end['compile_format_base_firstleg_replays']==0 and end['pictures']==1 and end['inspection_Player_writes']==1
image=next(r for r in rows if r['kind']=='ONE_ORIGINAL_FIXED_VIEWPORT_MIDPOINT_IMAGE')
assert sha(local(image['path']))==image['sha256']=='a76f504658551731245f4cc9feeaffe3594ec584cf042c610b1f604db9b00fa4'
# File SHA only, no PNG decode/view, raw image or prior mask replay.

gpath=GAME/'build/luoyang_hall_portal_fix_20261024a_root01/parent02/current_after_suffix.json'
bpath=gpath.with_name('current_before_suffix.json')
assert sha(gpath)=='263997d29121ac8c683e8833f49746c539292c679ad0516faa4835297b2fa7b1'
g=read(gpath);before=read(bpath)
assert g['passed'] and g['checked']==2120 and g['runtime_changes']==0 and g['save_count']==15 and g['save_changes']==0 and g['union_authorized_targets']==27
assert before['facts']==g['facts'] and len(g['facts'])==2120
assert g['comparison_sha256']==sha(bpath)=='5af8a68d7f63954d94c536b816fda830995d1461199d8d460ebced9dc763ce89'

review={
 'status':'FINITE_REMAINING_SUFFIX_COMPONENT_PASS_NOT_CLEAN_OR_WHOLECITY',
 'actual':{'path':res(result),'sha256':sha(result),'checks':51,'failures':0,'complete':True,'elapsed_ms':6158,'room_inspection_hidden_operable_draw_usec':4276948,'default_world_or_new_benchmark_credit':False},
 'process':{'path':res(process),'sha256':sha(process),'natural_retained_console_exit':0,'wall_ms':p['elapsed_wall_ms'],'stopped':False,'editor51856_retained':p['editor51856_still_running'],'ERROR':error_count,'WARNING':warning_count,'SCRIPT_ERROR':script_errors,'clean_exit_claim':False,'known_exit_errors':'Texture/RID leaks and RenderingServer destruction errors retained'},
 'source_protection':{'small_guard_count':22,'source_first_final_same':True,'fixed_fixture_guard_exact':True,'current_small_script_SHA_count':4,'save15_runtime_same':True,'runtime_mtime_precision':'Godot seconds','external_guard':{'path':res(gpath),'sha256':sha(gpath),'checked':2120,'facts_exact_to_before':True,'runtime_changes':0,'save15_changes':0,'union27_authorized':True}},
 'exact_identity_decimal_strings':{k:identity[0][k] for k in idkeys},
 'one_QA_pose':{'foot':[637.5,525],'writes':1,'explicit_inspection_not_default_or_travel':True},
 'natural_actual_alpha_observations':summary,
 'fixed_viewport':{'design':[1536,1024],'viewport':[1920,1080],'world':[1920,1280],'zoom':1.0,'centered_origin':[0,-100],'Camera2D':None,'original_transform_same_before_after':True,'camera_or_container_writes':0},
 'real_INPUT':{'segments':[{'start':r['start'],'target':r['target'],'actual_end':r['actual_end'],'physics_samples':r['physics_samples'],'all_recorded_feet_clear':True} for r in walks],'actual_Physics_queries':75,'mask_samples':0,'body':'original34x24','no_firstleg_or_base_or_geometry_replay':True},
 'image':{'path':image['path'],'sha256':image['sha256'],'one_only':True,'Root_visual_review':'Root already viewed; this QA review performs only fileSHA, no decode or ART override'},
 'preserved_failures':['91184_2821 wholeFAIL RGB helper precondition','124716_2789 wholeFAIL wrong QA camera predicate plus invalid production shared-parent snapshot'],
 'credit_limits':'Only remaining room midpoint/image/two realINPUT segments and valid actor-local current-alpha ghost observed3092->0. Earlier prefixes retain their own source/actual scope; no same journey continuation, Yamen/portal rerun, wholecity/wholeART/firstload<10s/clean-exit claim. No engine/collector/resource decode/raster/production writes by reviewer. Stop this test scope.'}
out=base/'suffix98132_finite_actual_independent_review_READY.json'
assert not out.exists();out.write_bytes((json.dumps(review,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print('REVIEW',sha(out),'result',sha(result),'process',sha(process),'complete51/0; console0; ERROR7/WARN0/SCRIPT0; stop')
