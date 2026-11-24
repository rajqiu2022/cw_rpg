"""NEW read-only evidence summary only. No game/engine/media decode or writes.
Three already-produced PNGs were visually inspected by QA before this summary.
"""
from pathlib import Path
import hashlib,json,re
Q=Path(__file__).resolve().parent;GAME=Q.parent.parent
ROOT=GAME/'build/luoyang_city_revision_20261024b_root01'
OUT=Q/'final_market_limited_component_closeout_READONLY.json'
def sha(raw): return hashlib.sha256(raw).hexdigest()
def res(p): return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def read(p,h=None):
    raw=p.read_bytes();actual=sha(raw)
    if h: assert actual==h,(p,h,actual)
    return json.loads(raw),actual
def native_path(p): return GAME/p[6:] if p.startswith('res://') else Path(p)

def main():
    assert not OUT.exists(),'NEW review only; preserve all original artifacts'
    definitions=[
      ('root_market_journey18_ground_READY/output_READY/67928_2743/result.json','e63fcb1ff64ab4f61e7efd86bd6dbabc472ba4226315f7a6518217a1214bed00','market_ground_journey_once_process_receipt.json',88,2,17774,1,35),
      ('market_remaining_vendor_task_READY/output_READY/27636_2764/result.json','0e3820d5888b7e4f9ac999c563ee68cb1fca8888a2cee5f14cbedabde9615be6','market_remaining_street_dialogue_once_process_receipt.json',574,2,21087,1,38),
      ('market_dialogue_only_remaining_READY/output_READY/112496_2730/result.json','a7f54a1633851b1ab917ca15a28ccc3467a917c2361228bc38c8c6eddebe0d19','market_dialogue_remaining_once_process_receipt.json',165,2,14891,1,40),
      ('market_task_decline_only_remaining_READY/output_READY/124704_2749/result.json','2872db18f7ff2c65d2218b7e6ed023dab22b80af42bcf26e0a5864db139bead1','market_task_decline_remaining_once_process_receipt.json',79,0,12721,0,45)]
    runs=[];full=[];pictures=[]
    for name,h,rname,checks,failures,elapsed,exitcode,count in definitions:
        data,rsha=read(Q/name,h);receipt,psha=read(ROOT/rname)
        assert (data['checks'],data['failures'],data['elapsed_ms'])==(checks,failures,elapsed)
        assert data['complete'] is (failures==0)
        assert len(data['source_before'])==count and data['source_before']==data['source_after']
        assert len(data['players_before'])==15 and data['players_before']==data['players_after']
        assert receipt['actual_natural_console_exit_code']==exitcode and receipt['exit_code_from_retained_process_WaitForExit'] is True
        assert receipt['process_stopped_by_tool'] is False and receipt['script_sha256']==receipt['script_after_sha256']
        assert sha(native_path(receipt['script']).read_bytes())==receipt['script_sha256']
        stderr=Path(receipt['stderr_path']).read_bytes();stdout=Path(receipt['stdout_path']).read_bytes()
        assert sha(stderr)==receipt['stderr_sha256'] and sha(stdout)==receipt['stdout_sha256']
        text=stderr.decode('utf-8-sig')
        errors=len(re.findall(r'(?m)^ERROR:',text));warnings=len(re.findall(r'(?m)^WARNING:',text));scripts=len(re.findall(r'(?m)^SCRIPT ERROR:',text))
        assert errors==7 and scripts==0 and warnings==(1 if checks==165 else 0)
        natural=[r for r in data['records'] if r.get('kind')=='NATURAL_CITY_OWNER_ONLY']
        assert natural and all(r['source_count']==1813 and r['token']=='1' for r in natural)
        for record in data['records']:
            if record.get('kind')=='FINITE_ACTUAL_PNG_NOT_WHOLECITY_ART':
                p=native_path(record['path']);assert sha(p.read_bytes())==record['sha256']
                pictures.append({'path':record['path'],'sha256':record['sha256'],'visual_inspection':'QA inspected original1920x1080 output, no crop/repaint'})
        runs.append({'result':{'path':res(Q/name),'sha256':rsha},'retained_process':{'path':res(ROOT/rname),'sha256':psha},
          'checks':checks,'failures':failures,'complete':data['complete'],'elapsed_ms':elapsed,'true_natural_console_exit':exitcode,
          'stderr_counts':{'ERROR':errors,'WARNING':warnings,'SCRIPT_ERROR':scripts},'exit_clean':False,
          'source_facts_count':count,'source_facts_before_after_identical':True,'fifteen_save_facts_before_after_identical':True,
          'Godot_mtime_granularity':'seconds; not rewritten as per-run nanosecond/ticks proof',
          'natural_city_records':len(natural),'natural_city_source_count':1813,'object_ID_numbers_not_transcribed':True,
          'QA_failure_messages':[line for line in text.splitlines() if 'CITY_LIFE_QA_FAIL' in line],
          'final_scope_counters':data['records'][-1]})
        full.append(data)
    assert len(pictures)==3
    room=full[0]['records'];room_sessions=[x for x in room if x.get('kind')=='ONLY_NATURAL_ROOM_SESSION']
    assert len(room_sessions)==1 and room_sessions[0]['finalized'] is True
    assert len([r for r in room if r.get('kind')=='EXITS_BEFORE_EXACT_FILTER' and r['found_count']==1])==2
    city_owners=[x for x in room if x.get('kind')=='NATURAL_CITY_OWNER_ONLY'];assert city_owners[0]['ids']==city_owners[1]['ids']
    street=[x for x in full[1]['records'] if x.get('kind')=='REAL_INPUT_ONLY_FINITE_SEGMENT']
    assert street[-1]['end']=='(1286.192, 1730.0)' and street[-1]['target']=='(1070.0, 1730.0)'
    vendor=[x for x in full[2]['records'] if x.get('kind')=='NATURAL_DIALOG_NODE_UI']
    assert [x['node'] for x in vendor[:5]]==['npc_opening_20261024b_hero','start','reply','npc_opening_20261024b_hero','npc_opening_20261024b_rumor']
    assert all(not x['choices_visible'] for x in vendor[:5])
    route=[x for x in full[2]['records'] if x.get('kind')=='REAL_INPUT_ONLY_FINITE_SEGMENT']
    assert [x['end'] for x in route]==['(780.0, 1260.0)','(780.0, 1400.0)','(520.0, 1400.0)']
    task=[x for x in full[3]['records'] if x.get('kind')=='NATURAL_DIALOG_NODE_UI']
    assert [x['node'] for x in task]==['npc_opening_20261024b_hero','x_0_menu','start','offer']
    assert task[-1]['script']=='ch4_city_tasks_20261016_paper_offer' and task[-1]['choices_visible'] is True
    waiter='res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png'
    assert next(x for x in task if x['node']=='x_0_menu')['portrait_resource']==waiter
    stage_defs=[('deployment36_actual.json','86795b49c9e4cec9a97c5342f28237638cb08fdc2f1415e9a60226dda2ac2067',36,3149,1797),
      ('deployment35_worker_facts_actual.json','a93d0241fcb35cbaa5e4c4e31384495fd2b4f4d7c55ef3838b384ca075280d62',35,3168,1808),
      ('deployment27_packed_actual.json','5609f29545c381f51d1497dba77d055301771a0ae4f8d347671774cf59c35834',27,3159,1813),
      ('deployment18_env_actual.json','6ec5f085a46e3ced5e6debc935c2ae68a8ed4604c91f97ff2d6647a5bda9a211',18,3144,1813)]
    stages=[]
    for name,h,count,source_count,map_count in stage_defs:
        deployment,dsha=read(ROOT/name,h);stage,ssha=read(native_path(deployment['stage']['path']),deployment['stage']['sha256'])
        assert deployment['passed'] is True and len(deployment['targets'])==count and stage['target_partition']['total']==count
        assert stage['source_first']==stage['source_final'] and len(stage['source_first'])==source_count
        stage_targets={x['target']:x for x in stage['targets']}
        assert len(stage_targets)==count
        for row in deployment['targets']: assert row['candidate_sha256']==row['actual_sha256']==stage_targets[row['target']]['candidate_sha256']
        node=stage['nodes']['expected_ch4_s3_luoyang_market_true'];assert len(node['value']['source_sha256'])==map_count
        stages.append({'deployment':{'path':res(ROOT/name),'sha256':dsha},'stage':{'path':deployment['stage']['path'],'sha256':ssha},
          'partition':stage['target_partition'],'declared_source_first_final_same':True,'declared_source_count':source_count,
          'Market_declared_source_count':map_count,'Root_retained_all_targets_match_stage':True,'QA_current_full_source_rehash':False})
    guard,gh=read(ROOT/'final_guard_all_successors_actual.json','90d05aad055c965a11c4eaaee552062f22507cfcd34b0e48b2584bfd845d7a55')
    assert guard['passed'] is True and guard['all36_union_current_expected'] is True
    assert guard['protected_count']==2120 and guard['unchanged_facts']==2085 and len(guard['authorized_existing_changes'])==35
    assert guard['latest15saves_exact_sha_bytes_ticks'] is True and guard['UI_extra_target_separately_in_union36'] is True
    assert guard['unique_source_files_checked']==3342 and guard['original_backup_count']==116
    report={'status':'FINITE_COMPONENTS_REVIEWED_WITH_PRESERVED_WHOLEFAILS_NOT_WHOLECITY_COMPLETE',
      'review_method':'Read existing result/key/process/log/Stage/deployment/guard JSON; visually inspect three original PNGs. No engine/collector/packet/image-raster recomputation or production write.',
      'runs':runs,'four_formal_stage_successors':stages,
      'components':{
        '67928_room':'Exact door/real Space in, natural finalized room, real short exit, Space warm return same Field/Player/Scene/layout passed. WholeFAIL preserved: QA incorrectly expected cold authored foot for warm remembered arrival.',
        'warm_arrival_source_contract':'Router640-659 arrival=remembered for room; authored==resident.authored_exit and remembered==resident.return_spawn separately. Field resident_resume assigns spawn*world_size. No production change.',
        '27636_street':'Threshold reverse and streetPNG passed; y1730 toward1070 stopped at x1286.192. No unique actual colliderID recorded; source NPC1260,1720 is a consistent explanation, not a uniquely measured collider claim. WholeFAIL retained.',
        '112496_vendor_and_walk':'Two hero/vendor daily/reply and hero/attributed-rumor openings, correct female vendor portrait and no choices passed. Three real Input segments7101260->7801260->7801400->5201400 passed (61movement steps/65bodyPhysics/1105mask checks). WholeFAIL retained only at QA menu node expectation.',
        '124704_task':'New independent scholar-near run: hero->source-derived x_0_menu three choices->KEY1 original paper start/offer->KEY2 decline. Functional79/0; unchanged flags/quests/inventory assertions,45smallsource facts and15save facts same;0movement/0PNG. Does not erase112496 FAIL.',
        'task_offer_UI':'Original pending side-offer UI is checked by actual DialogBox labels and pending quest ID, not by node.choices (offer node.choices remains empty). No accept/reward calls.',
        'retained_nonclean_exit':'All four have7 renderer/texture exit ERROR lines;112496 also1WARNING. True exits1,1,1,0. No Script ERROR. Final functional PASS is not process-clean PASS.'},
      'three_original_images':pictures,
      'QA_visual_findings':{
        'street_limited':'Two complete shop facades/doorways are readable beside adult sprites; spacing and local interaction view readable at original camera. No whole-street approval.',
        'vendor_limited':'Both original dialogue images show the matching elderly female vegetable vendor portrait, readable daily text and explicitly attributed unverified rumor. No choices displayed on these two lines.',
        'remaining_art_issues':['Hard rectangular pavement/material boundaries remain conspicuous.','Large sparse empty stone areas remain.','Scholar task menu still uses old inn-waiter portrait; no dedicated scholar portrait acceptance.','Four small subsidiary buildings were not redesigned in this batch.'],
        'PNG_no_edit':True},
      'protection':{'Root_final_guard':{'path':res(ROOT/'final_guard_all_successors_actual.json'),'sha256':gh},
        'Root_verified_source_files':3342,'Root_verified_original_backups':116,'latest_protected_domain':2120,'authorized_existing_differences':35,'unchanged_facts':2085,
        'UI_separately_checked_in_formal_union36':True,'latest15save_SHA_bytes_exactticks_same':True,
        'save_boundary':'Root comparison is Latest667A only, explicitly not old initial two-save differences. Per-run Godot reports separately show their own15save facts unchanged.',
        'QA_did_not_rehash_all3342_or_backups':True},
      'not_accepted':['No continuous apothecary-to-vendor journey completion; blocked street connection remains unresolved.',
        'No default/cold/warm loading performance or under10s claim from these explicit-near residuals.',
        'No whole-city functionality/ART completion or four-small-buildings/unique-scholar-portrait fix.',
        'No rewriting old67928/27636/112496 wholeFAIL reports as PASS.'],
      'stop':'No retries or further production/test modifications requested; this NEW summary is the only output.'}
    with OUT.open('xb') as stream: stream.write((json.dumps(report,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
    print(json.dumps({'review':res(OUT),'sha256':sha(OUT.read_bytes()),'final_task_functional_pass':True,'whole_journey_pass':False,'process_clean':False,'QA_engine_calls':0}))
if __name__=='__main__': main()
