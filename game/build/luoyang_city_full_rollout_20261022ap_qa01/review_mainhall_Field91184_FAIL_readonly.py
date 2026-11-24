from pathlib import Path
import hashlib,json
GAME=Path('F:/Code/RPG_GAME/game');Q=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01'
B=Q/'mainhall_two_columns_formal27_READY';OUT=Q/'mainhall_Field91184_actual_FAIL_prefix_review_READY.json'
assert not OUT.exists()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rpath=B/'output_READY/91184_2821/result.json';r=json.loads(rpath.read_bytes())
ppath=B/'field_once_process_receipt.json';p=json.loads(ppath.read_bytes())
assert sha(rpath)=='c53620c4877e1439fb94eb32cb938891a2535dbcd4340811d24777b9e223e949'
assert not r['complete'] and r['checks']==40 and r['failures']==2 and r['elapsed_ms']==16629
assert r['source_before']==r['source_after'] and len(r['source_before'])==21
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
assert p['actual_natural_console_exit_code']==-1073741819 and p['exit_code_from_retained_process_WaitForExit'] and not p['process_stopped_by_tool']
stderr=Path(p['stderr_path']);stdout=Path(p['stdout_path'])
assert sha(stderr)==p['stderr_sha256'] and sha(stdout)==p['stdout_sha256']
lines=stderr.read_text(encoding='utf-8',errors='replace').splitlines()
counts={'ERROR':sum(s.startswith('ERROR:')for s in lines),'WARNING':sum(s.startswith('WARNING:')for s in lines),'SCRIPT_ERROR':sum('SCRIPT ERROR' in s for s in lines)}
assert counts=={'ERROR':11,'WARNING':1,'SCRIPT_ERROR':0}
portal=next(x for x in r['records']if x.get('kind')=='REAL_CITY_HALL_PORTAL_READY_BEFORE_SPACE')
assert portal['can_enter'] and not portal['locked'] and portal['pulse']==1.0 and portal['shader'].endswith('portal_interaction_outline_CANDIDATE.gdshader') and portal['texture']=='res://art/ui/field_hud/portal_arrow_amber_v2.png'
draw=next(x for x in r['records']if x.get('kind')=='HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')
assert draw['draw']['elapsed_usec']==13522844
zone=next(x for x in r['records']if x.get('kind')=='HALL_ACTUAL_NATIVE_ZONE');assert zone['enabled_overlap_inrange'] and zone['shape_contract']
fail=next(x for x in r['records']if x.get('kind')=='HALL_FIELD_FAILURE');assert fail['leg']=='REAL_SPACE_HALL_ENTRY' and fail['loading']['failed']
assert not any(x.get('kind')in ['NATURAL_HALL_SESSION_AND_REAL_COMPILED_MARKER','CURRENT_FRAME_COLUMN_ALPHA_OBSERVATION','ONE_ORIGINAL_CAMERA_BEHIND_COLUMN_SCENE_IMAGE']for x in r['records'])
review={'status':'PRESERVED_WHOLE_FAIL_WITH_PASSED_YAMEN_PORTAL_PREFIX_NOT_SAME_JOURNEY_CONTINUATION','actual_result':{'path':str(rpath),'sha256':sha(rpath),'checks':40,'failures':2,'complete':False,'elapsed_ms':16629},'retained_process':{'path':str(ppath),'sha256':sha(ppath),'actual_exit':-1073741819,'hex':'C0000005','wall_ms':p['elapsed_wall_ms'],'logs':counts,'not_clean':True},'completed_prefix':{'explicit_near_Yamen_hidden_operable_draw_s':13.522844,'not_default_or_under10':True,'natural_C1262_full_fixed_map_assertion_passed_before_portal':True,'source_door1536_660_exact_polygon_ready':True,'runtime_portal':portal,'one_real_Space_attempt_dispatched_hall_Field':True},'not_completed':['hall hidden operable draw','hall natural finalized G session/compiled marker assertion','base negative query','one inspection setup','behind-column INPUT','ghost observations','screenshot'], 'failure':{'Field_error':'Main-hall fixed-column scope rejected','loading_stage_text_unreliable_encoding':'raw result retained','public_HANDED_OFF_is_previous_Yamen_not_hall_success':True,'RGB_diagnosis_scope':'Root independent PNG IHDR type2 plus helper requiresRGBA8 establishes a source-format incompatibility to fix. This actual did not record get_image format or individual helper rejection guard; do not invent a measured source format or claim that every earlier install gate passed.'},'protection':{'source21_first_final_equal':True,'save15_equal':True,'Godot_mtime':'seconds only','Root_exactUTCticks_guard':'separate Root receipt, not rehashed here'},'next_scope':'NEW direct-room public inspection run after exactRGB helper successor; not continuation of this failed journey. Do not repeat Yamen/arrow prefix or isolated tests.','no_engine_collector_image_decode_production_write':True}
OUT.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':str(OUT),'sha256':sha(OUT),'actual_result':sha(rpath),'log_counts':counts}))
