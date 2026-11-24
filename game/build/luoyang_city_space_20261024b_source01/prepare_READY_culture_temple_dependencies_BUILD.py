"""Exact Field/C source dependency metadata and two literal code successors.

BUILD only. Parents come from fixed formal805791 declarations, not a collector.
"""
from pathlib import Path
import hashlib
import json
import copy
import re

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = HERE / "runtime_dependencies_READY01"
assert not OUT.exists()
OUT.mkdir()

def sha(data):
    return hashlib.sha256(data).hexdigest()

def res(path):
    return "res://" + path.relative_to(ROOT).as_posix()

def read(resource, expected):
    data = (ROOT / resource[6:]).read_bytes()
    assert sha(data) == expected, (resource, sha(data), expected)
    assert b"tokens truncated" not in data
    return data

def write(name, data):
    path = OUT / name
    with path.open("xb") as file:
        file.write(data)
    return dict(path=res(path), sha256=sha(data), bytes=len(data))

def exact(data, old, new):
    a, b = old.encode("utf8"), new.encode("utf8")
    assert a != b and data.count(a) == 1
    after = data.replace(a, b, 1)
    assert after.count(b) == 1 and after.replace(b, a, 1) == data
    return after

stage_path = "res://build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_ActorParent_exact22_stage01/receipt.json"
stage = json.loads(read(stage_path, "8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392"))
oldmap = stage["nodes"]["expected_ch4_s3_luoyang_market_true"]["value"]["source_sha256"]
ready = json.loads((HERE / "runtime_READY02/mechanical_READY_freeze_inverse.json").read_text(encoding="utf8"))
FIELD = "res://scripts/field/field_walkable_controller.gd"
C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
COORD = "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
CONTRACT = "res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
TEMPLE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
before_contract = read(CONTRACT, oldmap[CONTRACT])
contract = json.loads(before_contract)
after_contract = before_contract
changes = {}
for target, key in [(FIELD, "Field"), (C, "C")]:
    previous = contract["source_sha256"][target]
    assert previous == oldmap[target]
    candidate = ready["candidates"][key]
    read(candidate["path"], candidate["sha256"])
    contract["source_sha256"][target] = candidate["sha256"]
    after_contract = exact(after_contract, previous, candidate["sha256"])
    changes[target] = {"old_sha256": previous, "new_sha256": candidate["sha256"]}
assert json.loads(after_contract) == contract
contract_result = write("runtime_contract_Field_C_literals_READY.json", after_contract)
before_coord = read(COORD, oldmap[COORD])
after_coord = exact(before_coord, oldmap[CONTRACT], contract_result["sha256"])
coord_result = write("Coordinator_READY.gd", after_coord)

before_temple = read(TEMPLE, oldmap[TEMPLE])
text = before_temple.decode("utf8")
binding_path = re.search(r'const BIND_PATH="([^"]+)"', text).group(1)
binding_sha = re.search(r'const BIND_SHA="([^"]+)"', text).group(1)
before_binding = read(binding_path, binding_sha)
binding = json.loads(before_binding)
old_binding = copy.deepcopy(binding)
parent = json.loads(read(binding["parent_binding_path"], binding["parent_binding_sha256"]))
old_merged = {**parent["source_sha256"], **binding["source_delta"]}
assert len(old_merged) == 189
for target, current in [(C, ready["candidates"]["C"]["sha256"]), (FIELD, ready["candidates"]["Field"]["sha256"]),
                        (COORD, coord_result["sha256"]), (CONTRACT, contract_result["sha256"])]:
    assert binding["source_delta"][target] == oldmap[target]
    binding["source_delta"][target] = current
dialogue = json.loads(read("res://build/luoyang_city_revision_20261024b_root01/dialogue_interface_admission.json", "f2199c78f03966597fa115b431d260257f6ca2d7b1a946c99cb812d36080ba5b"))
new_keys = {dialogue["helper"]["path"]: dialogue["helper"]["sha256"], **dialogue["canonical_UI_expected_after_deploy"],
            **dialogue["unchanged_existing_hero_media_explicitly_frozen"]}
assert len(new_keys) == 5 and not set(new_keys).intersection(old_merged)
binding["source_delta"].update(new_keys)
binding_bytes = (json.dumps(binding, ensure_ascii=False, indent=2) + "\n").encode("utf8")
binding_result = write("temple_binding_Field_C_Coord_contract_dialogue5_READY.json", binding_bytes)
new_merged = {**parent["source_sha256"], **binding["source_delta"]}
assert len(new_merged) == 194
assert {p for p in old_merged if old_merged[p] != new_merged[p]} == {C, FIELD, COORD, CONTRACT}
assert set(new_merged) - set(old_merged) == set(new_keys)
inverse = copy.deepcopy(binding)
for p in new_keys:
    del inverse["source_delta"][p]
for p in [C, FIELD, COORD, CONTRACT]:
    inverse["source_delta"][p] = old_binding["source_delta"][p]
assert inverse == old_binding
after_temple = exact(exact(before_temple, binding_path, binding_result["path"]), binding_sha, binding_result["sha256"])
temple_result = write("Temple_READY.gd", after_temple)
proof = dict(status="EXACT_READY_CULTURE_AND_TEMPLE_SOURCE_DEPENDENCIES_NOT_STAGE", ready=False,
             parent_stage_path=stage_path, parent_stage_sha256="8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392",
             contract=dict(target=CONTRACT, old_sha256=oldmap[CONTRACT], candidate=contract_result, changed=changes,
                           exact_two_literal_byte_inverse=True, whole_typed_inverse=True),
             coordinator=dict(target=COORD, old_sha256=oldmap[COORD], candidate=coord_result,
                              replacements=[dict(old=oldmap[CONTRACT], new=contract_result["sha256"])], wholebyte_inverse=True),
             temple_binding=dict(parent_path=binding_path, parent_sha256=binding_sha, candidate=binding_result,
                                 old_merged_count=189, new_merged_count=194, changed_existing=[C, FIELD, COORD, CONTRACT],
                                 new_ordinary_keys=new_keys, other185_values_unchanged=True, whole_typed_inverse=True),
             temple=dict(target=TEMPLE, old_sha256=oldmap[TEMPLE], candidate=temple_result,
                         replacements=[dict(old=binding_path, new=binding_result["path"]), dict(old=binding_sha, new=binding_result["sha256"])], wholebyte_inverse=True),
             no_C_or_AA_new_owned_members=True, engine_calls=0, collector_calls=0, formal_writes=0)
proof_result = write("culture_temple_dependency_inverse_NOT_STAGE.json", (json.dumps(proof, ensure_ascii=False, indent=2) + "\n").encode("utf8"))
print(json.dumps(dict(proof=proof_result, contract=contract_result, coordinator=coord_result, temple=temple_result, binding=binding_result)))
