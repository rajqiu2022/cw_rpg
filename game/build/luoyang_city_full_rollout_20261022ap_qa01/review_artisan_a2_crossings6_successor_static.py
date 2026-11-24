"""Final six-crossing input/header inverse to reviewed C0A; no producer run."""
import copy,hashlib,json
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
B=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01'
OUT=QA/'artisan_a2_crossings6_independent_static_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):return GAME/p[6:]
assert not OUT.exists()
base_review=QA/'artisan_a2_bound_publisher01_retry1_independent_static_review_READY.json'
assert sha(base_review)=='c8f6aec5473a685d8ff61687059e620a31c205907238ddb853cb437983ba1878'
oldp=B/'publisher_READY.gd';newp=B/'publisher_crossings6_READY.gd'
oldi=B/'input_READY.json';newi=B/'input_crossings6_READY.json'
assert sha(oldp)=='c0a46a1e529a7d306b36587976c44244390ea56fd8558ca3ccc0c6925a687711'
assert sha(newp)=='7af898b6c40c7bd286cdcb472e5a4ea0c2d93ca907128cee566d7e1917f06fbb'
assert sha(oldi)=='26d2cea27ad3be5e153896c60151d9a7dec27c5b757871b0285bd1358f6f18f2'
assert sha(newi)=='68a754894f570ea74e0dd617b8a03454fa5e76fb0c53f1182616d14d8c9589e1'
raw=oldp.read_bytes()
for old,new in [(b'/input_READY.json',b'/input_crossings6_READY.json'),
                (sha(oldi).encode(),sha(newi).encode()),
                (b'/artisan_a2_publication_epoch01/output/',b'/artisan_a2_publication_epoch01/output_crossings6/')]:
    assert raw.count(old)==1
    raw=raw.replace(old,new)
assert raw==newp.read_bytes()
a=json.loads(oldi.read_bytes());b=json.loads(newi.read_bytes());inv=copy.deepcopy(b)
supp=b['independent_six_crossings_source_screen'];s=json.loads(path(supp['path']).read_bytes())
assert sha(path(supp['path']))==supp['sha256']=='9f9e00aa4409a8bfeb7da247acd6e759e0c025c0a41c1c73a37a37d42c988a8f'
assert [row['points'] for row in b['new_finite_paths'][:6]]==[[row['from'],row['to']] for row in s['six_paths']]
assert [row['retired_source_solid_id'] for row in b['new_finite_paths'][:6]]==[row['original_retired_wall_contacts'][0] for row in s['six_paths']]
assert b['new_finite_paths'][-1]==a['new_finite_paths'][-1]
for k in ['new_finite_paths','scope']:inv[k]=copy.deepcopy(a[k])
del inv['independent_six_crossings_source_screen']
del inv['source_pins'][supp['path']]
assert inv==a and len(b['source_pins'])==137
for p,h in b['source_pins'].items():assert sha(path(p))==h
assert b['independent_expectation_path']==a['independent_expectation_path']
assert b['source_pins'][b['independent_expectation_path']]=='d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e'
out={'status':'INDEPENDENT_STATIC_SIX_CONTINUOUS_PATH_SUCCESSOR_ONLY_NOT_ACTUAL_NATIVE',
 'reviewed_parent':{'path':'res://'+base_review.relative_to(GAME).as_posix(),'sha256':sha(base_review)},
 'publisher':{'path':'res://'+newp.relative_to(GAME).as_posix(),'sha256':sha(newp)},
 'input':{'path':'res://'+newi.relative_to(GAME).as_posix(),'sha256':sha(newi)},
 'fixed_current_source_sha_checks':137,'code_exact_three_header_literal_inverse_toC0A':True,
 'input_whole_inverse_except_6paths_scope_and_9F9E_declaration':True,
 'independent_six_path_prior':supp,'selected_axes':[343,560,880,1840,2160,2320],
 'y_endpoints':[1404,1446],'original_rack_route_negative_unchanged':True,
 'D0D5_RGBA_prior_unchanged':True,'old400_reject_and_470_outside_fullbody_domain_preserved':True,
 'all_primitive_clone_inverse_and_bbox_PIP_algorithms_inherited_unchanged':True,
 'old_reviewer_placeholder_FAIL_preserved_and_retry1_only_corrected_literals':True,
 'engine_runs':0,'parse_runs':0,'PNG_decode':0,'ABI_runs':0,'native_packet_decode':0,'87517_replay':0,'collector_calls':0,'canonical_writes':0,
 'credit_boundary':'Only static preparation. Root unique actual publisher must independently pass199 finite body samples/negative/RGBA/storage before native-publication credit; no ART/Field/import/source closure or loading improvement claim.'}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'source_checks':137,'engine':0}))
