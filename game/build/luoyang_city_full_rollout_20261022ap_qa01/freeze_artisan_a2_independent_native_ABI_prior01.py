"""One readonly audit of the independent constant-source ABI run, no raster replay."""
import copy,hashlib,json
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
PROJECT=QA/'artisan_a2_native_pip_oracle01'
RESULT=PROJECT/'output/48360_496422/result.json'
OUT=QA/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert not OUT.exists()
assert sha(RESULT)=='c494b096aba693dc9385a8f0089d00b1968de2fb62572fb91b1b8c23110d7a5b'
assert sha(PROJECT/'oracle_READY.gd')=='4f5999e4db1cb11550831b6ef27cdf2002b568b765bf5cb09a22ad5223b60f4c'
assert sha(PROJECT/'input_READY.json')=='b836447e44e0642337b0dc3521191a2f90da97de1a71d802642854bd43c5acb1'
assert sha(PROJECT/'project.godot')=='ac2e002967f6f0f00a66a0feecb8b82d1ea2e4f4e116235ace83b5ca226b684e'
r=json.loads(RESULT.read_bytes());i=json.loads((PROJECT/'input_READY.json').read_bytes())
assert r['complete'] and not r['error'] and r['elapsed_usec']==414186 and r['elapsed_usec']<=5000000
expected_source={v['path']:v['sha256'] for v in i['source_files'].values()}
assert r['source_first']==r['source_final']==expected_source
for p,h in expected_source.items():assert sha(Path(p))==h
assert r['old_local_mismatch_count']==0 and r['old_local_first32_mismatches']==[]
assert r['complete_old_local_source_ABI_proof'] is True
assert r['domain_count']==8 and r['union_visited_pixels']==21538
assert r['changed_pixels']==17366 and r['black_to_white']==12706 and r['white_to_black']==4660
assert r['black_to_white']+r['white_to_black']==r['changed_pixels']
assert r['original_parent_RGBA_sha256']==r['whole_inverse_RGBA_sha256']=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da'
assert r['new_expected_full_RGBA_sha256']=='ba3713f65664983e9825187d722fe7d679fc604c2a5a07c6a403e597b4b366c1'
assert r['outside_eight_domains_unchanged_by_construction'] is True
assert r['fixed_rack_ABI_witness']=={'point':[2084.0,1397.0],'native_original_PIP':True}
for k in ['PNG_decode_or_output','Physics_or_collector_calls','ResourceLoader_calls','Scene_Field_native_packet_reads','autoloads','canonical_writes','compiler_helper_calls','old_route_samples_replayed']:assert r[k]==0

# Reuse only our fixed, pure source-arithmetic prefix BEFORE any image IO or
# failed PIP substitute. This does not invoke a System producer or read child art.
PREPARER=QA/'prepare_artisan_a2_independent_source_recipe01.py'
source=PREPARER.read_text(encoding='utf-8')
marker="mask_path=report['walk_candidate']['path']"
assert source.count(marker)==1
env={'__file__':str(PREPARER),'__name__':'independent_source_only_prefix'}
exec(compile(source.split(marker)[0],str(PREPARER),'exec'),env)
strict=env['strict'];old=env['old'];new=env['new'];o=old['scenes'][0];n=new['scenes'][0]
expected_domains=[{'id':d['id'],'phase':d['phase'],'closed':d['integer_guard_closed']} for d in env['domains']]
assert r['domains']==expected_domains and len(env['flat'])==21538
for key,rows in [('old_source_solids',env['oldsolids']),('new_source_solids',env['newsolids'])]:
    expected=[]
    for row in rows:
        expected.append({'id':row['id'],**({'rect_px':row['rect_px']} if 'rect_px' in row else {'polygon_px':row['polygon_px']})})
    assert r[key]==expected,('Exact independently transcribed Vector2 arithmetic differs',key)

undo=copy.deepcopy(new)
top=['scope','native_root','parent_publication','allowed_changed_solid_ids','root_approved_body_successor','root_chinese_shell_wall_A1_successor','visual_overlap_effective_contract']
for k in top:undo[k]=copy.deepcopy(old[k])
del undo['a2_ground_profiles'];del undo['a2_pending_consumer_contract']
added=set(new['source_sha256'])-set(old['source_sha256'])
assert len(added)==21
for p in added:
    assert p.startswith(env['BASE']+'artisan_a2_workyards_epoch01/atlases/')
    assert sha(env['path'](p))==new['source_sha256'][p]
    del undo['source_sha256'][p]
for k in ['ground_sections','placements','visual_depth_overlap_pairs','visual_depth_semantics']:undo['scenes'][0][k]=copy.deepcopy(o[k])
assert strict(undo,old)
assert strict(o['routes'],n['routes']) and strict(o['portals'],n['portals']) and len(o['routes'])==7 and len(o['portals'])==4
segments=[]
for route in o['routes']:
    for ordinal,(first,last) in enumerate(zip(route['points'],route['points'][1:])):
        hit=[d['id']+'/'+d['phase'] for d in env['domains'] if env['segment_box'](first,last,d['integer_guard_closed'],[17,12])]
        segments.append({'route_id':route['id'],'ordinal':ordinal,'first':first,'last':last,'changed_domain_hits':hit})
assert len(segments)==23 and not any(x['changed_domain_hits'] for x in segments)
four=[x for x in env['people']['people'] if x['scene_id']==env['SCENE']]
assert len(four)==4
for row in four:
    for field,half in [('foot_px',[17,15]),('approach_px',[17,12])]:
        assert not any(env['segment_box'](row[field],row[field],d['integer_guard_closed'],half) for d in env['domains'])
assert all(not any(env['segment_box'](row['foot'],row['foot'],d['integer_guard_closed'],[17,12]) for d in env['domains']) for row in o['portals'])
ground=env['ground_rows'](new)
assert len(ground)==118 and len(n['placements'])==14 and len(n['ground_sections'])==18
assert len(env['ground_rows'](old))==86 and len(o['placements'])==20
out={'status':'FROZEN_INDEPENDENT_SOURCE_ABI_PRIOR_ONLY_NOT_PUBLISHER_NATIVE_FIELD_OR_ART_ADMISSION',
 'prior_oracle':{'path':'res://'+RESULT.relative_to(GAME).as_posix(),'sha256':sha(RESULT),'Root_captured_console_exit':0,
     'complete':True,'elapsed_usec':414186,'checks':43122},
 'independent_source_sha256':expected_source,
 'recipe_sources':{'pure_source_transcription_script_sha256':sha(PREPARER),'oracle_script_sha256':sha(PROJECT/'oracle_READY.gd'),'input_sha256':sha(PROJECT/'input_READY.json')},
 'prior_mask':{'original_RGBA_sha256':r['original_parent_RGBA_sha256'],'expected_child_RGBA_sha256':r['new_expected_full_RGBA_sha256'],
     'whole_inverse_RGBA_sha256':r['whole_inverse_RGBA_sha256'],'old_eight_domains_RGBA_diff':0,
     'changed_pixels':17366,'black_to_white':12706,'white_to_black':4660,'union_visited_pixels':21538,
     'domains':r['domains'],'domain_outside_RGBA_unchanged':True,
     'source_rule':'Original compiler exact Vector2 expressions, rect ceil..floor closed, original polygon floor..ceil closed bbox then native Geometry2D; old33 complete local reproduction before new27 expected pixels. Not blind white fill.',
     'ABI_boundary':'Expected child is independent original-parent/source-author primitive oracle, NOT any System publisher/native result. Fixed (2084,1397) nativePIP true came from the original predicate across the whole eight-domain reconstruction, not a point exception.'},
 'whole_typed_author_inverse_to_C2AA':True,'old33_source_solids':r['old_source_solids'],'expected27_source_solids':r['new_source_solids'],
 'only_geometry_delta':{'retired_six_wall_solids':[p+'_base_0' for p in env['RETIRE']],
     'moved_rack':{'id':env['RACK']+'_hull_0','old_foot':[2200,1405],'new_foot':[2470,1446]},
     'other26_source_solids_exact':True},
 'exact_7_routes':o['routes'],'all_23_continuous_source_domain_screens':segments,
 'affected_old_route_segments':[],'old_route_evidence_inherited_not_replayed':True,
 'exact_4_people_and_approaches':four,'exact_4_portals':o['portals'],'exact_5_adult_door_declarations':old['adult_doors'],
 'visual_counts':{'old':[86,20,106],'expected_new':[118,14,132]},'expected_ground_visual_rows':ground,'expected_ground_section_profiles':new['a2_ground_profiles'],
 'source_only_new_targets_not_yet_runtime_admitted':{'rack_front_route':[[2040,1430],[2040,1490],[2470,1490],[2470,1486]],
     'retired_wall_stands':[[1840,1430],[2160,1430],[2320,1430]],'rack_negative':[2470,1436],
     'old_pending2350_1446_explicitly_not_safe':True},
 'old_failed_Python_PIP_and_one_pixel_diagnostic_preserved':True,'old_A1_ART_rejection_and_undeployed_preserved':True,
 'Root_next_only':'Freeze publisher source against this prior, one finite native publication and Root ART/source authority later; no old route/global geometry or Yamen/E replay.',
 'engine_runs_this_review':0,'PNG_decode_this_review':0,'native_packet_decode':0,'producer_helper_calls':0,'raster_replay_this_review':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'prior':str(OUT),'sha256':sha(OUT),'RGBA':r['new_expected_full_RGBA_sha256'],'changed_pixels':17366,'visited':21538,'whole_inverse':True,'source_count':4,'new_ground_rows':118,'engine':0}))
