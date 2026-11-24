"""Immutable PackedScene boundary: identical nodes, one Script path successor."""
from pathlib import Path
import hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
original = G / 'scenes/field_walkable.tscn'
raw = original.read_bytes()
assert sha(raw) == 'd605d74a12f297b1472ae613cbb38d567672808c44c0a11d0d01279a6c240058'
before = b'res://scripts/field/field_walkable_controller.gd'
after = res(N / 'base_field_business_snapshot01.gd').encode()
assert raw.count(before) == 1
candidate = raw.replace(before, after)
assert candidate.replace(after, before) == raw
out = N / 'base_field_scene_snapshot01.tscn'
assert not out.exists()
out.write_bytes(candidate)
proof = {'scope': 'Original PackedScene node/UI/resource bytes unchanged; only controller Script path points to approved immutable B674 business snapshot. No old owner setup or canonical mutation.', 'parent': {'path': res(original), 'sha256': sha(raw), 'bytes': len(raw)}, 'candidate': {'path': res(out), 'sha256': sha(candidate), 'bytes': len(candidate)}, 'replacement': {'before': before.decode(), 'after': after.decode()}, 'whole_utf8_inverse': True, 'historical_authority': {'path': 'res://build/joint_world_luoyang_20261003_qa/424_luoyang_full_source_inventory_20261009/source_inventory.json', 'sha256': '29e9f1b12d984134bed7e8ae292d0d4f68ba4706e053a56997a9a978baad99a6', 'selector': 'sources[].project_relative == game/scenes/field_walkable.tscn'}}
proof_path = N / 'base_field_scene_snapshot_whole_inverse_BUILD.json'
assert not proof_path.exists()
proof_path.write_bytes((json.dumps(proof, ensure_ascii=False, indent=2) + '\n').encode())
print(json.dumps(proof))
