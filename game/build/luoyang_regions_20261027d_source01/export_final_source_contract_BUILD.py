"""Export fixed Entry source-union declarations for QA; no runtime collection."""
from pathlib import Path
import hashlib, json, struct
N = Path(__file__).resolve().parent; G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
source = (S / 'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope = {'struct': struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')], scope)
sha = lambda raw: hashlib.sha256(raw).hexdigest()
def load_fixed(pin, binary=False):
    raw = (G / pin['path'][6:]).read_bytes()
    assert sha(raw) == pin['sha256']
    if 'bytes' in pin: assert len(raw) == pin['bytes']
    if not binary: return json.loads(raw)
    decoder = scope['FrozenVariant'](raw); value = decoder.value()
    assert decoder.p == len(raw)
    return value
manifest_pin = {'path': 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json', 'sha256': '54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6'}
manifest = load_fixed(manifest_pin); author = load_fixed(manifest['author'])
def expected(region_id):
    binding = manifest['compiled_bindings'][region_id]
    compiled = load_fixed(binding, True)
    sources = {manifest_pin['path']: manifest_pin['sha256'], manifest['author']['path']: manifest['author']['sha256'], **manifest['runtime_modules']}
    sources[binding['path']] = binding['sha256']
    for logical in compiled.get('source_context_ids', compiled['districts'].keys()):
        terminal_pin = author['terminal_bindings'][logical]
        terminal = load_fixed(terminal_pin, True)
        sources.update(terminal['sources']); sources[terminal_pin['path']] = terminal_pin['sha256']
    for path, value in compiled['sources'].items():
        assert path not in sources or sources[path] == value
        sources[path] = value
    sources[manifest['phase_projector']['path']] = manifest['phase_projector']['sha256']
    return compiled, sources
civic, civic_sources = expected('luoyang_civic_market_region_27d')
temple, temple_sources = expected('luoyang_temple_region_27d')
bell = next(row for row in temple['npcs'] if row['data']['npc_id'] == 'temple_bell_keeper_20261018t')
assert bell['foot'] == (2450.0, 2950.0) and bell['ground_anchored'] is True
gate_path = S / 'region_integration_20261027d01/unified32_READY01/maps/ch4_s0_luoyang_gate_true.json'
gate = json.loads(gate_path.read_bytes())
contract = {
    'status': 'FIXED_SOURCE_EXPRESSION_DECLARATIONS_NOT_OBSERVED_RECEIPTS',
    'formula': 'Exact region_entry._load_region union: manifest+author+runtime_modules+selected compiled bin+each selected terminal.sources and terminal bin+compiled.sources+phase_projector. No runtime hashes filled.',
    'manifest': manifest_pin,
    'expected_sources': {'civic': civic_sources, 'temple': temple_sources, 'gate': gate['source_sha256']},
    'counts': {'civic': len(civic_sources), 'temple': len(temple_sources), 'gate': len(gate['source_sha256'])},
    'civic': {'logical_id': 'ch4_s1_luoyang_yamen', 'old_uv': [0.5, 0.75], 'local_version': 3, 'public_anchor': [3072,1840], 'walk_points': [[3072,1840],[3072,2184],[3072,2216]], 'seam_y': 2200},
    'temple': {'logical_id': 'ch4_s4_ancient_temple', 'old_uv': [0.75,0.625], 'local_version': 3, 'public_anchor': [2220,3080], 'approach': [[2220,3080],[2450,3080],[2450,3040]], 'stand': [2450,3040], 'unlock_end': [2450,3056], 'npc_id': bell['data']['npc_id'], 'npc_name': bell['data']['npc_name'], 'npc_name_unicode_escape': bell['data']['npc_name'].encode('unicode_escape').decode('ascii'), 'npc_node_position': bell['foot'], 'npc_node_origin_offset': bell.get('node_origin_offset_px', [0,0]), 'source_primary': bell['data']['region27d_primary'], 'dialog_test': 'Original baima side offer, choose existing KEY2 暂且不接; do not assume culture wrapper or accept Quest'},
    'gate': {'logical_id': 'ch4_s0_luoyang_gate', 'owner_map': {'path': 'res://' + gate_path.relative_to(G).as_posix(), 'sha256': sha(gate_path.read_bytes())}, 'parent_id': 'finish_i_gate_east_supply', 'child_name': 'GateSupplySourceBoundDoorDepth'},
    'new_geometry_validation': False, 'engine_calls': 0,
}
out = N / 'final_bounded_source_contract_BUILD.json'
assert not out.exists()
raw = (json.dumps(contract, ensure_ascii=True, indent=2) + '\n').encode()
out.write_bytes(raw)
print(json.dumps({'path': 'res://' + out.relative_to(G).as_posix(), 'sha256': sha(raw), 'counts': contract['counts'], 'bell_name_unicode': contract['temple']['npc_name_unicode_escape']}))
