"""Root-approved mechanical READY/path/SHA propagation. Not Stage/deployment.

Only NEW exclusive outputs; code bodies are copied from the reviewed physical
candidates and narrowly replaced. No engine, collector, PNG or packet decoder.
"""
from pathlib import Path
import hashlib
import json
import copy

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = HERE / "runtime_READY01"
PREFIX = "res://build/luoyang_city_space_20261024b_source01/runtime_READY01/"
assert not OUT.exists()
OUT.mkdir()
records = []

def digest(data):
    return hashlib.sha256(data).hexdigest()

def res(path):
    return "res://" + path.relative_to(ROOT).as_posix()

def read(resource, sha):
    data = (ROOT / resource[6:]).read_bytes()
    assert digest(data) == sha, (resource, digest(data), sha)
    assert b"tokens truncated" not in data
    return data

def write(name, data):
    destination = OUT / name
    with destination.open("xb") as file:
        file.write(data)
    assert destination.read_bytes() == data
    return {"path": res(destination), "sha256": digest(data), "bytes": len(data)}

def code(parent, expected, name, replacements):
    before = read(parent, expected)
    after = before
    for old, new in replacements:
        a, b = old.encode("utf8"), new.encode("utf8")
        assert a != b and after.count(a) == 1, (name, old[:80], after.count(a))
        after = after.replace(a, b, 1)
    inverse = after
    for old, new in reversed(replacements):
        a, b = old.encode("utf8"), new.encode("utf8")
        assert inverse.count(b) == 1
        inverse = inverse.replace(b, a, 1)
    assert inverse == before
    result = write(name, after)
    records.append({"parent": {"path": parent, "sha256": expected}, "candidate": result,
                    "replacements": [{"old": a, "new": b} for a, b in replacements], "wholebyte_inverse": True})
    return result

binding_parent = "res://build/luoyang_city_space_20261024b_source01/market_space_binding_closed02_NOTREADY.json"
binding_bytes = read(binding_parent, "1a0979092696924dbea1347a6f5349910915209b72ce480642b1b172036909f4")
binding = json.loads(binding_bytes)
prior_binding = copy.deepcopy(binding)
binding.update(ready=True, source_closure_ready=True, blockers=[])
dialogue_path = "res://build/luoyang_city_revision_20261024b_root01/dialogue_interface_admission.json"
dialogue = json.loads(read(dialogue_path, "f2199c78f03966597fa115b431d260257f6ca2d7b1a946c99cb812d36080ba5b"))
ordinary_dialogue = {dialogue["helper"]["path"]: dialogue["helper"]["sha256"],
                     **dialogue["canonical_UI_expected_after_deploy"],
                     **dialogue["unchanged_existing_hero_media_explicitly_frozen"]}
for path, sha in ordinary_dialogue.items():
    assert path not in binding["source_sha256"]
    binding["source_sha256"][path] = sha
binding["dialogue_interface"] = {"path": dialogue_path, "sha256": "f2199c78f03966597fa115b431d260257f6ca2d7b1a946c99cb812d36080ba5b",
                                  "ordinary_new_keys": ordinary_dialogue, "DP_unchanged": dialogue["unchanged_DP"]}
binding_result = write("market_space_binding_READY.json", (json.dumps(binding, ensure_ascii=False, indent=2) + "\n").encode("utf8"))
back = copy.deepcopy(binding)
for path in ordinary_dialogue:
    del back["source_sha256"][path]
del back["dialogue_interface"]
back.update(ready=False, source_closure_ready=False, blockers=prior_binding["blockers"])
assert back == prior_binding
runtime_old = "res://build/luoyang_city_space_20261024b_source01/market_space_runtime_closed02_CANDIDATE.gd"
runtime = code(runtime_old, "b50c48f21c8cba132a0d1d015969de8917948cc8abe1f9455e2510abd41c573c", "market_space_runtime_READY.gd", [
    ("const READY=false", "const READY=true"),
    (runtime_old, PREFIX + "market_space_runtime_READY.gd"),
    (binding_parent, binding_result["path"]),
    ("1a0979092696924dbea1347a6f5349910915209b72ce480642b1b172036909f4", binding_result["sha256"]),
    ("var a:=left.duplicate(true);var b:=right.duplicate(true)", "var a: Dictionary=left.duplicate(true);var b: Dictionary=right.duplicate(true)"),
])
adapter_old = "res://build/luoyang_city_space_20261024b_source01/finite_adapter_closed02_CANDIDATE.gd"
adapter = code(adapter_old, "bb525d5f589dee344acd9143feb611615e53214718037c5480292b96e1947e8e", "finite_adapter_READY.gd", [
    (adapter_old, PREFIX + "finite_adapter_READY.gd"),
    (runtime_old, runtime["path"]),
    ("b50c48f21c8cba132a0d1d015969de8917948cc8abe1f9455e2510abd41c573c", runtime["sha256"]),
])
adapter_changes = [(adapter_old, adapter["path"]), ("bb525d5f589dee344acd9143feb611615e53214718037c5480292b96e1947e8e", adapter["sha256"])]
runtime_changes = [(runtime_old, runtime["path"]), ("b50c48f21c8cba132a0d1d015969de8917948cc8abe1f9455e2510abd41c573c", runtime["sha256"])]
base = "res://build/luoyang_city_space_20261024b_source01/"
candidate = {}
candidate["C"] = code(base + "C_space_closed02_CANDIDATE.gd", "a64b1ccfb99fd797f058e51b7d4317fed99f0b65445028fdf2aab266182cafc7", "C_READY.gd", adapter_changes)
candidate["Fade"] = code(base + "District_fade_closed02_CANDIDATE.gd", "58071692fcbba5ecdd76e02fcc74cca857330aaa454c5d95ddc36fbc0a7ea314", "Fade_READY.gd", adapter_changes + runtime_changes)
candidate["B"] = code(base + "B_closed02_CANDIDATE.gd", "47e35a3d72ac2797dd0fa9d3c9e222c3a8475c562d203345fb2aaa8963f14704", "B_READY.gd", adapter_changes + [
    (base + "District_fade_closed02_CANDIDATE.gd", candidate["Fade"]["path"]),
    ("58071692fcbba5ecdd76e02fcc74cca857330aaa454c5d95ddc36fbc0a7ea314", candidate["Fade"]["sha256"]),
])
candidate["DT"] = code(base + "District_closed02_CANDIDATE.gd", "aa50ce9a8efd9352528f01481252c55238efe130a0be2ffc271e9e11476a0d35", "DT_READY.gd", adapter_changes + runtime_changes)
candidate["G"] = code(base + "G_space_closed02_CANDIDATE.gd", "424eb9d017bff9305d9b107c04751d44f5ac37ca9cf46eb38af567b22f749ec1", "G_READY.gd", runtime_changes)
candidate["Field"] = code(base + "Field_dialog_space_closed02_CANDIDATE.gd", "2bc9ec905d755ecd366c226b7e88449a803e595a55f089f0a0121e185fb670ea", "Field_READY.gd", runtime_changes)
system = "res://build/luoyang_market_use_20261024b_system01/runtime_closed02/"
for key, filename, sha in [
    ("ENV", "environment_market_five_use_CANDIDATE.gd", "5f208710afc28597a79e7311e06870864f7256d8d39aa8547224b278b1da834e"),
    ("ground", "market_ground_exact_base37_CANDIDATE.gd", "f3566411eccdc1b86bdcf1fd7f06ca4b1c7b1fbbe76423bb5bf8eb61d55eec45"),
]:
    candidate[key] = code(system + filename, sha, key + "_READY.gd", runtime_changes + [("const MARKET_SPACE_READY=false", "const MARKET_SPACE_READY=true")])
manifest = dict(status="ROOT_CODE_SCOPE_MECHANICAL_READY_CANDIDATES_NOT_STAGE_OR_DEPLOYMENT", ready_for_code_parse_only=True,
                runtime=runtime, adapter=adapter, binding=binding_result, candidates=candidate, records=records,
                binding_typed_inverse={"parent": binding_parent, "parent_sha256": digest(binding_bytes),
                                       "ready_flags_only_plus_Root_F219_five_ordinary_dialogue_keys": True,
                                       "new_keys": ordinary_dialogue, "whole_typed_inverse": back == prior_binding},
                unchanged_owned_members=10, no_formal_writes=True, engine_calls=0, collector_calls=0,
                whole_street_GPU_ART=False, whole_city_ART=False, actual_final_Field_journey_pass=False)
result = write("mechanical_READY_freeze_inverse.json", (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf8"))
print(json.dumps(dict(proof=result, runtime=runtime, adapter=adapter, candidates=candidate, binding=binding_result)))
