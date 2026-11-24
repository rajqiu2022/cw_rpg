"""One readonly review of the Root finite publication; no output decode or replay."""
import hashlib,json,math
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
B=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01'
RESULT=B/'output_crossings6/runs/118352_1733/result.json'
PROCESS=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration14/artisan_a2_crossings6_process_receipt.json'
OUT=QA/'artisan_a2_publication118352_independent_readonly_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):return GAME/p[6:]
assert not OUT.exists()
assert sha(RESULT)=='a5f2200e76ca6bb7932c5760b3954748c0578c0c093755af86493a51a4ce25b7'
r=json.loads(RESULT.read_bytes());proc=json.loads(PROCESS.read_bytes())
assert proc['actual_natural_console_exit_code']==0 and proc['exit_code_from_retained_process_WaitForExit'] is True and proc['process_stopped_by_tool'] is False
assert proc['launcher_pid']==112484 and proc['script_sha256']==proc['script_after_sha256']=='7af898b6c40c7bd286cdcb472e5a4ea0c2d93ca907128cee566d7e1917f06fbb'
assert r['passed'] is True and r['published'] is True and r['error']=='' and (r['checks'],r['elapsed_ms'],r['limit_ms'])==(1941,3624,60000)
assert r['C_compile_fullraster_collectors_Physics_calls']==0
assert r['whole_packet_inverse'] and r['whole_scene_layout_inverse'] and r['scene_NPC_portals_inherited']
i=json.loads((B/'input_crossings6_READY.json').read_bytes())
assert sha(B/'input_crossings6_READY.json')=='68a754894f570ea74e0dd617b8a03454fa5e76fb0c53f1182616d14d8c9589e1'
prior=QA/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json'
assert sha(prior)=='d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e'
p=json.loads(prior.read_bytes());m=p['prior_mask'];proof=r['finite_proof'];audit=proof['full875_plus17_finite']
expected_sources=dict(i['source_pins'])
expected_sources['res://'+(B/'input_crossings6_READY.json').relative_to(GAME).as_posix()]=sha(B/'input_crossings6_READY.json')
expected_sources['res://'+(B/'publisher_crossings6_READY.gd').relative_to(GAME).as_posix()]=sha(B/'publisher_crossings6_READY.gd')
assert len(i['source_pins'])==137 and len(expected_sources)==139
assert r['source_first']==r['source_final']==expected_sources
for src,h in expected_sources.items():assert sha(path(src))==h,(src,'source changed')
lm=proof['local_mask']
assert lm['parent_rgba_sha256']==m['original_RGBA_sha256']
assert lm['child_rgba_sha256']==m['expected_child_RGBA_sha256']=='ba3713f65664983e9825187d722fe7d679fc604c2a5a07c6a403e597b4b366c1'
assert (lm['changed_pixels'],lm['visited_pixels'],lm['domain_count'])==(17366,21538,8)
assert lm['whole_RGBA_inverse'] and lm['outside_eight_guarded_domains_exact'] and lm['pixel_rebuilt_from_original_walkrect_and_ALL27_source_solids'] and lm['blind_white_fill'] is False
assert proof['body']==[34,24] and proof['native_storage_inverse']
assert (proof['old_visual_count'],proof['new_visual_count'],proof['new_ground_count'],proof['retained_opaque_props'],proof['old_solid_count'],proof['new_solid_count'])==(106,132,118,14,33,27)
assert proof['changed_solid_ids']==sorted(i['allowed_changed_solid_ids'])
assert proof['all_7_routes_all4NPC_all4portals_exact'] and proof['no_C_compile_or_full_raster_or_collectors']
assert proof['independent_expectation']=={'path':i['independent_expectation_path'],'sha256':sha(prior)}
assert audit['passed'] and audit['Physics_or_Field_credit'] is False and audit['not_whole_scene_route_replay']
expected_finite=[]
for row in i['new_finite_paths']:
    count=sum(math.ceil(math.dist(a,b)/4)+1 for a,b in zip(row['points'],row['points'][1:]))
    expected_finite.append({'id':row['id'],'samples':count,'full875_plus17':True})
assert audit['finite_new_paths']==expected_finite
assert [x['samples'] for x in expected_finite]==[12,12,12,12,12,12,127]
assert audit['finite_body_samples']==sum(x['samples'] for x in expected_finite)==199
expected_inherited=[{'id':row['id'],'segment':k} for row in p['exact_7_routes'] for k in range(len(row['points'])-1)]
assert len(expected_inherited)==23 and audit['inherited_original_segments']==expected_inherited and audit['affected_original_segments']==[]
assert audit['four_idle_people_and_approaches_inherited']==[
    {'id':n['npc_id'],'foot':n['foot_px'],'approach':n['approach_px'],'idle_only':True}
    for n in p['exact_4_people_and_approaches']]
assert audit['five_adult_door_measurements_inherited'] is True
artifacts=[]
assert len(r['artifacts'])==4
for ap,h in r['artifacts'].items():
    assert ap.startswith('res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/output_crossings6/native/')
    assert sha(path(ap))==h
    artifacts.append({'path':ap,'sha256':h,'bytes':path(ap).stat().st_size})
assert {Path(a['path']).name for a in artifacts}=={'layout.res','scene.res','packet.bin','walk.png'}
manifest_path=path(r['manifest_path']);manifest=json.loads(manifest_path.read_bytes())
assert manifest['status']=='BUILD_ONLY_A2_NATIVE_MASK_MATERIAL_ART_AND_RUNTIME_PENDING' and manifest['formal_enabled'] is False
assert manifest['artifacts']==r['artifacts'] and manifest['mask_sha256']==m['expected_child_RGBA_sha256']
assert manifest['finite_proof']==proof and manifest['source_first']==r['source_first']
assert manifest['outdoor_ART_pending'] and manifest['runtime_source_closure_pending'] and manifest['Physics_or_Field_pending'] and r['outdoor_ART_pending']
assert manifest['parent_publication']=={'path':i['parent_report'],'sha256':i['source_pins'][i['parent_report']]}
err=Path(proc['stderr_path']);stdout=Path(proc['stdout_path'])
assert sha(err)==proc['stderr_sha256'] and sha(stdout)==proc['stdout_sha256']
stderr=err.read_text(encoding='utf-8')
assert 'WARNING: ObjectDB instances leaked at exit' in stderr
assert stderr.count('WARNING:')==1 and 'ERROR:' not in stderr and 'SCRIPT ERROR' not in stderr
out={'status':'INDEPENDENT_ACTUAL_FINITE_A2_PUBLICATION_ONLY_NOT_ART_RUNTIME_IMPORT_OR_FIELD',
 'actual_result':{'path':'res://'+RESULT.relative_to(GAME).as_posix(),'sha256':sha(RESULT)},
 'Root_process_receipt':{'path':'res://'+PROCESS.relative_to(GAME).as_posix(),'sha256':sha(PROCESS),'natural_console_exit':0,'retained_WaitForExit':True,'elapsed_wrapper_wall_ms':proc['elapsed_wall_ms']},
 'actual':{'passed':True,'checks':1941,'elapsed_ms':3624,'limit_ms':60000},
 'source_first_final_current_SHA_exact':{'declared_input_sources':137,'plus_execution_key_and_input':2,'total':139},
 'frozen_independent_prior':{'path':i['independent_expectation_path'],'sha256':sha(prior)},
 'actual_matches_prior_mask':lm,'actual_visual_solid_counts':[106,33,132,27],'new_ground_count':118,'retained_opaque_props':14,
 'six_real_continuous_crossing_paths':i['new_finite_paths'][:6],
 'finite_samples_by_path':expected_finite,'total_new_finite_body_samples':199,
 'new_rack_negative_in_original_executed_key':i['new_negative_feet'],
 'old23_segments_inherited_not_replayed':expected_inherited,'four_idle_NPC_and_approaches_inherited':audit['four_idle_people_and_approaches_inherited'],
 'all4portals_and5door_declarations_inherited_not_actual_travel':True,
 'whole_native_packet_scene_layout_inverse_executed':True,'artifacts_SHA_bytes_only_no_decode':artifacts,
 'non_admitting_manifest':{'path':r['manifest_path'],'sha256':sha(manifest_path),'formal_enabled':False,'ART_source_closure_Physics_Field_pending':True},
 'logs':{'stderr_sha256':sha(err),'stdout_sha256':sha(stdout),'ObjectDB_exit_warning_count':1,'clean':False},
 'save_boundary':'This finite CPU key suspends checkpoint saves; no independent save-before/after facts in its result. Root external guard remains separate, no save-equality credit fabricated here.',
 'stopped_predecessor_failures_preserved':['Python local ray-predicate1px FAIL','Original x400 cart conflict','Unexecuted C0A3stand input not actual','Reviewer header-placeholder FAIL and old470 uniqueness assertion FAIL'],
 'next_allowed_evidence':'Root one contextual same-camera GPU ART check against these immutable4 artifacts; no repeat ABI/PNGdecode/875/native publication.',
 'engine_runs_this_review':0,'PNG_decode':0,'ABI_runs':0,'87517_replay':0,'native_packet_decode':0,'collector_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'source_total':139,'finite_samples':199,'native_artifacts':4,'engine':0,'clean':False}))
