"""Mechanical metadata successor only; no engine/collector/canonical writes.

Preserves the malformed earlier BUILD files. Never prints large JSON contents.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
PREFIX = "res://build/luoyang_city_space_20261024b_source01/"

def read(path):
    return json.loads(path.read_text(encoding="utf-8"))

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def res(path):
    return "res://" + path.relative_to(ROOT).as_posix()

old_path = ROOT / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/adapter_binding_READY.json"
assert digest(old_path) == "dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff"
old = read(old_path)["domains"]["market"]
report_path = ROOT / "build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/publication_result.json"
assert digest(report_path) == "86edae530049c0d5daaa256eba5ae7ae24b71cb92733f875581b86796404e92e"
report = read(report_path)
assert report["passed"] and report["source_first_final_same"]
author_path = HERE / "author_space_delta_route_detours_successor06_NOTREADY.json"
assert digest(author_path) == "7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f"
author = read(author_path)
art_path = ROOT / "build/luoyang_city_revision_20261024b_root01/local_two_asset_admission.json"
assert digest(art_path) == "317023fa18a840ae053d4e8fef2978d51d383fd7e997d620fec713d7cd96fd39"
art = read(art_path)
assert art["status"] == "ROOT_TWO_COMPLETE_SHOP_ASSETS_LOCAL_ADMISSION_ONLY"
assert art["local_ART_admitted"] and not art["whole_street_GPU_ART"] and not art["whole_city_ART"]
media_path = ROOT / "build/luoyang_city_revision_20261024b_root01/walk_two_leaf_actual.json"
assert digest(media_path) == "1ff7e8116c4cbfac7ccb883ddeabe7c39c86d0b1ebacb63a69dfa6ae8b94205c"
media = read(media_path)
stage_path = ROOT / "build/luoyang_hall_portal_fix_20261024a_source01/outputs/root_hall_ActorParent_exact22_stage01/receipt.json"
assert digest(stage_path) == "8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392"
stage = read(stage_path)
basis = "EXACT_CURRENT_FINITE_MARKET_TO_FULL_MERCHANT_BLOCK_20261024B"
artifacts = {path.rsplit("/", 1)[1]: {"path": path, "sha256": sha} for path, sha in report["result"]["artifacts"].items()}
immutable = json.loads(json.dumps(old["manifest_immutable"]))
immutable.update(geometry_proof_basis=basis, author_path=res(author_path), author_sha256=digest(author_path),
                 artifacts={path: sha for path, sha in report["result"]["artifacts"].items() if not path.endswith("walk.png")},
                 mask_sha256=report["result"]["mask_proof"]["child_rgba_sha256"],
                 layout_proof={"passed": True, "whole_record_packet_scene_layout_inverse": True,
                               "publication_path": res(report_path), "publication_sha256": digest(report_path)},
                 finite_art_admitted=True, finite_art_admission_path=res(art_path), finite_art_admission_sha256=digest(art_path))
immutable["finite_delta_parent_publication"] = {"packet_path": old["artifacts"]["packet.bin"]["path"], "packet_sha256": old["artifacts"]["packet.bin"]["sha256"], "basis": old["basis"]}
pins = dict(report["source_first"])
for path in [report_path, art_path, media_path]:
    pins[res(path)] = digest(path)
for row in media["leaves"]:
    pins[row["res"]] = row["sha"]
rooms = {}
for delta in author["two_return_only_registry_migrations"]:
    room_id = delta["room_scene_id"]
    source = "res://data/maps/luoyang_market_two_shops_20261021ao/rooms/" + room_id + "/author.json"
    building = "market_northeast_rear_frontage" if "northeast" in room_id else "market_east_ward_frontage"
    portal = next(row for row in author["native_portal_migrations"] if row["id"] == "enter_" + building + "_room")
    rooms[room_id] = dict(old_return_px=delta["old_world_px"], new_return_px=delta["new_world_px"],
                          new_threshold_px=portal["new_foot_px"], author_path=source, author_sha256=stage["source_first"][source])
    pins[source] = stage["source_first"][source]
value = dict(status="EXACT_MARKET_SPACE_SOURCE_BOUND_NOT_WHOLE_CITY", scene_id="ch4_s3_luoyang_market",
             ready=False, native_spec_ready=True, source_closure_ready=False, local_ART_admitted=True,
             local_ART_scope=art["scope"], local_ART_path=res(art_path), local_ART_sha256=digest(art_path),
             whole_street_GPU_ART=False, whole_city_ART=False, walk_media_admitted=True,
             blockers=["Root final code and finite source closure preparation authorization pending"],
             author_path=res(author_path), author_sha256=digest(author_path),
             purpose_ancestor_path=PREFIX + "author_space_delta_interaction_successor03_NOTREADY.json",
             purpose_ancestor_sha256="cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467",
             publication_path=res(report_path), publication_sha256=digest(report_path), source_sha256=pins,
             artifacts=artifacts, mask_rgba_sha256=report["result"]["mask_proof"]["child_rgba_sha256"],
             old_finite_packet=old["artifacts"]["packet.bin"], old_finite_basis=old["basis"], basis=basis,
             domain_overrides=dict(basis=basis, artifacts=artifacts, mask_rgba_sha256=immutable["mask_sha256"], manifest_immutable=immutable),
             room_returns=rooms, source_collector_calls=0, engine_calls=0)
destination = HERE / "market_space_binding_closed02_NOTREADY.json"
payload = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
with destination.open("xb") as file:
    file.write(payload)
assert read(destination) == value
assert "tokens truncated" not in payload.decode("utf-8")
print(json.dumps(dict(path=res(destination), sha256=digest(destination), bytes=len(payload), ready=False,
                      source_count=len(pins), rooms=len(rooms), fixed_parent_publication_preserved=immutable["parent_publication"] == old["manifest_immutable"]["parent_publication"])))
