"""NEW finite path facts/fixture only. No engine, packet, image or geometry scan."""
from pathlib import Path
import copy, hashlib, json, math, struct

Q = Path(__file__).resolve().parent
GAME = Q.parent.parent
SRC = GAME / 'build/luoyang_city_space_20261024b_source01'
OLD = Q / 'market_apothecary_vendor_journey_ui_successor01_NOTREADY'
NEW = Q / 'market_apothecary_vendor_route_contract_source06_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p, expected):
    raw = p.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == expected, p
    return json.loads(raw)
def res(p): return 'res://' + p.relative_to(GAME).as_posix()
def emit(p, value):
    assert not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes((json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii'))
    return sha(p)
def descriptor(p): return {'path': res(p), 'sha256': sha(p)}
def f32(x): return struct.unpack('<f', struct.pack('<f', x))[0]
def source_to_room_world(pair):
    return [f32(f32(f32(pair[i]) / f32([1536,1024][i])) * f32([1920,1280][i])) for i in range(2)]

author_path = SRC / 'author_space_delta_route_detours_successor06_NOTREADY.json'
a = read(author_path, '7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f')
publication_path = GAME / 'build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/publication_result.json'
publication = read(publication_path, '86edae530049c0d5daaa256eba5ae7ae24b71cb92733f875581b86796404e92e')
assert publication['passed'] is True and publication['source_first_final_same'] is True
assert publication['Field_Physics_collector_C_prepare_full_city_geometry_calls'] == 0
route_evidence = publication['diagnostics']['route_result']
inherit_evidence = publication['diagnostics']['inherited_route_evidence']
assert route_evidence['passed'] and route_evidence['checked_samples'] == 683 and route_evidence['only_two_changed_routes_checked']
assert inherit_evidence['prior_successful_samples'] == 4296 and inherit_evidence['prior_failed_samples'] == 24
assert set(x['id'] for x in route_evidence['segments']) == {'paper_stall','assembled_warehouse_edge_front'}
routes = {r['id']: r['new_points_px'] for r in a['route_replacements']}
ap = [x for x in a['complete_buildings'] if x['asset_id'] == 'apothecary']
assert len(ap) == 1
near = ap[0]['return_only_world_px']; threshold = ap[0]['threshold_world_px']
assert near == [1690,1663.7652439024391] and threshold == [1690,1596]
assert routes['room_northeastrear_approach'][-2:] == [near,threshold]
assert routes['medicine'][-1] == [710,1260]
assert routes['paper_stall'][1:3] == [[1070,1400],[330,1400]]

registry_path = GAME / 'data/maps/luoyang_estate_rooms_20261021am/registry.json'
registry = read(registry_path, '56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12')
room_id = 'luoyang_market_market_northeast_rear_frontage_interior_20261015'
row = registry['rooms'][room_id]
room_author_path = GAME / row['author_path'].removeprefix('res://')
room_author = read(room_author_path, 'be608338733807f1e7eaf06b45a1f2d53b913a42ce19d2a6cbf19c378100fdfc')
assert row['author_sha256'] == sha(room_author_path)
assert row['scene_path'] == 'res://data/maps/luoyang_market_two_shops_20261021ao/rooms/' + room_id + '/scene.res'
assert row['layout_path'] == row['scene_path'].removesuffix('scene.res') + 'layout.res'
geo = room_author['geometry']
assert geo['source_size_px'] == [1536,1024] and geo['actual_world_size_px'] == [1920,1280]
room_route = [x['points_px'] for x in geo['required_routes'] if x['id'] == 'spawn_to_exit']
assert room_route == [[[768,780],[768,830]]]
assert geo['spawn_foot_px'] == [768,780] and geo['front_exit']['approach_foot_px'] == [768,830]
room_world = [source_to_room_world(p) for p in room_route[0]]
assert room_world == [[960,975],[960,1037.5]]
room_facts = {'registry_provenance': descriptor(registry_path),
    'selection_chain': 'Current G INDEX.registry -> Estate.registry_source -> AM registry; not the historical T registry row',
    'id': room_id, 'author': descriptor(room_author_path),
    'scene': {'path': row['scene_path'], 'sha256': row['source_sha256'][row['scene_path']]},
    'layout': {'path': row['layout_path'], 'sha256': row['source_sha256'][row['layout_path']]},
    'source_size': [1536,1024], 'world_size': [1920,1280],
    'spawn_source': geo['spawn_foot_px'], 'exit_source': geo['front_exit']['approach_foot_px'],
    'world_formula': 'Vector2(source)/Vector2(1536,1024)*Vector2(1920,1280), per-operation binary32',
    'world_route': room_world,
    'old_return_in_provenance_not_new_expected': room_author['room']['return_foot_px'],
    'new_return_expected_from_author06': near,
    'native_scene_or_layout_not_loaded_or_decoded': True,
    'future_DAG_can_change_room_author_return_and_registry_sources_not_interior_route': True}

paths = {
    'entry_to_threshold': [near,threshold],
    'room_spawn_to_exit': room_world,
    'return_to_vendor': [near,[1690,1730],[1070,1730],[1070,1400],[780,1400],[780,1260],[710,1260]],
    'vendor_to_task': [[710,1260],[780,1260],[780,1400],[520,1400]]}
# A source-segment containment proof, NOT another raster or polygon sampler.
def subset_of_axis_segment(p, q, x, y):
    if x[0] == y[0] == p[0] == q[0]:
        return min(x[1],y[1]) <= min(p[1],q[1]) <= max(p[1],q[1]) <= max(x[1],y[1])
    if x[1] == y[1] == p[1] == q[1]:
        return min(x[0],y[0]) <= min(p[0],q[0]) <= max(p[0],q[0]) <= max(x[0],y[0])
    return False
evidence_routes = ['room_northeastrear_approach','market_loop','market_axis','paper_stall']
segments = []
new_edges = set()
for key in ['entry_to_threshold','return_to_vendor','vendor_to_task']:
    for i, (p, q) in enumerate(zip(paths[key],paths[key][1:])):
        witnesses = []
        for name in evidence_routes:
            for j, (x, y) in enumerate(zip(routes[name],routes[name][1:])):
                if subset_of_axis_segment(p,q,x,y): witnesses.append({'route': name, 'segment': j})
        if witnesses:
            status = 'SOURCE_SUBSEGMENT_OF_EXISTING_FINITE_SAMPLED_ROUTE_NOT_NEW_CONTINUOUS_OR_PHYSICS_CREDIT'
        else:
            status = 'NEW_SOURCE_DESIGNED_CONNECTOR_NO_PRIOR875_OR_PHYSICS_CREDIT_REAL_INPUT_MAY_FAIL'
            new_edges.add(tuple(sorted((tuple(p),tuple(q)))))
        segments.append({'path': key, 'segment': i, 'from': p, 'to': q, 'status': status, 'source_segment_witnesses': witnesses})
expected_new = {tuple(sorted(((780,1400),(780,1260)))), tuple(sorted(((780,1260),(710,1260))))}
assert new_edges == expected_new

# Independent actor positions: current immutable FB0B/author, never observed nodes.
projection_path = SRC / 'current_market_native_projection_ROOT_ACTUAL.json'
projection = read(projection_path, 'fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a')
old_native = {x['source_id']: x['foot_px'] for x in projection['record']['gameplay_slots']['npcs']}
native = {x['id']: x['new_foot_px'] for x in a['scene_npc_migrations']}
assert native['luoyang_paper_scholar'] == old_native['luoyang_paper_scholar'] == [520,1340]
herb = [x for x in a['runtime_district']['crowd'] if x['id'] == 'market_herb_buyer']
assert len(herb) == 1 and herb[0]['foot_px'] == [710,1300] and herb[0]['distance_px'] == 0
approaches = {'vendor': {'id': 'district_life_market_herb_buyer','actor_foot': [710,1300], 'stand': [710,1260], 'distance': 40},
              'task': {'id': 'luoyang_paper_scholar','actor_foot': [520,1340], 'stand': [520,1400], 'distance': 60}}
for value in approaches.values():
    assert math.dist(value['stand'],value['actor_foot']) == value['distance'] < 118
    value['meaning'] = 'Source-designed ordinary proximity; runtime must prove Space selected exact NPC, no manual interact/actor move or target override.'

contract = {'status': 'SOURCE06_FINITE_JOURNEY_ROUTE_PROPOSAL_NOTREADY_NOT_ENGINE_RUN',
    'ready': False, 'Source_approval_pending': True,
    'source_author': descriptor(author_path), 'native_publication_finite_evidence': descriptor(publication_path),
    'FB0B_provenance': descriptor(projection_path),
    'existing_publication_scope': {'new_two_route_samples': 683, 'inherited_prior_successful_samples': 4296,
        'all_old_routes_replayed': False, 'Field_or_Physics_run': False,
        'important': 'A passed publisher sample report does not prove the two new x780 connector edges, runtime NPC proximity, or this journey.'},
    'paths': paths, 'segment_facts': segments,
    'two_unique_new_unvalidated_edges': [list(map(list,edge)) for edge in sorted(new_edges)],
    'approaches': approaches, 'room': room_facts,
    'initial_setup': 'Exactly one public explicit near new apothecary return-only; nondefault/non-world/performance credit',
    'execution_bounds': {'whole_ms':60000,'entry_ms':20000,'room_ms':10000,'return_ms':10000,'PNG_max':3},
    'not_allowed': ['runtime path planning','Player teleport/inspection pose','position from observed nodes used as expected',
                    'extra geometry/PIP/raster/875 run to pre-pass connectors','accept quest/reward','collector'],
    'engine_packet_Image_Physics_PIP_or_geometry_by_QA': 0}
contract_path = NEW / 'route_contract_SOURCE_APPROVAL_PENDING.json'
contract_sha = emit(contract_path, contract)

old_fixture_path = OLD / 'fixture_NOTREADY.json'
f = read(old_fixture_path, '7486a667fca87f34b0e9299fc2847f6bcb5e9ad4a6118891e677cf3738736d60')
original = copy.deepcopy(f)
f['paths'] = paths
f['path_proof'] = {'path': res(contract_path), 'sha256': contract_sha, 'Source_approval_pending': True}
f['room_scene_path'] = row['scene_path'];f['room_layout_path'] = row['layout_path']
f['proposed_source_points_not_route_admission']['source_author'] = descriptor(author_path)
f['proposed_source_points_not_route_admission']['vendor_approach_and_task_approach'] = approaches
f['blockers'][0] = 'Source approval of two new finite x780 connector edges plus final independent owner/deployment/fresh authority remains pending; runtime true INPUT may fail, never a pre-passed full875 claim.'
old_author_res = 'res://build/luoyang_city_space_20261024b_source01/author_space_delta_interaction_successor03_NOTREADY.json'
old_author_sha = f['source_sha256'].pop(old_author_res)
assert old_author_sha == 'cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467'
new_guards = [author_path,publication_path,contract_path,room_author_path]
for p in new_guards:
    assert res(p) not in f['source_sha256']
    f['source_sha256'][res(p)] = sha(p)
fixture_path = NEW / 'fixture_NOTREADY.json'
fixture_sha = emit(fixture_path, f)
inverse = copy.deepcopy(f)
for p in new_guards: del inverse['source_sha256'][res(p)]
inverse['source_sha256'][old_author_res] = old_author_sha
for key in ['paths','path_proof','room_scene_path','room_layout_path','proposed_source_points_not_route_admission','blockers']:
    inverse[key] = original[key]
assert inverse == original
assert f['ready'] is False and f['formal_deployed'] is False and f['expected_city_sources'] == {} and f['expected_city_count'] is None
handoff = {'status':'ROUTE_AND_ROOM_SOURCE_FACTS_ONLY_AWAIT_SOURCE_APPROVAL_FORMAL_OWNER_NOTREADY',
    'fixture_sha256':fixture_sha,'route_contract_sha256':contract_sha,
    'reused_unmodified_key':{'path':res(OLD/'test_NOTREADY.gd'),'sha256':sha(OLD/'test_NOTREADY.gd')},
    'key_not_rewritten_or_frozen':True,'fixture_wholetyped_inverse':True,
    'fixture_only_delta':['four finite source paths','pathproof','exact fixed AO room Scene/layout paths',
        'source06 rather than source03 provenance','explicit approach-point source facts','first blocker text','four small source guards replacing author03'],
    'all_other_UI_dialog_owner_scope_budgets_unchanged':True,
    'Source_approval_pending':True,'new_unvalidated_unique_edges':2,
    'prior_native_samples_not_replayed':True,'QA_engine_Stage_collector_packet_Image_Physics_PIP':0}
hsha = emit(NEW/'handoff_NOTREADY.json',handoff)
print(json.dumps({'contract':contract_sha,'fixture':fixture_sha,'handoff':hsha},indent=2))
