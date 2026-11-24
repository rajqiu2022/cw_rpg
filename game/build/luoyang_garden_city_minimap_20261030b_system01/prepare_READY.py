"""Candidate-only 30b preparation. No engine, canonical source, PNG or save writes.
Keeps all ten immutable Region bins. Appends finite inverse owned-source edges.
"""
from pathlib import Path
import hashlib, json, re, difflib, copy, sys

BASE = Path(__file__).resolve().parent
GAME = BASE.parents[1]
OUT = BASE / (sys.argv[1] if len(sys.argv) > 1 else 'ready01')
assert OUT.parent == BASE and OUT.name.startswith('ready')
PREFIX = 'res://' + OUT.relative_to(GAME).as_posix() + '/'
ROOT = 'res://' + BASE.relative_to(GAME).as_posix() + '/'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p): return (GAME / p.removeprefix('res://')).read_bytes()
def enc(v): return (json.dumps(v, ensure_ascii=False, indent=2) + '\n').encode()
def once(b, old, new):
    old = old.encode() if isinstance(old, str) else old
    new = new.encode() if isinstance(new, str) else new
    assert b.count(old) == 1, (old[:100], b.count(old))
    return b.replace(old, new, 1)
def edit(b, replacements):
    out = b
    for old, new in replacements: out = once(out, old, new)
    inverse = out
    for old, new in reversed(replacements): inverse = once(inverse, new, old)
    assert inverse == b
    return out
def hunks(a, b):
    aa = a.decode().splitlines(keepends=True); bb = b.decode().splitlines(keepends=True)
    for context in [3, 6, 12, 24, 48]:
        result = []
        for group in difflib.SequenceMatcher(None, aa, bb, autojunk=False).get_grouped_opcodes(context):
            result.append({'old': ''.join(aa[group[0][1]:group[-1][2]]), 'new': ''.join(bb[group[0][3]:group[-1][4]])})
        if all(a.count(r['old'].encode()) == 1 and b.count(r['new'].encode()) == 1 for r in result):
            assert edit(a, [(r['old'], r['new']) for r in result]) == b
            return result
    raise ValueError('no unique finite hunk')
assert not OUT.exists(), 'exclusive candidate output; never overwrite a sealed set'
scope = json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
paths = [r['target'] for r in scope['targets']]
field = 'res://scripts/field/field_walkable_controller.gd'
region = 'res://build/luoyang_regions_20261027d_source01/region_field.gd'
town = 'res://build/three_towns_world_20261029j_system01/town_field.gd'
manifest = 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
router = 'res://scripts/autoload/scene_router.gd'
ct = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
coord = 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
ex = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ei = 'res://scripts/city/luoyang_execution_index_20261022ap.gd'
paths += [p for p in [region, town, manifest, router] if p not in paths]
before = {p: read(p) for p in paths}; after = {}; outputs = {}
oldsha = {p: sha(b) for p, b in before.items()}
assert oldsha[router].startswith('72863831') and oldsha[region].startswith('2674dd68')
assert oldsha[town].startswith('f28d97dc'), 'do not overwrite parallel native host'
def output(name, data):
    assert name not in outputs or outputs[name] == data
    outputs[name] = data
    return PREFIX + name

# Keep the original World branch and helper unchanged. Local fields use the
# same owned slot/release lifecycle, but an entirely different local data model.
local_setup = '''\tif not SceneRouter.is_world_map_scene(scene.scene_id):
\t\tif not is_instance_valid(_primary_hud) or not CITY_LOCAL_MINIMAP.accepts(scene): return
\t\tvar local_map: Control = CITY_LOCAL_MINIMAP.new()
\t\tlocal_map.name = "CityLocalMinimap"
\t\t_primary_hud.add_child(local_map)
\t\tif not local_map.call("configure", self, scene, _player, _world_camera, world_container):
\t\t\tlocal_map.queue_free(); return
\t\t_world_travel_minimap = local_map
\t\treturn
'''
after[field] = edit(before[field], [
    ('const WORLD_TRAVEL_MINIMAP := preload("res://scripts/ui/world_travel_minimap.gd")', 'const WORLD_TRAVEL_MINIMAP := preload("res://scripts/ui/world_travel_minimap.gd")\nconst CITY_LOCAL_MINIMAP := preload("' + ROOT + 'city_minimap.gd")'),
    ('func _setup_world_travel_minimap(scene: SceneScript) -> void:\n', 'func _setup_world_travel_minimap(scene: SceneScript) -> void:\n' + local_setup),
])
region_setup = '''func _setup_world_travel_minimap(scene: SceneScript) -> void:
\t_release_world_travel_minimap()
\tif not is_instance_valid(_primary_hud): return
\tvar local_map: Control = CityLocalMinimap.new()
\tlocal_map.name = "CityLocalMinimap"
\t_primary_hud.add_child(local_map)
\tif not local_map.call("configure", self, scene, _player, _world_camera, world_container, _region):
\t\tlocal_map.queue_free(); return
\t_world_travel_minimap = local_map

'''
after[region] = edit(before[region], [
    ('const GardenVisual = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_visual.gd")', 'const GardenVisual = preload("' + ROOT + 'garden_visual.gd")\nconst CityLocalMinimap = preload("' + ROOT + 'city_minimap.gd")'),
    ('\t_publish_region_navigation()\n\nfunc _region_fail(reason: String) -> void:', '\t_publish_region_navigation()\n\t_setup_world_travel_minimap(scene)\n\n' + region_setup + 'func _region_fail(reason: String) -> void:'),
    ('\tfor row: Dictionary in _region.surfaces:\n', '\tfor row: Dictionary in _region.surfaces:\n\t\tif not GardenVisual.visible_surface(_region, row): continue\n'),
])
after[town] = edit(before[town], [('\tTOWNS.ensure_watcher(SceneRouter)\n', '\tTOWNS.ensure_watcher(SceneRouter)\n\t_setup_world_travel_minimap(scene)\n')])
# Culture deliberately remains exact for Field. Advance this one real source
# pin and its coordinator contract literal; do not generalize its admission.
after[ct] = edit(before[ct], [('"' + field + '": "' + oldsha[field] + '"', '"' + field + '": "' + sha(after[field]) + '"')])
after[coord] = edit(before[coord], [(oldsha[ct], sha(after[ct]))])
assert b'path != "res://scripts/autoload/scene_router.gd" or not AP_NPC._source_matches' in after[coord]

art = GAME.parent / 'assets/staging/luoyang_garden_paths_20261030a_art01/visual_path_proposal.json'
spec = art.read_bytes()
assert json.loads(spec)['region_id'] == 'luoyang_estate_region_27d'
# New source file emitted by the preparation program, never a canonical edit.
spec_path = BASE / 'visual_paths.json'
if spec_path.exists(): assert spec_path.read_bytes() == spec
else:
    with spec_path.open('xb') as f: f.write(spec)

value = json.loads(before[manifest]); original_bins = copy.deepcopy(value['compiled_bindings'])
modules = value['runtime_modules']
for p, b in after.items():
    if p in modules:
        assert modules[p] == oldsha[p], p
        modules[p] = sha(b)
for name in ['city_minimap.gd', 'garden_visual.gd', 'visual_paths.json']:
    p = ROOT + name
    assert p not in modules
    modules[p] = sha(read(p))
assert value['compiled_bindings'] == original_bins
after[manifest] = enc(value)
old_header = re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"', before[router]).group(0)
new_header = b'const REGION27D_AUTHOR_SHA := "' + sha(after[manifest]).encode() + b'"'
after[router] = edit(before[router], [(old_header, new_header)])

# Complete immutable snapshots and whole inverses for the three owned sources.
old_ex = json.loads(before[ex]); text = before[ex].decode()
extras = {ROOT + name: sha(read(ROOT + name)) for name in ['city_minimap.gd', 'garden_visual.gd', 'visual_paths.json']}
owned_added = []
for p in [field, coord, router]:
    row = copy.deepcopy(old_ex['owned'][p]); assert row['current_sha256'] == oldsha[p]
    old_snapshot = next(e['new_snapshot'] for e in reversed(row['edges']) if e['new_sha256'] == oldsha[p])
    assert read(old_snapshot) == before[p]
    snapshot = output(Path(p).name, after[p]); extras[snapshot] = sha(after[p])
    row['current_sha256'] = sha(after[p]); row['edges'].append({'path': p, 'old_sha256': oldsha[p], 'new_sha256': sha(after[p]), 'old_snapshot': old_snapshot, 'new_snapshot': snapshot, 'whole_inverse': True, 'replacements': hunks(before[p], after[p])})
    marker = '    ' + json.dumps(p) + ': '
    start = text.index(marker) + len(marker)
    _, used = json.JSONDecoder().raw_decode(text[start:])
    replacement = json.dumps(row, ensure_ascii=False, indent=2).replace('\n', '\n    ')
    text = text[:start] + replacement + text[start + used:]
    owned_added.append(p)
start = text.index('  "source_sha256": {'); end = text.index('\n  }', start)
assert not any(p in old_ex['source_sha256'] for p in extras)
text = text[:end] + ''.join(',\n    ' + json.dumps(p) + ': ' + json.dumps(h) for p, h in extras.items()) + text[end:]
after[ex] = text.encode()
new_ex = json.loads(after[ex])
assert all(new_ex['source_sha256'][p] == h for p, h in old_ex['source_sha256'].items())
for p in old_ex['owned']:
    assert new_ex['owned'][p]['edges'][:len(old_ex['owned'][p]['edges'])] == old_ex['owned'][p]['edges']
after[ei] = edit(before[ei], [(oldsha[ex], sha(after[ex]))])

def source_update(raw, known):
    value = json.loads(raw); changes = {}
    def walk(node):
        if isinstance(node, dict):
            for key, member in node.items():
                if key in ('source_sha256', 'legacy_source_sha256', 'source_delta') and isinstance(member, dict):
                    for p, h in member.items():
                        if p in known and p in oldsha and h == oldsha[p] and known[p] != h:
                            changes['"' + p + '": "' + h + '"'] = '"' + p + '": "' + known[p] + '"'
                else: walk(member)
        elif isinstance(node, list):
            for member in node: walk(member)
    walk(value)
    result = raw
    for old, new in changes.items():
        assert old.encode() in result
        result = result.replace(old.encode(), new.encode())
    # Only append source pins to the established metadata source maps.
    key = 'legacy_source_sha256' if 'legacy_source_sha256' in value else 'source_sha256'
    if key in value:
        text = result.decode(); start = text.index('  "' + key + '": {'); end = text.index('\n  }', start)
        pins = {p: h for p, h in extras.items() if p not in value[key]}
        text = text[:end] + ''.join(',\n    ' + json.dumps(p) + ': ' + json.dumps(h) for p, h in pins.items()) + text[end:]
        result = text.encode()
    return result

known = {p: sha(b) for p, b in after.items()}
pending = [p for p in paths if p not in after]
def dependencies(p): return {q for q, h in oldsha.items() if q != p and h.encode() in before[p]}
for _ in range(len(paths)):
    progress = False
    for p in list(pending):
        if any(q in pending for q in dependencies(p)): continue
        if p.endswith('.json'): candidate = source_update(before[p], known)
        else:
            changes = [(oldsha[q], known[q]) for q in known if oldsha[q] != known[q] and oldsha[q].encode() in before[p]]
            candidate = edit(before[p], changes) if changes else before[p]
        if candidate != before[p]: after[p] = candidate; known[p] = sha(candidate)
        pending.remove(p); progress = True
    if not pending: break
    assert progress, ('dependency cycle', pending)
assert not pending

targets = []; gd_hunks = []
for p, data in after.items():
    name = Path(p).name
    if name in outputs and outputs[name] != data: name = p[6:].replace('/', '__')
    candidate = output(name, data)
    targets.append({'target': 'game/' + p[6:], 'candidate': 'game/' + candidate[6:], 'old_sha256': oldsha[p], 'new_sha256': sha(data), 'bytes': len(data)})
    if p.endswith('.gd'): gd_hunks.append({'target': 'game/' + p[6:], 'replacements': hunks(before[p], data)})
OUT.mkdir()
for name, data in outputs.items():
    with (OUT / name).open('xb') as f: f.write(data)
receipt = {'status': 'CANDIDATES_ONLY_NOT_ENGINE_VALIDATED', 'targets': targets, 'owned_edges_added': owned_added, 'old_EX_keys_preserved': True, 'all_ten_bins_unchanged': True, 'native_registry_and_sources_unchanged': True, 'canonical_writes': 0, 'engine_runs': 0}
for name, data in [('receipt_READY.json', enc(receipt)), ('hunks_READY.json', enc({'targets': gd_hunks})), ('auth_READY.json', enc({'sources': {r['target']: {'sha256': r['new_sha256'], 'bytes': r['bytes']} for r in targets}, 'new_modules': {'game/' + p[6:]: {'sha256': h, 'bytes': len(read(p))} for p, h in extras.items()}}))]:
    with (OUT / name).open('xb') as f: f.write(data)
print(json.dumps({'targets': len(targets), 'owned_edges_added': owned_added, 'receipt_sha256': sha(enc(receipt)), 'canonical_writes': 0, 'engine_runs': 0}))
