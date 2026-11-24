"""Finite BUILD constructor. Reads fixed Root backups, not live source tables."""
from pathlib import Path
import json
import hashlib
import difflib
import copy

GAME = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = HERE / "source_closure36_BUILD"
OUT.mkdir(exist_ok=False)
S = "res://build/luoyang_city_space_20261024b_source01/"
D = "res://build/luoyang_docks_ordinary_space_20261024b_system01/READY03/"
R = "res://build/luoyang_city_revision_20261024b_root01/"
H = "res://build/luoyang_hall_portal_fix_20261024a_source01/"
EXEC = "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read(path, expected=None):
    data = (GAME / path[6:]).read_bytes()
    assert expected is None or sha(data) == expected, (path, sha(data), expected)
    assert b"tokens truncated" not in data
    return data

def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n").encode("utf8")

def output(name, data):
    path = OUT / name
    with path.open("xb") as stream:
        stream.write(data)
    return dict(path="res://" + path.relative_to(GAME).as_posix(), sha256=sha(data), bytes=len(data))

def hunks(before, after):
    left, right = before.decode("utf8").splitlines(keepends=True), after.decode("utf8").splitlines(keepends=True)
    matcher = difflib.SequenceMatcher(None, left, right, autojunk=False)
    for context in [3, 6, 12, 24, 48, 96, max(len(left), len(right))]:
        pairs = []
        for group in matcher.get_grouped_opcodes(context):
            pairs.append(dict(old="".join(left[group[0][1]:group[-1][2]]), new="".join(right[group[0][3]:group[-1][4]])))
        forward, inverse = before.decode("utf8"), after.decode("utf8")
        good = True
        for pair in pairs:
            if not pair["new"] or forward.count(pair["old"]) != 1 or inverse.count(pair["new"]) != 1:
                good = False
                break
            forward = forward.replace(pair["old"], pair["new"], 1)
            inverse = inverse.replace(pair["new"], pair["old"], 1)
        if good and forward.encode("utf8") == after and inverse.encode("utf8") == before:
            return pairs
    raise AssertionError("NO_EXACT_UNIQUE_WHOLEBYTE_INVERSE")

backup = json.loads(read(R + "predeploy36/backup_receipt.json", "2090fb309bf20a81413d167199dfd623f6ced607845c269f4c5e4a0aec8d650f"))
assert backup["count"] == 36 and len(backup["records"]) == 36
old = {row["target"]: row for row in backup["records"]}
freeze = json.loads(read(S + "runtime_READY02/mechanical_READY_freeze_inverse.json", "c522cdd1b1388b5fa8a5361cab8cd7046057d38bdfa9f2fb032b74a4d1502454"))
dependency = json.loads(read(S + "runtime_dependencies_READY02/culture_temple_dependency_inverse_NOT_STAGE.json", "36a42c3dd6b2f6f2c207a55c244b901a38417ed5ac721d739f08633ebb7f815f"))
names = {
    "B": "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd",
    "C": "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd",
    "DT": "res://scripts/city/luoyang_district_life_20261016f.gd",
    "Fade": "res://scripts/city/luoyang_district_life_fade_20261016f.gd",
    "G": "res://scripts/city/luoyang_assembled_interiors_20261016g.gd",
    "Field": "res://scripts/field/field_walkable_controller.gd",
    "ENV": "res://scripts/city/luoyang_environment_layer_20261022ap.gd",
    "ground": "res://scripts/city/luoyang_market_ground_20261020ae.gd",
    "UI": "res://scripts/ui/dialog_box.gd",
    "AA": "res://scripts/city/luoyang_docks_district08_20261019aa.gd",
    "AC": "res://scripts/city/luoyang_docks_workyard_20261019ac.gd",
    "Coordinator": "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd",
    "Temple": "res://scripts/city/luoyang_temple_assembly_20261016.gd",
}
candidates = copy.deepcopy(freeze["candidates"])
candidates["G"] = dict(path=S + "runtime_READY02/G_scope_dialog_sources_READY.gd", sha256="66e81fe56206f5b52400a5e41f8c3114bbc10f01fb9d5758cc07dc6fe58b6905", bytes=29420)
candidates["Coordinator"] = dependency["coordinator"]["candidate"]
candidates["Temple"] = dependency["temple"]["candidate"]
candidates["UI"] = dict(path="res://build/luoyang_city_revision_20261024b_dialog01/fallback_successor02/stage_CANDIDATE/DialogBox_CANDIDATE.gd", sha256="fe8165682670f7bcc5689d963b456f5d9503ba7f6abece575ad4f04e82c9c337")
candidates["AA"] = dict(path=D + "AA_ordinary_C_READY_CANDIDATE.gd", sha256="43236a64e31dcfc0824601ce5b3999d77c0729b8a64662c81fa0d6467ecd1f34")
candidates["AC"] = dict(path=D + "AC_ordinary_AA_READY_CANDIDATE.gd", sha256="80d4df3ea47af83a7568aeb40bbd1dcea843d2712de290603e60b030ffc61ee0")
records = {}
for key, path in names.items():
    row = old[path]
    parent_path = "res://" + Path(row["backup_path"]).relative_to(GAME).as_posix()
    a, b = read(parent_path, row["sha256"]), read(candidates[key]["path"], candidates[key]["sha256"])
    assert len(a) == row["bytes"] and sha(a) == row["backup_sha256"]
    assert b.endswith(b"\n") and b"\r" not in b and not b.startswith(b"\xef\xbb\xbf"), (key, "STRICT_LF_CANDIDATE_REQUIRED")
    candidates[key]["bytes"] = len(b)
    records[path] = dict(name=key, parent=dict(path=parent_path, sha256=sha(a), bytes=len(a)),
                         candidate=candidates[key], hunks=hunks(a, b), wholebyte_forward_inverse=True)

prior_path = H + "actor_parent_successor02/execution_successor_PROPOSAL_NOT_APPROVED.json"
prior_bytes = read(prior_path, "9c60d1aa21c38eaf02e8d2e64444b43d9cd2a5bd41cbf2b92d5ddc72318206af")
prior = json.loads(prior_bytes)
assert encode(prior) == prior_bytes and len(prior["owned"]) == 10 and len(prior["source_sha256"]) == 109
authority = copy.deepcopy(prior)
changed = [names[k] for k in ["B", "G", "AC", "DT", "Field", "Coordinator", "Temple"]]
for path in changed:
    row, record = authority["owned"][path], records[path]
    assert row["current_sha256"] == record["parent"]["sha256"]
    old_snapshot = next(e["new_snapshot"] for e in row["edges"] if e["new_sha256"] == row["current_sha256"])
    assert read(old_snapshot, row["current_sha256"]) == read(record["parent"]["path"], record["parent"]["sha256"])
    row["edges"].append(dict(path=path, old_sha256=row["current_sha256"], new_sha256=record["candidate"]["sha256"],
                             old_snapshot=old_snapshot, new_snapshot=record["candidate"]["path"],
                             whole_inverse=True, replacements=record["hunks"]))
    row["current_sha256"] = record["candidate"]["sha256"]
    assert record["candidate"]["path"] not in authority["source_sha256"]
    authority["source_sha256"][record["candidate"]["path"]] = record["candidate"]["sha256"]
for extra in [dependency["contract"]["candidate"], dependency["temple_binding"]["candidate"]]:
    read(extra["path"], extra["sha256"])
    assert extra["path"] not in authority["source_sha256"]
    authority["source_sha256"][extra["path"]] = extra["sha256"]
assert len(authority["source_sha256"]) == 118
restored = copy.deepcopy(authority)
for path in changed:
    restored["owned"][path] = copy.deepcopy(prior["owned"][path])
restored["source_sha256"] = copy.deepcopy(prior["source_sha256"])
assert restored == prior and encode(restored) == prior_bytes
execution = output("execution_successor_PREPARATION.json", encode(authority))
proof = dict(status="EXACT36_CODE_AND_EXECUTION_FULLBYTE_INVERSE_NOT_STAGE", ready=False,
             root_backup=dict(path=R + "predeploy36/backup_receipt.json", sha256="2090fb309bf20a81413d167199dfd623f6ced607845c269f4c5e4a0aec8d650f"),
             records=records, execution=dict(parent=dict(path=prior_path, sha256=sha(prior_bytes)), candidate=execution,
                 changed_existing_owned=changed, owned_count=10, prior_proof_count=109, new_proof_count=118,
                 extra={p: h for p,h in authority["source_sha256"].items() if p not in prior["source_sha256"]},
                 whole_typed_and_serialized_UTF8_inverse=True, other_three_owned_rows_unchanged=True),
             contract=dependency["contract"], temple_binding=dependency["temple_binding"],
             ordinary_C_AA_not_added_to_owned=True, whole_author_native_geometry_unchanged_except_approved_Market_child=True,
             engine_calls=0, collector_calls=0, canonical_writes=0)
result = output("code_execution_full_inverse_NOT_STAGE.json", encode(proof))
print(json.dumps(dict(proof=result, execution=execution, code_records=len(records), changed_owned=len(changed), proof_count=118)))
