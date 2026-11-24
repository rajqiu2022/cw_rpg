"""Seal real Root-produced bins and actual NEW runtime dependencies once."""
from pathlib import Path
import argparse, hashlib, json, re
N = Path(__file__).resolve().parent
G = N.parents[1]
T = G / 'build/luoyang_city_rectification_20261027d_system01'
S = G / 'build/luoyang_city_finish_20261025i_source01'
ap = argparse.ArgumentParser(); ap.add_argument('--civic-result', required=True); ap.add_argument('--civic-result-sha256', required=True); args = ap.parse_args()
sha = lambda raw: hashlib.sha256(raw).hexdigest()
enc = lambda value: (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
res = lambda path: 'res://' + path.relative_to(G).as_posix()
def path_of(path): return G / path[6:]
def fixed(path, expected):
    raw = path.read_bytes(); assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)
def pin(path):
    raw = path.read_bytes(); return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}
def emit(path, value):
    assert not path.exists(), str(path); path.write_bytes(enc(value)); return pin(path)

result = fixed(path_of(args.civic_result), args.civic_result_sha256)
assert result['passed'] is True and not result['errors'] and result['whole_typed_inverse'] is True and result['added_render'] == 3 and result['removed_render'] == 2
old_report_path = N / 'temple_last_route_compile_output/121808/result.json'
report = json.loads(old_report_path.read_bytes())
assert report['passed'] is True and not report['errors'] and len(report['rows']) == 9
bindings = {row['region_id']: {**row['compiled'], 'bytes': int(row['compiled']['bytes'])} for row in report['rows']}
assert len(bindings) == 9
bindings['luoyang_civic_market_region_27d'] = result['compiled']
for binding in bindings.values():
    raw = path_of(binding['path']).read_bytes()
    assert sha(raw) == binding['sha256'] and len(raw) == binding['bytes']
author_path = N / 'regions_author06_native_buildings_BUILD.json'
author = fixed(author_path, '773e00411e878bd703bb22bdbf4ba7860de6de01b49bc891831d92bacf0cffab')
permission = N / 'root_integration_scope08_AUTHORIZED.json'
fixed(permission, '9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919')

# Module code is locked before Stage. The already loaded twelve and six retain
# their exact actual pins, rather than sampling any future observed Field.
prior_input = json.loads((N / 'runtime_syntax_input_ROOT_READY03.json').read_bytes())
pure_input = json.loads((N / 'pure_business6_syntax_input_ROOT_READY01.json').read_bytes())
fixed_modules = {**prior_input['source_sha256'], **pure_input['source_sha256']}
module_names = ['region_field.gd', 'region_entry.gd', 'router_region_dispatch.gd', 'region_session.gd', 'region_phase_scope.gd', 'region_actor_visuals.gd', 'region_source_context.gd', 'legacy_alias.gd', 'region_compiler.gd', 'base_field_business_snapshot01.gd', 'culture_business_snapshot01.gd', 'region_field.tscn', 'base_field_scene_snapshot01.tscn', 'room_wall_patch_repeat.gdshader', 'civic_market_scene.tres', 'estate_region_scene.tres', 'temple_region_scene.tres', 'estate_living_hall_scene.tres', 'estate_west_study_scene.tres', 'estate_east_bedroom_scene.tres', 'temple_main_hall_scene.tres', 'temple_monks_room_scene.tres', 'temple_sutra_room_scene.tres']
system_names = ['region_render_auxiliary.gd', 'culture_definition.gd', 'culture_definition_contract01_BUILD.json', 'presentation_definition.gd', 'presentation_definition_contract01_BUILD.json', 'logical_terminal_projector05_pure_presentation.gd', 'logical_context_bridge04_pure_presentation.gd', 'temple_source_business_snapshot01.gd', 'temple_paper_task_business_snapshot01.gd', 'temple_task_business_snapshot01.gd']
modules = {}
def declare(path, expected=None):
    key = res(path); raw = path.read_bytes(); actual = sha(raw)
    if expected is not None: assert actual == expected.lower(), key
    if key in modules: assert modules[key] == actual
    modules[key] = actual
for name in module_names:
    path = N / name; declare(path, fixed_modules.get(res(path)))
for name in system_names:
    path = T / name; declare(path, fixed_modules.get(res(path)))
for name, expected in [('culture_definition_contract01_BUILD.json', '3f538a6bfa2f03c70e6589f0584b891576343b1e771c14569fdbcc9238aa3412'), ('presentation_definition_contract01_BUILD.json', 'ed4ff178089a221d65f70520e9920687fe56ad8eae5ca583c3ac0d4cfe8a90ed')]:
    data = fixed(T / name, expected)
    for path, value in data['source_sha256'].items(): declare(path_of(path), value)
temple_text = (T / 'temple_task_business_snapshot01.gd').read_text(encoding='utf8')
temple_sources = json.loads(re.search(r'const BUSINESS_SOURCES: Dictionary=(\{[\s\S]*?\n\})', temple_text).group(1))
assert len(temple_sources) == 63
for path, expected in temple_sources.items(): declare(path_of(path), expected)

# These are the real stable classes/resources used by the new node and its
# inherited HUD/player/door constructors. No canonical Field/Router/old owner
# whole hash is used as this new session's identity.
stable_roots = ['scenes/player.tscn', 'scenes/npc_node.tscn', 'scenes/exit_zone.tscn', 'scenes/ui/inventory_panel.tscn', 'scenes/ui/character_panel.tscn', 'scenes/ui/skill_panel.tscn', 'scenes/ui/quest_panel.tscn', 'scenes/ui/world_map_panel.tscn', 'scenes/ui/field_primary_hud.tscn', 'scenes/ui/system_menu.tscn', 'scenes/ui/formal_confirm_dialog.tscn', 'scripts/field/outskirts_exit_zone.gd', 'scripts/ui/world_travel_minimap.gd', 'scripts/ui/wuxia_theme.gd', 'scripts/ui/ui_texture_skin.gd', 'scripts/ui/ui_layer_policy.gd', 'scripts/domain/scene_script.gd', 'scripts/domain/walkable_map_layout.gd', 'scripts/domain/dialog_script.gd', 'scripts/domain/dialog_node.gd', 'scripts/domain/quest_def.gd', 'scripts/domain/npc_profile.gd', 'scripts/domain/npc_catalog.gd', 'scripts/domain/shop_def.gd', 'scripts/domain/evidence_def.gd', 'data/npcs/npc_catalog.tres', 'shaders/interaction_outline.gdshader', 'shaders/environment_flame.gdshader', 'shaders/environment_rain.gdshader']
owner_targets = {row['target'] for row in json.loads((S / 'region_integration_20261027d01/current_01656_exact32_scope_PREPARATION.json').read_bytes())['targets']}
visited = set()
def stable_tree(path):
    key = res(path)
    if key in visited or not path.is_file(): return
    visited.add(key)
    assert key not in owner_targets, ('UNEXPECTED_NEW_REGION_OLD_OWNER_DEPENDENCY', key)
    declare(path)
    if path.suffix.lower() in ['.tscn', '.tres', '.gd']:
        text = path.read_text(encoding='utf8')
        links = re.findall(r'(?:preload\(|load\()\s*"(res://[^"\r\n]+)"|\[ext_resource[^\]\r\n]*?path="(res://[^"\r\n]+)"', text)
        for pair in links:
            linked = next(v for v in pair if v)
            if linked in owner_targets: continue # Global old authorities remain a Root/EX boundary, never new owner aliases.
            stable_tree(path_of(linked))
    if path.suffix.lower() in ['.png', '.jpg', '.jpeg', '.webp', '.wav', '.ogg']:
        side = Path(str(path) + '.import')
        if side.exists():
            declare(side)
            for linked in re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$', side.read_text(encoding='utf8'), re.M): declare(path_of(linked))
for name in stable_roots: stable_tree(G / name)
for name in ['event_bus', 'game_state', 'weather_manager', 'investigation_state', 'inventory', 'loading_manager', 'quest_manager', 'bounty_manager', 'dialog_player', 'save_manager', 'cursor_manager', 'platform_bridge', 'content_pack_manager', 'audio_manager', 'gm_console']:
    # Existing global services retain their own resource/lifecycle contracts.
    # Bind their actually consumed executable bytes, not their whole old city
    # source collectors or any mutable save/quest/flag state.
    declare(G / 'scripts/autoload' / (name + '.gd'))
projector = T / 'logical_terminal_projector05_pure_presentation.gd'
text = projector.read_text(encoding='utf8')
for linked in re.findall(r'preload\("(res://[^"\r\n]+)"\)', text):
    # Source modules are explicit. Old presentation execution imports left in a
    # pure copy are inactive declarations, not a request for their owner graph.
    if linked in ['res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd', 'res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd']: continue
    if linked not in owner_targets: declare(path_of(linked), fixed_modules.get(linked))
ambient = G / 'build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd'
declare(ambient)
for linked, expected in re.findall(r'const (?:VISUAL|AUTHOR|CONTRACT) := "([^"]+)"\r?\nconst (?:VISUAL|AUTHOR|CONTRACT)_SHA := "([^"]+)"', ambient.read_text(encoding='utf8')):
    declare(path_of(linked), expected)
    data = json.loads(path_of(linked).read_bytes())
    for path, value in data.get('required_source_sha256', {}).items():
        if path not in owner_targets: declare(path_of(path), value)
assert not owner_targets.intersection(modules)
declare(permission, '9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919')
manifest = {'schema': 'REGION27D_RUNTIME_MANIFEST_V1', 'adoption_enabled': True, 'status': 'ROOT08_SEALED_INPUTS_NOT_FIELD_ACCEPTANCE', 'author': pin(author_path), 'compiled_bindings': bindings, 'runtime_modules': modules, 'phase_projector': pin(T / 'logical_context_bridge04_pure_presentation.gd'), 'Root_authorization': pin(permission), 'source_authority_boundary': 'NEW Region immutable bins/module FIRST-FINAL. Canonical Router/Field are independently Root Stage/EX-approved exact successors, not reverse SHA dependencies in this manifest. Legacy source owners are never prepared or impersonated.', 'whole_city_art_pass': False, 'actual_field_pass': False}
manifest_pin = emit(N / 'region_runtime_manifest_BUILD.json', manifest)
declarations = {**modules, manifest_pin['path']: manifest_pin['sha256'], manifest['author']['path']: manifest['author']['sha256']}
for binding in bindings.values(): declarations[binding['path']] = binding['sha256']
declarations[res(permission)] = sha(permission.read_bytes())
declaration_pin = emit(N / 'region_runtime_source_declarations_BUILD.json', {'status': 'FIXED_NEW_REGION_RUNTIME_MODULE_AND_BIN_DECLARATIONS_NOT_OBSERVATION', 'source_sha256': declarations, 'compiled_component_count': 9, 'old_owner_targets_excluded': sorted(owner_targets), 'not_a_runtime_collector': True})
print(json.dumps({'manifest': manifest_pin, 'declarations': declaration_pin, 'runtime_module_count': len(modules), 'canonical_owner_targets_in_manifest': 0, 'components': len(bindings)}))
