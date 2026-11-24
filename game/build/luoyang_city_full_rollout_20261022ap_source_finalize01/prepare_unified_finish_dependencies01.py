"""Only NEW finite dependency candidates and Root execution proposal.

Never runs a stager, Godot, collector or canonical write. Values come from the
Root-reviewed fixed System v2 candidates and exact current predecessor pins.
"""
import base64
import copy
import json
from pathlib import Path
from prepare_handoff10 import HERE, GAME, resource, sha, same

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified_finish_dependencies01/"
SYSTEM = "res://build/luoyang_city_full_rollout_20261022ap_system01/unified_runtime_visual_finish_candidates_v2_READY.json"
SYSTEM_SHA = "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee"
EXE = "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
EXE_SHA = "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"
CONTRACT = "res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
CONTRACT_SHA = "4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a"
COORD = "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
COORD_SHA = "9e9b67b0c22000be9d9637b3c3cd1184c730c2ae8bc287196ccfe963e350ebad"
TEMPLE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
TEMPLE_SHA = "d9cd4138c1cfb8d8346c723110bdb1b1b5df99b9ac4a2fe555699aa43a8312c0"
BIND = "res://build/luoyang_city_full_rollout_20261022ap_system01/temple_binding_pin_successor_retry1/binding_READY.json"
BIND_SHA = "cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c"
FIELD = "res://scripts/field/field_walkable_controller.gd"
ROUTER = "res://scripts/autoload/scene_router.gd"
outputs, first = {}, {}


def read(path, expected):
    raw = resource(path).read_bytes()
    assert sha(raw) == expected, ("PIN_CHANGED", path)
    first[path] = expected
    return raw


def emit(name, data):
    path = P + name
    assert path not in outputs
    outputs[path] = data if isinstance(data, bytes) else (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    return {"path": path, "sha256": sha(outputs[path]), "bytes": len(outputs[path])}


def exact_replacements(raw, replacements):
    out = raw
    for row in replacements:
        old, new = row["old"].encode("utf-8"), row["new"].encode("utf-8")
        assert old != new and out.count(old) == 1
        out = out.replace(old, new)
    inverse = out
    for row in reversed(replacements):
        old, new = row["old"].encode("utf-8"), row["new"].encode("utf-8")
        assert new and inverse.count(new) == 1
        inverse = inverse.replace(new, old)
    assert inverse == raw
    return out


def system_inverse(row):
    before = read(row["canonical"], row["parent_sha256"])
    after = read(row["candidate"]["path"], row["candidate"]["sha256"])
    # Verify the supplied exact byte coordinates before constructing the actual
    # runtime-authority String replacement inverse, which has a stricter domain.
    old_cursor = new_cursor = 0
    pieces = []
    for hunk in row["offset_byte_hunks"]:
        o, n = hunk["old_offset"], hunk["new_offset"]
        old, new = base64.b64decode(hunk["old_b64"]), base64.b64decode(hunk["new_b64"])
        assert before[old_cursor:o] == after[new_cursor:n]
        assert before[o:o + len(old)] == old and after[n:n + len(new)] == new
        pieces.append({"old": old.decode("utf-8"), "new": new.decode("utf-8")})
        old_cursor, new_cursor = o + len(old), n + len(new)
    assert before[old_cursor:] == after[new_cursor:]
    inverse = after.decode("utf-8")
    for hunk in reversed(pieces):
        assert hunk["new"] and inverse.count(hunk["new"]) == 1, ("RUNTIME_UNIQUE_NEW_HUNK", row["canonical"])
        inverse = inverse.replace(hunk["new"], hunk["old"])
    assert inverse.encode("utf-8") == before
    return list(reversed(pieces))


system = json.loads(read(SYSTEM, SYSTEM_SHA))
system_targets = {r["canonical"]: r for r in system["targets"]}
assert len(system_targets) == 6
system_replacements = {p: system_inverse(row) for p, row in system_targets.items()}
field_sha, router_sha = system_targets[FIELD]["candidate"]["sha256"], system_targets[ROUTER]["candidate"]["sha256"]
assert field_sha == "a148154e8db886f508755ab91e7852c6ebe1e168a44d17badad9f3cc267499df"
assert router_sha == "7c65d2d1e7eee99b9f0d2f9418428382545ed49c9fc13f883ae0beb376acab2d"
contract_old = read(CONTRACT, CONTRACT_SHA)
contract0 = json.loads(contract_old)
contract_hunks = [{"old": contract0["source_sha256"][p], "new": value} for p, value in [(FIELD, field_sha), (ROUTER, router_sha)]]
contract_bytes = exact_replacements(contract_old, contract_hunks)
contract1 = json.loads(contract_bytes)
back = copy.deepcopy(contract1)
for p in [FIELD, ROUTER]:
    back["source_sha256"][p] = contract0["source_sha256"][p]
assert same(back, contract0)
contract_candidate = emit("runtime_contract_READY.json", contract_bytes)
coordinator_old = read(COORD, COORD_SHA)
coord_hunks = [{"old": CONTRACT_SHA, "new": contract_candidate["sha256"]}]
coord_bytes = exact_replacements(coordinator_old, coord_hunks)
coord_candidate = emit("Coordinator_contract_READY.gd", coord_bytes)

binding_old = read(BIND, BIND_SHA)
binding0 = json.loads(binding_old)
binding_updates = {FIELD: field_sha, ROUTER: router_sha, COORD: coord_candidate["sha256"], CONTRACT: contract_candidate["sha256"]}
binding_hunks = [{"old": binding0["source_delta"][p], "new": value} for p, value in binding_updates.items()]
binding_bytes = exact_replacements(binding_old, binding_hunks)
binding1 = json.loads(binding_bytes)
back = copy.deepcopy(binding1)
for p in binding_updates:
    back["source_delta"][p] = binding0["source_delta"][p]
assert same(back, binding0)
binding_candidate = emit("temple_binding_READY.json", binding_bytes)
temple_old = read(TEMPLE, TEMPLE_SHA)
temple_hunks = [{"old": BIND, "new": binding_candidate["path"]}, {"old": BIND_SHA, "new": binding_candidate["sha256"]}]
temple_bytes = exact_replacements(temple_old, temple_hunks)
temple_candidate = emit("Temple_binding_READY.gd", temple_bytes)

approval_old = read(EXE, EXE_SHA)
approval0 = json.loads(approval_old)
assert len(approval0["owned"]) == 10 and len(approval0["source_sha256"]) == 37
approval1 = copy.deepcopy(approval0)
changes = {
    FIELD: {"candidate": system_targets[FIELD]["candidate"], "replacements": system_replacements[FIELD]},
    ROUTER: {"candidate": system_targets[ROUTER]["candidate"], "replacements": system_replacements[ROUTER]},
    COORD: {"candidate": coord_candidate, "replacements": coord_hunks},
    TEMPLE: {"candidate": temple_candidate, "replacements": list(reversed(temple_hunks))},
}
new_pins, owned_rows = {}, []
for path, spec in changes.items():
    old_sha = approval0["owned"][path]["current_sha256"]
    predecessor = next(e["new_snapshot"] for e in approval0["owned"][path]["edges"] if e["new_sha256"] == old_sha)
    read(predecessor, old_sha)
    candidate = spec["candidate"]
    raw = outputs[candidate["path"]] if candidate["path"] in outputs else read(candidate["path"], candidate["sha256"])
    inverse = raw.decode("utf-8")
    for replacement in spec["replacements"]:
        assert replacement["new"] and inverse.count(replacement["new"]) == 1
        inverse = inverse.replace(replacement["new"], replacement["old"])
    assert inverse.encode("utf-8") == read(predecessor, old_sha)
    edge = {"path": path, "old_sha256": old_sha, "new_sha256": candidate["sha256"], "old_snapshot": predecessor, "new_snapshot": candidate["path"], "whole_inverse": True, "replacements": spec["replacements"]}
    approval1["owned"][path]["current_sha256"] = candidate["sha256"]
    approval1["owned"][path]["edges"].append(edge)
    for p, value in [(predecessor, old_sha), (candidate["path"], candidate["sha256"])]:
        assert p not in approval1["source_sha256"] or approval1["source_sha256"][p] == value
        if p not in approval1["source_sha256"]:
            new_pins[p] = value
        approval1["source_sha256"][p] = value
    owned_rows.append({"target": path, "old_sha256": old_sha, "candidate": candidate, "edge": edge})
for p, value in [(contract_candidate["path"], contract_candidate["sha256"]), (binding_candidate["path"], binding_candidate["sha256"]), (SYSTEM, SYSTEM_SHA)]:
    assert p not in approval1["source_sha256"]
    new_pins[p] = approval1["source_sha256"][p] = value
restored = copy.deepcopy(approval1)
for path in changes:
    restored["owned"][path] = copy.deepcopy(approval0["owned"][path])
for path in new_pins:
    del restored["source_sha256"][path]
assert same(restored, approval0)
assert all(approval1["source_sha256"].get(p) == value for p, value in approval0["source_sha256"].items())
proposal = emit("execution_successor_PROPOSAL.json", approval1)
dependency_proof = emit("dependency_byte_typed_inverses_READY.json", {"status": "SOURCE_CANDIDATES_EXACT_INVERSES_NOT_ROOT_APPROVAL", "system_fixed_handoff": {"path": SYSTEM, "sha256": SYSTEM_SHA}, "contract": {"parent_path": CONTRACT, "parent_sha256": CONTRACT_SHA, "candidate": contract_candidate, "changed_source_paths": [FIELD, ROUTER], "replacements": contract_hunks, "whole_byte_and_typed_inverse": True}, "coordinator": {"parent_path": COORD, "parent_sha256": COORD_SHA, "candidate": coord_candidate, "replacements": coord_hunks, "whole_byte_inverse": True}, "temple_binding": {"parent_path": BIND, "parent_sha256": BIND_SHA, "candidate": binding_candidate, "changed_source_paths": list(binding_updates), "replacements": binding_hunks, "whole_byte_and_typed_inverse": True, "parent_binding_and_all_other189_values_preserved": True}, "temple": {"parent_path": TEMPLE, "parent_sha256": TEMPLE_SHA, "candidate": temple_candidate, "replacements": temple_hunks, "whole_byte_inverse": True}})
handoff = emit("handoff_READY.json", {"status": "PENDING_ROOT_EXACT80A_SUCCESSOR_APPROVAL_AND_UNIFIED_TARGET_SCOPE_NOT_STAGED", "execution_parent": {"path": EXE, "sha256": EXE_SHA}, "execution_proposal": proposal, "owned_changed_exactly4": owned_rows, "other6_owned_rows_whole_typed_identical": True, "original37_proof_pins_unchanged": True, "new_proof_pins": new_pins, "final_proof_pin_count": len(approval1["source_sha256"]), "whole_typed_inverse_to_original80A": True, "dependency_proof": dependency_proof, "additional_canonical_targets": [{"target": CONTRACT, "old_sha256": CONTRACT_SHA, "candidate": contract_candidate}, {"target": COORD, "old_sha256": COORD_SHA, "candidate": coord_candidate}, {"target": TEMPLE, "old_sha256": TEMPLE_SHA, "candidate": temple_candidate}], "build_only_dependency": binding_candidate, "system6_candidates_and2shaders_unchanged": True, "runtime_ready_or_approval_claim": False, "no_engine_collector_geometry_stage_or_canonical_write": True})
assert all(sha(resource(path).read_bytes()) == expected for path, expected in first.items())
assert not resource(P).exists()
for path, data in outputs.items():
    destination = resource(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("xb") as stream:
        stream.write(data)
print(json.dumps({"handoff": handoff, "proposal": proposal, "contract": contract_candidate, "coordinator": coord_candidate, "binding": binding_candidate, "temple": temple_candidate, "proof_count": len(approval1["source_sha256"]), "canonical_written": False, "stager_executed": False}))
