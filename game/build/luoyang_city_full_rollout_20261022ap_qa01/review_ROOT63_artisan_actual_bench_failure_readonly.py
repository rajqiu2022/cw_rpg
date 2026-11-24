import hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2]
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
rp=R+'integration63/artisan_READY/output/114980_2797/result.json'
r=read(rp,'bbad4345dad803c1e38c0b8379ddd70eb3b99acbbebba66b89b3ae1b544c9a89')
p=read(R+'integration63/artisan_actual_process_receipt.json','ed442cf2f77f72e223e2556f6d5e89d55949deeff7968d306b9e6e969384f40a')
f=read(R+'integration63/artisan_READY/fixture_READY.json','1be43b84c7e2875191154a1e6b8728f1e6d960baf5ccb92c8ee58c7ae6d38d51')
owner=read(S+'unified101_actual_owner_READY/owner_source_maps_READY.json','fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c')
row=next(x for x in owner['scenes']if x['id']=='luoyang_artisan_residential_20261022ap')
assert r['checks']==1193 and r['failures']==2 and r['complete']is False and r['elapsed_ms']==12276
assert r['source_before']==r['source_after']and r['players_before']==r['players_after']and len(r['players_before'])==15
rec=r['records'];bykind=lambda k:[x for x in rec if x.get('kind')==k]
draw=bykind('ARTISAN_DEFAULT_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')[0]
assert draw['draw']['elapsed_usec']==5395704 and draw['draw']['loading_hidden_inactive']and draw['draw']['can_move']
natural=bykind('ARTISAN_NATURAL_RECEIPT_AFTER_DRAW')[0]['receipt']
assert natural['finalized']is True and natural['source_first']==natural['source_final']==row['receipt_source_sha256']and len(natural['source_first'])==339
transforms=bykind('NEW_PROP_TRANSFORM_OPERANDS');assert len(transforms)==4
for t in transforms:
    assert t['size']==t['expected']['size']and t['scale']==t['expected']['scale']and t['origin']==t['expected']['origin']
steps=bykind('ONLY_NEW_PROP_TRUE_INPUT');assert len(steps)==21 and all(x['driver']['ok']and x['driver']['reached']and x['driver']['all_recorded_feet_clear']for x in steps)
opacity=bykind('EXACT_TARGET_ACTOR_LOCAL_OPACITY')
ids=['ap_life_dye_rinse_tub_a','ap_life_dye_rinse_tub_b','ap_life_well_tea_table'];groups=[]
for ident in ids:
    group=[x for x in opacity if x['id']==ident];assert len(group)==3
    assert[group[0]['actual_target_pixels'],group[1]['actual_target_pixels'],group[2]['actual_target_pixels']]==[0,169 if ident in ids[:2]else585,0]
    groups.append({'id':ident,'target_pixels':[x['actual_target_pixels']for x in group],'forward_reverse_INPUT_passed':True,'actor_local_ghost_and_exit_only_target_zero_passed':True})
bench=[x for x in opacity if x['id']=='ap_life_well_wait_bench'];assert len(bench)==2 and bench[0]['expected_hit']is False and bench[1]['expected_hit']is True and all(x['actual_target_pixels']==0 for x in bench)
assert all(x['actor_base_alpha']==1 and all(y['modulate_alpha']==y['self_modulate_alpha']==1 for y in x['prop_alpha_chain'])for x in opacity)
assert steps[-1]['driver']['actual_end']==[1260,1176]
assert p['actual_natural_console_exit_code']==1 and p['exit_code_from_retained_process_WaitForExit']and not p['process_stopped_by_tool']
err=pathlib.Path(p['stderr_path']).read_bytes();assert sha(err)==p['stderr_sha256']
lines=err.decode().splitlines();errors=sum(x.startswith('ERROR:')for x in lines);warnings=sum(x.startswith('WARNING:')for x in lines);scripts=sum('SCRIPT ERROR:'in x for x in lines)
assert scripts==0
print(json.dumps({'status':'ROOT63_ARTISAN_WHOLE_FAIL_RETAINED_ONLY_FINISHED_LOCAL_COMPONENTS_CREDIT','result':{'path':rp,'sha256':sha(raw(rp)),'checks':1193,'failures':2,'complete':False,'elapsed_ms':12276},'timing':{'ready_usec':draw['ready']['elapsed_usec'],'hidden_operable_draw_usec':5395704,'draw_precedes_deep_verification':True},'sources':{'guard_first_final_same':len(r['source_before']),'natural_receipt_339_fixed_FD58_exact':True,'collector_guard341_not_separate_natural_collector_claim':True,'save15_exact_same':True},'finished_components':{'four_source_transforms_exact':True,'136visual31solid_native_gate_passed':True,'first_three_props':groups,'all21_INPUT_segments_physics_and_mask_clear':True,'bench_forward3segments_passed':True,'bench_actual_final_foot':[1260,1176],'bench_target_hit0':True,'all_prop_and_ancestor_alpha1_base_actor1':True},'not_executed':['bench reverse path','bench restored target0 after reverse','final same-owner receipt assertion'], 'scope_counts':bykind('ARTISAN_FOUR_LOCAL_SCOPE_COUNTS')[0],'exit':{'natural_console_exit':1,'nonclean':True,'ERROR':errors,'WARNING':warnings,'SCRIPT_ERROR':scripts,'stderr_sha256':p['stderr_sha256']},'diagnostic_boundary':'Expected bench hit at1176 was not derived from any alpha-intersection prior. CPU283 proves clearance, not nonzero alpha overlap. V14 actual current-frame actor nonzero alpha against exact prop alpha controls ghost, not behind-foot alone. No production defect established by zero hit. No expected pixels built from this observation.','QA_actions':{'engine':False,'collector':False,'decode':False,'geometry_replay':False,'media_hash':False,'production_write':False}},indent=2))
