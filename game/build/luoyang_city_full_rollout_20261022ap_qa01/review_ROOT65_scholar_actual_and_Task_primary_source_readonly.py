import hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2];Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
rp=R+'integration65/market_scholar_READY/output/13548_2725/result.json';r=read(rp,'5a122f911c6fe284e340e5a0ac2fdb1fbab30cae0b42441b4c5d6729fbff257f')
proc=read(R+'integration65/market_scholar_actual_process_receipt.json','79b999769f87312f17ea4490b6c948316106f0bd978271ef02a7d9803e340fe9')
owner=read(Q+'unified102_deployed_classification15_owner_ROOT64_READY/owner_source_maps_READY.json','c9d9d25bdbcd8c096e0fd16165fdc23943000e34755f11fafa07e5e782822a61')
market=next(x for x in owner['scenes']if x['id']=='ch4_s3_luoyang_market');sources=market['source_sha256']
taskp='res://scripts/city/luoyang_city_tasks_20261016.gd';specp='res://data/luoyang_city_tasks_20261016/overlay.json';coordp='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';dialogp='res://data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres';fieldp='res://scripts/field/field_walkable_controller.gd'
for p in(taskp,specp,coordp,dialogp,fieldp):assert sha(raw(p))==sources[p]
task=raw(taskp).decode();coord=raw(coordp).decode();field=raw(fieldp).decode();spec=json.loads(raw(specp))
assert 'const PREFIX := "luoyang_city_tasks_20261016/"'in task and 'static func _dialog(id: String) -> String: return PREFIX+id'in task
assert 'npc["dialog_id"]=_dialog(id)'in task and 'var dialog: String="paper_offer"'in task and '_set_dialog(npcs[index],dialog)'in task
assert spec['market']['scholar']['npc_id']=='luoyang_paper_scholar'and spec['market']['scholar']['dialog_id']=='ch4_luoyang_paper_offer'
assert 'runtime_npcs=projected.npcs'in field and 'npc.dialog_id = String(d.get("dialog_id", ""))'in field
assert 'npc.set_meta("culture_x_primary", {"dialog_id": npc.dialog_id, "interaction_action": npc.interaction_action})'in coord and 'npc.interaction_action = "culture_x_menu"'in coord
expected='luoyang_city_tasks_20261016/'+'paper_offer'
assert r['checks']==3530 and r['failures']==2 and r['complete']is False and r['elapsed_ms']==27539
assert r['source_before']==r['source_after']and r['players_before']==r['players_after']and len(r['players_before'])==15
rec=r['records'];get=lambda k:next(x for x in rec if x['kind']==k)
draw=get('PAWN_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY');natural=get('SCHOLAR_NATURAL_CITY_SOURCE_OWNER_AFTER_DRAW');actual=get('SCHOLAR_ALL_SOURCE_OPERANDS_BEFORE_EXACT_ASSERT')
assert draw['ready']['elapsed_usec']==11266350 and draw['draw']['elapsed_usec']==11384491
assert natural['source_count']==1741 and natural['sources']==sources and natural['token']>0
assert actual['dialog_id']==actual['culture_primary']['dialog_id']==expected and actual['interaction_action']=='culture_x_menu'and actual['culture_primary']['interaction_action']==''
assert actual['id']=='luoyang_paper_scholar'and actual['position']==actual['expected_foot']and actual['native_sprite_scale']==actual['expected_native_scale']and actual['body_size']==actual['expected_body']
assert not any(x['kind']=='EXPLICIT_CAMERA_ONLY_SCHOLAR_INSPECTION_NOT_DEFAULT_TRAVEL'for x in rec)
assert proc['actual_natural_console_exit_code']==-1073741819 and proc['exit_code_from_retained_process_WaitForExit']and not proc['process_stopped_by_tool']
err=pathlib.Path(proc['stderr_path']).read_bytes();assert sha(err)==proc['stderr_sha256'];lines=err.decode().splitlines()
guard=read(R+'integration65/final_guard.json','96c3018b8869eb9a119d04409892fe81645285363ca19656915cbc38b7068bef');assert guard['passed']and guard['checked']==2119 and guard['save_count']==15 and guard['save_change_count']==0 and guard['unexpected_change_count']==0
print(json.dumps({'status':'ROOT65_SCHOLAR_WHOLE_FAIL_RETAINED_RUNTIME_PRIMARY_SOURCE_DERIVED_QA_EXPECTATION_ERROR','result':{'path':rp,'sha256':'5a122f911c6fe284e340e5a0ac2fdb1fbab30cae0b42441b4c5d6729fbff257f','checks':3530,'failures':2,'elapsed_ms':27539,'complete':False},'completed':{'ready_usec':11266350,'hidden_operable_draw_usec':11384491,'under10s':False,'natural_full1741_exact_C9D9':True,'scholar_exact_new_texture_160_usedRect_scale_body_groundfoot_passed_before_primary_assert':True,'native_visible_height':actual['native_visible_height'],'source_guard_first_final_same':len(r['source_before']),'save15_same':True},'primary_source_proof':{'fixed_C9D9_source_pins':{p:sources[p]for p in(taskp,specp,coordp,dialogp,fieldp)},'raw_TRES_dialog_only_preprojection_matching_value':spec['market']['scholar']['dialog_id'],'Task_PREFIX':'luoyang_city_tasks_20261016/','Task_default_not_started_suffix':'paper_offer','derived_not_observed_expected':expected,'Field_applies_projected_npcs_before_NPC_assignment':True,'Coordinator_captures_Task_primary_then_culture_menu':True,'actual_config_matches_source_derived_expected':True,'no_task_helper_or_dialog_execution_by_QA':True},'not_executed':['camera inspection1PNG','camera restoration','postinspection gameplay comparison','postinspection owner repeat'],'exit':{'natural_console':-1073741819,'hex':'0xC0000005','nonclean':True,'ERROR':sum(x.startswith('ERROR:')for x in lines),'WARNING':sum(x.startswith('WARNING:')for x in lines),'SCRIPT_ERROR':sum('SCRIPT ERROR:'in x for x in lines),'stderr_SHA':proc['stderr_sha256']},'Root65final2119_save15same':True,'next_scope':'Only source-correct primary plus camera-only1PNG/restore/gameplay and passive C owneridentity/count1741. No body/default benchmark/fullsource/collector repeat.','QA_engine_Stage_collector_media_decode_or_production_write':False},indent=2))
