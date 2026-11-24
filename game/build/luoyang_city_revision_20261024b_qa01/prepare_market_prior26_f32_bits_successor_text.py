"""NEW hardfalse text successor: geometry-only f32 ABI comparison, no PNG/PIP/run.

Expected bits come ONLY from the immutable independent F484 source model.
The failed actual is read exclusively by the separate diagnostic comparison.
"""
from pathlib import Path
import copy, difflib, hashlib, json, math, struct

Q = Path(__file__).resolve().parent
GAME = Q.parent.parent
SRC = GAME / 'build/luoyang_city_space_20261024b_source01'
OLD = Q / 'market_mask_prior26_explicit_keys_NOTREADY'
NEW = Q / 'market_mask_prior26_f32_bits_NOTREADY'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p, h):
    assert sha(p) == h, (p, sha(p), h)
    return json.loads(p.read_bytes())
def emit(p, value):
    assert not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes((json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii'))
    return sha(p)
def put(p, data):
    assert not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(data)
    return sha(p)

# First independently construct the expected bits without accessing any actual.
model_path = Q / 'market_mask_prior26_NOTREADY/independent_f32_source_model_NOT_PIP.json'
model = read(model_path, 'f4843526445d6ba40ae2a6358a5786c83b2fcd4544413190390fc71bfc8c4eb3')
def bits(pair):
    assert type(pair) is list and len(pair) == 2
    assert all(type(n) is float and math.isfinite(n) for n in pair)
    packed = struct.pack('<ff', *pair)
    assert list(struct.unpack('<ff', packed)) == pair
    return packed.hex()
def bit_rows(rows):
    out = []
    for row in rows:
        assert set(row) == {'id', 'center', 'size', 'polygons'} and type(row['id']) is str
        out.append({'id': row['id'], 'center_f32_le': bits(row['center']),
                    'size_f32_le': bits(row['size']),
                    'polygons_f32_le': [[bits(p) for p in poly] for poly in row['polygons']]})
    return out
bit_model = {'status': 'FIXED_SOURCE_MODEL_GEOMETRY_ONLY_F32_BITS_NOT_PIP_OR_RGBA_PRIOR',
             'source_model_absolute_path': model_path.as_posix(), 'source_model_sha256': sha(model_path),
             'encoding': 'IEEE754 binary32 coordinate pairs, little-endian Windows ABI; no epsilon',
             'old': bit_rows(model['old']), 'child': bit_rows(model['child'])}
assert len(bit_model['old']) == 23 and len(bit_model['child']) == 25
bit_path = NEW / 'independent_f32_bits_NOT_PIP.json'
bit_sha = emit(bit_path, bit_model)

# Diagnose the existing FAIL, never use it as expected input.
actual_path = GAME / 'build/luoyang_city_revision_20261024b_root01/market_prior26_READY/output/result.json'
actual = read(actual_path, '0812129327237de68f9d28003cca2ed18ea0a19d9da25b4a83f6e8ab370a8ad4')
differences = []
leaf_count = 0
def strict_compare(a, b, path):
    global leaf_count
    if type(a) is not type(b): differences.append({'path': path, 'kind': 'type'}); return
    if isinstance(a, dict):
        if set(a) != set(b): differences.append({'path': path, 'kind': 'keys'}); return
        for k in a: strict_compare(a[k], b[k], path + '/' + k)
    elif isinstance(a, list):
        if len(a) != len(b): differences.append({'path': path, 'kind': 'length'}); return
        for i, (x, y) in enumerate(zip(a, b)): strict_compare(x, y, path + '/' + str(i))
    else:
        leaf_count += 1
        if a != b: differences.append({'path': path, 'kind': 'value'})
for domain in ('old', 'child'):
    strict_compare(actual['records'][0][domain], model[domain], domain)
assert differences == []
assert not actual['complete'] and actual['failures'] == 2 and actual['checks'] == 33
assert actual['Image_decodes'] == actual['native_packet_decodes'] == actual['PNG_outputs'] == 0
diagnosis = {'status': 'ACTUAL23768_FAIL_RETAINED_ZERO_MASK_DECODE_OFFLINE_GEOMETRY_COMPARISON',
             'actual_result': actual_path.as_posix(), 'actual_result_sha256': sha(actual_path),
             'independent_model_sha256': sha(model_path), 'old_rows': 23, 'child_rows': 25,
             'recursive_scalar_leaves_compared': leaf_count, 'strict_python_type_and_value_differences': differences,
             'meaning': 'No evidenced source-expression discrepancy. Runtime expected JSON leaf/typed-container metadata was not recorded; exact Godot equality subreason remains unproven.',
             'not_claimed': ['No successful mask prior', 'No specific parser-versus-container root cause', 'No publisher/runtime admission'],
             'successor': 'Source-model-only f32 bit strings; narrow native Vector2 pair/row shape checking, no arbitrary storage normalization.',
             'preserves_original_actual_and_ALL_prior_files': True, 'PNG_decodes_by_QA': 0, 'engine_runs_by_QA': 0}
diagnosis_sha = emit(NEW / 'actual23768_projection_equality_diagnosis_READONLY.json', diagnosis)

# Final source03: mask fields remain exactly source02, no geometry/PIP replay.
old_author = SRC / 'author_space_delta_threshold_return_successor02_NOTREADY.json'
new_author = SRC / 'author_space_delta_interaction_successor03_NOTREADY.json'
a = read(old_author, '28b2f8126417d0d4af4c804702652347bbc7ed9cdd5f20d2fe6a8401fa54813d')
b = read(new_author, 'cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467')
same_fields = ['assets', 'complete_buildings', 'native_object_moves', 'retire_closed_stall_ids',
               'low_wall_asset', 'low_wall_components', 'changed_mask_domains_closed',
               'runtime_district', 'district_assets', 'district_current_frozen']
assert all(a[k] == b[k] for k in same_fields)
old_input = SRC / 'publication_input_threshold_return_successor02_NOTREADY.json'
new_input = SRC / 'publication_input_interaction_successor03_NOTREADY.json'
read(new_input, '48a3920d65a36e73f08fd003ef1bff3f69bff07291af895cffd92bbdc066abe2')
old_geom = SRC / 'market_replan_geometry_threshold_return_successor02_CANDIDATE.gd'
new_geom = SRC / 'market_replan_geometry_interaction_successor03_CANDIDATE.gd'
assert sha(new_geom) == '25be67db002ceb1db1990cde55b5b237bcec0bbfbee70aea7e4d7c4b193744ec'
fixture_path = OLD / 'fixture_NOTREADY.json'
fixture = read(fixture_path, '7390c0fb4819a91d8c2802261175e3105a4b18ba2c559eb53b502ed9e0d18846')
old_fixture = copy.deepcopy(fixture)
project = NEW / 'project.godot'
put(project, (OLD / 'project.godot').read_bytes())
replacements = [(old_author, new_author), (old_input, new_input), (old_geom, new_geom),
                (OLD / 'project.godot', project)]
for old, new in replacements:
    assert fixture['source_sha256'].pop(old.as_posix()) == sha(old)
    fixture['source_sha256'][new.as_posix()] = sha(new)
fixture['source_sha256'][bit_path.as_posix()] = bit_sha
fixture['independent_f32_bits_absolute_path'] = bit_path.as_posix()
fixture['author_absolute_path'] = new_author.as_posix()
fixture['status'] = 'INDEPENDENT26_DOMAIN_F32_BITS_GEOMETRY_GATE_REPAIR_NOTREADY'
fixture['blockers'] = ['Root must read and authorize the remaining finite mask oracle. Actual23768 whole FAIL is retained; no successful childRGBA/count exists yet.']
fixture_sha = emit(NEW / 'fixture_NOTREADY.json', fixture)
inverse_fixture = copy.deepcopy(fixture)
for old, new in reversed(replacements):
    assert inverse_fixture['source_sha256'].pop(new.as_posix()) == sha(new)
    inverse_fixture['source_sha256'][old.as_posix()] = sha(old)
assert inverse_fixture['source_sha256'].pop(bit_path.as_posix()) == bit_sha
del inverse_fixture['independent_f32_bits_absolute_path']
for k in ('author_absolute_path', 'status', 'blockers'): inverse_fixture[k] = old_fixture[k]
assert inverse_fixture == old_fixture

# Geometry-specific ABI gate only. No generic JSON numeric normalization.
helper = '''func f32_pair_bits(value: Vector2) -> String:
	return PackedFloat32Array([value.x,value.y]).to_byte_array().hex_encode()
func fixed_pair(value: Vector2,expected: Variant,path: String) -> Dictionary:
	var actual: String=f32_pair_bits(value)
	if typeof(expected)!=TYPE_STRING or expected.length()!=16 or not is_finite(value.x) or not is_finite(value.y) or actual!=expected:
		return {"ok":false,"path":path,"actual_f32_le":actual,"expected_f32_le":expected,"reason":"finite native Vector2 exact source-f32 bits"}
	return {"ok":true}
func fixed_geometry_model(rows: Array,expected: Variant,path: String) -> Dictionary:
	if not expected is Array or rows.size()!=expected.size(): return {"ok":false,"path":path,"reason":"row shape"}
	for i: int in rows.size():
		var row: Dictionary=rows[i];var e: Variant=expected[i];var at: String=path+"/"+str(i)
		if not e is Dictionary or e.size()!=4 or typeof(e.get("id"))!=TYPE_STRING or row.id!=e.get("id") or not e.get("polygons_f32_le") is Array:
			return {"ok":false,"path":at,"reason":"exact id/shape"}
		for component: String in ["center","size"]:
			var pair: Dictionary=fixed_pair(row[component],e.get(component+"_f32_le"),at+"/"+component)
			if not pair.ok: return pair
		var polys: Array=e.polygons_f32_le
		if row.polys.size()!=polys.size(): return {"ok":false,"path":at,"reason":"polygon count"}
		for j: int in row.polys.size():
			var poly: PackedVector2Array=row.polys[j];var ep: Variant=polys[j]
			if not ep is Array or poly.size()!=ep.size(): return {"ok":false,"path":at+"/polygons/"+str(j),"reason":"vertex count"}
			for k: int in poly.size():
				var pair: Dictionary=fixed_pair(poly[k],ep[k],at+"/polygons/"+str(j)+"/"+str(k))
				if not pair.ok: return pair
	return {"ok":true,"rows":rows.size(),"comparison":"native binary32 pair bits from independent F484 model, no JSON-double/container equality"}

'''
old_gate = '''	var model: Variant=JSON.parse_string(FileAccess.get_file_as_string(f.independent_f32_model_absolute_path))
	if not check(model is Dictionary and projection(old)==model.get("old") and projection(child)==model.get("child"),"Native original Vector2 expressions exact independent struct-f32 model, before mask/PIP"): return {}
'''
new_gate = '''	var model: Variant=JSON.parse_string(FileAccess.get_file_as_string(f.independent_f32_bits_absolute_path))
	if not check(model is Dictionary,"Fixed source-derived f32 bit model before mask/PIP"): return {}
	var old_bits: Dictionary=fixed_geometry_model(old,model.get("old"),"old")
	var child_bits: Dictionary=fixed_geometry_model(child,model.get("child"),"child")
	records.append({"kind":"SOURCE_MODEL_ONLY_F32_BIT_GEOMETRY_GATE_BEFORE_MASK","old":old_bits,"child":child_bits})
	if not check(old_bits.ok and child_bits.ok,"Native original Vector2 expressions exact independent f32 bits, before mask/PIP"): return {}
'''
old_key = OLD / 'oracle_NOTREADY.gd'
assert sha(old_key) == 'bd46b891b7f62b872538fd468532cd1631ca3582bcf5b0e5456697158e4da224'
source = old_key.read_bytes()
nl = b'\r\n' if b'\r\n' in source else b'\n'
def native(s): return s.replace('\n', nl.decode()).encode()
ops = [(native('func run_prior(f: Dictionary) -> Dictionary:\n'), native(helper + 'func run_prior(f: Dictionary) -> Dictionary:\n')),
       (native(old_gate), native(new_gate)),
       (fixture_path.as_posix().encode(), (NEW / 'fixture_NOTREADY.json').as_posix().encode()),
       (sha(fixture_path).encode(), fixture_sha.encode()),
       ((OLD / 'output_NOTREADY').as_posix().encode(), (NEW / 'output_NOTREADY').as_posix().encode())]
for before, after in ops:
    assert source.count(before) == 1, before[:100]
    source = source.replace(before, after, 1)
inverse = source
for before, after in reversed(ops):
    assert inverse.count(after) == 1
    inverse = inverse.replace(after, before, 1)
assert inverse == old_key.read_bytes()
key = NEW / 'oracle_NOTREADY.gd'
put(key, source)
put(NEW / 'complete_vs_BD46.diff', ''.join(difflib.unified_diff(old_key.read_text().splitlines(True), source.decode().splitlines(True), fromfile=str(old_key), tofile=str(key))).encode())
proof = {'status': 'HARDFALSE_GEOMETRY_F32_BITS_ONLY_GATE_REPAIR_AND_FINAL_SOURCE03_NOT_RUN',
         'key_sha256': sha(key), 'fixture_sha256': fixture_sha, 'project_sha256': sha(project),
         'expected_bits_sha256': bit_sha, 'expected_bits_derived_only_from_F484': True,
         'diagnosis_sha256': diagnosis_sha, 'key_wholebyte_inverse_to_BD46': True,
         'key_only_edits': ['three fixture/output literals', 'one geometry gate', 'three geometry-only bit helpers'],
         'fixture_wholetyped_inverse': True, 'source03_mask_fields_exact_source02': same_fields,
         'raster_body_alpha_domain_algorithm_bytes_unchanged': True,
         'original_model_and_failed_actual_preserved': True,
         'runtime_storage_numeric_normalization': False, 'epsilon': False,
         'fixed_domains': 26, 'fixed_union_pixels': 147805, 'whole_ms': 30000,
         'RGBA_prior_and_changed_pixels': 'UNKNOWN until Root one successful remaining oracle',
         'engine_PNG_packet_PIP_by_QA': 0, 'source_guard_count': len(fixture['source_sha256'])}
proof_sha = emit(NEW / 'wholebyte_inverse_and_handoff_NOTREADY.json', proof)
print(json.dumps({'key': sha(key), 'fixture': fixture_sha, 'project': sha(project), 'bits': bit_sha,
                  'diagnosis': diagnosis_sha, 'proof': proof_sha}, indent=2))
