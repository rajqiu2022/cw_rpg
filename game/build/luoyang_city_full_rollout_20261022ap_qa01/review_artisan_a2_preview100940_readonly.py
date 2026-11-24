"""One source/receipt/image-hash review, no image decode or additional engine."""
import hashlib,json
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
B=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_visual_epoch01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
P=B/'output/100940_2587/result.json';PROCESS=ROOT/'integration14/artisan_a2_one_camera_process_receipt.json'
GUARD=ROOT/'integration14/final_guard.json';BEFORE=ROOT/'integration14/guard_before.json'
ART=ROOT/'artisan_A2_local_layout_material_admission_READY.json'
OUT=QA/'artisan_a2_preview100940_independent_readonly_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):return GAME/p[6:]
assert not OUT.exists()
assert sha(P)=='64e699fb06727f97163c8a290ac4e2a605144f38001db638ae6c06a0de98b5e4'
assert sha(GUARD)=='6197bfd4edf7af510689b8c8d781f9e5296449cc3c261397d486b81379c993f1'
assert sha(ART)=='eaab96070310ea773dfce3aeac212c2d29bc1f8c48d089623c74488b793e7b14'
r=json.loads(P.read_bytes());pr=json.loads(PROCESS.read_bytes());g=json.loads(GUARD.read_bytes());before=json.loads(BEFORE.read_bytes());art=json.loads(ART.read_bytes())
assert r['complete'] and (r['checks'],r['failures'],r['elapsed_ms'])==(538,0,2223)
assert pr['actual_natural_console_exit_code']==0 and pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
assert pr['script_sha256']==pr['script_after_sha256']=='29775d57bd412612083d656fd5497530f5e0f5c37c7de34340ef2dff2988e074'
assert r['source_before']==r['source_after'] and len(r['source_before'])==78
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
i=json.loads((B/'input_READY.json').read_bytes());assert sha(B/'input_READY.json')=='a00dee4ad10b3bed206e3d03df0fe7ae4ffd93fb6747ebde014de6d66dc098a6'
assert len(i['source_pins'])==77
expected=dict(i['source_pins']);expected['res://'+(B/'input_READY.json').relative_to(GAME).as_posix()]=sha(B/'input_READY.json')
assert set(expected)==set(r['source_before'])
for source,h in expected.items():
    f=r['source_before'][source];current=path(source)
    assert f['exists'] and f['sha256']==h and sha(current)==h and current.stat().st_size==f['bytes']
    assert current.stat().st_mtime_ns//1000000000==f['mtime']
material=r['records'][0];frame=r['records'][1]
assert len(r['records'])==2
assert material['kind']=='A2_132_NATIVE_CONTEXT_EXACT_MATERIALS' and material['ground_materials']==118 and material['opaque_props']==14 and material['Field_NPC_Player_nodes']==0
assert material['constructor']['ok'] and material['constructor']['all_source_pixels_unchanged'] and material['constructor']['no_geometry_modified'] and material['constructor']['no_Field_lease_or_runtime_admission']
assert material['shader_uniforms']==sorted(i['required_shader_uniforms']) and len(material['shader_uniforms'])==11
assert frame['same_world_rect']==[1152,968,1920,1080] and frame['world_scale']==1.0
assert frame['camera_effective_center']=='(2112.0, 1508.0)' and frame['camera_requested']=='(2816.0, 1716.0)'
assert frame['geometry_Physics_collector_import_calls']==0 and frame['Field_Player_NPC_HUD_omitted'] and frame['not_pixel_identical_full_Field_frame']
pic=frame['image'];assert pic['sha256']=='30436ed17c5fd25556b46a4b1f0921cfbc5c852359ac0fc5dba9258f3b092fd6' and sha(path(pic['path']))==pic['sha256']
assert art['preview_report']=={'path':'res://'+P.relative_to(GAME).as_posix(),'sha256':sha(P)} and art['image']['sha256']==pic['sha256']
assert art['approved_by_root'] and art['image']['Root_actually_viewed'] and art['whole_district_ART_pass'] is False and art['whole_city_complete'] is False
assert art['Field_NPC_Player_Physics_or_loading_credit'] is False and art['production_deployed_by_this_record'] is False
assert g['passed'] and (g['checked'],g['exact_unchanged'],g['authorized_change_count'],g['unexpected_change_count'],g['save_count'],g['save_change_count'])==(2113,2113,0,0,15,0)
assert sha(BEFORE)==g['before_sha256'] and before['facts']==g['facts']
err=Path(pr['stderr_path']);stdout=Path(pr['stdout_path']);assert sha(err)==pr['stderr_sha256'] and sha(stdout)==pr['stdout_sha256']
log=err.read_text(encoding='utf-8');assert log.count('ERROR:')==9 and log.count('WARNING:')==1
assert 'SCRIPT ERROR' not in log and 'SHADER ERROR' not in log and 'Shader compilation' not in log
assert 'WASAPI: init_output_device error' in log and '3 RID allocations' in log and log.count('RenderingServer::get_singleton()')==3
out={'status':'INDEPENDENT_READONLY_FINITE_A2_PREVIEW_EVIDENCE_NOT_WHOLE_ART_OR_FIELD',
 'preview_result':{'path':'res://'+P.relative_to(GAME).as_posix(),'sha256':sha(P),'complete':True,'checks':538,'failures':0,'elapsed_ms':2223},
 'Root_process_receipt':{'path':'res://'+PROCESS.relative_to(GAME).as_posix(),'sha256':sha(PROCESS),'actual_natural_console_exit':0,'retained_WaitForExit':True},
 'fixed_source_pins':77,'plus_input_fact':1,'source_before_after_current_SHA_bytes_seconds_mtime_exact':78,
 'save_before_after_seconds_facts_exact':15,
 'Root_external_guard':{'path':'res://'+GUARD.relative_to(GAME).as_posix(),'sha256':sha(GUARD),'facts':2113,'exact_unchanged':2113,'save_exactticks':15,'no_authorized_or_unexpected_changes':True,'fresh_before_fact_values_exact_equal':True},
 'material_constructor_and_reflection':material,'camera':{'effective_center':[2112,1508],'requested':[2816,1716],'world_rect':[1152,968,1920,1080],'world_scale':1,'actor_and_UI_omitted':True},
 'single_PNG_SHA_only_no_open_or_decode':pic,
 'Root_finite_ART_authority':{'path':'res://'+ART.relative_to(GAME).as_posix(),'sha256':sha(ART),'admitted_scope':art['admitted_scope'],'whole_district_ART_pass':False,'whole_city_complete':False},
 'nonclean_logs':{'stderr_sha256':sha(err),'stdout_sha256':sha(stdout),'ERROR_lines':9,'WARNING_lines':1,'WASAPI_fallback':True,'Texture_RID_and_RenderingServer_teardown_errors':True,'shader_compile_or_GDScript_errors_observed':False,'clean':False},
 'credit_boundary':'Contextual132 native/118 ground+14 opaque props preview and Root limited layout/material authority only. No actor-local/Field/Physics/door travel/load speed/import or runtime-source integration credit; original A1 wholeART rejection and all prior FAILs remain.',
 'engine_runs_this_review':0,'PNG_decode_or_open':0,'ABI_runs':0,'native_decode':0,'87517_replay':0,'collector_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'sources':78,'save_seconds':15,'guardfacts':2113,'clean':False,'engine':0}))
