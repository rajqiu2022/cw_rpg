"""Mechanical full-byte business snapshots and eight real Scene resources.
No canonical file is changed. A snapshot is not an old owner receipt.
"""
from pathlib import Path
import hashlib, json

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
stage_path = G / 'build/luoyang_city_finish_20261025i_source01/outputs/root_garden_estate_exact32_stage02/receipt.json'
stage_bytes = stage_path.read_bytes()
assert sha(stage_bytes) == '956f16b0321dc8b29415ec390d4a1ba113aa4db27cd4b85e7fc57df5d00ca1c3'
stage = json.loads(stage_bytes)
authority = dict(stage['source_final'])
for row in stage['targets']:
    authority[row['target']] = row['candidate_sha256']

def create(path, raw):
    assert not path.exists(), str(path)
    path.write_bytes(raw)

snapshots = []
for original, name in [('res://scripts/field/field_walkable_controller.gd', 'base_field_business_snapshot01.gd'), ('res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd', 'culture_business_snapshot01.gd')]:
    raw = (G / original[6:]).read_bytes()
    assert sha(raw) == authority[original], original
    raw.decode('utf8')
    target = N / name
    create(target, raw)
    assert target.read_bytes() == raw
    snapshots.append({'canonical_parent': original, 'parent_sha256': authority[original], 'immutable_snapshot': res(target), 'sha256': sha(raw), 'bytes': len(raw), 'whole_utf8_identity': True, 'owner_adoption': False})

scenes = {
    'estate_region_scene.tres': ('luoyang_estate_region_27d', '洛阳·宅园与私家后园', 3072, 4096),
    'temple_region_scene.tres': ('luoyang_temple_region_27d', '古寺·山门五院', 3072, 4608),
    'estate_living_hall_scene.tres': ('estate27d_living_hall', '宅园·会客正厅', 1920, 1440),
    'estate_west_study_scene.tres': ('estate27d_west_study', '宅园·西厢书房', 1536, 1280),
    'estate_east_bedroom_scene.tres': ('estate27d_east_bedroom', '宅园·东厢卧房', 1536, 1280),
    'temple_main_hall_scene.tres': ('temple27d_main_hall', '古寺·正殿', 1920, 1536),
    'temple_monks_room_scene.tres': ('temple27d_monks_room', '古寺·西僧舍', 1536, 1280),
    'temple_sutra_room_scene.tres': ('temple27d_sutra_room', '古寺·东经堂', 1536, 1280),
}
for name, (identity, label, width, height) in scenes.items():
    text = f'''[gd_resource type="Resource" script_class="SceneScript" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/domain/scene_script.gd" id="1_scene"]
[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="2_layout"]

[sub_resource type="Resource" id="Layout"]
script = ExtResource("2_layout")
design_size = Vector2i({width}, {height})

[resource]
script = ExtResource("1_scene")
scene_id = &"{identity}"
display_name = "{label}"
is_walkable = true
actor_positions_are_feet = true
is_settlement = true
map_layout = SubResource("Layout")
player_spawn = Vector2(0.5, 0.875)
camera_zoom = 1.0
'''
    create(N / name, text.encode())

proof = {'status': 'BUILD_FULL_BYTE_SNAPSHOTS_NOT_OWNER_ADOPTION', 'parent_stage': {'path': res(stage_path), 'sha256': sha(stage_bytes)}, 'snapshots': snapshots, 'use': 'RegionField extends the immutable full business snapshot; the new bridge calls only pure Culture table/reducer/dialog methods. Original readiness/owner functions remain unchanged and are not used to claim legacy ownership.', 'canonical_writes': 0, 'engine_runs': 0, 'scene_resources': {res(N / name): sha((N / name).read_bytes()) for name in scenes}}
create(N / 'business_snapshots_and_real_room_resources_BUILD.json', (json.dumps(proof, ensure_ascii=False, indent=2) + '\n').encode())
print(json.dumps(proof, ensure_ascii=False))
