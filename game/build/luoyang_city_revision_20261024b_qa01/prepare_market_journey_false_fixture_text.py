"""Small text-only future Field scope. No source collector, packets or images.

No actual-native output exists yet: source-author proposals are provenance only.
Missing final routes/owner/deployment pins remain null/empty and hard-blocked.
"""
from pathlib import Path
import hashlib, json, re

Q = Path(__file__).resolve().parent
GAME = Q.parent.parent
NEW = Q / 'market_apothecary_vendor_journey_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def data(p): return json.loads(p.read_bytes())
def emit(p, value):
    assert not p.exists(), p
    p.write_bytes((json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii'))
    return sha(p)

dialog_root = GAME / 'build/luoyang_city_revision_20261024b_dialog01'
helper = dialog_root / 'npc_conversation_CANDIDATE.gd'
field_candidate = dialog_root / 'portrait_successor04/Field_final_CANDIDATE.gd'
assert sha(helper).startswith('535fb1d3') and sha(field_candidate).startswith('a976')
author_path = GAME / 'build/luoyang_city_space_20261024b_source01/author_space_delta_interaction_successor03_NOTREADY.json'
assert sha(author_path) == 'cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467'
author = data(author_path)
ap_author = GAME / 'build/luoyang_city_full_rollout_20261022ap_npc01/author.json'
ap_source = GAME / 'build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd'
npc_id = 'district_life_market_herb_buyer'
daily = [r for r in data(ap_author)['daily_rows'] if r['npc_id'] == npc_id]
assert len(daily) == 1 and daily[0]['scene_id'] == 'ch4_s3_luoyang_market'
daily_path = GAME / daily[0]['dialog_path'].removeprefix('res://')
text = daily_path.read_text(encoding='utf-8')
lines = re.findall(r'^text = "((?:[^"\\]|\\.)*)"$', text, re.M)
assert len(lines) == 2
lines = [json.loads('"' + s + '"') for s in lines]
helper_text = helper.read_text(encoding='utf-8')
rumor_match = re.search(r'"ch4_s3_luoyang_market\|district_life_market_herb_buyer": ("(?:[^"\\]|\\.)*")', helper_text)
assert rumor_match
rumor = json.loads(rumor_match[1])
sprite = 'res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png'
portrait = 'res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png'
assert '"' + sprite + '": "' + portrait + '"' in helper_text
daily_builder_text = ap_source.read_text(encoding='utf-8')
assert 'script.nodes.push_front(menu); script.entry_node_id = menu.node_id' in daily_builder_text
assert 'original.nodes.size() != 2' in daily_builder_text
assert 'menu.node_id = &"ap_daily_menu"' in daily_builder_text
assert '"first"' not in daily[0]  # Actual expectation is source node start, not a guessed menu .tres.
text_contract = GAME / 'data/luoyang_culture_integration_20261019x/text_contract.json'
ct = data(text_contract)
labels = [ct['primary_option_labels']['luoyang_paper_scholar'], ct['common']['culture_topics'], ct['common']['leave']]
task_tres = GAME / 'data/dialogs/luoyang_city_tasks_20261016/paper_offer.tres'
task_source = task_tres.read_text(encoding='utf-8')
task_script_id = re.findall(r'^dialog_id = &"([^"]+)"', task_source, re.M)
assert task_script_id == ['ch4_city_tasks_20261016_paper_offer']
assert 'accept_quest = &"q_ch4_side_02_luoyang_paper"' in task_source
apothecary = [r for r in author['complete_buildings'] if r['asset_id'] == 'apothecary']
assert len(apothecary) == 1
place = apothecary[0]
crowd = [r for r in author['runtime_district']['crowd'] if r['id'] == 'market_herb_buyer']
assert len(crowd) == 1 and crowd[0]['foot_px'] == [710, 1300]

fixed_paths = [GAME / 'tests/test_luoyang_city_life_cpu_draft_20261016f.gd',
               GAME / 'tests/helpers/v15_input_driver.gd',
               GAME / 'scripts/autoload/dialog_player.gd', GAME / 'scripts/ui/dialog_box.gd',
               helper, field_candidate, ap_source, ap_author, daily_path, text_contract, task_tres,
               author_path]
guards = {'res://' + p.relative_to(GAME).as_posix(): sha(p) for p in fixed_paths}
fixture = {
    'ready': False, 'formal_deployed': False,
    'status': 'FUTURE_ONE_EXPLICIT_NEAR_APOTHECARY_VENDOR_AND_TASK_DECLINE_NOTREADY',
    'blockers': ['Publication/native/routes have not passed; source-derived route arrays intentionally empty.',
                 'No final independent city owner/map or current canonical source successors/deployment authority yet.',
                 'Root must approve complete final key/fixture and exclusive one execution. QA does not run.'],
    'whole_ms': 60000, 'entry_ms': 20000, 'room_ms': 10000, 'return_ms': 10000, 'max_pictures': 3,
    'expected_city_count': None, 'expected_city_sources': {}, 'independent_owner': None,
    'deployment_actual': None, 'guard_before': None, 'guard_parent_final': None,
    'near_return_world': place['return_only_world_px'],
    'city_threshold_world': place['threshold_world_px'],
    'author_return_world': place['return_only_world_px'],
    'room_exit_world': [960, 1037.5], 'room_scene_path': None, 'room_layout_path': None,
    'paths': {'entry_to_threshold': [], 'room_spawn_to_exit': [], 'return_to_vendor': [], 'vendor_to_task': []},
    'path_proof': None,
    'proposed_source_points_not_route_admission': {
        'source_author': {'path': 'res://' + author_path.relative_to(GAME).as_posix(), 'sha256': sha(author_path)},
        'apothecary_near_return': place['return_only_world_px'], 'apothecary_threshold': place['threshold_world_px'],
        'old_unchanged_room_source_spawn': [768, 780], 'old_unchanged_room_source_exit': [768, 830],
        'room_source_to_world_expression': 'Vector2(source)/Vector2(1536,1024)*Vector2(1920,1280)',
        'room_world_spawn': [960, 975], 'room_world_exit': [960, 1037.5],
        'vendor_native_actor_foot': crowd[0]['foot_px'],
        'vendor_approach_and_task_approach': 'PENDING source-backed finite paths; no observed-node expected backfill'},
    'vendor': {'id': npc_id, 'name': daily[0]['npc_name'], 'sprite_path': sprite, 'portrait': portrait,
               'AP_authored_dialog_id': daily[0]['dialog_id'], 'AP_authored_two_line_resource': daily[0]['dialog_path'],
               'actual_runtime_builder': 'presentation_execution.build_daily_menu adds ap_daily_menu to exact2 authored zero-effect lines; conversation helper chooses first target without options',
               'first_text': lines[0], 'reply_text': lines[1], 'rumor_text': rumor,
               'first_expected_node_ids': ['npc_opening_20261024b_hero', 'start', 'reply'],
               'second_expected_node_ids': ['npc_opening_20261024b_hero', 'npc_opening_20261024b_rumor'],
               'rumor_voice_credit': False},
    'hero_fallback_portrait': 'res://art/characters/protagonist_portrait.png',
    'task': {'id': 'luoyang_paper_scholar', 'primary_path_id': 'luoyang_city_tasks_20261016/paper_offer',
             'primary_script_id': task_script_id[0], 'quest_id': 'q_ch4_side_02_luoyang_paper',
             'culture_menu_labels': labels, 'offer_labels': ['接受委托', '暂且不接'],
             'interaction_choice_policy': 'Real KEY_1 selects existing primary topic only. At real original side-offer, KEY_2 declines; never KEY_1 at accept UI.',
             'quest_state_precondition': 'Existing default offer must remain available; no QA state reset/flag changes to force it.'},
    'source_sha256': guards,
    'scope': {'public_initial_request': 'exactly1 explicit near return-only, NOT default/performance claim',
              'room': 'one real Space entry and one real Space exit, old interior geometry not re-audited',
              'movement': 'only source-fixed finite segments via real Input and current34x24 Physics/local17 mask; no Player or camera reposition or runtime path planner',
              'source': 'one naturally computed complete C dictionary compared to independent final map; no C/G source_paths/collector/validator/finalize call',
              'screenshots': ['ordinary live camera after real shop return', 'vendor first authored NPC line portrait', 'vendor second attributed rumor portrait'],
              'persistent_protection': 'checkpoint suspension and real15save first/final, flags+QuestManager+Inventory snapshot unchanged after near entry',
              'not_covered': ['default cold timing', 'whole-city art', 'all original routes', 'old17/42units', 'task acceptance/reward', 'voice coverage', 'other rooms']}}
fixture_sha = emit(NEW / 'fixture_NOTREADY.json', fixture)
template = NEW / 'test_TEMPLATE_NOTREADY.gd'
body = template.read_bytes()
res_path = 'res://' + (NEW / 'fixture_NOTREADY.json').relative_to(GAME).as_posix()
ops = [(b'PENDING_NEW_FIXED_FIXTURE_PATH', res_path.encode()), (b'PENDING_NEW_FIXED_FIXTURE_SHA', fixture_sha.encode())]
for a, b in ops:
    assert body.count(a) == 1
    body = body.replace(a, b)
inverse = body
for a, b in reversed(ops): inverse = inverse.replace(b, a, 1)
assert inverse == template.read_bytes() and b'const JOURNEY_READY=false' in body
key = NEW / 'test_NOTREADY.gd'
assert not key.exists();key.write_bytes(body)
handoff = {'status': 'KEY_AND_SOURCE_DERIVED_DIALOG_EXPECTATIONS_ONLY_NOTREADY_NOT_RUN',
           'key_path': 'res://' + key.relative_to(GAME).as_posix(), 'key_sha256': sha(key), 'fixture_sha256': fixture_sha,
           'template_sha256': sha(template), 'template_two_literal_binding_wholebyte_inverse': True,
           'source_guard_current_small_provenance_count': len(guards),
           'candidate_source_pin_is_not_deployment': {'helper': sha(helper), 'Field_candidate': sha(field_candidate)},
           'first_second_daily_expectations_derived_from': ['fixed AP author exact row', 'fixed AP presentation builder source', 'fixed original two-line daily resource', '535F conversation helper'],
           'source_coordinate_proposals_are_not_passed_routes': True,
           'pending_required': ['passed publication finite route proof including return-to-vendor and vendor-to-task',
                                'final independent complete Market owner dictionary', 'formal canonical source/deployment/fresh guard pins',
                                'current room scene/layout declared paths and old-author/world conversion provenance'],
           'root_explicit_near_authorized_no_default_claim': True,
           'new_key_not_wholebyte_successor_of_old_unrelated_journeys': True,
           'inherited_only': ['cpu draft first/final/source/save/report lifecycle', 'existing true keyboard driver key/completed stage', 'ordinary public go_field_smart and actual G/C receipt read protocol'],
           'agent_engine_Stage_collector_image_packet_calls': 0,
           'hardfalse': True, 'fixed_ms': 60000, 'pictures_max': 3}
hs = emit(NEW / 'handoff_NOTREADY.json', handoff)
print(json.dumps({'key': sha(key), 'fixture': fixture_sha, 'handoff': hs}, indent=2))
