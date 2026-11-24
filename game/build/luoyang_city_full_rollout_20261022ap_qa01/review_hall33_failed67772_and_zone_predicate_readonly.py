"""Read-only actual failure/guard audit. No key fix, engine or portal decoding."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
D=QA/'hall_roundtrip_ROOT33_READY';R=ROOT/'integration33'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'output/67772_2753/result.json';r=rd(rp)
assert sha(rp)=='01dbdca45b05629ccaccd7e5ba1a197da6dd830925e84778570042fb0ea6b609'
assert (r['checks'],r['complete'],r['failures'],r['elapsed_ms'])==(3102,False,2,28082)
assert r['source_before']==r['source_after']and len(r['source_before'])==1290
assert r['players_before']==r['players_after']and len(r['players_before'])==15
fixturep=D/'hall_roundtrip_fixture_ROOT33_READY.json';f=rd(fixturep)
assert sha(fixturep)=='92a78e2530269d8798f5f52e0ffd9eb46d5d6b2c9361a4267e8b9879bc375bc2'
expected={**f['source_sha256'],'res://'+fixturep.relative_to(GAME).as_posix():sha(fixturep)}
assert {p:v['sha256']for p,v in r['source_before'].items()}==expected
assert [v['kind']for v in r['records']]==['HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY','HALL_NATURAL_CITY_SOURCE_OWNER_AFTER_DRAW','HALL_REAL_INPUT']
draw,natural,walk=r['records']
assert draw['draw']['elapsed_usec']==13088910 and draw['ready']['elapsed_usec']==12960190 and draw['draw']['loading_hidden_inactive']and draw['draw']['can_move']
assert natural['initial']and natural['source_count']==1239 and natural['sources']==f['expected_city_sources']and natural['token']>0
assert walk['label']=='street716to660'and walk['result']['ok']and walk['result']['all_recorded_feet_clear']and walk['result']['physics_samples']==8 and walk['result']['actual_end']==[1536.,660.]
processp=R/'hall_roundtrip_once_process_receipt.json';pr=rd(processp)
assert sha(processp)=='139aaf7b641efda0dc845ef5907db052925cadd63d6342cd8b70ceec667c55db'
assert pr['actual_natural_console_exit_code']==-1073741819 and pr['exit_code_from_retained_process_WaitForExit']and not pr['process_stopped_by_tool']
keyp=D/'test_hall_roundtrip_ROOT33_READY.gd';assert pr['script_sha256']==pr['script_after_sha256']==sha(keyp)=='d16f5dbbac971bfdd25f95790d8ebefe449914b95161840ec76126cc6a54b609'
ep=R/'hall_roundtrip_once_stderr.log';op=R/'hall_roundtrip_once_stdout.log'
assert sha(ep)==pr['stderr_sha256']and sha(op)==pr['stdout_sha256']
err=ep.read_text(encoding='utf-8-sig')
assert 'CITY_LIFE_QA_FAIL One exact authored native target and door foot <null>'in err
counts={'ERROR':len(re.findall(r'^ERROR:',err,re.M)),'WARNING':len(re.findall(r'^WARNING:',err,re.M)),'SCRIPT_ERROR':len(re.findall(r'^SCRIPT ERROR:',err,re.M))}
assert counts=={'ERROR':10,'WARNING':1,'SCRIPT_ERROR':0}
gp=R/'final_guard.json';g=rd(gp)
assert sha(gp)=='9944e3be37d89a949915b3f7a622a3c960c1036f8a11839b87ae44dc295eaf86'
assert g['passed']is False and g['checked']==2118 and g['exact_unchanged']==2117 and g['authorized_change_count']==0 and g['unexpected_change_count']==1 and g['save_change_count']==0 and g['save_count']==15
change=g['unexpected_changes'][0]
assert Path(change['path']).resolve()==(GAME.parent/'prompts/tasks.yaml').resolve()
assert change['before']['sha256']=='36b7622dad7d98fe39039da867c0bc60184a978d0e680b8e37b3a64b3784aaf0'and change['after']['sha256']=='9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'
assert change['before']['bytes']==735412 and change['after']['bytes']==769954 and change['before']['ticks']!=change['after']['ticks']
savebase=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for k,row in r['players_after'].items():
    p=savebase/k.removeprefix('user://');assert p.exists()==row['exists']
    if row['exists']:assert p.stat().st_size==row['bytes']and sha(p)==row['sha256']
zonep=GAME/'scripts/field/world_v15_exit_zone.gd';v3p=GAME/'scripts/field/luoyang_v3_exit_zone.gd';fieldp=GAME/'scripts/field/field_walkable_controller.gd';G=GAME/'scripts/city/luoyang_assembled_interiors_20261016g.gd'
zone=zonep.read_text(encoding='utf-8');v3=v3p.read_text(encoding='utf-8');field=fieldp.read_text(encoding='utf-8');gs=G.read_text(encoding='utf-8');key=keyp.read_text(encoding='utf-8')
assert 'extends "res://scripts/field/world_v15_exit_zone.gd"'in v3
assert 'shape.disabled = true'in zone and 'polygon.name = "DoorwayPolygon"'in zone and 'add_child(polygon)'in zone
assert 'zone.set_script(load("res://scripts/field/luoyang_v3_exit_zone.gd"))'in field and 'zone.call("configure_doorway", polygon, _player, _is_inside_walkable_screen)'in field
assert 'collider!=null and not collider.disabled'in key
assert 'node is Area2D and node.get("target_scene_id")==String(target) and node.position==foot'in key
assert 'if not check(found.size()==1,"One exact authored native target and door foot"): return false'in key
assert 'Vector2(float(row.return_foot_px[0])/3072.0,float(row.return_foot_px[1])/2048.0)'in gs and '_screen_size = _world_size'in field
out=QA/'hall33_67772_failure_guard_and_zone_static_diagnosis_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'HALL33_ACTUAL_WHOLEFAIL_AND_GUARDFAIL_PRESERVED_READONLY_NO_RERUN_OR_FIX_AUTHORITY','report':{'path':str(rp),'sha256':sha(rp)},'process_receipt':{'path':str(processp),'sha256':sha(processp)},'actual_components':{'whole_complete':False,'checks':3102,'failures':2,'elapsed_ms':28082,'near_ready_usec':12960190,'near_draw_usec':13088910,'entry20s_component':True,'not_default_world_travel':True,'natural_C_FINAL1239_exact':True,'real_INPUT716to660_8physics_fullbody_clear':True,'first_zone_selection_failed_count_not1':True,'actual_count_or_pernode_mismatch_not_recorded':True,'Space_hall_room_park_warm_return_not_executed':True,'no_hall_or_warm_performance_credit':True},'source_and_save':{'report1290_firstfinal_exact':True,'expected_guard1289_plusfixture_exact':True,'15save_report_firstfinal_and_currentSHAbytes_same':True,'Root_final_guard':{'sha256':sha(gp),'passed':False,'2118checked':True,'2117exact':True,'unexpected1':change,'no_retroactive_authorization':True,'do_not_overwrite_or_restore_external_tasks':True,'future_fresh_baseline_must_preserve_external_new_value':True}},'zone_diagnosis':{'first_failed_predicate':'found.size()==1 after Area2D + exact target String + exact node.position filters','first_cause_not_proven':'No candidate count/rows/target types/worldsize/positions were recorded; cannot distinguish absent/multiple/target/position mismatch from this actual report. Static author still1536,660; no permission to infer or move the portal.','separate_definite_unreached_QA_bug':'City luoyang_v3_exit_zone inherits world_v15_exit_zone.configure_doorway, which disables original CollisionShape2D and adds DoorwayPolygon. Current key later requires not collider.disabled, incompatible with an intentional polygon doorway. This was not reached and is not evidence for first selection failure.','source_pins':{str(p):sha(p)for p in (zonep,v3p,fieldp,G)},'no_production_fix_proposed_or_applied':True},'exit':{'true_console':-1073741819,'hex':'C0000005','counts':counts,'nonclean':True,'root_cause_not_inferred':True},'operations':{'engine':0,'collector':0,'packet_or_image_decode':0,'production_or_old_report_writes':0,'newtest_or_rerun':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'exitcounts':counts}))
