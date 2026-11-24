"""Build only: exact current-formal declarations, no collector/live hash fill."""
from pathlib import Path
import json
import hashlib

GAME = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
PARENT = "res://build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_ActorParent_exact22_stage01/receipt.json"
PARENT_SHA = "8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392"

def digest(data):
    return hashlib.sha256(data).hexdigest()

def fixed(path, expected=None):
    data = (GAME / path[6:]).read_bytes()
    assert expected is None or digest(data) == expected
    assert b"tokens truncated" not in data
    return json.loads(data)

stage = fixed(PARENT, PARENT_SHA)
old = {}
for key, row in stage["nodes"].items():
    if key.startswith("expected_ch4_"):
        for path, value in row["value"]["source_sha256"].items():
            assert path not in old or old[path] == value
            old[path] = value
rows = [dict(target=r["target"], old_sha256=r["candidate_sha256"],
             old_declaration=dict(path=PARENT, sha256=PARENT_SHA, pointer=["targets", i, "candidate_sha256"]),
             role="Existing formal metadata/index cascade; all histories and Root64 classification retained")
        for i, r in enumerate(stage["targets"])]
extras = [
    ("scripts/city/luoyang_precomputed_bundle_20261018r.gd", "Bound new Market child and exact adapter/fade source successors"),
    ("scripts/city/luoyang_enclosure_v11_candidate_contract.gd", "Ordinary C exact adapter literals; no new OWNED member"),
    ("scripts/city/luoyang_district_life_20261016f.gd", "Exact adapter and source-bound Market projection"),
    ("scripts/city/luoyang_district_life_fade_20261016f.gd", "Exact adapter and four source-bound low-prop identifiers"),
    ("scripts/field/field_walkable_controller.gd", "Approved dialogue parent plus two exact task-position hooks"),
    ("scripts/city/luoyang_environment_layer_20261022ap.gd", "Market-only five purpose layers, nonowned"),
    ("scripts/city/luoyang_market_ground_20261020ae.gd", "Exact new Market complete37 bound-parent branch, nonowned"),
    ("scripts/ui/dialog_box.gd", "Two approved portrait fallback fixes, ordinary source"),
    ("scripts/city/luoyang_docks_district08_20261019aa.gd", "Ordinary C source byte-chain literals, author/geometry unchanged"),
    ("scripts/city/luoyang_docks_workyard_20261019ac.gd", "Ordinary AA source byte-chain literals; existing AC owner edge"),
    ("scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd", "One exact culture-contract SHA literal"),
    ("scripts/city/luoyang_temple_assembly_20261016.gd", "Two exact binding path/SHA literals; merged194 source scope"),
    ("data/luoyang_culture_integration_20261019x/runtime_contract.json", "Exact C and Field source SHA values only"),
    ("data/maps/luoyang_estate_rooms_20261021am/registry.json", "Five DT source values; original twelve rooms/native/author retained"),
]
ui_parent = "02c46cbf1519d6a2b8a95f1ffc8f0193e197a6f710611a89b86eee975f635c7c"
ui_receipt = "res://build/luoyang_city_revision_20261024b_dialog01/fallback_successor02/stage_CANDIDATE/receipt.json"
ui = fixed(ui_receipt)
assert ui_parent in json.dumps(ui)
for suffix, role in extras:
    path = "res://" + suffix
    assert path not in {r["target"] for r in rows}
    if path.endswith("/dialog_box.gd"):
        value = ui_parent
        source = dict(path=ui_receipt, sha256=digest((GAME / ui_receipt[6:]).read_bytes()), selector="fixed source old_sha256 for canonical dialog_box.gd")
    else:
        assert path in old, path
        value = old[path]
        source = dict(path=PARENT, sha256=PARENT_SHA, selector="four fixed expected source maps; equal wherever present")
    rows.append(dict(target=path, old_sha256=value, old_declaration=source, role=role))
assert len(rows) == 36 and len({r["target"] for r in rows}) == 36
assert sum(r["target"].endswith(".gd") for r in rows) == 21
out = dict(status="EXACT36_EXISTING_TARGET_SCOPE_PREPARATION_ONLY_NOT_STAGE", ready=False,
           parent_actual_stage=dict(path=PARENT, sha256=PARENT_SHA), target_count=36,
           target_partition=dict(apply_patch_GD=21, exact_copy_JSON=15), targets=rows,
           no_runtime_authority_whitelist_expansion=True, active_owned_members_unchanged=10,
           owned_successor_members=["B", "G", "AC", "DT", "Field", "Coordinator", "Temple"],
           prior_proof_sources=109, proposed_proof_sources=118,
           new_UI_target_not_in_prior_2120_guard=True,
           Root_must_capture_and_backup_all36_before_deployment=True,
           F219_five_ordinary_sources_scope="All eight city/quarter/Estate/Temple full sources and G room full sources; never runtime_authority whitelist",
           frozen=["other seven native scenes/layouts/walks", "all room native publications and raw authors", "portal shader", "Family", "hash worker", "Router", "CityTasks", "DP", "task rewards/flags"],
           engine_calls=0, collector_calls=0, canonical_writes=0)
data = (json.dumps(out, ensure_ascii=False, indent=2) + "\n").encode("utf8")
path = HERE / "exact36_existing_scope_PREPARATION_NOT_STAGE.json"
with path.open("xb") as stream:
    stream.write(data)
print(json.dumps(dict(path="res://" + path.relative_to(GAME).as_posix(), sha256=digest(data), bytes=len(data), targets=36, GD=21, JSON=15)))
