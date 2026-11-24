"""Read-only physical byte checks; writes one NEW derived BUILD proof only."""
from pathlib import Path
import hashlib
import json
import difflib

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

def sha(data):
    return hashlib.sha256(data).hexdigest()

def path(res):
    assert res.startswith("res://") and ".." not in res
    return ROOT / res[6:]

def relative(p):
    return "res://" + p.relative_to(ROOT).as_posix()

baseline_path = ROOT / "build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_ActorParent_exact22_stage01/receipt.json"
assert sha(baseline_path.read_bytes()) == "8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392"
baseline = json.loads(baseline_path.read_text(encoding="utf8"))
baseline_map = baseline["nodes"]["expected_ch4_s3_luoyang_market_true"]["value"]
if "source_sha256" in baseline_map:
    baseline_map = baseline_map["source_sha256"]
pairs = [
    ("scripts/city/luoyang_precomputed_bundle_20261018r.gd", "B_closed02_CANDIDATE.gd"),
    ("scripts/city/luoyang_enclosure_v11_candidate_contract.gd", "C_space_closed02_CANDIDATE.gd"),
    ("scripts/city/luoyang_district_life_20261016f.gd", "District_closed02_CANDIDATE.gd"),
    ("scripts/city/luoyang_district_life_fade_20261016f.gd", "District_fade_closed02_CANDIDATE.gd"),
    ("scripts/city/luoyang_assembled_interiors_20261016g.gd", "G_space_closed02_CANDIDATE.gd"),
]
records = []
for original, candidate in pairs:
    old_path = ROOT / original
    new_path = HERE / candidate
    old = old_path.read_bytes()
    new = new_path.read_bytes()
    assert sha(old) == baseline_map[relative(old_path)]
    assert b"tokens truncated" not in new
    old_lines = old.splitlines(keepends=True)
    new_lines = new.splitlines(keepends=True)
    ops = []
    for tag, a0, a1, b0, b1 in difflib.SequenceMatcher(None, old_lines, new_lines, autojunk=False).get_opcodes():
        if tag == "equal":
            continue
        ops.append(dict(offset=sum(map(len, old_lines[:a0])), new_offset=sum(map(len, new_lines[:b0])),
                        old=b"".join(old_lines[a0:a1]).decode("utf8"), new=b"".join(new_lines[b0:b1]).decode("utf8")))
    forward = old
    for op in reversed(ops):
        previous = op["old"].encode("utf8")
        assert forward[op["offset"]:op["offset"] + len(previous)] == previous
        forward = forward[:op["offset"]] + op["new"].encode("utf8") + forward[op["offset"] + len(previous):]
    assert forward == new
    reverse = new
    for op in reversed(ops):
        previous = op["new"].encode("utf8")
        assert reverse[op["new_offset"]:op["new_offset"] + len(previous)] == previous
        reverse = reverse[:op["new_offset"]] + op["old"].encode("utf8") + reverse[op["new_offset"] + len(previous):]
    assert reverse == old
    records.append(dict(target=relative(old_path), old_sha256=sha(old), candidate=relative(new_path),
                        candidate_sha256=sha(new), bytes=len(new), operations=ops, wholebyte_forward_inverse=True))

field_parent = ROOT / "build/luoyang_city_revision_20261024b_dialog01/portrait_successor04/Field_final_CANDIDATE.gd"
assert sha(field_parent.read_bytes()) == "a97631c54e31dff83b49b4b2c80ece5360d7c82f6ce41c576a29f54520dc1a1d"
field = HERE / "Field_dialog_space_closed02_CANDIDATE.gd"
old = field_parent.read_bytes()
new = field.read_bytes()
assert b"tokens truncated" not in new
old_lines = old.splitlines(keepends=True)
new_lines = new.splitlines(keepends=True)
ops = []
for tag, a0, a1, b0, b1 in difflib.SequenceMatcher(None, old_lines, new_lines, autojunk=False).get_opcodes():
    if tag != "equal":
        ops.append(dict(offset=sum(map(len, old_lines[:a0])), new_offset=sum(map(len, new_lines[:b0])),
                        old=b"".join(old_lines[a0:a1]).decode("utf8"), new=b"".join(new_lines[b0:b1]).decode("utf8")))
forward = old
for op in reversed(ops):
    forward = forward[:op["offset"]] + op["new"].encode() + forward[op["offset"] + len(op["old"].encode()):]
assert forward == new
reverse = new
for op in reversed(ops):
    reverse = reverse[:op["new_offset"]] + op["old"].encode() + reverse[op["new_offset"] + len(op["new"].encode()):]
assert reverse == old
records.append(dict(target="res://scripts/field/field_walkable_controller.gd", parent=relative(field_parent),
                    old_sha256=sha(old), candidate=relative(field), candidate_sha256=sha(new), bytes=len(new),
                    operations=ops, wholebyte_forward_inverse=True, original_dialogue_parent_unchanged=True))

extra = []
for name in ["market_space_runtime_closed02_CANDIDATE.gd", "finite_adapter_closed02_CANDIDATE.gd", "market_space_binding_closed02_NOTREADY.json"]:
    p = HERE / name
    data = p.read_bytes()
    assert b"tokens truncated" not in data
    if p.suffix == ".json":
        value = json.loads(data)
        assert value["native_spec_ready"] and not value["ready"] and not value["source_closure_ready"]
        assert value["local_ART_admitted"] and not value["whole_street_GPU_ART"] and not value["whole_city_ART"]
    extra.append(dict(path=relative(p), sha256=sha(data), bytes=len(data)))
proof = dict(status="PHYSICAL_CLOSED02_CANDIDATES_WHOLE_BYTE_INVERSE_NOT_STAGE", ready=False,
             baseline_path=relative(baseline_path), baseline_sha256=sha(baseline_path.read_bytes()),
             records=records, additional=extra, JSON_strict_parse=True, no_truncation_in_all_delivered_files=True,
             source_collector_calls=0, engine_calls=0, canonical_writes=0,
             excluded_bad_BUILD_files_preserved=["C_space_CANDIDATE.gd", "market_space_binding_NOTREADY.json", "market_space_binding_media01_NOTREADY.json"])
destination = HERE / "closed02_physical_code_inverse_NOTREADY.json"
payload = (json.dumps(proof, ensure_ascii=False, indent=2) + "\n").encode("utf8")
with destination.open("xb") as file:
    file.write(payload)
assert json.loads(destination.read_bytes()) == proof
print(json.dumps(dict(path=relative(destination), sha256=sha(payload), bytes=len(payload), records=len(records),
                      changes=sum(len(r["operations"]) for r in records), passed=True)))
