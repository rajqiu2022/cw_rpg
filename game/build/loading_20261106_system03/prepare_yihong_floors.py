"""Prepare an isolated, exact two-floor Yihong successor; never deploys it."""

import base64
import copy
import hashlib
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REG = "game/build/luoyang_regions_20261027d_source01/"
MANIFEST = REG + "region_runtime_manifest_BUILD.json"
ENTRY = REG + "region_entry.gd"
FIELD = REG + "region_field.gd"
LOWER = "yihongyuan27n_interior"
UPPER = "yihongyuan27n_upper"
NEXT = "game/build/yihongyuan_floors_20261107_runtime01/"
BIN = {floor: NEXT + floor + ".bin" for floor in (LOWER, UPPER)}
HELPER = NEXT + "upper_room.gd"
SCENE = NEXT + UPPER + ".tres"
QUALITY = "game/build/luoyang_quality_20261101b_runtime01/"
QUALITY_CODE = QUALITY + "scene_art_quality_runtime.gd"
QUALITY_PINS = QUALITY + "source_pins_READY.json"
GROUND = "game/build/luoyang_quality_20261101b_ground01/ground_visual.gd"
ROUTER = "game/scripts/autoload/scene_router.gd"
EX = "game/data/maps/luoyang_full_city_20261022ap/execution_successor.json"
EX_INDEX = "game/scripts/city/luoyang_execution_index_20261022ap.gd"
AUTH = "game/scripts/city/luoyang_execution_authority_20261022ap.gd"
GATE = "game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json"
CULTURE = "game/data/luoyang_culture_integration_20261019x/runtime_contract.json"
SNAP = "res://build/luoyang_yihong_floors_20261107_source01/scene_router.gd.snapshot.txt"
PROOF = "game/build/interior_identity_20261106_system01/formal_actual/60764/result.json"
MEDIA_RECEIPT = "game/build/yihongyuan_floors_20261107_art01/floor_media_formal_install_receipt.json"
GATE_HISTORY = BASE / "formal_residual02/actual/37116/result.json"
PARENT = BASE / "yihong_source_REVIEW01/receipt.json"
HASHES = {
    ENTRY: "af4a33cd8a86ad6a964b5c1c8fb8b39a6982296e48710d9ebeea1ab04d06b8bf",
    FIELD: "fadacfa277fe19fab06f8e1d21583394b1dd98c6ed1b632dac709e5f4bf2eec2",
    QUALITY_CODE: "2ad745c02959770a14a15d1e10a65247f1f461dbe2101d3e5c502a1bc9d636ba",
    QUALITY_PINS: "ad64f2b7f975da828dce31df563c79dbf04631092c59626408ddb606d595ece5",
    GROUND: "77183150ee076c4a57f0e3fac537a1e5fdd3d1884ea714102cf9156343c47fcc",
}
MAPS = {"source_sha256", "legacy_source_sha256", "runtime_authority_sha256", "source_pins"}


def check(ok, *reason):
    if not ok:
        raise ValueError(*reason)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def path(rel, base="game"):
    check(isinstance(rel, str) and "\\" not in rel and all(x not in {"", ".", ".."} for x in rel.split("/")), "UNSAFE_PATH", rel)
    target = (ROOT / rel).resolve()
    check(target.is_relative_to((ROOT / base).resolve()), "PATH_SCOPE", rel)
    check(not {x.casefold() for x in target.parts} & {"save", "saves", "app_userdata", "appdata", "localappdata"} and not re.fullmatch(r"save_\d+\.json(?:\.bak|\.tmp)?", target.name, re.I), "NO_SAVE", rel)
    return target


def read(rel):
    return path(rel).read_bytes()


def res(rel):
    check(rel.startswith("game/"), "RESOURCE_PREFIX", rel)
    return "res://" + rel[5:]


def rel(resource):
    check(resource.startswith("res://"), "RESOURCE_PATH", resource)
    return "game/" + resource[6:]


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode()


def once(raw, old, new):
    old = old.encode() if isinstance(old, str) else old
    new = new.encode() if isinstance(new, str) else new
    check(raw.count(old) == 1 and old != new, "ONE_EDIT", old[:100], raw.count(old))
    return raw.replace(old, new, 1)


def row_span(raw, key, indent):
    text = raw.decode()
    pattern = "^" + re.escape(" " * indent + json.dumps(key) + ": {")
    found = list(re.finditer(pattern, text, re.M))
    check(len(found) == 1, "JSON_ROW", key, indent)
    start = found[0].end() - 1
    _, end = json.JSONDecoder().raw_decode(text[start:])
    return text, start, start + end


def row(raw, key, value, indent):
    text, start, end = row_span(raw, key, indent)
    lines = json.dumps(value, ensure_ascii=False, indent=2).splitlines()
    return (text[:start] + lines[0] + "".join("\n" + " " * indent + line for line in lines[1:]) + text[end:]).encode()


def add(raw, key, values):
    text, _, end = row_span(raw, key, 2)
    check(text[end-4:end] == "\n  }" and not set(json.loads(raw)[key]) & set(values), "MAP_ADDITIONS_ONLY", key)
    lines = [json.dumps(k) + ": " + json.dumps(v, ensure_ascii=False, indent=2).replace("\n", "\n    ") for k, v in values.items()]
    return (text[:end-4] + "".join(",\n    " + line for line in lines) + text[end-4:]).encode()


def mapped(raw, known):
    expected = json.loads(raw)

    def visit(obj):
        nonlocal raw
        if isinstance(obj, list):
            for value in obj:
                visit(value)
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key in MAPS and isinstance(value, dict):
                    for pin in sorted(set(value) & set(known)):
                        old, new = known[pin]
                        if value[pin] == old:
                            raw = once(raw, f"{json.dumps(pin)}: {json.dumps(old)}", f"{json.dumps(pin)}: {json.dumps(new)}")
                            value[pin] = new
                else:
                    visit(value)

    visit(expected)
    check(json.loads(raw) == expected, "SOURCE_PINS_ONLY")
    return raw


def startup():
    parent = PARENT.read_bytes()
    check(sha(parent) == "1ec20d03fbd74d594249152ef232765815b9471508ce4708079ebd845cc493bb", "PARENT_RECEIPT")
    parent = json.loads(parent)
    hashes = {entry["target"]: entry["after_sha256"] for entry in parent["targets"]} | HASHES
    originals = {target: read(target) for target in hashes}
    for target, raw in originals.items():
        check(sha(raw) == hashes[target], "LIVE_PREIMAGE_DRIFT", target, sha(raw))
    check(sha(read(CULTURE)) == "deadf17e6f2d8a8362725c4ee78d23f8713364e38d2da5f1a9af77d713bd609e", "STRICT_CULTURE_CONTRACT_DRIFT")
    prior = parent["router_snapshot"]["path"]
    check(read(rel(prior)) == originals[ROUTER], "ROUTER_SNAPSHOT_PREIMAGE")
    check(len(originals) == 29, "REVIEWED_29_EXISTING_TARGETS")
    return parent, hashes, originals, prior


def gate_baseline(old):
    old_proof = GATE_HISTORY.read_bytes()
    check(sha(old_proof) == "22dd15f77926563c5642c30a499be330c22169d95f2c93edf5e29de782d4a4fd", "PREDECESSOR_GATE_PROOF_DRIFT")
    history = json.loads(old_proof)["gate_source_admission"]
    check(history["passed"] and history["actual_sources"] == history["expected_sources"], "PREDECESSOR_GATE_NOT_EXACT")
    proof = read(PROOF)
    check(sha(proof) == "b0868a7ec483503e1863b5de2deaadccc98f5d5806a7c165a7d8ec21d3b6e0ba", "ACCEPTED_GATE_PROOF_DRIFT")
    result = json.loads(proof)
    gate = result["evidence"]["gate"]
    check(result["failures"] in ([], 0) and gate["passed"] is True and gate["actual_count"] == gate["expected_count"] == 1758 and not any(gate[k] for k in ("different", "extra", "missing")), "ACCEPTED_RUN_NOT_PASS")
    baseline = gate_pins(json.loads(old[GATE]))
    dynamic = set(history["actual_sources"]) - set(baseline)
    check(len(dynamic) == 8 and res(GATE) in dynamic, "GATE_DYNAMIC_EXACT_EIGHT", sorted(dynamic))
    return baseline | {resource: sha(read(rel(resource))) for resource in dynamic}, dynamic


def gate_pins(manifest):
    return manifest["artifacts"] | manifest["runtime_authority_sha256"] | manifest["legacy_source_sha256"]


def audit_hashes(sources, overlay):
    def verify(item):
        resource, expected = item
        candidate = overlay.get(rel(resource))
        actual = sha(candidate if candidate is not None else read(rel(resource)))
        return resource, expected, actual

    with ThreadPoolExecutor(max_workers=4) as pool:
        mismatch = [r for r in pool.map(verify, sources.items()) if r[1] != r[2]]
    check(not mismatch, "SOURCE_SHA_DIFF", mismatch)


def media_sources(pin_file):
    source = read(MEDIA_RECEIPT)
    check(sha(source) == "6d554da7908d8b022d3c0ef96544f18c3910ed426a6a051dfea4268fa8c5e3d8", "INSTALLED_MEDIA_RECEIPT_DRIFT")
    receipt = json.loads(source)
    check(receipt["scope"] == "INSTALLED_YIHONG_FLOORS_9_LEAVES_NO_CONSUMER_SWITCH", "MEDIA_RECEIPT_SCOPE")
    installed = {}
    kinds = set()
    for row in receipt["targets"]:
        role, kind = row["role"], row["kind"]
        check((role, kind) not in kinds and role in {"upper_shell", "up_stair", "tea_table"}, "MEDIA_ROLE_DOMAIN")
        kinds.add((role, kind))
        relative = Path(row["target"]).resolve().relative_to(ROOT).as_posix()
        if kind == "ctex":
            check(re.fullmatch(rf"game/\.godot/imported/{role}\.png-[0-9a-f]{{32}}\.ctex", relative), "MEDIA_CACHE_DOMAIN", relative)
        else:
            check(kind in {"png", "import"} and relative == f"game/art/modules/yihongyuan_floors_20261107/{role}.png" + (".import" if kind == "import" else ""), "MEDIA_SOURCE_DOMAIN", relative)
        check(relative not in installed and row["before"] == "ABSENT", "MEDIA_LEAF_DUPLICATE_OR_OVERWRITE", relative)
        installed[relative] = row["after_sha256"]
    check(len(installed) == 9 and json.loads(read(pin_file)) == installed, "COMPILE_MEDIA_EQUALS_ADMITTED_NINE")
    audit_hashes({res(p): h for p, h in installed.items()}, {})
    return installed


def replay_exact(pre, after, spec, count):
    check(spec.get("whole_inverse") is True and len(spec["hunks"]) == count, "EXACT_ROOM_HUNK_COUNT", count)
    forward = pre
    for hunk in spec["hunks"]:
        pos, previous, revised = hunk["offset"], hunk["old"].encode(), hunk["new"].encode()
        check(previous in revised and forward.find(previous) == pos and forward.count(previous) == 1, "ROOM_FORWARD_EXACT_SPAN")
        forward = forward[:pos] + revised + forward[pos+len(previous):]
    check(forward == after, "ROOM_FORWARD_BYTE_MATCH")
    for hunk in reversed(spec["hunks"]):
        pos, previous, revised = hunk["offset"], hunk["old"].encode(), hunk["new"].encode()
        check(forward[pos:pos+len(revised)] == revised, "ROOM_INVERSE_EXACT_SPAN")
        forward = forward[:pos] + previous + forward[pos+len(revised):]
    check(forward == pre, "ROOM_WHOLE_INVERSE")


def build(room, media=None):
    parent, hashes, old, prior = startup()
    gate0, dynamic = gate_baseline(old)
    check(len(gate0) == 1758, "ACCEPTED_GATE_EXPECTED_COUNT")
    if room is None:
        audit_hashes(gate0, {})
        return {"status": "BASELINE_READ_ONLY", "existing_targets": len(old), "gate_pins": len(gate0)}
    after = {}
    old_region = json.loads(old[MANIFEST])
    check(set(room) == {ENTRY, FIELD, HELPER, SCENE, *BIN.values()}, "EXACT_SIX_ROOM_TARGETS")
    check(all(not path(p).exists() for p in (HELPER, SCENE, *BIN.values(), rel(SNAP))), "NEW_LEAF_ALREADY_PRESENT")
    for target, spec in room.items():
        candidate = path(spec["candidate"], "game/build")
        check(candidate != path(target) and not candidate.is_relative_to(path(NEXT[:-1])), "CANDIDATE_SCOPE", target)
        after[target] = candidate.read_bytes()
        check(spec["before_sha256"] == hashes.get(target) and sha(after[target]) == spec["sha256"], "ROOM_STAGE_DRIFT", target)
        check(not any(hashes[p].encode() in after[target] for p in (FIELD, ENTRY, MANIFEST)) or target in (FIELD, ENTRY), "ROOM_PINS_CYCLE", target)
    for id_, target in BIN.items():
        check(b"LUOYANG_REGION_27D_V1" in after[target] and id_.encode() in after[target] and b"region27d_target" in after[target], "COMPILED_ROOM_ID_OR_AUTHORED_STAIRS", target)
    for p, digest in media.items():
        for id_, target in BIN.items():
            if id_ == UPPER or "upper_shell.png" not in p:
                check(res(p).encode() in after[target] and digest.encode() in after[target], "BIN_MISSING_AUTHORIZED_MEDIA_PIN", target, p)
    check(f'scene_id = &"{UPPER}"'.encode() in after[SCENE] and b"design_size = Vector2i(1536, 1024)" in after[SCENE], "UPPER_SCENE_ID_OR_SIZE")
    check(b"func seal_room(" in after[HELPER] or b"func seal_upper(" in after[HELPER], "UPPER_ROOM_SEAL_API")
    replay_exact(old[ENTRY], after[ENTRY], room[ENTRY], 4)
    replay_exact(old[FIELD], after[FIELD], room[FIELD], 2)
    # Other canonical Region/terminal geometry is not republished or rewritten.
    author = json.loads(read(rel(old_region["author"]["path"])))
    for binding in list(old_region["compiled_bindings"].values()) + list(author["terminal_bindings"].values()):
        payload = read(rel(binding["path"]))
        check(sha(payload) == binding["sha256"] and len(payload) == int(binding["bytes"]), "FROZEN_BIN_DRIFT", binding["path"])
        check(not any(hashes[p].encode() in payload for p in (FIELD, ENTRY, MANIFEST)), "OTHER_BIN_REQUIRES_SHARED_REBIND", binding["path"])
    new_binding = {id_: {"bytes": len(after[target]), "path": res(target), "sha256": sha(after[target])} for id_, target in BIN.items()}
    after[MANIFEST] = add(row(old[MANIFEST], LOWER, new_binding[LOWER], 4), "compiled_bindings", {UPPER: new_binding[UPPER]})
    model = copy.deepcopy(old_region)
    model["compiled_bindings"].update(new_binding)
    for p in (FIELD, ENTRY):
        check(model["runtime_modules"][res(p)] == hashes[p], "REGION_MODULE_PREIMAGE", p)
        after[MANIFEST] = once(after[MANIFEST], f"{json.dumps(res(p))}: {json.dumps(hashes[p])}", f"{json.dumps(res(p))}: {json.dumps(sha(after[p]))}")
        model["runtime_modules"][res(p)] = sha(after[p])
    module_additions = {res(p): sha(after[p]) for p in (HELPER, SCENE)}
    model["runtime_modules"].update(module_additions)
    after[MANIFEST] = add(after[MANIFEST], "runtime_modules", module_additions)
    check(json.loads(after[MANIFEST]) == model, "REGION_EXACT_TWO_BIN_TWO_REPIN_TWO_NEW_MODULES")
    after[GROUND] = once(old[GROUND], f'const FIELD_SHA := "{hashes[FIELD]}"', f'const FIELD_SHA := "{sha(after[FIELD])}"')
    after[QUALITY_CODE] = old[QUALITY_CODE]
    for name, target in (("FIELD_SHA", FIELD), ("REGION_MANIFEST_SHA", MANIFEST)):
        after[QUALITY_CODE] = once(after[QUALITY_CODE], f'const {name} := "{hashes[target]}"', f'const {name} := "{sha(after[target])}"')
    old_bin = old_region["compiled_bindings"][LOWER]
    after[QUALITY_CODE] = once(after[QUALITY_CODE], f'"{LOWER}": "{old_bin["sha256"]}"', f'"{LOWER}": "{new_binding[LOWER]["sha256"]}"')
    quality_model = json.loads(old[QUALITY_PINS])
    check(quality_model["region_bindings"][LOWER] == old_bin, "QUALITY_LOWER_PREIMAGE")
    check(quality_model["source_pins"].pop(old_bin["path"]) == old_bin["sha256"], "QUALITY_LOWER_PIN_PREIMAGE")
    quality_model["region_bindings"][LOWER] = new_binding[LOWER]
    quality_model["source_pins"][new_binding[LOWER]["path"]] = new_binding[LOWER]["sha256"]
    for p in (FIELD, MANIFEST, GROUND, QUALITY_CODE):
        check(quality_model["source_pins"][res(p)] == hashes[p], "QUALITY_EXPECTED_PIN", p)
        quality_model["source_pins"][res(p)] = sha(after[p])
    check(len(quality_model["region_bindings"]) == 4, "UPPER_DOES_NOT_ENABLE_31B_OVERLAY")
    after[QUALITY_PINS] = encoded(quality_model)
    old_line = f'const REGION27D_AUTHOR_SHA := "{hashes[MANIFEST]}"'
    new_line = f'const REGION27D_AUTHOR_SHA := "{sha(after[MANIFEST])}"'
    after[ROUTER] = once(old[ROUTER], old_line, new_line)
    after[rel(SNAP)] = after[ROUTER]
    check(SNAP.startswith("res://build/luoyang_") and b'not next_path.begins_with("res://build/luoyang_")' in read(AUTH), "EX_STRICT_PREFIX")
    check(once(after[ROUTER], new_line, old_line) == read(rel(prior)), "EX_FULL_BYTE_INVERSE")
    router = res(ROUTER)
    ex_model = json.loads(old[EX])
    auth = ex_model["owned"][router]
    check(auth["current_sha256"] == ex_model["source_sha256"][prior] == hashes[ROUTER], "EX_PARENT_SHA")
    check(all(e["new_snapshot"] != SNAP and e["new_sha256"] != sha(after[ROUTER]) for e in auth["edges"]), "EX_SUCCESSOR_UNIQUE")
    auth["current_sha256"] = sha(after[ROUTER])
    auth["edges"].append({"path": router, "old_sha256": hashes[ROUTER], "new_sha256": sha(after[ROUTER]), "old_snapshot": prior, "new_snapshot": SNAP, "whole_inverse": True, "replacements": [{"old": old_line, "new": new_line}]})
    known = {res(p): (hashes[p], sha(data)) for p, data in after.items() if p in hashes}
    after[EX] = add(mapped(row(old[EX], router, auth, 4), known), "source_sha256", {SNAP: sha(after[ROUTER])})
    check(json.loads(after[EX])["owned"] == ex_model["owned"], "EX_OTHER_OWNED_FROZEN")
    after[EX_INDEX] = once(old[EX_INDEX], hashes[EX], sha(after[EX]))
    for p in (EX, EX_INDEX):
        known[res(p)] = hashes[p], sha(after[p])
    pending = [entry["target"] for entry in parent["targets"] if entry["target"] not in after]
    appended = [EX]
    while pending:
        ready = [p for p in pending if not any(q != p and hashes[q].encode() in old[p] for q in pending)]
        check(ready, "SOURCE_PIN_CYCLE", pending)
        for p in ready:
            data = old[p]
            if p.endswith(".json"):
                data = mapped(data, known)
                model = json.loads(data)
                for key in ("source_sha256", "legacy_source_sha256"):
                    if prior in model.get(key, {}):
                        data = add(data, key, {SNAP: sha(after[ROUTER])})
                        model[key][SNAP] = sha(after[ROUTER])
                        appended.append(p)
                check(json.loads(data) == model, "ONLY_NEW_IMMUTABLE_ROUTER_HISTORY", p)
            else:
                for before_hash, after_hash in known.values():
                    if before_hash.encode() in data:
                        data = once(data, before_hash, after_hash)
            check(data != old[p], "ACTIVE_SOURCE_MAP_NOT_REBOUND", p)
            after[p] = data
            known[res(p)] = hashes[p], sha(data)
            pending.remove(p)
    check(len(appended) == len(set(appended)) and set(appended) == set(parent["snapshot_appended_to"]), "EXACT_PREDECESSOR_PIN_FAMILY", appended)
    expected = gate_pins(json.loads(after[GATE])) | {p: sha(after[rel(p)]) if rel(p) in after else gate0[p] for p in dynamic}
    predicted = {p: sha(after[rel(p)]) if rel(p) in after else h for p, h in gate0.items()} | {SNAP: sha(after[ROUTER])}
    check(expected == predicted and len(expected) == 1759, "GATE_EXPECTED_SOURCE_DIFF", sorted(set(expected) ^ set(predicted)))
    audit_hashes(expected, after)
    check(set(after) == set(old) | {HELPER, SCENE, *BIN.values(), rel(SNAP)}, "EXACT_29_EXISTING_5_NEW_TARGETS")
    for p, raw in old.items():
        check(read(p) == raw, "LATE_SOURCE_DRIFT", p)
    return {
        "old": old,
        "after": after,
        "manifest_sha256": sha(after[MANIFEST]),
        "bindings": new_binding,
        "gate": {"baseline_pid": 60764, "baseline_count": 1758, "predicted_count": len(expected), "new_only": SNAP, "needs_live_admission": True},
    }


def main(args):
    if args == ["--baseline"]:
        print(json.dumps(build(None)))
        return
    check(len(args) == 3 and re.fullmatch(r"[0-9a-f]{64}", args[1]) and (args[2] == "--dry-run" or re.fullmatch(r"yihong_floors_REVIEW\d+", args[2])), "USAGE: ROOM_STAGE_JSON STAGE_SHA256 --dry-run|yihong_floors_REVIEW01")
    room_raw = path(args[0], "game/build").read_bytes()
    check(sha(room_raw) == args[1], "ROOM_STAGE_RECEIPT_DRIFT")
    media_file = path(args[0], "game/build").with_name("media_pins.json").relative_to(ROOT).as_posix()
    media = media_sources(media_file)
    result = build(json.loads(room_raw), media)
    result["media_pin_file"] = media_file
    result["media_pin_file_sha256"] = sha(read(media_file))
    old, after = result.pop("old"), result.pop("after")
    result["status"] = "DRY_RUN_NO_WRITES"
    result["target_count"] = len(after)
    if args[2] != "--dry-run":
        out = BASE / args[2]
        out.mkdir(exist_ok=False)
        result["status"] = "STAGED_29_EXISTING_5_NEW_NO_RUNTIME_WRITES"
        (out / ".gdignore").touch()
        result["targets"] = []
        for p, data in after.items():
            candidate = out / p.replace("/", "__")
            candidate.write_bytes(data)
            result["targets"].append({
                "target": p,
                "candidate": candidate.relative_to(ROOT).as_posix(),
                "before_sha256": sha(old[p]) if p in old else None,
                "after_sha256": sha(data),
                "before_b64": base64.b64encode(old[p]).decode() if p in old else None,
            })
        result["room_receipt"] = args[0]
        result["room_receipt_sha256"] = args[1]
        receipt = encoded(result)
        (out / "receipt.json").write_bytes(receipt)
        print(json.dumps({"status": result["status"], "manifest_sha256": result["manifest_sha256"], "gate": result["gate"], "receipt_sha256": sha(receipt)}))
    else:
        print(json.dumps(result))


if __name__ == "__main__":
    main(sys.argv[1:])
