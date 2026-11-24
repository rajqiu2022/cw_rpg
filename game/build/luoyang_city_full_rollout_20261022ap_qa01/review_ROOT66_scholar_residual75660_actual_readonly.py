import hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2];R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
rp=R+'integration66/scholar_residual_READY/output/75660_2737/result.json';rh='545322a2ca324565d0d7edff75a87942a64fe59f0769841276b19fb06974169c';a=read(rp,rh)
pp=R+'integration66/scholar_residual_actual_process_receipt.json';ph='9b6e0e500807f6c2caa5297681a606daefd244073d1a879d7f1b04cb994aa29f';p=read(pp,ph)
f=read(R+'integration66/scholar_residual_READY/fixture_READY.json','596c8c59b7833dc2905ad89210d5d787deb411d79363a717f6a6e782b86f37d5')
assert a['checks']==35 and a['failures']==0 and a['complete']is True and a['elapsed_ms']==12263
assert a['source_before']==a['source_after']and len(a['source_before'])==16
assert a['players_before']==a['players_after']and len(a['players_before'])==15
records=a['records'];owners=[r for r in records if r['kind']=='RESIDUAL_PASSIVE_C_OWNER_SCALARS'];assert len(owners)==2
assert owners[0]['initial']is True and owners[1]['initial']is False and owners[0]['identity']==owners[1]['identity']and owners[0]['identity']['source_count']==1741 and owners[0]['identity']['token']>0
assert all(r['fresh_validation_invoked_by_QA']is False and r['source_table_copied_or_rehashed']is False and r['full1741_retest_credit']is False for r in owners)
primary=next(r for r in records if r['kind']=='SOURCE_DERIVED_TASK_PRIMARY_ONLY');spec=f['scholar']
assert primary['id']==spec['id']and primary['dialog_id']==primary['culture_primary']['dialog_id']==spec['task_projected_dialog_id']==spec['primary_dialog_id']=='luoyang_city_tasks_20261016/paper_offer'
assert primary['interaction_action']=='culture_x_menu'and primary['culture_primary']['interaction_action']==''and primary['quest_status']==0
image=next(r for r in records if r['kind']=='EXPLICIT_CAMERA_ONLY_SCHOLAR_INSPECTION_NOT_DEFAULT_TRAVEL');restore=next(r for r in records if r['kind']=='SAME_CAMERA_POSITION_RESTORED_DEFAULT_PLAYER_NEVER_MOVED')
assert image['pictures']==1 and image['Player_unchanged']and image['image_SHA']=='5cdc086d05292bb6b0f6062b3b9b4f08c2228a0b759345d09bbbeaef893866a8'
assert image['limits_can_clamp_not_exact_focus_claim']and restore['restored']and restore['camera_position_writes']==2 and restore['camera_position']==restore['original_position']
scope=next(r for r in records if r['kind']=='ONLY_PRIMARY_AND_INHERITED_CAMERA_RESIDUAL_SCOPE')
assert all(scope[k]==0 for k in('INPUT','Space','Physics','room','collector','full1741_table_copy_or_hash','PlayDialog_or_task_execution','Player_position_writes'))and scope['body_sprite_retest']is False and scope['default_load_benchmark_credit']is False
assert p['actual_natural_console_exit_code']==-1073741819 and p['exit_code_from_retained_process_WaitForExit']and p['process_stopped_by_tool']is False
assert p['script_sha256']==p['script_after_sha256']=='8731b0100cec98eeec5b3a8415d3309c92fdd3bbffc640e53c9ea06e50e7236a'
err=pathlib.Path(p['stderr_path']).read_bytes();out=pathlib.Path(p['stdout_path']).read_bytes();assert sha(err)==p['stderr_sha256']and sha(out)==p['stdout_sha256']
lines=err.decode().splitlines();errors=sum(r.startswith('ERROR:')for r in lines);warnings=sum(r.startswith('WARNING:')for r in lines);scripts=sum('SCRIPT ERROR:'in r for r in lines);assert(errors,warnings,scripts)==(12,2,0)
print(json.dumps({'status':'ROOT66_RESIDUAL_FUNCTIONAL_COMPONENT_PASS_EXIT_C0000005_NONCLEAN_NOT_WHOLEPASS','actual':{'path':rp,'sha256':rh,'checks':35,'failures':0,'complete':True,'elapsed_ms':12263},'completed_components':{'source_correct_Task_primary_and_culture_wrapper':True,'only_one_existing_camera_inspection_PNG':{'path':image['image'],'sha256':image['image_SHA'],'QA_reopened_or_decoded':False,'fixed_focus_source':image['fixed_focus_source'],'actual_camera_center':image['actual_screen_center'],'original_limits_may_clamp':True},'same_camera_restore_and_Player_never_moved':True,'gameplay_flags_quests_inventory_unchanged_assertion_passed':True,'natural_C_same_Field_Scene_layout_token_1741_passive_only':owners[0]['identity']},'protection':{'16small_sources_before_after_same':True,'15save_before_after_same':True,'save_fact_precision':'Existing FileAccess exists/SHA/bytes/modified-time facts; no new Windows exact-ticks or global2119 guard is invented by this review.','Root66_global_final_guard_not_supplied_in_this_task':True},'exit':{'process_receipt':{'path':pp,'sha256':ph},'natural_retained_console_exit':-1073741819,'hex':'0xC0000005','ERROR':12,'WARNING':2,'SCRIPT_ERROR':0,'nonclean':True,'stderr_SHA':p['stderr_sha256'],'stdout_SHA':p['stdout_sha256']},'scope_exclusions':scope,'not_claimed':['wholeclean/RELEASE pass','Task dialogue execution or quest action','new full1741 source verification','repeated body/sprite/usedRect credit','default-load benchmark or under10s','default camera or whole-city ART','Root65 wholeFAIL repaired retroactively'], 'QA_actions':{'engine':False,'collector':False,'PNG_or_source_decode':False,'media_hash':False,'production_write':False}},indent=2))
