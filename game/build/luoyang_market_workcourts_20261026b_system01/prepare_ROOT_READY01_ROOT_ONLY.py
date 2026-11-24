"""Root-only three-file readiness transport. No engine/import/canonical writes."""
import hashlib, json
from pathlib import Path

BASE = Path(__file__).resolve().parent
GAME = BASE.parents[1]
PREFIX = "res://build/luoyang_market_workcourts_20261026b_system01/"
PINS = {
    "publish_market_workcourts_NOTREADY.gd": "8a9e049972ae43f56d89ac0a9ac39dd5eae27da74fa65b3732a19836a3497a38",
    "input_NOTREADY.json": "881dd25c4af04d8d889f4fcd9eb390de2d7a00e301a2f0e94b675c67687028ab",
}
def digest(data): return hashlib.sha256(data).hexdigest()
def physical(path): return GAME / path.removeprefix("res://")

def main():
    old = {name: (BASE / name).read_bytes() for name in PINS}
    assert all(digest(old[name]) == pin for name, pin in PINS.items())
    value = json.loads(old["input_NOTREADY.json"])
    assert value["ready"] is False
    for path, pin in value["sources"].items():
        assert digest(physical(path).read_bytes()) == pin, path
    dest = BASE / "ROOT_READY01"
    assert not dest.exists(), "ROOT_READY01 must be ABSENT"
    ready = json.loads(old["input_NOTREADY.json"])
    ready["ready"] = True
    ready["output_root"] = PREFIX + "ROOT_READY01/output/"
    new_input = (json.dumps(ready, ensure_ascii=False, indent=2) + "\n").encode()
    restore = json.loads(new_input)
    restore["ready"] = False
    restore["output_root"] = value["output_root"]
    assert (json.dumps(restore, ensure_ascii=False, indent=2) + "\n").encode() == old["input_NOTREADY.json"]
    key = old["publish_market_workcourts_NOTREADY.gd"]
    changes = [
        (b"const READY: bool=false", b"const READY: bool=true"),
        ((PREFIX + "input_NOTREADY.json").encode(), (PREFIX + "ROOT_READY01/input_ROOT_READY.json").encode()),
        (PINS["input_NOTREADY.json"].encode(), digest(new_input).encode()),
    ]
    for before, after in changes:
        assert key.count(before) == 1
        key = key.replace(before, after)
    back = key
    for before, after in reversed(changes):
        assert back.count(after) == 1
        back = back.replace(after, before)
    assert back == old["publish_market_workcourts_NOTREADY.gd"]
    project = (BASE / "project.godot").read_bytes()
    outputs = {"input_ROOT_READY.json": new_input, "publish_ROOT_READY.gd": key, "project.godot": project}
    proof = {"status": "ROOT_READY_TRANSPORT_NOT_ENGINE_RESULT", "whole_input_inverse": True, "whole_key_inverse": True, "changes": [[a.decode(), b.decode()] for a, b in changes], "parent_pins": PINS, "written": {name: {"sha256": digest(data), "bytes": len(data)} for name, data in outputs.items()}}
    dest.mkdir()
    for name, data in outputs.items():
        with (dest / name).open("xb") as stream: stream.write(data)
    with (dest / "readiness_whole_inverse.json").open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(proof, stream, ensure_ascii=False, indent=2); stream.write("\n")
    print(json.dumps(proof, ensure_ascii=False))

if __name__ == "__main__": main()
