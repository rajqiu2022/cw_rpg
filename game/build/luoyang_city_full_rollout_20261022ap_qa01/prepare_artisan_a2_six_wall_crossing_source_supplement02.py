"""NEW source-only axis selection; retains original400 reject and01 assertion FAIL."""
import hashlib,json,math
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
PREVIOUS=QA/'prepare_artisan_a2_six_wall_crossing_source_supplement01.py'
OUT=QA/'artisan_a2_six_wall_crossing_source_supplement02_READY.json'
assert not OUT.exists()
code=PREVIOUS.read_text(encoding='utf-8')
marker='initial=evaluate(400)'
assert code.count(marker)==1
env={'__file__':str(PREVIOUS),'__name__':'fixed_source_sweep_functions_only'}
exec(compile(code.split(marker)[0],str(PREVIOUS),'exec'),env)
evaluate=env['evaluate'];p=env['p'];prior=env['PRIOR'];sha=env['sha']
initial=evaluate(400);assert initial['retained_true_source_primitive_contacts']==['ap_carpentry_cart_v2_hull_0']
wall=next(x for x in p['old33_source_solids'] if x['id']=='ap_smith_wall_w1_base_0')
bound=env['bounds'](env['poly'](wall))
interval=[bound[0]+17,bound[2]-17]
first=math.ceil(interval[0]);last=math.floor(interval[1])
screen=[evaluate(x) for x in range(first,last+1,4)]
clear=[row for row in screen if row['source_continuous_clear_only']]
assert [row['from'][0] for row in clear]==[343,347]
chosen=clear[0]['from'][0]
assert chosen==343
axes=[chosen,560,880,1840,2160,2320]
rows=[evaluate(x) for x in axes]
assert all(row['source_continuous_clear_only'] and len(row['original_retired_wall_contacts'])==1 for row in rows)
assert set(row['original_retired_wall_contacts'][0] for row in rows)==set(p['only_geometry_delta']['retired_six_wall_solids'])
proposal470=evaluate(470)
assert proposal470['source_continuous_clear_only'] and 470>interval[1]
out={'status':'SOURCE_ONLY_SIX_CONTINUOUS_WALL_CROSSING_PATHS_NOT_MASK_OR_NATIVE_RUNTIME_ADMISSION',
 'parent_independent_prior':{'path':'res://'+prior.relative_to(GAME).as_posix(),'sha256':sha(prior)},
 'RGBA_prior_unchanged':p['prior_mask'],
 'source_authority':'Frozen independent48360 source27 real Vector2 polygons/rectangles and fixed4 NPC feet; not System publisher actual/native observations.',
 'original400_precise_source_rejection':initial,
 '470_proposal_not_selected':{'source_sweep':proposal470,'reason':'True cart polygon clears, but center470 exceeds strict originalwall high-17; body straddles original w1/w2. Root required fullbody-center interval, so not selected.'},
 'selection':{'original_w1_real_x_extent':[bound[0],bound[2]],'center_allowed_closed':interval,
    'integer_first_last':[first,last],'step':4,'candidate_count':len(screen),
    'ordered_source_screens':screen,'clear_centers':[343,347],'selected_center':343,
    'rule':'First clear integer-axis center, beginning ceil(originalwalllow+17), 4px steps through floor(originalwallhigh-17). Selection entirely source-derived before publisher actual; no cart movement/body shrink/actual avoidance.'},
 'six_paths':rows,'all6_source_continuous_sweeps_clear_of27_primitives_and4_idle_bodies':True,
 'body':[34,24],'idle_body':[34,30],
 'sweep_proof':'Vertical straight INPUT segment union is exact closed rectangle x+-17 and y1404-12..1446+12. Exact frozen source polygon/rectangle intersections and segment edges tested without epsilon; AABB broad-phase alone cannot reject the cart-clear343 path.',
 'rack_front_route_and_negative_unchanged':p['source_only_new_targets_not_yet_runtime_admitted'],
 'prior01_failure_preserved':'Original01 expected each oldwall contact unique at470 and failed; no oracle output. NEW02 records that extra contact and selects strict Root interval instead.',
 'required_actual':'Root-approved NEW publisher/input six paths still require original full87517 finite body checks; source analytic clearance is not mask-white/Physics/Field/ART credit.',
 'PNG_decode':0,'ABI_runs':0,'engine_runs':0,'87517_samples':0,'Physics_queries':0,'publisher_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'supplement':str(OUT),'sha256':sha(OUT),'six_axes':axes,
    'candidates':len(screen),'source_clear_centers':[343,347],'rejected400':True,'470_outside_strict_interval':True,'engine':0}))
