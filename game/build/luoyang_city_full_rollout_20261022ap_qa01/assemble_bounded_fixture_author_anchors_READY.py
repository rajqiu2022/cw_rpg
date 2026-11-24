"""Assemble frozen QA expectations only; no engine, collector or current-disk SHA backfill.

All three input manifests must be externally fixed by explicit SHA arguments. The
owners manifest must be produced from Root's actual stage receipt; geometry is a
separate fixed source-native translation. No unresolved slot is auto-filled.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
BASE = QA / "bounded_groups_v3_dialogues_NOTREADY.json"
COORDS = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_system01/final_system_coordinates_handoff_READY.json"
COORDS_SHA = "761092c89967b8fd80aa5f7915a52b9c6317a7e36e2fd9d60a1294ab966623a0"
ACTORS = QA / "finite_actor_expectations_READY.json"
ACTORS_SHA = "34d99c9df2ddab5abf70318e5701da30086ef77e5f563c4610f1c726d9ba4ce3"
OUTDOOR = ["ch4_s0_luoyang_gate", "ch4_s3_luoyang_market", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "luoyang_estate_riverside_20261021ai", "ch4_s4_ancient_temple", "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]


def frozen(path, expected):
    p = Path(path).resolve()
    if not p.is_relative_to(ROOT) or len(expected) != 64:
        raise ValueError("Exact workspace input and external SHA required")
    raw = p.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected.lower():
        raise ValueError("Frozen input changed: " + str(p))
    return json.loads(raw)


def f32(value):
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def vec(value):
    if not isinstance(value, list) or len(value) != 2 or any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in value):
        raise ValueError("Finite source pair required")
    return [f32(v) for v in value]


def uv(foot, source=(3072, 2048)):
    return [f32(f32(a) / f32(b)) for a, b in zip(vec(foot), source)]


def world(foot, source, size):
    return [f32(a * f32(b)) for a, b in zip(uv(foot, source), size)]


def source_rows(rows, expected_ids):
    result = {r["id"]: r for r in rows}
    if len(result) != len(rows) or set(result) != set(expected_ids):
        raise ValueError("Exact unique owner ID set required")
    for row in result.values():
        for key in ("source_sha256", "receipt_source_sha256"):
            if not isinstance(row.get(key), dict) or not row[key] or any(not isinstance(k, str) or not k.startswith("res://") or len(v) != 64 for k, v in row[key].items()):
                raise ValueError("Complete independent collector/receipt maps required")
        if row["scene_path"] not in row["source_sha256"] or row["layout_path"] not in row["source_sha256"]:
            raise ValueError("Native scene/layout must belong to full source map")
        if not isinstance(row.get("npc_rows"), list) or not isinstance(row.get("visual_ids"), list):
            raise ValueError("Explicit finite visual/NPC expectations required")
        vec(row["world_size"])
    return result


def attach_metadata(row, actors):
    """Fixed native identity schema, not a current canonical filesystem scan."""
    identity = row["id"]
    kinds = {"C": "CITY", "G": "ROOM", "Quarter": "QUARTER", "Estate": "ESTATE", "Temple": "TEMPLE"}
    row["owner"] = kinds.get(row["owner"], row["owner"])
    if identity in ("ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen"):
        prefix = "res://data/maps/luoyang_layout_bundle_20261018t_retry2/" + identity + "/"
    elif identity == "ch4_s3_luoyang_market":
        prefix = "res://data/maps/luoyang_full_city_20261022ap/market/" + identity + "/"
    elif identity == "ch4_s2_canal_docks":
        prefix = "res://data/maps/luoyang_docks_workyard_20261019ac/runtime/" + identity + "/"
    elif identity == "luoyang_estate_riverside_20261021ai":
        prefix = "res://data/maps/luoyang_estate_courtyard_20261021am/"
    elif row["owner"] == "QUARTER":
        prefix = "res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/" + identity + "/"
    elif row["owner"] == "ROOM":
        prefix = "res://data/maps/luoyang_full_city_20261022ap/rooms/" + identity + "/"
    elif identity == "ch4_s4_ancient_temple":
        prefix = None
    else:
        raise ValueError("No independent native identity recipe")
    row["scene_path"] = prefix + "scene.res" if prefix else "res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres"
    row["layout_path"] = prefix + "layout.res" if prefix else "res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres"
    row["world_size"] = [1920, 1280] if row["owner"] in ("ROOM", "TEMPLE") else [3072, 2048]
    finite = actors["scenes"].get(identity, {"npc_rows": [], "daily_identities": []})
    row["npc_rows"] = finite["npc_rows"]
    row["daily_identities"] = finite["daily_identities"]
    row["visual_ids"] = {
        "ch4_s3_luoyang_market": ["market_west_ward_frontage", "north_market_front"],
        "luoyang_artisan_residential_20261022ap": ["ap_courtyard_home_west", "ap_courtyard_home_east", "ap_woodwork_court_west_chinese_v3", "ap_cloth_dye_workshop_east", "ap_carpentry_general_shop_south"],
        "luoyang_riverside_garden_20261022ap": ["ap_river_pavilion", "ap_curved_bridge_scenic"],
    }.get(identity, [])
    return row


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--owners", required=True)
    parser.add_argument("--owners-sha", required=True)
    parser.add_argument("--geometry", required=True)
    parser.add_argument("--geometry-sha", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    plan = frozen(BASE, args.base_sha)
    coordinates = frozen(COORDS, COORDS_SHA)
    owners = frozen(args.owners, args.owners_sha)
    geometry = frozen(args.geometry, args.geometry_sha)
    actors = frozen(ACTORS, ACTORS_SHA)
    if owners.get("status") != "ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS" or geometry.get("status") != "INDEPENDENT_RAW_SOURCE_DATA_AND_ONE_FROZEN_DOCKS_RECIPE_NO_ENGINE":
        raise ValueError("No pending source/geometry scope may become READY")
    room_ids = [r["target"] for r in coordinates["doors"]]
    scenes = source_rows([attach_metadata(r, actors) for r in owners["scenes"]], OUTDOOR)
    rooms = source_rows([attach_metadata(r, actors) for r in owners["rooms"]], room_ids)
    all_rows = {**scenes, **rooms}
    raw_domains = dict(geometry["geometry"])
    recipe = geometry["Docks_recipe"]
    raw_domains[recipe["id"]] = {
        "recipe": "DOCKS_FIXED_PACKET_AND_DISTRICT_AUTHOR",
        "packet_path": recipe["packet_path"], "packet_sha256": recipe["packet_sha256"],
        "district_author_path": recipe["District_author"], "district_author_sha256": recipe["District_author_sha256"],
        "source_size_px": recipe["source_size_px"], "floor_regions_px": recipe["floor_regions_px"],
        "foot_forbidden_regions_px": recipe["foot_forbidden_regions_px"], "solids": [], "mask_path": "", "mask_sha256": "",
    }
    if set(raw_domains) != set(all_rows):
        raise ValueError("Exact thirteen independent geometry domains")
    if not owners.get("core_source_sha256") or owners.get("actual_stage_receipt") is None:
        raise ValueError("Actual stage receipt and fixed runtime authority required")
    for identity, row in all_rows.items():
        g = raw_domains[identity]
        if "mask_sha256" not in g:
            g["mask_sha256"] = row["source_sha256"].get(g["mask_path"], "") if g["mask_path"] else ""
        if not all(k in g for k in ("floor_regions_px", "solids", "source_size_px", "foot_forbidden_regions_px", "mask_path", "mask_sha256")):
            raise ValueError("Complete raw polygon oracle input required")
        if not g["floor_regions_px"] or (not g["solids"] and g.get("recipe") != "DOCKS_FIXED_PACKET_AND_DISTRICT_AUTHOR"):
            raise ValueError("Nonempty real floor and solids required")
        if g["mask_path"] and row["source_sha256"].get(g["mask_path"]) != g["mask_sha256"]:
            raise ValueError("Mask exact identity must belong to scene collector")
        row["geometry"] = g
        row["ordinary_picture_label"] = identity
        row["negative_stations"] = []
    for c in coordinates["scene_setup_candidates"]:
        row = scenes[c["id"]]
        source_size = row["geometry"]["source_size_px"]
        row["setup_uv"] = None if c["default_setup"] else uv(c["setup_foot"], source_size)
        if c["id"] == "ch4_s4_ancient_temple":
            start = [f32(f32(a) * f32(b)) for a, b in zip(c["source_default_uv"], row["world_size"])]
            end = world(c["short_source_input_to"], source_size, row["world_size"])
        else:
            start = world(c.get("source_default_foot", c.get("setup_foot")), source_size, row["world_size"])
            end = world(c["short_input_to"], source_size, row["world_size"])
        row["input_points"] = [start, end]
    for row in plan["doors"]:
        c = next(r for r in coordinates["doors"] if r["id"] == row["id"])
        room = rooms[c["target"]]
        row.update({k: c[k] for k in ("source", "target", "source_approach", "source_portal_foot", "authored_return_foot")})
        row["setup_uv"] = uv(c["setup_foot"])
        row["return_memory_policy"] = "ACTUAL_CAPTURED_FOOT" if row["source"] == "ch4_s3_luoyang_market" else "AUTHORED_PORTAL_ANCHOR"
        row["source_portal_foot"] = world(c["source_portal_foot"], [3072, 2048], scenes[c["source"]]["world_size"])
        row["entry_authored_target_uv"] = uv(c["room_arrival_source_foot"], c["room_source_size"])
        row["exit_authored_target_uv"] = uv(c["authored_return_foot"])
        row["room_arrival_foot"] = world(c["room_arrival_source_foot"], c["room_source_size"], room["world_size"])
        row["room_exit_foot"] = world(c["room_exit_source_foot"], c["room_source_size"], room["world_size"])
        row["room_exit_approach"] = [row["room_arrival_foot"], row["room_exit_foot"]]
    plan["links"] = []
    for c in coordinates["links"]:
        row = dict(c)
        row["setup_uv"] = uv(row.pop("setup_foot"))
        row["source_portal_foot"] = world(c["source_portal_foot"], [3072, 2048], scenes[c["source"]]["world_size"])
        row["target_portal_foot"] = world(c["target_portal_foot"], [3072, 2048], scenes[c["target"]]["world_size"])
        row["target_arrival_foot"] = world(c["target_arrival_foot"], [3072, 2048], scenes[c["target"]]["world_size"])
        row["entry_authored_target_uv"] = uv(c["target_arrival_foot"])
        row["exit_authored_target_uv"] = uv(c["expected_return_foot"])
        row["return_max_ms"] = 10000
        row["return_memory_policy"] = "AUTHORED_PORTAL_ANCHOR"
        row["setup_is_not_interdistrict_travel"] = True
        plan["links"].append(row)
    for row in plan["dialogues"]:
        c = next(r for r in coordinates["daily_dialogues"] if r["id"] == row["id"])
        row["setup_uv"] = uv(c["setup_foot"])
        row["approach"] = c["source_approach"]
        row["coordinate_status"] = "FROZEN_SOURCE_AUTHOR_NORMAL_INPUT_REQUIRES_ACTUAL_BODY_PHYSICS"
    garden = scenes["luoyang_riverside_garden_20261022ap"]
    garden["negative_stations"] = [{"id": "water_%d" % i, "foot": p} for i, p in enumerate(coordinates["Garden"]["water_negative_points"])]
    transfer = coordinates["Garden"]["bridge_source_to_world"]
    scale = f32(transfer["uniform_scale_numerator"] / transfer["uniform_scale_denominator"])
    for i, poly in enumerate(coordinates["Garden"]["bridge_negative_source_base_polygons"]):
        centroid = [sum(p[a] for p in poly) / len(poly) for a in range(2)]
        foot = [f32(f32(f32(f32(centroid[a]) - f32(transfer["source_anchor"][a])) * scale) + f32(transfer["world_foot"][a])) for a in range(2)]
        garden["negative_stations"].append({"id": "visible_bridge_stone_base_%d" % i, "foot": foot})
    # Explicitly public near-pavilion setup allows a finite real rim walk without
    # claiming the near setup was continuous interdistrict travel.
    garden["setup_uv"] = uv([1536, 768])
    garden["input_points"] = [[1536, 768], [1536, 680]]
    plan["scenes"] = [scenes[i] for i in OUTDOOR]
    plan["rooms"] = [rooms[i] for i in room_ids]
    plan["core_source_sha256"] = owners["core_source_sha256"]
    for res_path, input_sha in geometry["source_sha256"].items():
        if res_path in plan["core_source_sha256"] and plan["core_source_sha256"][res_path] != input_sha.lower():
            raise ValueError("Conflicting frozen raw geometry source")
        plan["core_source_sha256"][res_path] = input_sha.lower()
    receipt = owners["actual_stage_receipt"]
    if not isinstance(receipt, dict) or set(receipt) != {"path", "sha256"} or not receipt["path"].startswith("res://") or len(receipt["sha256"]) != 64:
        raise ValueError("Exact fixed Root actual-stage authority receipt required")
    plan["core_source_sha256"][receipt["path"]] = receipt["sha256"]
    for input_path, input_sha in ((COORDS, COORDS_SHA), (ACTORS, ACTORS_SHA), (Path(args.geometry).resolve(), args.geometry_sha), (Path(args.owners).resolve(), args.owners_sha)):
        res_path = "res://" + input_path.relative_to(ROOT / "game").as_posix()
        if res_path in plan["core_source_sha256"] and plan["core_source_sha256"][res_path] != input_sha.lower():
            raise ValueError("Conflicting independently frozen QA source")
        plan["core_source_sha256"][res_path] = input_sha.lower()
    plan["source_authority"] = {"actual_stage_receipt": owners["actual_stage_receipt"], "owners_input": str(Path(args.owners).resolve()), "owners_sha256": args.owners_sha, "geometry_input": str(Path(args.geometry).resolve()), "geometry_sha256": args.geometry_sha, "coordinate_source_sha256": COORDS_SHA}
    plan["input_endpoint_tolerance_px"] = .3
    plan["schema"] = "AP_QA_BOUNDED_GROUPS_V5_AUTHORED_AP_ANCHORS"
    plan["door_coordinates_boundary"] = "Frozen native portal centers and authored target UV are separately exact. Market2 old-city rooms return actual pre-entry captured canonical UV roundtrip. NewQuarter3 doors and3links return authored callback source portal anchor, exactly as unchanged Field24B5/Router source_spawn contract; ordinary INPUT endpoint independently only original driver.3px. Timber source portal1900 is the stored pair anchor while its authored room-exit target remains1924; both are explicitly predeclared, not observed-value backfill."
    plan["return_memory_authority"] = {"Field": "res://scripts/field/field_walkable_controller.gd", "Field_sha256": "24b5159b01470b571955f68a2762b9e979fc45703168e86cb8da157defea1179", "Router": "res://scripts/autoload/scene_router.gd", "Router_sha256": "c3452fd4735cfed1d1bc2b12dbf689b09a46ca093f430ba3ee940241ff443de6", "source": "Field._on_exit_triggered captures resident_actual_spawn only for FUNCTIONAL_INTERIORS.CITIES -> revision_room; otherwise callback authored source_portal_spawn remains. Router._prepare_joint_portal_arrival stores that source_spawn unchanged. Root selected this policy before first actual."}
    plan["blockers"] = []
    plan["ready"] = True
    out = Path(args.output).resolve()
    if out.exists() or not out.is_relative_to(QA):
        raise ValueError("NEW qa01 output only")
    payload = (json.dumps(plan, ensure_ascii=False, indent=2) + "\n").encode()
    if b"PENDING" in payload or b"NOT_ASSUMED" in payload:
        raise ValueError("No unresolved expected values")
    out.write_bytes(payload)
    print(json.dumps({"status": "FROZEN_QA_FIXTURE_NOT_ACTUAL_FIELD_CREDIT", "path": str(out), "sha256": hashlib.sha256(payload).hexdigest(), "fields": 8, "rooms": 5, "links": 3, "engine_executed": False}))


if __name__ == "__main__":
    main()
