"""Read-only independent byte inversion and call-surface review. No engine."""
import hashlib,json,re
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
P=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/portal_clone_field_timing03/handoff_CANDIDATES_NOT_DEPLOYED.json'
OUT=QA/'portal_catalogue_field_timings03_independent_static_review_READY.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):return GAME/p[6:]
assert not OUT.exists()
assert sha(P.read_bytes())=='ebb4695b05ad9acc029205b4cfef10888f66e9dcaf5a52265adabe25ff0f59ee'
h=json.loads(P.read_bytes());rows=[]
for r in h['candidates']:
    parent=path(r['parent']['path']).read_bytes();candidate=path(r['candidate']['path']).read_bytes()
    assert sha(parent)==r['parent']['sha256'] and sha(candidate)==r['candidate']['sha256']
    assert path(r['target']).read_bytes()==parent,'Current canonical must remain frozen parent'
    v=parent
    for op in r['operations']:
        at=op['byte_offset_before_this_change'];old=op['old'].encode();new=op['new'].encode()
        assert v[at:at+len(old)]==old,(r['target'],op['label'],'old byte slice')
        v=v[:at]+new+v[at+len(old):]
    assert v==candidate
    for op in reversed(r['operations']):
        at=op['byte_offset_before_this_change'];old=op['old'].encode();new=op['new'].encode()
        assert v[at:at+len(new)]==new
        v=v[:at]+old+v[at+len(new):]
    assert v==parent
    text=candidate.decode();before=parent.decode()
    if r['target'].endswith('luoyang_assembled_interiors_20261016g.gd'):
        old_method=before[before.index('static func project_portals('):before.index('static func _door_polygon(')]
        new_method=text[text.index('static func project_portals('):text.index('static func _door_polygon(')]
        assert old_method.count('catalogue()')==3 and new_method.count('catalogue()')==1
        # OLD authority and all 12 author_for_id evaluations remain original.
        assert before.count('author_for_id(')==text.count('author_for_id(')
        assert len(r['operations'])==2
        rows.append({'target':r['target'],'candidate_SHA':sha(candidate),'whole_byte_inverse':True,
            'only_project_portals_two_hunks':True,'method_catalogue_call_sites_before_after':[3,1],
            'author_for_id_and_all_author_door_body_checks_preserved':True,
            'snapshot_scope':'Single synchronous method call only; no cross-call catalogue cache added.',
            'performance_boundary':'At least twelve cached whole-registry deep clones avoided for twelve-room projection. No measured time/speedup credit.'})
    else:
        assert sha(candidate)=='67a83fb081f34b9fcea4c2045a1d36fb7fea04ef1405d51a78bc946337529b82'
        # Instrumentation must not alter original cooperative scheduling or source calls.
        for pattern in [r'\bawait\b',r'\bWorkerThreadPool\.',r'FileAccess\.get_sha256\(',r'ResourceLoader\.load\(',r'\bload\(',r'\bhash\(',r'\bcall_deferred\(']:
            assert len(re.findall(pattern,before))==len(re.findall(pattern,text)),pattern
        assert before.count('>= 8000:')==text.count('>= 8000:')
        assert '"profile_origin":"FIELD_SCENE_SETUP_NOT_WARM_RESUME"' in text
        assert '"records_warm_resume":false' in text and 'result["fresh_source_validation_credit"] = false' in text
        assert 'live_token > 0 and int(result.get("transition_token", 0)) > 0 and live_token == int(result.transition_token)' in text
        assert 'var loading_spawn_revision: int = _city3_motion_revision\n\tvar loading_spawn_scene: SceneScript = _current_scene' in text
        assert text.count('loading_spawn_revision, loading_spawn_scene')==3
        rows.append({'target':r['target'],'candidate_SHA':sha(candidate),'whole_byte_inverse':True,
            'declared_hunks':len(r['operations']),'all_original_await_and_worker_hash_load_call_counts_preserved':True,
            'original_8ms_budget_preserved':True,'no_new_yield_or_background_job':True,
            'write_guard':'COLLECTING + captured revision + same current scene + same scene/layout instance + one label only',
            'spawn_async_owner_captured_before_original_await':True,
            'read_guard':'setup_identity_current distinct from positive exact same_live_transition; token0 and warm resume do not relabel original setup as new-source credit',
            'timing_boundary':'Wall usec includes original awaits; setup_total overlaps child phases; ready_ui precedes setup and consumed once; absent phases unavailable, not zero; getters do not validate source.',
            'performance_boundary':'Timing observability only; no engine/parse/actual loading improvement credit.'})
out={'status':'INDEPENDENT_STATIC_BYTE_INVERSE_AND_OWNER_SCHEDULING_REVIEW_ONLY',
 'handoff':{'path':'res://'+P.relative_to(GAME).as_posix(),'sha256':sha(P.read_bytes())},
 'candidate_reviews':rows,'blocking_static_issues_found':[],
 'requires_later': ['Root source-only metadata DAG closure retaining ED4C/DB9D classification and all original proof edges',
                   'Root-authorized minimal actual only after final source pins; no replay of Yamen three props or E'],
 'engine_runs':0,'GDScript_parse_runs':0,'candidate_methods_called':0,'collector_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT.read_bytes()),'candidates':2,'engine':0,'static_blockers':[]}))
