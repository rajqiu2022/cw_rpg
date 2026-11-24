"""Stage exact two-floor consumers; never write canonical targets."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
HOME = Path(__file__).resolve().parent
RUN = "game/build/yihongyuan_floors_20261107_runtime01/"
RES = "res://build/yihongyuan_floors_20261107_runtime01/"
BASE = "game/build/luoyang_regions_20261027d_source01/"
FIELD = BASE + "region_field.gd"
ENTRY = BASE + "region_entry.gd"
BEFORE = {
    FIELD: "fadacfa277fe19fab06f8e1d21583394b1dd98c6ed1b632dac709e5f4bf2eec2",
    ENTRY: "af4a33cd8a86ad6a964b5c1c8fb8b39a6982296e48710d9ebeea1ab04d06b8bf",
}
LOWER, UPPER = "yihongyuan27n_interior", "yihongyuan27n_upper"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def rel(path):
    return path.resolve().relative_to(ROOT).as_posix()


def new(path, data):
    with path.open("xb") as f:
        f.write(data)


def exact(path, patches, output):
    before = (ROOT / path).read_bytes()
    if sha(before) != BEFORE[path]:
        raise RuntimeError(f"canonical predecessor changed: {path}")
    data = before
    spans = []
    for old, replacement in patches:
        old, replacement = old.encode(), replacement.encode()
        if data.count(old) != 1:
            raise RuntimeError(f"not a unique patch: {path}: {old!r}")
        pos = data.index(old)
        data = data[:pos] + replacement + data[pos+len(old):]
        spans.append((pos, old, replacement))
    inverse = data
    for pos, old, replacement in reversed(spans):
        if inverse[pos:pos+len(replacement)] != replacement:
            raise RuntimeError("reverse span collision")
        inverse = inverse[:pos] + old + inverse[pos+len(replacement):]
    if inverse != before:
        raise RuntimeError("whole inverse mismatch")
    candidate = output / (Path(path).name + ".txt")
    new(candidate, data)
    return {"candidate": rel(candidate), "before_sha256": sha(before), "sha256": sha(data), "whole_inverse": True,
            "hunks": [{"offset": pos, "old": old.decode(), "new": replacement.decode()} for pos, old, replacement in spans]}


def fresh(path, candidate):
    if (ROOT / path).exists():
        raise RuntimeError(f"new target unexpectedly exists: {path}")
    return {"candidate": rel(candidate), "before_sha256": None, "sha256": sha(candidate.read_bytes())}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--compile-result", help="Relative project path to Root-owned compile result; omit for source-only staging.")
    parser.add_argument("--stage", required=True)
    a = parser.parse_args()
    if not a.stage.replace("_", "").isalnum():
        raise RuntimeError("invalid stage name")
    output = HOME / a.stage
    output.mkdir(exist_ok=False)
    helper_old = 'const YIHONG_ROOM_RUNTIME := "res://build/interior_identity_20261107_runtime01/room_runtime.gd"\n'
    helper = helper_old + f'const YIHONG_FLOOR_RUNTIME := "{RES}upper_room.gd"\n'
    field_marker = '\tif _region.get("navigation_kind") != "AUTHORED_INTERIOR": return true\n'
    field_next = field_marker + '\tif _region.get("id") == "yihongyuan27n_upper":\n\t\tvar second_floor := load(YIHONG_FLOOR_RUNTIME) as GDScript\n\t\treturn second_floor != null and second_floor.call("seal_upper", self, _region_owner, _current_scene, _region) == true\n'
    alias_old = f'const ALIASES := {{"{LOWER}": "{LOWER}", '
    alias_new = alias_old + f'"{UPPER}": "{UPPER}", '
    scene_old = f'const SCENE_RESOURCES := {{"{LOWER}": "res://data/scenes/{LOWER}.tres", '
    scene_new = scene_old + f'"{UPPER}": "{RES}{UPPER}.tres", '
    entry_old = "\tvar entry: Dictionary = Alias.arrive(compiled, String(id), point, version, extension)\n"
    entry_new = entry_old + '\tif entry.get("ok") != true and id == &"yihongyuan27n_interior" and compiled.get("yihong_floor_profile","") == "YIHONG_LOWER_20261107_V1":\n\t\tvar floors := load(YIHONG_FLOOR_RUNTIME) as GDScript\n\t\tif floors == null or not loaded.sources.has(YIHONG_FLOOR_RUNTIME):\n\t\t\treturn {"matched": true, "ok": false, "error": "YIHONG_LOWER_STAIR_SOURCE"}\n\t\tentry = floors.call("recover_lower_stair", compiled, String(id), point, version, extension, entry)\n'
    rows = {
        FIELD: exact(FIELD, [(helper_old, helper), (field_marker, field_next)], output),
        ENTRY: exact(ENTRY, [(helper_old, helper), (alias_old, alias_new), (scene_old, scene_new), (entry_old, entry_new)], output),
    }
    for name in ("upper_room.gd", f"{UPPER}.tres"):
        leaf = output/(name+".txt")
        new(leaf, (HOME/(name+".txt")).read_bytes())
        rows[RUN+name] = fresh(RUN+name, leaf)
    if a.compile_result:
        result_path = (ROOT / a.compile_result).resolve()
        if not result_path.is_relative_to(HOME / "compile_actual"):
            raise RuntimeError("compile output outside exact evidence folder")
        report = json.loads(result_path.read_bytes())
        if report["failures"] or set(report["rooms"]) != {LOWER, UPPER}:
            raise RuntimeError("compile report not a two-room pass")
        for room, record in report["rooms"].items():
            path = ROOT / ("game/" + record["candidate"].removeprefix("res://"))
            if path.parent != result_path.parent or len(path.read_bytes()) != record["bytes"]:
                raise RuntimeError("wrong evidence generation/length")
            row = fresh(RUN+room+".bin", path)
            if row["sha256"] != record["sha256"]:
                raise RuntimeError("wrong room hash")
            rows[RUN+room+".bin"] = row
        media = {}
        for res, digest in report["media_pins"].items():
            path = "game/"+res.removeprefix("res://")
            if sha((ROOT/path).read_bytes()) != digest:
                raise RuntimeError("media live drift: "+path)
            media[path] = digest
        if len(media) != 9:
            raise RuntimeError("expected exactly three image+import+ctex triples")
        new(output/"media_pins.json",(json.dumps(media,indent=2)+"\n").encode())
    receipt = output / "stage_core.json"
    new(receipt, (json.dumps(rows, ensure_ascii=False, indent=2)+"\n").encode())
    print(f"{rel(receipt)} {sha(receipt.read_bytes())} leaves={len(rows)}")


if __name__ == "__main__":
    main()
