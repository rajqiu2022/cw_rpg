"""Review tiny completed publication records only; never read a packet or raster."""
import hashlib
import json
from pathlib import Path

Q=Path(__file__).resolve().parent;G=Q.parents[1]
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration59'
Y=G/'build/luoyang_city_full_rollout_20261022ap_system01'
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
A=R/'artisan_life_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=p.read_bytes()
    if h:assert sha(b)==h.lower(),str(p)
    return b
def load(p,h=None):return json.loads(read(p,h))
def ref(p,h=None):return {'path':'res://'+p.relative_to(G).as_posix(),'sha256':sha(read(p,h)),'bytes':p.stat().st_size}

rp=A/'output/runs/39704_1734/result.json'
r=load(rp,'8627107dc1a9a7973a331d4538e32384afe44474b1f9babadc9dcc1a8e337fc6')
assert r['passed'] is True and r['published'] is True and r['error']=='' and r['checks']==9296 and r['elapsed_ms']==658
assert r['formal_enabled'] is False and r['ART_Field_runtime_source_pending'] is True
assert r['whole_packet_inverse'] is True and r['whole_scene_layout_inverse'] is True
assert r['old_geometry_recompile_fullraster_collector_Physics_Field_import_calls']==0
p=r['finite_proof'];priorp=Q/'artisan_life_independent_four_polygon_pixel_prior_READY_NOT_RUNTIME.json'
prior=load(priorp,'3eb82257dc87d92fa354ac3340d99b5d41dd82d77b60fecb2bac92c85b1cc48e')
assert p['independent_prior']=={'path':'res://'+priorp.relative_to(G).as_posix(),'sha256':sha(priorp.read_bytes())}
assert p['native_f32_polygons']==prior['polygons'] and p['domains_closed']==prior['domains_closed']
assert [p[k] for k in ['old_visual_count','new_visual_count','old_solid_count','new_solid_count','ground_count_unchanged','low_opaque_props']]==[132,136,27,31,118,18]
assert p['original_a2_finite_proof_wholetyped_retained'] is True and p['whole_scene_layout_inverse'] is True and p['Physics_Field_ART_or_runtime_credit'] is False
mask=p['local_mask']
assert mask['changed_pixels']==prior['changed_pixels']==6735 and mask['visited_pixels']==prior['union_visited_pixels']==8714
assert mask['child_rgba_sha256']==prior['expected_child_RGBA_sha256']=='c0c5a42ceb22326da932e146a4a1c233dfc3c0a8206d2e977f32137293d369f8'
assert mask['parent_rgba_sha256']==prior['parent_rgba_sha256']=='ba3713f65664983e9825187d722fe7d679fc604c2a5a07c6a403e597b4b366c1'
assert mask['domain_count']==4 and all(mask[k] is True for k in ['old27_or_old_routes_not_rasterized','only_white_to_black','outside_all4_domains_exact','whole_RGBA_inverse'])
local=p['local_finite_body']
assert local['finite_body_samples']==283 and local['four_negative_bodies_rejected'] is True and local['Physics_or_Field_credit'] is False
assert [x['samples'] for x in local['finite_new_paths']]==[60,80,68,75] and sum(x['samples'] for x in local['finite_new_paths'])==283
assert all(x['full875_plus17'] is True for x in local['finite_new_paths'])
authorp=Y/'artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json'
author=load(authorp,'1dd5a3949e36ecbada0b4a73f2c109cc1561572b64e3cd8a3e49fa4e2c21df09')
expected_segments=[{'id':route['id'],'segment':i} for route in author['scenes'][0]['routes'] for i in range(len(route['points'])-1)]
inherit=p['inherited']
assert len(author['scenes'][0]['routes'])==7 and len(expected_segments)==23 and inherit['original7_route_segments_inherited']==expected_segments
assert inherit['old_geometry_not_resampled'] is True and inherit['original4portals_plus10_plus24_inherited'] is True
assert len(inherit['original4NPC34x30_and48approaches_inherited'])==4 and len(inherit['original5_door_aprons_inherited'])==5

inputp=A/'input_READY.json';input_raw=read(inputp,'322ae6f9ed3b0a1bd1b6d72fcaa63ab4d4fabdcfa429614316375d27e1b51be1');cfg=json.loads(input_raw)
expected=dict(cfg['source_pins']);expected['res://'+inputp.relative_to(G).as_posix()]=sha(input_raw)
expected[cfg['independent_prior']['path']]=cfg['independent_prior']['sha256']
pubp=A/'publisher_READY.gd';pub=read(pubp,'98272a658e9ec52b0063e2b1ed5c3ce0470adb375eaa0991866e427d02fe04be')
expected['res://'+pubp.relative_to(G).as_posix()]=sha(pub)
assert len(expected)==20 and expected==r['source_first']==r['source_final']
original_pub=read(Y/'artisan_life_delta_publication_epoch01/publisher_NOTRUN.gd','7916bf28eba031751fc2e8709513a0dc5a246bee5523dd4f989b71badf1ba707')
ops=[(b'const READY=false',b'const READY=true'),
     (b'res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/input_NOTREADY.json',('res://'+inputp.relative_to(G).as_posix()).encode()),
     (b'dfc8e7367e25b70c77f41ee8df48833b5d773ad2d710d0a567d43eda8bf4b37e',sha(input_raw).encode()),
     (b'res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/output_NOTRUN/',('res://'+(A/'output').relative_to(G).as_posix()+'/').encode())]
inverse_pub=pub
for old,new in reversed(ops):assert inverse_pub.count(new)==1;inverse_pub=inverse_pub.replace(new,old,1)
assert inverse_pub==original_pub
inverse_input=input_raw.replace(b'"ready": true',b'"ready": false',1).replace(b'"independent_prior_ready": true',b'"independent_prior_ready": false',1)
boundp=S/'performance96_artisan_life_prior_binding_BUILD/input_prior_bound_NOTREADY.json'
assert inverse_input==read(boundp,'e59d3da256d82d1d7afacafb870ec9b726e7ede2068dd989d9a9dc212eb6b35e')
binding=load(S/'performance96_artisan_life_prior_binding_BUILD/two_literal_inverse_and_prior_interface_READY.json','e6dd3efcae2a62a14faf3878f6e1238100eb52088faff59c5d836d96bcc8f223')
for h in reversed(binding['replacements']):
    a=h['old'].encode();b=h['new'].encode();assert inverse_input.count(b)==1;inverse_input=inverse_input.replace(b,a,1)
assert inverse_input==read(Y/'artisan_life_delta_publication_epoch01/input_NOTREADY.json','dfc8e7367e25b70c77f41ee8df48833b5d773ad2d710d0a567d43eda8bf4b37e')

mp=A/'output/manifest_PENDING.json';manifest=load(mp)
assert manifest['formal_enabled'] is False and manifest['runtime_Family132_27_gate_not_changed'] is True and manifest['outdoor_alpha_ART_and_actor_local_ghost_pending'] is True
assert manifest['finite_proof']==p and manifest['artifacts']==r['artifacts'] and manifest['source_first']==r['source_first']
assert manifest['parent_A2']==cfg['parent'] and manifest['mask_sha256']==prior['expected_child_RGBA_sha256']
assert set(Path(x).name for x in r['artifacts'])=={'layout.res','scene.res','packet.bin','walk.png'}
artifact_inventory=[{'path':x,'sha256_from_actual_and_manifest':h,'current_bytes_only_stat':(G/x[6:]).stat().st_size,'current_digest_rehashed_by_QA':False} for x,h in r['artifacts'].items()]
for label in [b'WHOLE_NEW_PNG_RGBA_READBACK',b'WHOLE_NEW_NATIVE_STORAGE_READBACK',b'NEW_PACKET_WHOLE_READBACK',b'PARENT_RESOURCES_IMMUTABLE_AFTER_PUBLICATION']:
    assert pub.count(label)==1

pp=R/'actual_artisan_life_publication_process_receipt.json';proc=load(pp)
assert proc['actual_natural_console_exit_code']==0 and proc['exit_code_from_retained_process_WaitForExit'] is True and proc['process_stopped_by_tool'] is False
assert proc['script_sha256']==proc['script_after_sha256']==sha(pub)
stderr=read(R/'actual_artisan_life_publication_stderr.log');stdout=read(R/'actual_artisan_life_publication_stdout.log')
assert sha(stderr)==proc['stderr_sha256'] and sha(stdout)==proc['stdout_sha256']
lines=stderr.decode('utf-8-sig').splitlines();errors=sum(x.startswith('ERROR:') for x in lines);warnings=sum(x.startswith('WARNING:') for x in lines);scripts=sum('SCRIPT ERROR:' in x for x in lines)
assert errors==0 and warnings==2 and scripts==0
before=load(R/'guard_before.json','25b91cee70aafd5fc6411f329fa2891f0f67fac19210c7035bfd09324e5c4a34')
after=load(R/'final_guard.json','754bf211018f3a63c513a7cafe822a25a6afe016ad1108ebde0df9becfa818e6')
assert before['passed'] and after['passed'] and before['facts']==after['facts'] and after['checked']==after['exact_unchanged']==2118
assert after['save_count']==15 and after['save_change_count']==after['authorized_change_count']==after['unexpected_change_count']==0
threebefore=load(R/'source_only_three_facts_before.json');threeafter=load(R/'source_only_three_facts_after.json')
assert threebefore['facts']==threeafter['facts'] and len(threebefore['facts'])==3
family=G/'scripts/city/luoyang_quarters_family_20261022ap.gd'
family_raw=read(family,'58e6d986ce26142ca2c3a852bae4ede3e01a28892ebe594512d3106c59b2204f')
assert b'raw.solids.size()!=27' in family_raw and b'visual_objects.array_values.size()==132' in family_raw

review={'status':'INDEPENDENT_ROOT59_ARTISAN_FOUR_PROP_BUILD_TECHNICAL_COMPONENT_PASSED_NOT_FORMAL_OR_ART',
        'actual_result':ref(rp),'passed':True,'published_BUILD_only':True,'checks':9296,'elapsed_ms':658,
        'native_counts':{'old_visual':132,'new_visual':136,'old_solid':27,'new_solid':31,'old_ground_retained':118,'low_opaque_props':18},
        'four_native_f32_polygons_exact_independent_prior':True,
        'local_mask':mask,'independent_prior':ref(priorp),
        'inherited_source_scope':{'old132_visual_order_values_and27_native_packet_solids_whole_inverse_from_actual':True,'old_A2_finite_proof_wholetyped_retained':True,'routes':7,'route_segments_inherited_without_replay':23,'NPCs_and_approaches':4,'door_aprons':5,'portals':4,'old_geometry_raster_repeated':False},
        'new_finite_cpu_body_only':local,
        'four_artifacts_report_and_nonadmitting_manifest_same':artifact_inventory,
        'tiny_nonadmitting_manifest':ref(mp),
        'readback_credit_boundary':'Root actual passed all original code gates: complete savedPNG RGBA readback, savedScene/Layout storage readback, packet whole readback and parent-resource immutability. QA checked exact frozen publisher body and tiny report/manifest agreement, not decoded/rehashed the25MB packet or re-rendered/re-rasterized anything.',
        'source_first_final_complete20_exact_fixed_ready_input_plus_prior_and_self':True,
        'publisher_only4header_literals_inverse_7916_and_input2flags_plus_prior2literal_inverse_DFC8':True,
        'Root_guard_before':ref(R/'guard_before.json'),'Root_guard_after':ref(R/'final_guard.json'),
        'all2118_guard_facts_and_save15_exactticks_same':True,'three_SOURCE_ONLY_fact_records_same':True,'threeproof_after':ref(R/'source_only_three_facts_after.json'),
        'process_receipt':ref(pp),'true_natural_exit':0,'process_wall_ms':proc['elapsed_wall_ms'],
        'stderr':ref(R/'actual_artisan_life_publication_stderr.log'),'nonclean':{'ERROR':0,'WARN':2,'SCRIPT':0,'rawPNG_export_load_warning':True,'ObjectDB_exit_warning':True},
        'formal_enabled':False,'Family_current132_27_gate_SHA_unchanged':sha(family_raw),'Family_accepts_new136_31_not_claimed':True,
        'no_Field_Physics_actorghost_outdoor_alpha_ART_import_or_sourceStage_credit':True,
        'QA_actions':{'engine_parse_collector':0,'packet_or_image_decode':0,'PIP_283body_or_oldgeometry_replay':0,'production_or_existing_source_writes':0,'new_readonly_QA_receipt_only':True}}
out=Q/'artisan_ROOT59_four_prop_publication_actual_readonly_review_READY.json';assert not out.exists()
text=json.dumps(review,ensure_ascii=False,indent=2)+'\n'
patch='*** Begin Patch\n*** Add File: '+str(out).replace('\\','/')+'\n'+''.join('+'+line+'\n' for line in text.splitlines())+'*** End Patch'
print(json.dumps({'patch':patch,'summary':{'actual_passed':True,'checks':9296,'elapsed_ms':658,'sources':20,'visuals':136,'solids':31,'local_points':8714,'changed':6735,'new_body_samples':283,'native_packet_decode_by_QA':0,'guard2118_save15_same':True,'true_exit':0,'warnings':2,'formal':False,'Field_ART':False}}))
