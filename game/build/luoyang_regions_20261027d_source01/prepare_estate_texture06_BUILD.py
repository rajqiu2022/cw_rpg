"""One Estate-only residual: exact PNG/JPEG/Atlas headers and non-foot layers.
No image decode, geometry change, prior terminal rebuild, engine or adoption.
"""
from pathlib import Path
import collections, hashlib, json, math, re, struct

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda path: 'res://' + path.relative_to(G).as_posix()

def create(path, raw):
    assert not path.exists(), str(path)
    path.write_bytes(raw)
    return sha(raw)

parent = N / 'terminal_estate_atlas_input_ROOT_READY01.json'
before = parent.read_bytes()
assert sha(before) == '7b66ca986a98bff23b8f98a734cd9b9d3f67a904b377f949685416540f793e25'
data = json.loads(before)
binding = data['bindings'][0]
reader = (G / 'build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope = {'struct': struct}
exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')], scope)
raw = (G / binding['payload']['path'][6:]).read_bytes()
assert sha(raw) == binding['payload']['sha256']
payload = scope['FrozenVariant'](raw).value()
rows = payload['effective_navigation']
descriptions = dict(binding['atlas_textures'])

def jpeg_size(raw):
    assert raw[:2] == b'\xff\xd8'
    offset = 2
    while offset < len(raw):
        assert raw[offset] == 255
        while raw[offset] == 255:
            offset += 1
        marker = raw[offset]
        offset += 1
        if marker in (1, *range(0xd0, 0xd9)):
            continue
        assert marker not in (0xda, 0xd9), 'SOF must precede compressed image data'
        length = struct.unpack_from('>H', raw, offset)[0]
        assert length >= 2 and offset + length <= len(raw)
        if marker in (0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf):
            height, width = struct.unpack_from('>HH', raw, offset + 3)
            assert width > 0 and height > 0
            return [width, height]
        offset += length
    raise AssertionError('NO_JPEG_SOF')

formats = collections.Counter()
for path in sorted({row['texture'] for row in rows}):
    extension = Path(path).suffix
    formats[extension] += 1
    assert extension in ('.png', '.jpg', '.tres'), path
    raw = (G / path[6:]).read_bytes()
    expected = data['available_parent_sources'][path]
    assert sha(raw) == expected, path
    if extension == '.tres':
        assert descriptions[path]['resource_sha256'] == expected
        continue
    if extension == '.png':
        assert raw[:8] == b'\x89PNG\r\n\x1a\n'
        dimensions = list(struct.unpack_from('>II', raw, 16))
        method = 'PNG_IHDR'
    else:
        dimensions = jpeg_size(raw)
        method = 'JPEG_SOF'
    assert min(dimensions) > 0
    descriptions[path] = {'resource_sha256': expected, 'format': extension[1:], 'texture_size_px': dimensions, 'size_evidence': method}
    for required in (path, path + '.import'):
        assert required in data['terminal_sources'][binding['logical_id']], required

nonfeet = []
for row in rows:
    foot = row.get('world_foot_px')
    has_foot = isinstance(foot, (tuple, list)) and len(foot) == 2 and all(math.isfinite(v) for v in foot)
    if not has_foot and 'depth_sort_foot_y' not in row:
        assert row.get('sort_by_feet') is False, row['id']
        assert isinstance(row.get('z_index'), int), row['id']
        assert all(math.isfinite(v) for v in row['pos'])
        nonfeet.append({'id': row['id'], 'source_pos_uv': row['pos'], 'sort_by_feet': False, 'z_index': row['z_index'], 'render_anchor_kind': 'POSITION_ONLY_NOT_GROUND'})
assert len(rows) == 125 and len(nonfeet) == 73
assert formats == {'.png': 17, '.jpg': 1, '.tres': 14}
binding['texture_descriptions'] = descriptions
binding['nonfeet_render_layers'] = nonfeet

adapter0 = N / 'terminal_adapter05_estate_atlases.gd'
code = adapter0.read_bytes()
assert sha(code) == '50d9bb2d667f2410b61218b0db0a2b3d4e6a4a9d044d611e368236c40f86ab9e'
changes = [
    (b'binding.get("atlas_textures", {})', b'binding.get("texture_descriptions", {})'),
    (b'\t\tif not foot.is_finite() and row.has("depth_sort_foot_y"): foot = Vector2(position.x, float(row.depth_sort_foot_y) * size.y)\n',
     b'\t\tif not foot.is_finite() and row.has("depth_sort_foot_y"): foot = Vector2(position.x, float(row.depth_sort_foot_y) * size.y)\n\t\t# Non-foot layers retain their actual placement and original fixed z. This\n\t\t# transport anchor is not a building foot, body or positive-ground claim.\n\t\tif not foot.is_finite() and row.get("sort_by_feet") == false:\n\t\t\tif not row.get("z_index") is int: return fail("NONFEET_LAYER_Z", id)\n\t\t\tfoot = position\n'),
    (b'"texture_size_px": dimensions, "source_row": row.duplicate(true)',
     b'"texture_size_px": dimensions, "render_anchor_kind": "POSITION_ONLY_NOT_GROUND" if row.get("sort_by_feet") == false else "SOURCE_DEPTH_FOOT", "source_row": row.duplicate(true)'),
    (b'\tif path.ends_with(".png"): return png_size(path)\n\tvar description: Dictionary = descriptions.get(path, {})\n\tif description.is_empty() or not path.ends_with(".tres") or pins.get(path) != description.get("resource_sha256"): return Vector2.ZERO\n',
     b'\tvar description: Dictionary = descriptions.get(path, {})\n\tif description.is_empty() or pins.get(path) != description.get("resource_sha256"): return Vector2.ZERO\n\tvar expected_size: Vector2 = Core.vec(description.get("texture_size_px"))\n\tif path.ends_with(".png"):\n\t\treturn expected_size if description.get("format") == "png" and png_size(path) == expected_size else Vector2.ZERO\n\tif path.ends_with(".jpg"):\n\t\t# SOF dimensions come from these exact source bytes, not an image decode.\n\t\tvar texture: Texture2D = load(path) as Texture2D\n\t\treturn expected_size if description.get("format") == "jpg" and description.get("size_evidence") == "JPEG_SOF" and texture != null and texture.get_size() == expected_size and expected_size.is_finite() and expected_size.x > 0 and expected_size.y > 0 else Vector2.ZERO\n\tif not path.ends_with(".tres"): return Vector2.ZERO\n')
]
candidate = code
for old, new in changes:
    assert candidate.count(old) == 1
    candidate = candidate.replace(old, new)
inverse = candidate
for old, new in reversed(changes):
    assert inverse.count(new) == 1
    inverse = inverse.replace(new, old)
assert inverse == code
adapter = N / 'terminal_adapter06_estate_texture_layers.gd'
adapter_sha = create(adapter, candidate)
worker0 = N / 'terminal_estate_atlas_worker_ROOT_READY01.gd'
worker_before = worker0.read_bytes()
assert sha(worker_before) == '98710367c424ce6e22ce310976233cecde1ecd3be54d108457c15da2eeaad65c'
worker = N / 'terminal_estate_texture_worker_ROOT_READY02.gd'
worker_sha = create(worker, worker_before.replace(adapter0.name.encode(), adapter.name.encode()))
modules = data['module_sources']
modules.pop(res(adapter0)); modules[res(adapter)] = adapter_sha
modules.pop(res(worker0)); modules[res(worker)] = worker_sha
data['status'] = 'ESTATE_ONLY_EXACT_PNG_JPEG_ATLAS_AND_NONFEET_LAYERS'
data['format_inventory'] = {'render_rows': len(rows), 'unique_formats': dict(formats), 'nonfeet_layers': len(nonfeet), 'pixel_decodes': 0}
data['inherited_components']['Estate'] = '36912 all fourteen Atlas descriptions admitted; whole FAIL retained. Same complete source payload and solids.'
inp = N / 'terminal_estate_texture_input_ROOT_READY02.json'
input_sha = create(inp, (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode())
boot0 = N / 'terminal_estate_atlas_bootstrap_ROOT_READY01.gd'
boot = boot0.read_bytes().replace(parent.name.encode(), inp.name.encode()).replace(sha(before).encode(), input_sha.encode()).replace(worker0.name.encode(), worker.name.encode()).replace(sha(worker_before).encode(), worker_sha.encode())
bootstrap = N / 'terminal_estate_texture_bootstrap_ROOT_READY02.gd'
bootstrap_sha = create(bootstrap, boot)
print(json.dumps({'adapter': res(adapter), 'adapter_sha256': adapter_sha, 'input': res(inp), 'input_sha256': input_sha, 'worker': res(worker), 'worker_sha256': worker_sha, 'bootstrap': res(bootstrap), 'bootstrap_sha256': bootstrap_sha, 'formats': dict(formats), 'render_count': 125, 'nonfeet_count': 73, 'whole_adapter_inverse': inverse == code}))
