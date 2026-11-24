"""One completed actual review. No engine, collector, geometry or image decode."""
import copy
import hashlib
import json
from pathlib import Path

Q=Path(__file__).resolve().parent;G=Q.parents[1]
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration58'
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=p.read_bytes()
    if h:assert sha(b)==h.lower(),str(p)
    return b
def load(p,h=None):return json.loads(read(p,h))
def ref(p,h=None):return {'path':'res://'+p.relative_to(G).as_posix(),'sha256':sha(read(p,h)),'bytes':p.stat().st_size}

rp=R/'docks_default_READY/output/100500_2807/result.json'
r=load(rp,'f5e2acd544c3bfc7865b8a4ed9740b81a391abae6783427963887865c17da432')
assert r['complete'] is True and r['failures']==0 and r['checks']==3501 and r['elapsed_ms']==26312
def record(kind):
    rows=[x for x in r['records'] if x.get('kind')==kind];assert len(rows)==1,kind;return rows[0]
draw=record('DEFAULT_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')
assert draw['ready']['elapsed_usec']==12996512 and draw['draw']['elapsed_usec']==13103148
assert draw['under10s'] is False and draw['draw']['loading_hidden_inactive'] and draw['draw']['can_move']
assert draw['draw']['foot']=='(2140.0, 1840.0)'
assert draw['draw']['usec']-draw['ready']['usec']==106636
assert 13103148<20000000 and 26312<60000
natural=record('NATURAL_C_FINAL_AFTER_FROZEN_DRAW')
ownerp=S/'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json'
owner=load(ownerp,'c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb')
expected=next(x for x in owner['scenes'] if x['id']=='ch4_s2_canal_docks')['source_sha256']
assert len(expected)==1729 and natural['source_count']==1729 and natural['token']==1 and natural['sources']==expected
assert natural['default_spawn_argument'] is None and natural['test_setup_or_teleport'] is False and natural['test_validator_or_collector_calls']==0
assert natural['warm_return_claim'] is False and natural['actual_foot']=='(2140.0, 1840.0)'
walk=record('FIXED_ONLY32PX_REAL_INPUT_WITH_LIVE_BODY');result=walk['result']
assert result=={'actual_end':[2172.0,1840.0],'all_recorded_feet_clear':True,'first_bad':[],'ok':True,'physics_samples':5,'reached':True,'start':[2140.0,1840.0],'target':[2172.0,1840.0]}
assert walk['Physics_queries']==6 and walk['mask17_observations']==102 and walk['first_bad']=={} and walk['source875_or_geometry_replay'] is False
cam=record('DEFAULT_ORIGINAL_CAMERA_ALL_OPERANDS_BEFORE_CHECK')
assert cam['camera_instance']==cam['active_camera_instance']==cam['first_draw_camera_instance']==draw['draw']['camera_instance']
assert cam['Field_camera_zoom']==cam['scene_camera_zoom']==cam['input_scene_camera_zoom']==cam['expected_camera_zoom']==1.05
assert cam['same_Field'] and cam['same_Scene'] and cam['enabled'] and cam['loading_hidden'] and cam['camera_or_player_writes']==0
assert cam['viewport']=='(1920.0, 1080.0)' and cam['zoom']=='(1.05, 1.05)' and cam['camera_position']=='(0.0, 0.0)'
pic=record('DEFAULT_ONE_IMAGE_NOT_FULL_ART_APPROVAL');png=G/pic['path'][6:]
read(png,'53e6864cb788372afb73db2fe4649785994e217b7ef5e0dbd08abc19bb720fe4')
assert pic['sha256']==sha(png.read_bytes()) and pic['pictures_total']==1 and pic['camera_instance']==cam['camera_instance']
scope=record('DOCKS_ONLY_TERMINAL_DIAGNOSTIC_SCOPE_COUNTS')
assert scope['public_requests']==scope['pictures']==1 and scope['INPUT']==5 and scope['Physics']==6 and scope['mask']==102
assert all(scope[k]==0 for k in ['Space','collector','native_decode','position_writes','rooms','validator'])
assert r['source_before']==r['source_after'] and len(r['source_before'])==1734
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
assert all(r['source_before'][p]['sha256']==h for p,h in expected.items())

fp=R/'docks_default_READY/fixture_READY.json'
fixture=load(fp,'bce6fc92d16c9a637a8ab7d00ec9ddbf2096ba509ba00e9f95b8f2562b46ce36')
pendingp=Q/'docks_ordinary21_default_entry_NOTREADY/fixture_NOTREADY.json'
pending=load(pendingp,'0aed3319110fb70c557572fb53b96e1df4544b56102b933085a450e7c2f167f3')
assert fixture['source_sha256']==fixture['legs'][0]['expected_sources']==expected and fixture['expected_guard_count']==1729
inversefix=copy.deepcopy(fixture)
for k in ['ready','status','blockers','Root_fresh_before','Root_deployment_final']:inversefix[k]=pending[k]
assert inversefix==pending
kp=R/'docks_default_READY/test_docks_default_READY.gd'
key=read(kp,'bf8da888d4f8aa97397f4f9e497a64dbebe0120e0818683dca0b34f968f1c3e4')
oldkey=read(Q/'docks_ordinary21_default_entry_NOTREADY/test_docks_default_ordinary21_NOTREADY.gd','edec16ce5ab6fc4c928594b2135493b789559a3a64961e1d16ae3e1563d7b3fc')
ops=[(b'const FIXTURE_READY=false',b'const FIXTURE_READY=true'),
     (('res://'+pendingp.relative_to(G).as_posix()).encode(),('res://'+fp.relative_to(G).as_posix()).encode()),
     (sha(pendingp.read_bytes()).encode(),sha(fp.read_bytes()).encode()),
     (b'res://build/luoyang_city_full_rollout_20261022ap_qa01/docks_ordinary21_default_entry_NOTREADY/output_NOTREADY',b'res://build/luoyang_city_full_rollout_20261022ap_root01/integration58/docks_default_READY/output')]
back=key
for a,b in reversed(ops):assert back.count(b)==1;back=back.replace(b,a,1)
assert back==oldkey

pp=R/'actual_default_docks_process_receipt.json'
proc=load(pp,'d8ce1e1a6e403e19a199271e9ec0d8aca04bc899050a45cc7d6669130a0f5b55')
assert proc['actual_natural_console_exit_code']==-1073741819 and proc['exit_code_from_retained_process_WaitForExit'] is True and proc['process_stopped_by_tool'] is False
assert proc['script_sha256']==proc['script_after_sha256']==sha(key)
stderr=read(R/'actual_default_docks_stderr.log');stdout=read(R/'actual_default_docks_stdout.log')
assert sha(stderr)==proc['stderr_sha256'] and sha(stdout)==proc['stdout_sha256']
errlines=stderr.decode('utf-8-sig').splitlines()
errors=sum(x.startswith('ERROR:') for x in errlines);warnings=sum(x.startswith('WARNING:') for x in errlines)
scripts=sum('SCRIPT ERROR:' in x for x in errlines)
assert errors==12 and warnings==2 and scripts==0
before=load(R/'guard_before.json','1e7680a53450421d48c41b1de839df43cd54aec17ea2deba7aa908f9fccbf3f1')
after=load(R/'final_guard.json','1d5c07122349cff5f7a01e44258efb536c13690c75966054e98a35612a466d9e')
assert before['passed'] and after['passed'] and before['checked']==after['checked']==2118
assert before['facts']==after['facts'] and after['exact_unchanged']==2118 and after['save_count']==15 and after['save_change_count']==0
assert after['authorized_change_count']==after['unexpected_change_count']==0
threebefore=load(R/'source_only_three_facts_before.json');threeafter=load(R/'source_only_three_facts_after.json')
assert threebefore['facts']==threeafter['facts'] and len(threebefore['facts'])==3
assert threebefore['runtime_texture_credit'] is False and threeafter['runtime_texture_credit'] is False

review={'status':'INDEPENDENT_ROOT58_DOCKS_DEFAULT_LOCAL_FUNCTIONAL_PASS_PROCESS_NONCLEAN_FIRST_OVER10_RETAINED',
        'actual':ref(rp),'functional_component_complete':True,'checks':3501,'failures':0,'functional_elapsed_ms':26312,
        'ready_usec':12996512,'hidden_operable_postdraw_usec':13103148,'ready_to_hidden_draw_usec':106636,
        'entry_under_original20s':True,'whole_function_under_original60s':True,'firstdraw_under10s':False,
        'timing_boundary':'Single public default entry after prechecks, not world travel/SSD cold or stable statistical speedup. Deep source comparison, INPUT and capture occur after the frozen13.103148s draw. Do not call the26.312s functional report duration the draw time.',
        'ordinary_default_and_source':{'public_requests':1,'spawn_argument':None,'formal_source_count':1729,'natural_C_token':1,'whole_expected_map_exact_independent_owner95':True,'default_foot':[2140,1840],'raw_input_old340_not_actual_default':True,'warm_or_room_credit':False},
        'local_true_INPUT':{'start':[2140,1840],'end':[2172,1840],'physics_samples':5,'live_body_Physics_queries':6,'existing_mask_observations':102,'original_body':[34,24],'all_clear':True,'geometry875_replay':False,'Space_or_room':False},
        'original_camera':{'zoom':1.05,'viewport':[1920,1080],'same_active_instance_before_after':True,'writes':0},
        'single_original_image':ref(png),
        'image_readonly_observation':'Reviewed only this existing image once. A distinct waterfront building, two boats/water, rope/plank mooring area, crates and named dock workers are visible with an open lane. Repeated gray stone remains extensive; straight/jagged bank treatment and sparse working detail remain visible limitations. This is local current-frame evidence, not whole-district/city ART approval or a new pixel analysis.',
        'source_facts_before_after_SHA_bytes_seconds_same':1734,'player_saves_report_seconds_same':15,
        'Root_guard_before':ref(R/'guard_before.json'),'Root_guard_after':ref(R/'final_guard.json'),
        'Root_guard_2118_SHA_bytes_exactticks_same':True,'Root_guard_save15_exactticks_same':True,
        'three_SOURCE_ONLY_facts_before_after_same':True,'three_proof_after':ref(R/'source_only_three_facts_after.json'),
        'freeze_whole_key_four_literal_inverse_and_fixture5fields_inverse':True,
        'process_receipt':ref(pp),'true_exit':-1073741819,'true_exit_hex':'C0000005','process_wall_ms':proc['elapsed_wall_ms'],
        'nonclean':{'ERROR_lines':12,'WARNING_lines':2,'SCRIPT_ERROR_lines':0,'WASAPI_dummy_fallback':True,'shader_Texture_RID_resource_exit_leaks':True,'ObjectDB_exit_warning':True,'stderr':ref(R/'actual_default_docks_stderr.log'),'exit_fault_root_cause_proven':False},
        'whole_clean_runtime_or_allcity_PASS':False,'Root53_original_failed_entry_retained':True,
        'QA_actions':{'new_engine_or_test':0,'collector_geometry_route_replay':0,'packet_or_runtime_texture_decode':0,'existing_image_view':1,'image_edits':0,'source_or_production_writes':0}}
out=Q/'docks_ROOT58_actual_default_1729_local_function_nonclean_review_READY.json'
assert not out.exists()
txt=json.dumps(review,ensure_ascii=False,indent=2)+'\n'
patch='*** Begin Patch\n*** Add File: '+str(out).replace('\\','/')+'\n'+''.join('+'+x+'\n' for x in txt.splitlines())+'*** End Patch'
print(json.dumps({'patch':patch,'summary':{'functional_component':True,'draw_sec':13.103148,'under10':False,'natural_sources':1729,'input_samples':5,'Physics':6,'mask':102,'source_facts':1734,'save15':True,'guard2118':True,'errors':errors,'warnings':warnings,'script_errors':scripts,'exit':proc['actual_natural_console_exit_code'],'whole_clean_pass':False}}))
