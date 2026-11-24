"""One bounded visual/body retirement publication; no engine or canonical writes."""
from pathlib import Path
import copy, hashlib, json, struct

N = Path(__file__).resolve().parent
G = N.parents[1]
O = N / 'visual_finish04_BUILD'
sha = lambda b: hashlib.sha256(b).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
enc = lambda d: (json.dumps(d, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode('utf8')

def read_pin(path, expected):
    raw = path.read_bytes()
    assert sha(raw) == expected, str(path)
    return raw

def pin(path):
    b = path.read_bytes()
    return dict(path=res(path), sha256=sha(b), bytes=len(b))

def create(path, raw):
    assert not path.exists(), str(path)
    path.write_bytes(raw)
    return pin(path)

manifest = json.loads(read_pin(N / 'region_runtime_manifest_BUILD.json', '85c16eb0506e60bb3b0310218bb942beafd90840f447b503d5e231de43be6023'))
author_path = G / manifest['author']['path'][6:]
author_raw = read_pin(author_path, '66cdda9904b49651c75d81e1a60e0d7fefc006bb8bbcd5280965c022b236e149')
author = json.loads(author_raw)
parent_field = read_pin(N / 'region_field.gd', 'e61e0ebc917735683a5f720eb3cbfa7157bd1eb2c97d463f2a7a94c1b489a4cd')
source = (N.parent / 'luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
env = {'struct': struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')], env)

soil = author['texture_roles']['service_earth']
underlay = dict(texture=soil['path'], source_sha256=soil['source_sha256'], period_px=[384, 256], z_index=-1100, decorative_only=True)
names = {'ch4_s1_luoyang_yamen': '洛阳·府衙街', 'ch4_s3_luoyang_market': '洛阳·南市', 'luoyang_estate_riverside_20261021ai': '洛阳·宅园', 'ch4_s4_ancient_temple': '古寺·山门五院'}
ids = ['luoyang_civic_market_region_27d', 'luoyang_estate_region_27d', 'luoyang_temple_region_27d']
counts = [(109, 130, 0), (77, 86, 32), (54, 59, 24)]
components = []
for region_id, expected in zip(ids, counts):
    binding = manifest['compiled_bindings'][region_id]
    raw = read_pin(G / binding['path'][6:], binding['sha256'])
    d = env['FrozenVariant'](raw)
    c = d.value()
    assert d.p == len(raw) and (len(c['render']), len(c['solids'])) == expected[:2]
    retired = [r for r in c['render'] if r['texture'].endswith('/native_wall_vertical.png') or r['owner_id'] in ['seven26c_temple_west_pilgrim_front', 'seven26c_temple_east_pilgrim_front']]
    assert len(retired) == expected[2]
    definition = author['regions'][region_id]
    definition['visual_underlay'] = copy.deepcopy(underlay)
    definition['hud_display_names'] = {k: names[k] for k in c['districts']}
    keys = [r['key'] for r in retired]
    owners = {}
    for r in retired:
        reused = 'reused_source_owner' in r
        owners[('reused/' + r['id']) if reused else r['key']] = r['key']
        if not reused:
            district = next(t for t in definition['districts'] if t['logical_id'] == r['logical_id'])
            assert r['owner_id'] not in district['retired_owners']
            district['retired_owners'].append(r['owner_id'])
            for plot in district['plots']:
                if r['owner_id'] in plot['owners']: plot['owners'].remove(r['owner_id'])
            district['plots'] = [p for p in district['plots'] if p['owners']]
    retired_ids = {r['id'] for r in retired if 'reused_source_owner' in r}
    definition['reused_instances'] = [r for r in definition.get('reused_instances', []) if r['id'] not in retired_ids]
    item = dict(id=region_id, parent=binding, retire_keys=keys, retire_owner_to_key=owners)
    if region_id == ids[0]:
        item['door'] = dict(key='ch4_s1_luoyang_yamen/to_city_gate', old_foot=[3072, 2160], old_return=[3072, 2100], foot=[720, 2090], return_foot=[1000, 2110], routes=[[[720, 2090], [720, 2110], [1000, 2110], [3072, 2110], [3072, 2100]]])
        yamen = next(t for t in definition['districts'] if t['logical_id'] == 'ch4_s1_luoyang_yamen')
        assert yamen['portals']['to_city_gate'] == [3072, 2160]
        yamen['portals']['to_city_gate'] = [720, 2090]
        definition['portal_region_return_feet']['ch4_s1_luoyang_yamen']['to_city_gate'] = [1000, 2110]
        route = next(r for r in definition['routes'] if r['id'] == 'yamen_gate_hall')
        assert route['points_px'] == [[3072, 2160], [3072, 2040], [3072, 1040], [3072, 940]]
        route['points_px'] = [[720, 2090], [720, 2110], [1000, 2110], [3072, 2110], [3072, 2040], [3072, 1040], [3072, 940]]
    components.append(item)

author['visual_rectification04'] = {'status': 'ROOT_APPROVED_INCREMENTAL_DATA_NOT_ART_ACCEPTANCE', 'retired_proxy_rows': 54, 'retired_isolated_short_walls': 2, 'positive_ground_expansion': False, 'new_assets': False}
edits = [
    ('func _draw_region_surfaces() -> bool:\n', 'func _draw_region_surfaces() -> bool:\n\tif not _draw_region_underlay(): return false\n'),
    ('func _draw_room_enclosure() -> bool:\n', '''func _draw_region_underlay() -> bool:
	var descriptor: Dictionary = _region.get("visual_underlay", {})
	if descriptor.is_empty(): return true # Authored interiors keep their own floor.
	var path: String = String(descriptor.get("texture", ""))
	if descriptor.get("decorative_only") != true or descriptor.get("z_index") != -1100 or descriptor.get("source_sha256", {}).get(path) != _region_sources.get(path) or not _region_sources.has(path): return false
	var texture: Texture2D = load(path) as Texture2D
	var period: Vector2 = RegionCompiler.vec(descriptor.get("period_px"))
	if texture == null or not period.is_finite() or period.x <= 0 or period.y <= 0: return false
	var floor := Polygon2D.new(); floor.name = "RegionDecorativeUnderlay"
	floor.texture = texture; floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(_world_size.x, 0), _world_size, Vector2(0, _world_size.y)])
	var uv := PackedVector2Array()
	for point: Vector2 in floor.polygon: uv.append(point / period * texture.get_size())
	floor.uv = uv; floor.z_index = -1100; _visual_layer.add_child(floor)
	return true

func _draw_room_enclosure() -> bool:
'''),
    ('\tEventBus.scene_entered.emit(StringName(logical_id))\n', '\tvar display_name: String = _current_scene.display_name if _region.get("navigation_kind") == "AUTHORED_INTERIOR" else String(_region.get("hud_display_names", {}).get(source_id, source.display_name))\n\tif scene_title != null: scene_title.text = display_name\n\tif _primary_hud != null: _primary_hud.set_scene_info(display_name)\n\tEventBus.scene_entered.emit(StringName(logical_id))\n')
]
field = parent_field.decode('utf8')
for before, after in edits:
    assert field.count(before) == 1
    field = field.replace(before, after, 1)
inverse = field
for before, after in reversed(edits):
    assert inverse.count(after) == 1
    inverse = inverse.replace(after, before, 1)
assert inverse.encode() == parent_field and field.endswith('\n') and not field.endswith('\n\n')
assert not O.exists()
O.mkdir()
author_pin = create(O / 'regions_author08_visual_rectification_BUILD.json', enc(author))
field_pin = create(O / 'region_field_visual_CANDIDATE.gd', field.encode())
worker = N / 'visual_rectification_delta_ROOT_READY01.gd'
module_sources = {res(worker): pin(worker)['sha256'], res(N / 'region_compiler.gd'): manifest['runtime_modules'][res(N / 'region_compiler.gd')], res(N / 'civic_three_building_delta_ROOT_READY.gd'): pin(N / 'civic_three_building_delta_ROOT_READY.gd')['sha256']}
data = dict(root_authorized=True, scope='Only three frozen outdoor bins: decorative soil/HUD, 54 proxy+2 isolated render/body retirement and one bound Gate door relocation. No mask/import/full compile/routes matrix/Field.', parent_author=manifest['author'], author=author_pin, terminals={k:v for k,v in author['terminal_bindings'].items() if k in ['luoyang_estate_riverside_20261021ai','ch4_s4_ancient_temple']}, components=components, module_sources=module_sources, output_root=res(O / 'output'))
input_pin = create(O / 'visual_delta_input_ROOT_READY01.json', enc(data))
bootstrap = (N / 'runtime_syntax_bootstrap_ROOT_READY03.gd').read_text(encoding='utf8')
for a, b in [('res://build/luoyang_regions_20261027d_source01/runtime_syntax_input_ROOT_READY03.json', input_pin['path']), ('926efa34a4dd267d5b03fb982385c5e284d5de3398ca7c7eaa82aa105e7fd8ad', input_pin['sha256']), ('res://build/luoyang_regions_20261027d_source01/runtime_syntax_worker_ROOT_READY01.gd', res(worker)), ('a6ac5de71527f6ea94c93160fbe6be1f2eef2315ccd96befc7697b3c1951f461', module_sources[res(worker)])]:
    assert bootstrap.count(a) == 1
    bootstrap = bootstrap.replace(a, b, 1)
boot_pin = create(O / 'visual_delta_bootstrap_ROOT_READY01.gd', bootstrap.encode())
proof = dict(parent_Field=pin(N / 'region_field.gd'), candidate_Field=field_pin, hunks=[dict(before=a, after=b) for a,b in edits], full_UTF8_inverse=True, original_phase_and_Dialog_business_unchanged=True, parent_manifest=pin(N / 'region_runtime_manifest_BUILD.json'), author=author_pin, worker=pin(worker), input=input_pin, bootstrap=boot_pin, canonical_writes=0, engine_calls=0)
proof_pin = create(O / 'visual_Field_whole_inverse_BUILD.json', enc(proof))
print(json.dumps(dict(author=author_pin, Field=field_pin, worker=pin(worker), input=input_pin, bootstrap=boot_pin, proof=proof_pin)))
