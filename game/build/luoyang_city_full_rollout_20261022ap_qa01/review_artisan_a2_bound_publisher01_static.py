"""Independent final publisher/input prior binding and whole-byte inverse review."""
import hashlib,json
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
B=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01'
OUT=QA/'artisan_a2_bound_publisher01_independent_static_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):return GAME/p[6:]
assert not OUT.exists()
pub=B/'publisher_READY.gd';inp=B/'input_READY.json'
assert sha(pub)=='c0a46a1e529a7d306b36587976c44244390ea56fd8558ca3ccc0c6925a687711'
assert sha(inp)=='26d2cea27ad3be5e153896c60151d9a7dec27c5b757871b0285bd1358f6f18f2'
i=json.loads(inp.read_bytes());text=pub.read_text(encoding='utf-8')
assert len(i['source_pins'])==136
for p,h in i['source_pins'].items():assert sha(path(p))==h,(p,'current source differs')
prior=path(i['independent_expectation_path'])
assert sha(prior)==i['source_pins'][i['independent_expectation_path']]=='d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e'
r=json.loads(prior.read_bytes());m=r['prior_mask']
assert i['parent_rgba_sha256']==m['original_RGBA_sha256']==m['whole_inverse_RGBA_sha256']
assert i['local_domains_xywh']==[[d['closed'][0],d['closed'][1],d['closed'][2]-d['closed'][0]+1,d['closed'][3]-d['closed'][1]+1] for d in m['domains']]
assert set(i['allowed_changed_solid_ids'])==set(r['only_geometry_delta']['retired_six_wall_solids'])|{r['only_geometry_delta']['moved_rack']['id']}
assert [x['points'] for x in i['new_finite_paths']]==[
 [[1840,1430],[1840,1430]],[[2160,1430],[2160,1430]],[[2320,1430],[2320,1430]],
 r['source_only_new_targets_not_yet_runtime_admitted']['rack_front_route']]
assert i['new_negative_feet']==[[2470,1436]]
assert not any([2350,1446] in x['points'] for x in i['new_finite_paths'])
proof=json.loads((B/'prior_schema_successor_inverse_READY.json').read_bytes())
template=path(proof['template']['path']);assert sha(template)==proof['template']['sha256']
old=(B/'publisher_bbox_successor_NOTEXEC.gd').read_bytes();assert hashlib.sha256(old).hexdigest()==proof['parent_template_sha256']
v=old
for op in proof['template_exact_substitutions']:
    a=op['before'].encode();b=op['after'].encode();assert v.count(a)==1
    v=v.replace(a,b)
assert v==template.read_bytes()
for op in reversed(proof['template_exact_substitutions']):
    a=op['before'].encode();b=op['after'].encode();assert v.count(b)==1
    v=v.replace(b,a)
assert v==old
expected_final=template.read_bytes().replace(b'const READY=false',b'const READY=true').replace(b'__INPUT_SHA__',sha(inp).encode())
assert expected_final==pub.read_bytes()
assert 'digest==expected.expected_child_RGBA_sha256' in text
assert 'changed==int(expected.changed_pixels)' in text and 'visited.size()==int(expected.union_visited_pixels)' in text
assert 'domains,oracle.prior_mask)' in text
assert 'Geometry2D.is_point_in_polygon(Vector2(p),row.polygon_px)' in text
assert 'p.x<floori(b.position.x)' in text and 'p.x>ceili(b.end.x)' in text
assert 'p.y<floori(b.position.y)' in text and 'p.y>ceili(b.end.y)' in text
assert 'source_layout.visual_objects,old.visuals' in text and 'parent.solids,old.solids' in text
assert 'api.equal(packet_inverse,parent)' in text and 'api.equal(inverse_scene,parent.scene_storage)' in text and 'api.equal(inverse_layout,parent.layout_storage)' in text
assert 'for key: String in ["visual_objects","blockers","walkable_mask_path"]' in text
assert '"formal_enabled":false' in text and '"runtime_source_closure_pending":true' in text
assert 'api=load(config.bundle_api_path)' in text
assert 'C.compile(' not in text and 'C.audit(' not in text
out={'status':'INDEPENDENT_STATIC_PRIOR_BINDING_BYTE_INVERSE_REVIEW_NOT_ACTUAL_PUBLICATION',
 'publisher':{'path':'res://'+pub.relative_to(GAME).as_posix(),'sha256':sha(pub)},
 'input':{'path':'res://'+inp.relative_to(GAME).as_posix(),'sha256':sha(inp)},
 'prior':{'path':i['independent_expectation_path'],'sha256':sha(prior)},
 'fixed_source_SHA_checks':136,'whole_schema_successor_inverse_to83F6':True,
 'final_READY_header_only_inverse_to_CE686':True,
 'expected_RGBA':m['expected_child_RGBA_sha256'],'expected_changed_pixels':m['changed_pixels'],
 'expected_visited_pixels':m['union_visited_pixels'],'exact_8_domains_xywh':i['local_domains_xywh'],
 'read_review':{'old_whole_native_storage_106rows_33solids_before_new':True,
   'new27_exact_source_solids_against_parent_7ids':True,'original_bbox_then_native_PIP':True,
   'all27_pixel_rebuild_not_blind_white':True,'D0D5_prior_full_RGBA_count_union_and_inverse_necessary':True,
   'scene_layout_packet_full_inverse_and_readback':True,
   'portals_NPCs_all_unlisted_storage_fields_inherited':True,
   '23_original_segments_only_affected_sampling_not_whole_replay':True,
   'three_wall_stands_and_new_front_route_only':True,'old2350_1446_not_safe':True,
   'new_mask_native_outputs_build_only_manifest_non_admitting':True,
   'material_interface_SHA_pinned_only_no_constructor_or_shader_credit':True},
 'static_blockers_found':[],'future_credit':'Root single actual publication must match this independent prior. No native, ART, mask import, Physics/Field, source closure or <10s improvement credit from this static review.',
 'engine_runs':0,'PNG_decode':0,'native_packet_decode':0,'producer_calls':0,'collector_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'fixed_sources':136,'static_blockers':[]}))
