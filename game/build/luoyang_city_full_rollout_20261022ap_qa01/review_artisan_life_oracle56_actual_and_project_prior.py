"""Read-only actual review and exact result projection; no image/PIP/engine calls."""
import hashlib
import json
import math
import struct
from pathlib import Path

Q=Path(__file__).resolve().parent
G=Q.parents[1]
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration56'
OLD=Q/'artisan_life_four_polygon_native_oracle01'
RETRY=Q/'artisan_life_four_polygon_native_oracle_retry1'
def sha(raw): return hashlib.sha256(raw).hexdigest()
def read(p,h=None):
    raw=p.read_bytes()
    if h: assert sha(raw)==h.lower(),str(p)
    return raw
def load(p,h=None): return json.loads(read(p,h))
def reference(p,h=None):
    raw=read(p,h)
    return {'path':'res://'+p.relative_to(G).as_posix(),'sha256':sha(raw),'bytes':len(raw)}

rp=R/'oracle_READY/output_READY/95128_354965/result.json'
r=load(rp,'01424aa5e9362ccf49822642500088361069994d254b0761353faf452fca3e8a')
assert r['complete'] is True and r['failure']=='' and r['checks']==32923 and r['elapsed_usec']==269002
assert r['PNG_decodes']==1 and r['PNG_outputs']==0 and r['packet_ResourceLoader_Field_Physics_collector_calls']==0 and r['canonical_writes']==0
assert r['status']=='INDEPENDENT_ARTISAN_LIFE_FOUR_POLYGON_PRIOR_NOT_RUNTIME'
assert r['parent_rgba_sha256']==r['whole_inverse_parent_RGBA_sha256']=='ba3713f65664983e9825187d722fe7d679fc604c2a5a07c6a403e597b4b366c1'
assert r['expected_child_RGBA_sha256']=='c0c5a42ceb22326da932e146a4a1c233dfc3c0a8206d2e977f32137293d369f8'
assert r['WHITE_to_BLACK_only'] is True and r['outside_four_domains_exact_by_construction'] is True
assert r['changed_pixels']==6735 and r['union_visited_pixels']==8714
gap=load(OLD/'source_f32_and_boundary_gap_NOTREADY.json','2f88c2861b57d72d35d327aed073e5986702af2613e4f034c3f600375e710024')
models=gap['four_source_f32_models']
expected_polys=[{'id':x['id'],'points':x['model_points']} for x in models]
assert expected_polys==r['polygons']==r['derived_native_polygons_before_domain_assert']
for model,observed in zip(models,r['polygons']):
    assert [struct.pack('<ff',*p).hex() for p in observed['points']]==model['model_f32_bytes_hex']
assert r['domains_closed']==r['derived_native_closed_domains_before_domain_assert']==gap['domains_closed']
assert len(r['domain_counts'])==4
for row,closed,visited,changed in zip(r['domain_counts'],gap['domains_closed'],[1620,1620,3472,2002],[1041,1041,2961,1692]):
    assert row=={'closed':closed,'visited_pixels':visited,'changed_pixels':changed}
    assert visited==(closed[2]-closed[0]+1)*(closed[3]-closed[1]+1)
assert sum(x['visited_pixels'] for x in r['domain_counts'])==8714
assert sum(x['changed_pixels'] for x in r['domain_counts'])==6735
for actual,expected in zip(r['derived_native_closed_domains_before_domain_assert'],r['fixed_JSON_closed_domains_before_domain_assert']):
    assert len(actual)==len(expected)==4
    assert all(type(a) is int and type(b) is float and math.isfinite(b) and float(a)==b for a,b in zip(actual,expected))

original_input=read(OLD/'input_NOTREADY.json','d950cb216b5bb070ce8229d0e1c9ec0815e1e6dd43d92da05d790a26b057d95d')
ready_input=read(R/'oracle_READY/input_READY.json','b391f84b5aa99da0209cec7f0dde5a00b29af2c3f8bec835a44c7dd4f25065e3')
assert ready_input.replace(b'"ready": true',b'"ready": false',1)==original_input
fixture=json.loads(ready_input)
assert len(fixture['sources'])==9 and r['source_first']==fixture['sources']
assert set(r['source_final'])==set(fixture['sources'])
assert all(r['source_final'][k]==row['sha256'] for k,row in fixture['sources'].items())
key=read(R/'oracle_READY/oracle_READY.gd','30fea87f9d983be23d6ccc1030051e2533e259fd8b318fc79222e08eb3126baa')
base=read(RETRY/'oracle_NOTREADY.gd','71b2eefa962d3b799ee521424cdd6e8645fe31019db7cdbb20551da36e1ef26d')
freeze_ops=[(b'const READY=false',b'const READY=true'),(b'res://input_NOTREADY.json',b'res://input_READY.json'),
            (b'd950cb216b5bb070ce8229d0e1c9ec0815e1e6dd43d92da05d790a26b057d95d',b'b391f84b5aa99da0209cec7f0dde5a00b29af2c3f8bec835a44c7dd4f25065e3'),
            (b'res://output_NOTREADY/',b'res://output_READY/')]
inverse=key
for before,after in reversed(freeze_ops):
    assert inverse.count(after)==1
    inverse=inverse.replace(after,before,1)
assert inverse==base
assert read(R/'oracle_READY/project.godot')==read(OLD/'project.godot')

proc_path=R/'four_polygon_oracle_once_process_receipt.json'
proc=load(proc_path)
stderr=read(R/'four_polygon_oracle_once_stderr.log')
stdout=read(R/'four_polygon_oracle_once_stdout.log')
assert stderr==b'' and sha(stderr)==proc['stderr_sha256']
assert sha(stdout)==proc['stdout_sha256'] and b'"complete":true' in stdout
assert proc['actual_natural_console_exit_code']==0 and proc['exit_code_from_retained_process_WaitForExit'] is True and proc['process_stopped_by_tool'] is False
assert proc['script_sha256']==proc['script_after_sha256']==sha(key)
before=load(R/'guard_before.json');after=load(R/'final_guard.json')
assert before['passed'] and after['passed'] and before['checked']==after['checked']==2118
assert before['facts']==after['facts'] and len(before['save_paths'])==15 and after['save_count']==15 and after['save_change_count']==0
assert after['exact_unchanged']==2118 and after['authorized_change_count']==after['unexpected_change_count']==0
three_before=load(R/'source_only_three_facts_before.json');three_after=load(R/'source_only_three_facts_after.json')
assert three_before['facts']==three_after['facts'] and len(three_before['facts'])==3
assert three_before['runtime_texture_credit'] is False and three_after['runtime_texture_credit'] is False
failed55=load(G/'build/luoyang_city_full_rollout_20261022ap_root01/integration55/oracle_READY/output_READY/123924_88715/result.json')
assert failed55['complete'] is False and failed55['failure']=='FOUR_SOURCE_DERIVED_CLOSED_DOMAINS' and failed55['PNG_decodes']==0

review={'status':'INDEPENDENT_ROOT56_NATIVE_FOUR_POLYGON_PRIOR_LIMITED_ACTUAL_REVIEW_COMPLETE',
        'actual_result':reference(rp),'actual_key':reference(R/'oracle_READY/oracle_READY.gd'),
        'actual_input':reference(R/'oracle_READY/input_READY.json'),
        'functional_complete':True,'checks':32923,'elapsed_usec':269002,
        'natural_exit':0,'process_receipt':reference(proc_path),'process_wall_ms':proc['elapsed_wall_ms'],
        'stderr_bytes':0,'stderr_SHA256':sha(stderr),'warnings_errors_script':0,
        'four_native_polygon_coordinates_and_f32_bytes_exact_preexisting_independent_model':True,
        'all_native_domains_exact_expected_values_with_JSON_float_spelling_explicit':True,
        'domain_counts':r['domain_counts'],'visited':8714,'white_to_black':6735,
        'child_RGBA_SHA256':r['expected_child_RGBA_sha256'],'full_inverse_parent_RGBA_SHA256':r['whole_inverse_parent_RGBA_sha256'],
        'source_count':9,'actual_source_first_final_equal_fixed_fixture':True,
        'READY_key_only_four_literal_byte_inverse_to_retry1':True,'input_only_ready_boolean_byte_inverse_to_original_D950_not_CF8E':True,
        'Root_guard_before':reference(R/'guard_before.json'),'Root_guard_after':reference(R/'final_guard.json'),
        'Root_guard_2118_facts_SHA_bytes_ticks_exact':True,'player_saves_15_exact':True,
        'three_SOURCE_ONLY_proof_facts_exact':True,'three_fact_after':reference(R/'source_only_three_facts_after.json'),
        'Root55_runtime_domain_failure_and_Root56_first_freeze_failure_preserved':True,
        'credit_boundary':'Only independent native source/f32/PIP prior for four new furniture polygons. WholeRGBA equality/inverse are credited from this fixed Root actual, not recomputed. No publisher result, packet/native publication, import, Field/Physics, route875, runtime source closure or ART admission.',
        'QA_actions':{'new_engine_parse_PIP_or_PNGdecode':0,'packet_or_publisher_output_read':0,'collector_or_geometry_replay':0,'production_System_false_flag_modification':0}}
prior_keys=['status','parent_rgba_sha256','whole_inverse_parent_RGBA_sha256','expected_child_RGBA_sha256',
            'changed_pixels','union_visited_pixels','domains_closed','polygons']
prior={k:r[k] for k in prior_keys}
prior['independent_oracle_provenance']={'result':reference(rp),'key':reference(R/'oracle_READY/oracle_READY.gd'),
                                        'input':reference(R/'oracle_READY/input_READY.json'),'true_exit':0,
                                        'source_first':r['source_first'],'source_final':r['source_final']}
prior['only_fixed_actual_projection_no_pixel_recalculation']=True
prior['publisher_and_input_readiness_changed']=False
prior['runtime_ART_Physics_sourceStage_credit']=False
files={'artisan_life_Root56_native_prior_actual_readonly_review_READY.json':review,
       'artisan_life_independent_four_polygon_pixel_prior_READY_NOT_RUNTIME.json':prior}
patch='*** Begin Patch\n'
for name,value in files.items():
    p=Q/name
    assert not p.exists()
    text=json.dumps(value,ensure_ascii=False,indent=2)+'\n'
    patch+='*** Add File: '+str(p).replace('\\','/')+'\n'+''.join('+'+line+'\n' for line in text.splitlines())
patch+='*** End Patch'
print(json.dumps({'patch':patch,'summary':{'checks':32923,'domain_counts':r['domain_counts'],'changed':6735,'visited':8714,'native_float_model_match':True,'script_full_inverse':True,'input_full_inverse_originalD950':True,'all9sources_same':True,'guard2118_and15save_same':True,'stderr_bytes':len(stderr),'exit':0}}))
