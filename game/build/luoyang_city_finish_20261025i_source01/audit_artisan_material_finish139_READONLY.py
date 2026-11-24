"""Finite frozen payload/contract selector. No engine, raster, packet or publication."""
from pathlib import Path
import hashlib, json, struct

N = Path(__file__).resolve().parent
G = N.parents[1]
S = 'res://build/luoyang_city_finish_20261025i_source01/'

def read(path, expected):
    raw = (G / path.removeprefix('res://')).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == expected, path
    return raw

binding_pin = dict(path=S+'docks_gallery_family_repair01/closure_READY01/finish8_binding_READY.json', sha256='ed3bdd2b59ab7c18cfbbe274404a04e1d75045dd61d7852f7bc6b4494c12fa66')
binding = json.loads(read(binding_pin['path'], binding_pin['sha256']))
scene_id = 'luoyang_artisan_residential_20261022ap'
scene = binding['scenes'][scene_id]
payload_pin = scene['payload']
assert payload_pin['sha256'] == '5e890e3424f10125c48ece2cc1892aa3cb6834c75dfe91a347eda9bb2cbe233a'
decoder_source = (N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf-8')
decoder_scope = {'struct': struct}
exec(decoder_source[decoder_source.index('class FrozenVariant:'):decoder_source.index('binding_pin=')], decoder_scope)
raw = read(payload_pin['path'], payload_pin['sha256'])
assert len(raw) == payload_pin['bytes']
decoder = decoder_scope['FrozenVariant'](raw)
data = decoder.value()
assert decoder.p == len(raw)
parent, effective = data['parent_navigation'], data['effective_navigation']
patches, additions = data['visual_patches'], data['visual_additions']
assert len(parent) == 136 and len(effective) == 139 and len(patches) == 18 and len(additions) == 3
assert parent == data['parent_native_navigation'] and data['visual_retired'] == []
by_id = {row['id']: row for row in parent}
changed = {row['id']: row for row in patches}
assert len(by_id) == 136 and len(changed) == 18
assert all(by_id[row['id']] == row['before'] for row in patches)
assert [changed[row['id']]['after'] if row['id'] in changed else row for row in parent]+additions == effective

contract_pin = dict(path='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_contract_READY.json', sha256='87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af')
helper_pin = dict(path='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/life_production100_READY/material_runtime_life_READY.gd', sha256='7bd26f666035fc45a2f3161cc8df323da5ef6756f758ba16a6ffc1814ee5836a')
shader_pin = dict(path='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_use_candidate.gdshader', sha256='11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e')
contract = json.loads(read(contract_pin['path'], contract_pin['sha256']))
read(helper_pin['path'], helper_pin['sha256']); read(shader_pin['path'], shader_pin['sha256'])
assert contract['status'] == 'FROZEN_EXACT_A2_118_GROUND_14_PROPS_PREVIEW_ONLY'
assert contract['scene_id'] == scene_id
ground_ids = [row['id'] for row in contract['ground']]
prop_ids = [row['placement']['id'] for row in contract['props']]
life_ids = ['ap_life_dye_rinse_tub_a','ap_life_dye_rinse_tub_b','ap_life_well_tea_table','ap_life_well_wait_bench']
assert len(ground_ids) == 118 and len(prop_ids) == 14
assert set(by_id) == set(ground_ids+prop_ids+life_ids)
assert [row['id'] for row in parent if row['id'] not in changed] == ground_ids
expected_motion_ids = ['ap_courtyard_home_west','ap_courtyard_home_east','ap_woodwork_court_west_chinese_v3','ap_cloth_dye_workshop_east','ap_carpentry_general_shop_south','ap_carpentry_cart_v2','ap_cloth_rack_v2']
geometry_keys = ['blocking','city_v3_solid_polygons_px','collision_size_px','physical_center_px','world_foot_px']
details = []
motion_ids = []
for patch in patches:
    before, after = patch['before'], patch['after']
    old_changes = [key for key in before if before[key] != after.get(key)]
    assert sorted(set(after)-set(before)) == geometry_keys
    assert set(before).issubset(after)
    if old_changes:
        assert old_changes == ['pos','depth_sort_foot_y']
        motion_ids.append(patch['id'])
    details.append(dict(id=patch['id'], original_keys_changed=old_changes, added_geometry_keys=geometry_keys, texture=after['texture'], pos=after['pos'], world_foot_px=after['world_foot_px'], render_size_px=after['render_size_px']))
assert motion_ids == expected_motion_ids
assert [row['id'] for row in additions] == ['new_open_forge','new_pottery_kiln_workshop','new_plain_kitchen_rear_house']
assert all(all(changed[key]['before'][field] == changed[key]['after'][field] for field in changed[key]['before']) for key in life_ids)
report = dict(
    status='READONLY_FIXED_ARTISAN_136_TO139_MATERIAL_BRIDGE_SOURCE_FACTS_NOT_RUNTIME_PASS', passed=True,
    binding=binding_pin, payload=payload_pin, contract=contract_pin, original_material_helper=helper_pin, original_shader=shader_pin,
    counts=dict(parent_native_navigation=136,parent_navigation=136,effective_navigation=139,original_ground=118,original_props=14,old_life_props=4,visual_patches=18,actual_position_patches=7,geometry_metadata_only_patches=11,visual_additions=3,visual_retired=0),
    source_projection_exact=True, original_patch_before_rows_exact=True, original118_ground_whole_decoded_rows_unchanged=True,
    seven_position_patch_ids=motion_ids, patch_details=details,
    metadata_only_ids=[row['id'] for row in details if not row['original_keys_changed']],
    four_life_ids=life_ids, four_life_all_original_fields_exact=True,
    new_rows=[{key:row[key] for key in ['id','texture','pos','render_size_px','world_foot_px','finish_source_size_px','finish_source_anchor_px','finish_source_scale']} for row in additions],
    original_material_contract=dict(ground_count=118,props_count=14,profile_names=list(contract['profiles']),section_rect_count=len(contract['section_rects']),union_exterior_profile_count=len(contract['union_exterior_segments']),ground_row_keys=list(contract['ground'][0]),profiles=contract['profiles'],uniforms=['ap_sprite_origin','ap_source_to_world','ap_coverage','ap_edge_width','ap_tree_pit','ap_tree_rect','ap_grass_saturation','ap_tone','ap_contrast','ap_edges','ap_edge_count']),
    limitations=['Read-only frozen byte/SHA selection and decoded row comparison, not engine, Geometry2D or independent geometry verification.','Original 136/118/14/4 guards and fullPNG/opaque/sourcefoot/shader conditions must remain; 139 count alone is not admission.','System owns actual finish lease/owner/texture/node validation. No new closure, World head, authority or canonical write.'],
    engine_calls=0,collector_calls=0,packet_decodes=0,PNG_decodes=0,canonical_writes=0)
output = N/'artisan_material_finish139_READONLY.json'
assert not output.exists()
encoded = (json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
with output.open('xb') as stream: stream.write(encoded)
print(json.dumps(dict(path=S+output.name,sha256=hashlib.sha256(encoded).hexdigest(),bytes=len(encoded),counts=report['counts'])))
