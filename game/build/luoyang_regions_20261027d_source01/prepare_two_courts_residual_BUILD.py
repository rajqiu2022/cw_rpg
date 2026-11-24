"""Only ART07's kitchen migration and Temple route; inherit seven actual bins."""
from pathlib import Path
import copy, hashlib, json

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda b: hashlib.sha256(b).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()

def fixed(path, expected):
    raw = path.read_bytes(); assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)

def create(path, raw):
    assert not path.exists(), str(path)
    path.write_bytes(raw)
    return sha(raw)

patch_path = G / 'build/luoyang_city_rebuild_20261027d_art01/two_outdoor_residuals07_BUILD_ONLY.json'
patch = fixed(patch_path, '36563638f9019acc882bed04896bff1327a57cdaf7153e16b9676a2b3d600090')
old_author_path = N / 'regions_author03_three_real_rooms_BUILD.json'
old_author = fixed(old_author_path, patch['parent_author']['sha256'])
author = copy.deepcopy(old_author)
for item in patch['patches']:
    region = author['regions'][item['region_id']]
    if item['operation'] == 'replace_target_foot_only_by_unique_reason_in_each_named_migration_array':
        district = next(r for r in region['districts'] if r['logical_id'] == item['logical_id'])
        for path in item['arrays']:
            rows = district
            for key in path.split('.'): rows = rows[key]
            matches = [r for r in rows if r['reason'] == item['reason']]
            assert len(matches) == 1 and matches[0]['target_foot_px'] == item['before'] and matches[0]['old_rect'] == item['preserve_old_rect']
            matches[0]['target_foot_px'] = copy.deepcopy(item['after'])
    else:
        matches = [r for r in region['routes'] if r['id'] == item['id']]
        assert len(matches) == 1 and matches[0]['points_px'] == item['before']
        matches[0]['points_px'] = copy.deepcopy(item['after'])
author_path = N / 'regions_author04_two_courts_residual_BUILD.json'
author_raw = (json.dumps(author, ensure_ascii=False, indent=2) + '\n').encode()
author_sha = create(author_path, author_raw)
inverse = copy.deepcopy(author)
for item in reversed(patch['patches']):
    region = inverse['regions'][item['region_id']]
    if 'logical_id' in item:
        district = next(r for r in region['districts'] if r['logical_id'] == item['logical_id'])
        for path in item['arrays']:
            rows = district
            for key in path.split('.'): rows = rows[key]
            next(r for r in rows if r['reason'] == item['reason'])['target_foot_px'] = item['before']
    else: next(r for r in region['routes'] if r['id'] == item['id'])['points_px'] = item['before']
assert (json.dumps(inverse, ensure_ascii=False, indent=2) + '\n').encode() == old_author_path.read_bytes()

actual = fixed(N / 'three_regions_rooms_compile_output/109892/result.json', patch['actual_failure_result']['sha256'])
assert actual['passed'] is False and len(actual['errors']) == 2 and len(actual['rows']) == 7
inherited = copy.deepcopy(actual['rows'])
for row in inherited:
    binding = row['compiled']; raw = (G / binding['path'][6:]).read_bytes()
    assert sha(raw) == binding['sha256'] and len(raw) == binding['bytes']
    row['inherited'] = True
    row['credit'] = 'Prior successful compiled component; old whole failure retained. No recomputation or Field credit.'
worker0 = N / 'three_regions_rooms_compile_worker_ROOT_READY01.gd'
before = worker0.read_bytes()
assert sha(before) == '68de3bd30275c82c90931958b632ef17957eac93a69eb289f3d083037a4c5c32'
text = before.decode()
text = text.replace('const Rooms = preload("res://build/luoyang_regions_20261027d_source01/region_room_compiler.gd")\n', '').replace('const Furniture = preload("res://build/luoyang_regions_20261027d_source01/room_furniture_terminal.gd")\n', '')
text = text.replace('for logical: String in author.terminal_bindings:', 'for logical: String in input.required_terminal_ids:')
start = text.index('\tfor logical: String in author.furniture_donor_bindings:')
end = text.index('\tvar directory:', start)
text = text[:start] + text[end:]
start = text.index('\tvar inherited: Dictionary = input.inherited_civic')
end = text.index('\tfor identity: String in ids:', start)
text = text[:start] + '''	for component: Dictionary in input.inherited_rows:
		var binding: Dictionary = component.compiled
		if FileAccess.get_sha256(binding.path) != binding.sha256 or FileAccess.get_file_as_bytes(binding.path).size() != int(binding.bytes): result.errors.append("INHERITED_COMPONENT_PIN"); return result
		result.rows.append(component.duplicate(true))
	var ids: Array = ["luoyang_estate_region_27d", "luoyang_temple_region_27d"]
''' + text[end:]
text = text.replace('Courts.compile(author, identity, inputs) if identity not in Rooms.ROOMS else Rooms.compile(author, identity, inputs)', 'Courts.compile(author, identity, inputs)')
text = text.replace('## One cold pure content compile: inherit Civic21844, compile two new courts\n## and their six real rooms. Never reproject the four successful terminals.', '## Only two outdoor residuals. Seven successful compiled bins are inherited;\n## no successful room, terminal, source owner or Civic geometry is recompiled.')
worker = N / 'two_courts_residual_worker_ROOT_READY02.gd'
worker_sha = create(worker, text.encode())
input0 = N / 'three_regions_rooms_compile_input_ROOT_READY01.json'
data = fixed(input0, '6386a8f1b0b91f6d5ecfebdc182ac810d0f99036627c826172dc6c159dbf2a37')
data['author'] = {'path': res(author_path), 'sha256': author_sha, 'bytes': len(author_raw)}
data.pop('inherited_civic')
data['inherited_rows'] = inherited
data['required_terminal_ids'] = ['luoyang_estate_riverside_20261021ai', 'ch4_s4_ancient_temple']
data['module_sources'].pop(res(worker0)); data['module_sources'][res(worker)] = worker_sha
data['module_sources'].pop(res(N / 'room_furniture_terminal.gd'))
data['output_root'] = res(N / 'two_courts_residual_compile_output')
data['scope'] = 'ART07 only kitchen target in three version arrays and one Temple route. Civic and six actual room bins inherited, zero reprojections or geometry changes elsewhere.'
inp = N / 'two_courts_residual_input_ROOT_READY02.json'
input_sha = create(inp, (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode())
boot = (N / 'three_regions_rooms_compile_bootstrap_ROOT_READY01.gd').read_bytes().replace(input0.name.encode(), inp.name.encode()).replace('6386a8f1b0b91f6d5ecfebdc182ac810d0f99036627c826172dc6c159dbf2a37'.encode(), input_sha.encode()).replace(worker0.name.encode(), worker.name.encode()).replace(sha(before).encode(), worker_sha.encode())
bootstrap = N / 'two_courts_residual_bootstrap_ROOT_READY02.gd'
bootstrap_sha = create(bootstrap, boot)
print(json.dumps({'author': res(author_path), 'author_sha256': author_sha, 'author_whole_inverse': True, 'input': res(inp), 'input_sha256': input_sha, 'worker_sha256': worker_sha, 'bootstrap': res(bootstrap), 'bootstrap_sha256': bootstrap_sha, 'inherited': 7, 'residuals': 2}))
