"""Join the four actual terminals, ART exact stations and six concrete rooms.
Civic21844 is inherited. No old extraction, world sampling or canonical write.
"""
from pathlib import Path
import copy, hashlib, json, re

N = Path(__file__).resolve().parent
G = N.parents[1]
A = G / 'build/luoyang_city_rebuild_20261027d_art01'
S = G / 'build/luoyang_city_rectification_20261027d_system01'
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()

def fixed(path, expected):
    raw = path.read_bytes()
    assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)

def create(path, data):
    assert not path.exists(), str(path)
    raw = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode()
    path.write_bytes(raw)
    return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}

author = fixed(N / 'regions_author02_real_civic_BUILD.json', '371d452a2b35198cccbccda276145a5e5cd171bbfbf3b517fbbb23ba8315b49a')
estate = fixed(A / 'estate_exact_stations06_BUILD_ONLY.json', '5aea5ec318d1638a52f34e7e5e4a142f6729d23fa75267d5548cf39e5f6dd9e1')
temple = fixed(A / 'temple_exact_stations05_BUILD_ONLY.json', 'a9598886e05d315f3ebc8f7f21bc407d0b8e27ff7a82198aff0683892a8c556d')
author['status'] = 'THREE_REGIONS_SIX_ROOMS_COMPILE_CANDIDATE_NO_RUNTIME_ADOPTION'
author['adoption_enabled'] = False
for region_id, patch, key in [('luoyang_estate_region_27d', estate, 'estate_district_patch'), ('luoyang_temple_region_27d', temple, 'temple_district_patch')]:
    definition = author['regions'][region_id]
    district = definition['districts'][0]
    station = patch[key]
    for field in ['legacy_size_px', 'legacy_version', 'legacy_frame_origin', 'save_fallback_uv', 'actors', 'portals', 'interactions', 'station_transforms', 'migrations', 'display_name']:
        if field in station: district[field] = copy.deepcopy(station[field])
    # Author used +.01 solely to close its final map edge. Core already has an
    # exact UV=1 outer-edge rule; replace only that declared exterior overhang.
    for migration in district['migrations']:
        for axis in range(2):
            start, length = migration['old_rect'][0][axis], migration['old_rect'][1][axis]
            maximum = district['legacy_size_px'][axis]
            if start + length > maximum:
                assert round(start + length - maximum, 5) == .01
                migration['old_rect'][1][axis] = maximum - start
    district['legacy_version_migrations'] = {str(v): copy.deepcopy(district['migrations']) for v in [1, 2]}
    definition['routes'] = [r for r in definition['routes'] if r['id'] not in patch.get('routes_replace_ids', [])] + copy.deepcopy(patch['routes_additions'])
    definition['portal_region_return_feet'] = {district['logical_id']: copy.deepcopy(patch['portal_region_return_feet'])}
    binding = copy.deepcopy(patch['source_terminal']['terminal'])
    binding['sha256'] = binding['sha256'].lower()
    assert sha((G / binding['path'][6:]).read_bytes()) == binding['sha256']
    author['terminal_bindings'][district['logical_id']] = binding
    definition['auxiliary_render_children'] = []

estate_region = author['regions']['luoyang_estate_region_27d']
estate_region['retired_portal_ids'] = [r['legacy_id'] for r in estate['portal_replacements']]
estate_region['resident_transfers'] = []
for transfer in estate['room_resident_reassignments']:
    room = next(r for r in estate_region['rooms'] if r['id'] == transfer['room_id'])
    room['residents'] = [{'source_logical_id': transfer['source_logical_id'], 'npc_id': transfer['npc_id'], 'foot_px': transfer['foot_px']}]
    estate_region['resident_transfers'].append({'source_logical_id': transfer['source_logical_id'], 'npc_id': transfer['npc_id'], 'target_room': transfer['room_id']})

profiles = fixed(S / 'region_auxiliary_fixed_door_specs_BUILD.json', '223de3596b7cb1bf2b9a16eb310892a60c58a18e0f961f9d46f98485fb71a1c3')['profiles']
estate_region['auxiliary_render_children'].append(copy.deepcopy(profiles[0]['descriptor']))
temple_region = author['regions']['luoyang_temple_region_27d']
for parent_key in [profiles[1]['descriptor']['parent_key'], profiles[1]['second_exact_parent_key']]:
    descriptor = copy.deepcopy(profiles[1]['descriptor']); descriptor['parent_key'] = parent_key
    temple_region['auxiliary_render_children'].append(descriptor)
# Original estate_al_door_main_hall remains in the retained owner set. Do not
# attach the third hall profile and double that existing independent dark layer.

lookup = json.loads((N / 'terminal_estate_texture_input_ROOT_READY02.json').read_text(encoding='utf8'))['available_parent_sources']

def media(path):
    assert path in lookup
    sidecar = path + '.import'
    raw = (G / sidecar[6:]).read_bytes(); assert sha(raw) == lookup[sidecar]
    ctex = re.search(rb'path="(res://[^"\r\n]+\.ctex)"', raw)[1].decode()
    return {p: lookup[p] for p in [path, sidecar, ctex]}

author['media_authority'] = {}
author['furniture_donor_bindings'] = {}
for name in ['mansion_reception', 'scholar_study', 'guest_room']:
    path = 'res://data/maps/luoyang_assembled_interiors_20261016g/' + name + '_author.json'
    data = fixed(G / path[6:], lookup[path])
    logical = data['room']['scene_id']
    author['furniture_donor_bindings'][logical] = {'path': path, 'sha256': lookup[path], 'logical_id': logical}
    for item in data['furniture']: author['media_authority'].update(media(item['texture']))

wall_texture = 'res://art/modules/luoyang_assembled_interiors_20261016g/shell_formal_hall_v1.png'
wall_shader = N / 'room_wall_patch_repeat.gdshader'
wall_sources = media(wall_texture); wall_sources[res(wall_shader)] = sha(wall_shader.read_bytes())
author['room_wall_material'] = {'texture': wall_texture, 'shader': res(wall_shader), 'source_size_px': [1536, 1024], 'wall_patch_px': [[650, 210], [250, 100]], 'cap_patch_px': [[650, 180], [250, 14]], 'source_sha256': wall_sources, 'policy': 'Repeated material samples only; full original shell is not stretched into new room geometry.'}

portrait_receipt_path = G / 'build/luoyang_city_finish_20261025i_system01/qa_role_new/monk_portraits2_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
sprite_receipt_path = G / 'build/luoyang_city_finish_20261025i_art01/monks19_three_media_promoted_ROOT_ACTUAL.json'
portrait = fixed(portrait_receipt_path, '5edf8edbb346cc856273e75bb63f296276ff23ef415f67de2998b71bd40ff42f')
sprite = fixed(sprite_receipt_path, '350408128265e5e408da64b6b5feaddc51e727de4d0c13f78cb906ae803a87a4')
sprite_rows = sprite.get('copied', sprite.get('written', []))
pair_sources = {r['path']: r['sha256'].lower() for r in portrait['written'] if 'cave_keeper_elder' in r['path']}
for row in sprite_rows:
    path = row.get('path', row.get('target_res', ''))
    if 'cave_keeper_elder_idle' in path: pair_sources[path] = row['sha256'].lower()
assert len(pair_sources) == 6, sprite.keys()
old = 'res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png'
temple_region['actor_visual_overrides'] = [{'source_logical_id': 'ch4_s4_ancient_temple', 'npc_id': 'temple_cave_keeper_20261018t', 'before': {'sprite_path': old, 'portrait_path': old}, 'after': {'sprite_path': 'res://art/characters/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1_runtime.png', 'portrait_path': 'res://art/characters/portraits/luoyang_city_finish_20261025i/cave_keeper_elder_portrait_v1.png'}, 'source_sha256': pair_sources, 'frame_size_px': [160, 160], 'preserve_all_other_actor_fields': True, 'provenance': [{'path': res(sprite_receipt_path), 'sha256': sha(sprite_receipt_path.read_bytes())}, {'path': res(portrait_receipt_path), 'sha256': sha(portrait_receipt_path.read_bytes())}]}]

author['compile_provenance'] += [{'path': res(A / filename), 'sha256': sha((A / filename).read_bytes())} for filename in ['estate_exact_stations06_BUILD_ONLY.json', 'temple_exact_stations05_BUILD_ONLY.json']]
author_pin = create(N / 'regions_author03_three_real_rooms_BUILD.json', author)
worker = N / 'three_regions_rooms_compile_worker_ROOT_READY01.gd'
module_names = ['region_compiler.gd', 'region_content_compiler.gd', 'region_content_rooms02.gd', 'region_room_compiler.gd', 'region_actor_visuals.gd', 'room_furniture_terminal.gd', worker.name]
modules = {res(N / name): sha((N / name).read_bytes()) for name in module_names}
civic_path = N / 'civic_compile_output/21844/civic_region.bin'
civic_raw = civic_path.read_bytes(); assert sha(civic_raw) == 'bfa4d8cb35c2811de7d700cc2603d88eabbd8d7a1ad9e6946796742ded93b3d9'
input_data = {'root_authorized': True, 'authorization_scope': 'Root authorized one fixed three-region/six-room pure compilation; not execution or runtime adoption.', 'author': author_pin, 'module_sources': modules, 'inherited_civic': {'path': res(civic_path), 'sha256': sha(civic_raw), 'bytes': len(civic_raw)}, 'output_root': res(N / 'three_regions_rooms_compile_output'), 'scope': 'Four actual terminals inherited; only two new exterior authors and six interiors compiled. No Field, legacy owner, reprojection, pixels, save or canonical writes.'}
inp = create(N / 'three_regions_rooms_compile_input_ROOT_READY01.json', input_data)
boot = (N / 'civic_author_compile_bootstrap_ROOT_READY01.gd').read_text(encoding='utf8')
boot = boot.replace('civic_author_compile_input_ROOT_READY01.json', 'three_regions_rooms_compile_input_ROOT_READY01.json').replace('451ee781789758c6d39be967c9a2240db417442efe76cfedb7884584c7c21af1', inp['sha256']).replace('civic_author_compile_worker_NOTREADY.gd', worker.name).replace('636d1a8a4b4167c2bea9cb9c49bb2457256247715002c6cffeb6e10275ba1f96', modules[res(worker)])
bootstrap = N / 'three_regions_rooms_compile_bootstrap_ROOT_READY01.gd'
assert not bootstrap.exists(); bootstrap.write_text(boot, encoding='utf8', newline='\n')
print(json.dumps({'author': author_pin, 'input': inp, 'bootstrap_sha256': sha(bootstrap.read_bytes()), 'worker_sha256': modules[res(worker)], 'groups': 'Civic inherited + two courts + six rooms', 'canonical_writes': 0}))
