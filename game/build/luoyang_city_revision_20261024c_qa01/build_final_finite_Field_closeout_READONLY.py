"""Final small actual/retained-process/guard review. No engine/media decoding."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
ROOT=GAME/'build/luoyang_city_revision_20261024c_root01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def read(p,h):
    assert sha(p)==h,(p,sha(p));return json.loads(p.read_text(encoding='utf-8'))
def actual(rel,h,receipt_name,expected_exit):
    rp=BASE/rel;r=read(rp,h)
    pp=ROOT/receipt_name;p=json.loads(pp.read_text(encoding='utf-8'))
    assert p['exit_code_from_retained_process_WaitForExit'] is True and p['actual_natural_console_exit_code']==expected_exit
    assert p['process_stopped_by_tool'] is False and p['script_sha256']==p['script_after_sha256']
    log=Path(p['stderr_path']);out=Path(p['stdout_path'])
    assert sha(log)==p['stderr_sha256'] and sha(out)==p['stdout_sha256']
    lines=log.read_text(encoding='utf-8').splitlines()
    counts={k:sum(x.startswith(k+':') for x in lines) for k in ['ERROR','WARNING','SCRIPT ERROR']}
    assert counts=={'ERROR':7,'WARNING':0,'SCRIPT ERROR':0},counts
    assert r['source_before']==r['source_after'] and r['players_before']==r['players_after'] and len(r['players_before'])==15
    return r,dict(result=dict(path=res(rp),sha256=h),process=dict(path=res(pp),sha256=sha(pp)),
        complete=r['complete'],checks=r['checks'],failures=r['failures'],elapsed_ms=r['elapsed_ms'],
        true_console_exit=expected_exit,stderr_counts=counts,clean_exit=False,
        own_source_first_final_same_count=len(r['source_before']),own_save15_first_final_same=True)
def main():
    first,fr=actual('finite_Field_READY01/yamen_courts/output_READY/43628_2926/result.json',
        '48761b930f69c867ffd020f3c7f08773531d089ca6b69e7dcb2149f0653e5f10','yamen_finite_Field_once_process_receipt.json',1)
    remaining,rr=actual('finite_Field_remaining_READY01/output_READY/112620_2770/result.json',
        '5a19b43a509f37b6bbf992b294a32c081bed98f3ba6d17ea5d0f2820fd853036','yamen_remaining_Field_once_process_receipt.json',0)
    scholar,sr=actual('finite_Field_READY01/scholar_portrait/output_READY/51180_2778/result.json',
        '12eca74c04726eea875526558c1ad9d922abd40ed0a2b60c9b5fe870e500fc63','scholar_finite_Field_once_process_receipt.json',0)
    assert (first['complete'],first['checks'],first['failures'])==(False,40,2)
    assert (remaining['complete'],remaining['checks'],remaining['failures'],remaining['elapsed_ms'])==(True,85,0,14598)
    assert (scholar['complete'],scholar['checks'],scholar['failures'],scholar['elapsed_ms'])==(True,35,0,12024)
    rows=remaining['records'];ident=[x['identity'] for x in rows if x['kind']=='REMAINING_PASSIVE_OWNER_ONLY']
    assert len(ident)==2 and ident[0]==ident[1] and ident[0]['source_count']==1319
    setups=[x for x in rows if x['kind']=='APPROVED_QA_INSPECTION_SETUP_NOT_TRAVEL']
    assert len(setups)==2 and [x['actual'] for x in setups]==['(590.0, 1048.0)','(2664.0, 1098.0)']
    legs=[x for x in rows if x['kind']=='REAL_INPUT_ONLY_FINITE_SEGMENT']
    assert len(legs)==2 and [(x['start'],x['end']) for x in legs]==[('(590.0, 1048.0)','(590.0, 1135.0)'),('(2664.0, 1098.0)','(2664.0, 1260.0)')]
    assert [len(x['samples']) for x in legs]==[11,22]
    scope=[x for x in rows if x['kind']=='FINITE_24C_ONLY'][0]
    assert (scope['real_INPUT_ticks'],scope['Physics_queries'],scope['local_mask_samples'],scope['pictures'])==(33,41,697,1)
    npcs=[x for x in rows if x['kind']=='MAPPED_ORIGINAL_NINE_NPC_LOOKUP_SOURCE_PROOF'][0]['rows']
    assert len(npcs)==9 and sum(x['lookup_found'] for x in npcs)==7
    assert all(x['lookup_found'] for x in npcs[:6])
    assert npcs[3]['runtime_id']=='district_life_yamen_clerk' and npcs[3]['actual_foot']=='(1130.0, 1360.0)'
    assert all(x.get('meaning')=='LOOKUP_ABSENT_NOT_VALIDATED_QUESTGATE' for x in npcs if not x['lookup_found'])
    east=[x for x in rows if x['kind']=='LOCAL_PNG_NOT_WHOLE_CITY_ART'][0]
    assert east['sha256']=='f279a73b2e098c7d7ce77c780952bee12321fef6ac40af25087b13f3d15a4253'
    dialogs=[x for x in scholar['records'] if x['kind']=='NATURAL_DIALOG_NODE_UI']
    portrait='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png'
    assert [x['node'] for x in dialogs]==['npc_opening_20261024b_hero','x_0_menu']
    assert dialogs[0]['portrait_visible'] is True and dialogs[0]['choices_visible'] is False
    assert dialogs[1]['active_npc']=='luoyang_paper_scholar' and dialogs[1]['portrait_resource']==dialogs[1]['signal']['portrait']==portrait
    assert dialogs[1]['portrait_visible'] is True and dialogs[1]['choices_visible'] is True and len(dialogs[1]['choices'])==3
    assert dialogs[1]['pending_side_offer']==''
    owners=[x for x in scholar['records'] if x['kind']=='NATURAL_LOCAL_CITY_FINAL']
    assert len(owners)==2 and owners[0]['Scene']==owners[1]['Scene'] and owners[0]['layout']==owners[1]['layout'] and all(x['count']==1823 for x in owners)
    ss=[x for x in scholar['records'] if x['kind']=='FINITE_24C_ONLY'][0]
    assert ss['pictures']==ss['real_INPUT_ticks']==ss['Physics_queries']==ss['quest_accept_or_reward_calls']==0
    gp=ROOT/'post_Field30_guard_actual.json'
    g=read(gp,'55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1')
    assert g['passed'] is True and g['checked']==2120 and g['authorized_target_count']==30 and g['save_count']==15 and g['save_exact'] is True
    assert g['Stage_source_count']==3190 and g['Stage_source_first_final_was_equal'] is True and g['full30_backup_sha_bytes_exact'] is True
    assert g['unexpected']==[] and len(g['authorized_changed'])==30
    report=dict(status='24C_FINITE_COMPONENT_CLOSEOUT_NOT_WHOLECITY_OR_CLEAN_EXIT',
        first_Yamen_wholeFAIL_retained=fr,Yamen_remaining_component=rr,Market_scholar_component=sr,
        passed_components=dict(
            prefix='Natural1319 + finalized40/10 lease, two exact existing source sprites/.5, two corresponding newbase Physics/polygon negatives and original hall1536,660 passed in43628; not repeated.',
            remaining='Two explicitly approved QA setups, not continuous travel; real INPUT west1048->1135/east1098->1260. Same Field/Player/Scene/layout/token/mask,33INPUT/41Physics/697localmask. Existing western image not repeated.',
            NPC='Correct source prefix maps all six district_life_ rows; six + native patrol found active, clerk1130,1360 correct. Two other lookups absent/UNKNOWN, not validated quest gating.',
            scholar='Real Space hero opening -> exact new scholar TextureRect and text_displayed portrait path visible at original x_0_menu -> real KEY3 leave; original state unchanged,1823 natural owners same,0PNG/no Task acceptance.'),
        original_failure='43628 safe public near fallback was not exact source path start; strict QA start refused before INPUT. Keep wholeFAIL40/2, not a failed navigation crossing or erased by residual.',
        images=dict(QA_viewed_west_original=True,QA_viewed_east_original=True,east=east,
            finite_observation='Both official annexes read as complete one-storey buildings at matching scale; doors/steps and side-wall clearance readable. East image confirms full roof and wall recess. Large empty stone paving, repetitive/hard surface divisions and disconnected wall ends still visible; NOT wholecourtyard/world ART.'),
        final_protection=dict(path=res(gp),sha256=sha(gp),Root_guard_declared_Stage_sources_current_same=3190,protected_checked=2120,authorized_targets=30,save15_SHA_bytes_exactticks_same=True,full30_backups_exact=True,
            boundary='QA only read the fixed guard report; did not rehash3190 sources or backups. Root states post guard is an independent fresh Python read, not a cached pre guard. Equal pre/post file bytes are retained as fact.'),
        explicit_limits=['Every process retains7 renderer/RID/Texture exit ERRORs: true exit0 residual/portrait is not clean wholePASS.',
            'No continuous west-to-east court travel, world default performance or firstload10seconds claim.',
            'No fullcity ART, all9NPC active proof, new Task acceptance/reward, room/old875/fourcollector replay.',
            'Original oracle/publisher/Field prior FAILs and successful components remain separate; no production changes by QA.'],
        QA_operations=dict(engine=0,collector=0,PNG_decode_or_raster_replay=0,packet_decode=0,production_write=0,existing_images_viewed=2),
        action='Stop this finite QA scope; do not retry passed components.')
    target=BASE/'final_courts_scholar_finite_closeout_READONLY.json';assert not target.exists()
    target.write_bytes((json.dumps(report,ensure_ascii=True,indent=2)+'\n').encode())
    print(json.dumps(dict(path=res(target),sha256=sha(target),bytes=target.stat().st_size)))

if __name__=='__main__':main()
