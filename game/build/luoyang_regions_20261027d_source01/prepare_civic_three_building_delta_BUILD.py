"""Freeze the one Civic delta after Root's single three-image promotion."""
from pathlib import Path
import copy, hashlib, json, re
N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda path: 'res://' + path.relative_to(G).as_posix()
enc = lambda value: (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
def fixed(path, expected):
    raw = path.read_bytes(); assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)
def create(path, raw):
    assert not path.exists(), str(path); path.write_bytes(raw)
    return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}
parent = N / 'regions_author05_temple_route_residual_BUILD.json'
author = fixed(parent, 'd91a022ca806cfbf4ec004966874ebaecb94464bea797d54971da45501cfa49d')
annotation_path = G / 'build/luoyang_city_rebuild_20261027d_art01/three_PADDED_native_ground_doors10_ROOT_ACTUAL.json'
annotations = fixed(annotation_path, 'e9737d4a0e25261f6e19daa693b5349f53d658bdef9b02527521bd7251955968')
permission = N / 'root_integration_scope08_AUTHORIZED.json'
fixed(permission, '9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919')
promotion_path = G / 'build/luoyang_city_rectification_20261027d_system01/three_building_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
promotion_raw = promotion_path.read_bytes()
promotion = json.loads(promotion_raw)
assert promotion['passed'] is True and len(promotion['written']) == 9
rows = {r['path']: r for r in promotion['written']}
definition = author['regions']['luoyang_civic_market_region_27d']
before = copy.deepcopy(author)
for building in definition['pending_buildings']:
    geometry = next(row for row in annotations['rows'] if row['id'] == building['id'])
    native = geometry['native']
    candidates = [path for path in rows if path.endswith('.png') and Path(path).stem in [building['id'], building['id'] + '_padded']]
    assert len(candidates) == 1
    texture = candidates[0]; sidecar = texture + '.import'
    assert rows[texture]['sha256'].lower() == native['sha256'].lower()
    side_raw = (G / sidecar[6:]).read_bytes(); assert sha(side_raw) == rows[sidecar]['sha256'].lower()
    ctex = re.findall(rb'^path="(res://[^"\r\n]+\.ctex)"\r?$', side_raw, re.M)
    assert len(ctex) == 1
    sources = {p: rows[p]['sha256'].lower() for p in [texture, sidecar, ctex[0].decode()]}
    alpha = native['complete_A1']
    asset = {'texture': texture, 'native_size_px': native['size_px'], 'native_ground_anchor_px': geometry['render_transform']['source_anchor_px'], 'world_scale': geometry['render_transform']['uniform_scale'], 'source_sha256': sources, 'complete_alpha_rect_px': [alpha[:2], [alpha[2]-alpha[0], alpha[3]-alpha[1]]], 'native_closed_ground_polygon_px': geometry['source_closed_footprint_before_door_difference'], 'native_front_walk_channel_px': geometry['source_door_walk_channel_to_subtract'], 'body_operator': 'EXACT_GODOT_POLYGON_CLOSED_MINUS_FRONT_CHANNEL', 'ground_source_is_not_alpha_bbox': True}
    assert building['target_foot_px'] == geometry['render_transform']['target_foot_px']
    assert building['uniform_scale'] == asset['world_scale']
    building['adoption_enabled'] = True
    building['status'] = 'ROOT_IMPORTED_NATIVE_READY_PENDING_DELTA_COMPONENT_AND_FIELD'
    building['asset_binding'] = asset
for replacement in definition['pending_replacements']:
    replacement['assets_ready'] = True
author['adoption_enabled'] = True
author['status'] = 'NATIVE_THREE_BUILDING_DELTA_READY_NOT_FIELD_ACCEPTANCE'
author['native_building_publication'] = {'operator': 'civic_three_building_delta_ROOT_READY.gd', 'parent_component': 'civic21844', 'old_successful_components_inherited': 9, 'retirement_is_atomic_with_three_media_and_true_ground': True, 'source': {'path': res(annotation_path), 'sha256': sha(annotation_path.read_bytes())}, 'promotion': {'path': res(promotion_path), 'sha256': sha(promotion_raw)}, 'Root_authorization': {'path': res(permission), 'sha256': sha(permission.read_bytes())}}
author_path = N / 'regions_author06_native_buildings_BUILD.json'
author_pin = create(author_path, enc(author))
# Reversing these explicit data edits yields the entire prior author exactly.
inverse = copy.deepcopy(author)
inverse['regions']['luoyang_civic_market_region_27d']['pending_buildings'] = before['regions']['luoyang_civic_market_region_27d']['pending_buildings']
inverse['regions']['luoyang_civic_market_region_27d']['pending_replacements'] = before['regions']['luoyang_civic_market_region_27d']['pending_replacements']
inverse['adoption_enabled'] = before['adoption_enabled']; inverse['status'] = before['status']; del inverse['native_building_publication']
assert enc(inverse) == parent.read_bytes()
aprons = fixed(G / 'build/luoyang_city_rebuild_20261027d_art01/pending_raw_three_door_aprons01_BUILD_ONLY.json', '70af8091d33cd28890d660dd0405bd41d5620099b251f30eaf7d580ecadc6fe1')
worker = N / 'civic_three_building_delta_ROOT_READY.gd'
module_sources = {res(worker): sha(worker.read_bytes()), res(N / 'region_compiler.gd'): '55899bec695743c7229e19f6c156b03de467a7f147b9651a32e21e4e254b5e04'}
data = {'root_authorized': True, 'authorization_scope': 'Root08: only native three-building Civic delta; not engine execution or Field acceptance.', 'author': author_pin, 'parent_author': {'path': res(parent), 'sha256': sha(parent.read_bytes())}, 'parent_compiled': {'path': res(N / 'civic_compile_output/21844/civic_region.bin'), 'sha256': 'bfa4d8cb35c2811de7d700cc2603d88eabbd8d7a1ad9e6946796742ded93b3d9', 'bytes': 352248}, 'module_sources': module_sources, 'new_door_routes': [{'id': row['id'] + '_public_front', 'points_px': row['public_approach_route']} for row in aprons['pending_buildings']], 'output_root': res(N / 'civic_three_building_delta_output'), 'scope': 'Only three new true bases/door channels and bounded affected old routes/stations; all nine previous successful components inherited. No original media recapture, full geometry, owner projection or PNG decoding.'}
input_path = N / 'civic_three_building_delta_input_ROOT_READY01.json'
input_pin = create(input_path, enc(data))
parent_boot = N / 'runtime_syntax_bootstrap_ROOT_READY03.gd'
boot = parent_boot.read_bytes()
assert sha(boot) == '4fd668d6a69006a2bb40b8bc6471ced9b7c3fd7d88bc81f9bc75cba1ad4378e5'
for old, new in [('runtime_syntax_input_ROOT_READY03.json', input_path.name), ('926efa34a4dd267d5b03fb982385c5e284d5de3398ca7c7eaa82aa105e7fd8ad', input_pin['sha256']), ('runtime_syntax_worker_ROOT_READY01.gd', worker.name), ('a6ac5de71527f6ea94c93160fbe6be1f2eef2315ccd96befc7697b3c1951f461', module_sources[res(worker)])]:
    assert old.encode() in boot; boot = boot.replace(old.encode(), new.encode())
bootstrap = create(N / 'civic_three_building_delta_bootstrap_ROOT_READY01.gd', boot)
print(json.dumps({'author': author_pin, 'author_whole_inverse': True, 'input': input_pin, 'bootstrap': bootstrap, 'worker_sha256': module_sources[res(worker)]}))
