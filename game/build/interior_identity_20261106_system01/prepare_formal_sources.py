"""Mechanical staging only. Never writes a production target."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
STAGE = HERE / "formal_stage01"
FIELD = "game/build/luoyang_regions_20261027d_source01/region_field.gd"
ENTRY = "game/build/luoyang_regions_20261027d_source01/region_entry.gd"
SEATED = "game/build/luoyang_quality_20261101b_seated01/live_seated_view.gd"
QUALITY = "game/build/luoyang_quality_20261101b_runtime01/scene_art_quality_runtime.gd"
QUALITY_PINS = "game/build/luoyang_quality_20261101b_runtime01/source_pins_READY.json"
REGION = "game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
NEW = "game/build/interior_identity_20261107_runtime01/"
OLD_BIN = "res://build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/yihongyuan27n_interior.bin"
ROOM = "yihongyuan27n_interior"
PINNED = {
    FIELD: "fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5",
    SEATED: "2102ac7cceae72b6de97a183c8a9cc97faa5ae01366d789911b51f1c0a411bb1",
    QUALITY: "8418d1dfc066be790cdf75fbdc50001a264a8f8cac9dd29f9481d2ad5d9abf69",
    REGION: "91533bb8714a613eb6534657e71a650f6d519b1fa73dd1d33ff9907dc28ddec5",
}


def digest(value):
    return hashlib.sha256(value).hexdigest()


def res(path):
    return "res://" + path.removeprefix("game/")


def put_new(path, data):
    if path.exists():
        if path.read_bytes() != data:
            raise RuntimeError(f"staged artifact drift: {path}")
        return
    path.write_bytes(data)


def read_before(path):
    raw = (ROOT / path).read_bytes()
    if path in PINNED and digest(raw) != PINNED[path]:
        raise RuntimeError(f"exact preimage drift: {path}")
    return raw


def replace_exact(raw, old, new):
    options = []
    for newline in ("\n", "\r\n"):
        source = old.replace("\n", newline).encode()
        target = new.replace("\n", newline).encode()
        if raw.count(source) == 1 and (source, target) not in options:
            options.append((source, target))
    if len(options) != 1:
        raise RuntimeError(f"nonunique source hunk: {old[:120]!r}")
    source, target = options[0]
    off = raw.index(source)
    return raw[:off] + target + raw[off+len(source):], {"offset":off,"old":source.decode(),"new":target.decode()}


def staged_file(path, replacements, index):
    raw = read_before(path)
    after, hunks = raw, []
    for old, new in replacements:
        after, hunk = replace_exact(after, old, new)
        hunks.append(hunk)
    inverse = after
    for hunk in reversed(hunks):
        off = hunk["offset"]
        old, new = hunk["old"].encode(), hunk["new"].encode()
        if inverse[off:off+len(new)] != new:
            raise RuntimeError(f"inverse offset mismatch: {path}")
        inverse = inverse[:off]+old+inverse[off+len(new):]
    if inverse != raw:
        raise RuntimeError(f"not whole-file reversible: {path}")
    output = STAGE / (path.removeprefix("game/").replace("/","__") + ".txt")
    put_new(output,after)
    index[path] = {"candidate":output.relative_to(ROOT).as_posix(),"before_sha256":digest(raw),"sha256":digest(after),"hunks":hunks,"whole_inverse":True}


def core_stage(index):
    staged_file(FIELD, [
        (
            'const YihongDaily = preload("res://build/luoyang_yihongyuan_20261029n_system01/ambient_conversation.gd")\n',
            'const YihongDaily = preload("res://build/luoyang_yihongyuan_20261029n_system01/ambient_conversation.gd")\n'
            'const YIHONG_ROOM_RUNTIME := "res://build/interior_identity_20261107_runtime01/room_runtime.gd"\n'
            'const YIHONG_NATIVE_SCENE := "res://build/interior_identity_20261107_runtime01/native_actor.tscn"\n',
        ),
        (
            '\tif _region.get("id") == "yihongyuan27n_interior": return YihongLayers.complete_room_enclosure(self, _region_owner, _region)\n',
            '\tif _region.get("id") == "yihongyuan27n_interior":\n'
            '\t\tif _region.has("interior_identity_20261107"):\n'
            '\t\t\tvar authored_room := load(YIHONG_ROOM_RUNTIME) as GDScript\n'
            '\t\t\treturn authored_room != null and authored_room.call("seal_room", self, _region_owner, _current_scene, _region) == true\n'
            '\t\treturn YihongLayers.complete_room_enclosure(self, _region_owner, _region)\n',
        ),
        (
            '\tvar npc: NPCNode = NPC_SCENE.instantiate() as NPCNode\n',
            '\tvar npc_scene: PackedScene = NPC_SCENE\n'
            '\tvar native_plan: Dictionary = {}\n'
            '\tif _region.get("id") == "yihongyuan27n_interior" and _region.has("interior_identity_20261107"):\n'
            '\t\tvar authored_room := load(YIHONG_ROOM_RUNTIME) as GDScript\n'
            '\t\tif authored_room == null: return false\n'
            '\t\tnative_plan = authored_room.call("actor_plan", source, data, _region_owner.receipt().source_first)\n'
            '\t\tif native_plan.get("ok") != true: return false\n'
            '\t\tif native_plan.get("native") == true: npc_scene = load(YIHONG_NATIVE_SCENE) as PackedScene\n'
            '\tif npc_scene == null: return false\n'
            '\tvar npc: NPCNode = npc_scene.instantiate() as NPCNode\n',
        ),
        (
            '\t_actor_layer.add_child(npc); _npc_nodes.append(npc)\n',
            '\tif native_plan.get("native") == true and (not npc.has_method("set_native_plan") or npc.call("set_native_plan", native_plan) != true):\n'
            '\t\tnpc.free(); return false\n'
            '\t_actor_layer.add_child(npc)\n'
            '\tif native_plan.get("native") == true and (not npc.has_method("native_grid_ready") or npc.call("native_grid_ready") != true):\n'
            '\t\tnpc.free(); return false\n'
            '\t_npc_nodes.append(npc)\n',
        ),
    ], index)
    staged_file(ENTRY, [
        (
            'const Phase = preload("res://build/luoyang_regions_20261027d_source01/region_phase_scope.gd")\n',
            'const Phase = preload("res://build/luoyang_regions_20261027d_source01/region_phase_scope.gd")\n'
            'const YIHONG_ROOM_RUNTIME := "res://build/interior_identity_20261107_runtime01/room_runtime.gd"\n',
        ),
        (
            '\t\tentry = Courts31dRestore.arrive(compiled, String(id), extension, entry)\n',
            '\t\tentry = Courts31dRestore.arrive(compiled, String(id), extension, entry)\n'
            '\tif id == &"yihongyuan27n_interior" and compiled.has("interior_identity_20261107"):\n'
            '\t\tvar authored_room := load(YIHONG_ROOM_RUNTIME) as GDScript\n'
            '\t\tif authored_room == null or not loaded.sources.has(YIHONG_ROOM_RUNTIME):\n'
            '\t\t\treturn {"matched": true, "ok": false, "error": "YIHONG_RESTORE_HELPER_SOURCE"}\n'
            '\t\tentry = authored_room.call("recover_predecessor", compiled, String(id), point, version, extension, entry)\n',
        ),
    ], index)
    staged_file(SEATED, [
        (
            'const HOME := "res://build/luoyang_quality_20261101b_seated01/"\n',
            'const HOME := "res://build/luoyang_quality_20261101b_seated01/"\n'
            'const YIHONG_NATIVE_SCRIPT := "res://build/interior_identity_20261107_runtime01/native_actor.gd"\n'
            'const YIHONG_NATIVE_IDS := ["yihongyuan27n_musician", "yihongyuan27n_singer", "yihongyuan27n_tea_attendant", "yihongyuan27n_receptionist"]\n',
        ),
        (
            '\tif not region is Dictionary or region.get("id") != ROOM or not region.get("npcs") is Array or region.npcs.size() != 6:\n'
            '\t\treturn _fail("SEATED_EXACT_ROOM_SIX_ROWS")\n',
            '\tif not region is Dictionary or region.get("id") != ROOM or not region.get("npcs") is Array:\n'
            '\t\treturn _fail("SEATED_EXACT_ROOM")\n'
            '\tvar upgraded: bool = region.get("interior_identity_20261107","") == "YIHONG_NATIVE_ROOM_20261107_V1"\n'
            '\tvar expected_count := 10 if upgraded else 6\n'
            '\tif region.npcs.size() != expected_count: return _fail("SEATED_EXACT_ROOM_ROWS")\n',
        ),
        (
            '\tif not actors is Dictionary or actors.size() != 6 or not live_npcs is Array or live_npcs.size() != 6:\n'
            '\t\treturn _fail("SEATED_EXACT_SIX_LIVE_ACTORS")\n',
            '\tif not actors is Dictionary or actors.size() != expected_count or not live_npcs is Array or live_npcs.size() != expected_count:\n'
            '\t\treturn _fail("SEATED_EXACT_LIVE_ACTORS")\n'
            '\tvar new_seen: Dictionary = {}\n',
        ),
        (
            '\t\tif id not in IDS or by_id.has(id) or row.get("logical_id") != LOGICAL or row.get("slot_key") != key:\n'
            '\t\t\treturn _fail("SEATED_SOURCE_IDS_OR_SLOTS")\n',
            '\t\tif row.get("logical_id") != LOGICAL or row.get("slot_key") != key:\n'
            '\t\t\treturn _fail("SEATED_SOURCE_IDS_OR_SLOTS")\n'
            '\t\tif id not in IDS:\n'
            '\t\t\tvar native: NPCNode = actors.get(key, {}).get("node") as NPCNode\n'
            '\t\t\tif not upgraded or id not in YIHONG_NATIVE_IDS or new_seen.has(id) or not is_instance_valid(native) or native not in live_npcs or native.npc_id != id or native.get_script() == null or native.get_script().resource_path != YIHONG_NATIVE_SCRIPT or native.call("native_grid_ready") != true:\n'
            '\t\t\t\treturn _fail("SEATED_UNDECLARED_NEW_ACTOR:" + id)\n'
            '\t\t\tnew_seen[id] = true\n'
            '\t\t\tcontinue\n'
            '\t\tif by_id.has(id): return _fail("SEATED_DUPLICATE_ORIGINAL_ID")\n',
        ),
        (
            '\t# No source dictionaries, room.sources or the four speaking adults are edited.\n',
            '\tif by_id.size() != 6 or new_seen.size() != expected_count - 6: return _fail("SEATED_EXACT_ROSTER_PARTITIONS")\n'
            '\t# No source dictionaries, room.sources or the four speaking adults are edited.\n',
        ),
    ], index)
    for leaf in ("room_runtime.gd", "native_actor.gd", "native_actor.tscn"):
        candidate = STAGE / (leaf + ".txt")
        live = NEW + leaf
        if (ROOT / live).exists():
            raise RuntimeError(f"expected new live path not absent: {live}")
        index[live] = {"candidate":candidate.relative_to(ROOT).as_posix(),"before_sha256":None,"sha256":digest(candidate.read_bytes()),"new_leaf":True}


def quality_stage(index, region_manifest, room_path):
    manifest = json.loads(region_manifest.read_bytes())
    region_binding = manifest["compiled_bindings"][ROOM]
    if region_binding["path"] != res(NEW + "yihongyuan27n_interior.bin") or region_binding["sha256"] != digest(room_path.read_bytes()) or int(region_binding["bytes"]) != room_path.stat().st_size:
        raise RuntimeError("successor manifest is not bound to exact requested candidate bin")
    old_manifest = json.loads(read_before(REGION))
    if any(manifest["compiled_bindings"][id] != val for id,val in old_manifest["compiled_bindings"].items() if id != ROOM):
        raise RuntimeError("unrelated Region binding changed")
    manifest_sha = digest(region_manifest.read_bytes())
    target_room = NEW + "yihongyuan27n_interior.bin"
    if (ROOT / target_room).exists():
        raise RuntimeError("expected new room target not absent")
    index[target_room] = {
        "candidate":room_path.resolve().relative_to(ROOT).as_posix(),
        "before_sha256":None,
        "sha256":region_binding["sha256"],
        "new_leaf":True,
    }
    staged_file(QUALITY, [
        (PINNED[FIELD],index[FIELD]["sha256"]),
        (PINNED[REGION],manifest_sha),
        (old_manifest["compiled_bindings"][ROOM]["sha256"],region_binding["sha256"]),
        ('\t\tif _decor_enabled:\n','\t\tif _decor_enabled and region.get("interior_identity_20261107","") != "YIHONG_NATIVE_ROOM_20261107_V1":\n'),
    ], index)
    old = read_before(QUALITY_PINS)
    value = json.loads(old)
    next_value = json.loads(old)
    next_value["region_bindings"][ROOM] = region_binding
    pins = next_value["source_pins"]
    for target, expected in [(FIELD,index[FIELD]["sha256"]),(REGION,manifest_sha),(SEATED,index[SEATED]["sha256"]),(QUALITY,index[QUALITY]["sha256"])]:
        pins[res(target)] = expected
    pins.pop(OLD_BIN)
    pins[region_binding["path"]] = region_binding["sha256"]
    output = STAGE / "source_pins_READY.json.txt"
    put_new(output,(json.dumps(next_value,ensure_ascii=False,indent=2)+"\n").encode())
    reverse = json.loads(output.read_bytes())
    reverse["region_bindings"][ROOM] = value["region_bindings"][ROOM]
    reverse["source_pins"].pop(region_binding["path"])
    reverse["source_pins"][OLD_BIN] = value["source_pins"][OLD_BIN]
    for target in [FIELD,REGION,SEATED,QUALITY]:
        reverse["source_pins"][res(target)] = value["source_pins"][res(target)]
    if reverse != value:
        raise RuntimeError("quality source JSON reverse difference")
    index[QUALITY_PINS] = {"candidate":output.relative_to(ROOT).as_posix(),"before_sha256":digest(old),"sha256":digest(output.read_bytes()),"whole_json_inverse":True}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--region-manifest",type=Path)
    parser.add_argument("--room-bin",type=Path)
    args = parser.parse_args()
    if bool(args.region_manifest) != bool(args.room_bin): parser.error("both successor leaves required")
    index = {}
    core_stage(index)
    if args.region_manifest:
        quality_stage(index,args.region_manifest,args.room_bin)
        suffix = "full"
    else:
        suffix = "core"
    receipt = STAGE / ("stage_" + suffix + ".json")
    put_new(receipt,(json.dumps(index,ensure_ascii=False,indent=2)+"\n").encode())
    print(receipt.relative_to(ROOT).as_posix(),digest(receipt.read_bytes()),len(index))

if __name__ == "__main__":
    main()
