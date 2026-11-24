"""Root-only mechanical READY transport; no engine or canonical writes."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
DEST = BASE / "ROOT_READY01"
PINS = {
    "publish_retire_wall_NOTREADY.gd": "f59e6d07b8fe7b706395708f01ca0ae9d575d3ed9c76945ab3b7e96610df3a05",
    "input_NOTREADY.json": "cbdf7864d964e6b2219277c439a20e0aa33b1b96cf3919bdcac3eb6ddf586298",
    "project.godot": "f841ea63d22d3f42cd644891af8d55b5b0d82d1ff66595342e62aa58b48f032a",
}
def sha(data):
    return hashlib.sha256(data).hexdigest()
def replace_once(data, old, new):
    assert data.count(old) == 1, old
    result = data.replace(old, new)
    assert result.count(new) == 1 and result.replace(new, old) == data
    return result
def main():
    originals = {name: (BASE / name).read_bytes() for name in PINS}
    for name, data in originals.items():
        assert sha(data) == PINS[name], name
    assert not DEST.exists(), DEST
    source_input = originals["input_NOTREADY.json"]
    ready_input = replace_once(source_input, b'"ready": false', b'"ready": true')
    ready_input = replace_once(ready_input, b'BUILD_ONLY_ONE_GARDEN_WALL_RETIREMENT', b'ROOT_READY_ONE_GARDEN_WALL_RETIREMENT')
    worker = originals["publish_retire_wall_NOTREADY.gd"]
    worker = replace_once(worker, b'const READY: bool=false', b'const READY: bool=true')
    worker = replace_once(worker, b'/input_NOTREADY.json"', b'/ROOT_READY01/input_ROOT_READY.json"')
    worker = replace_once(worker, b'PENDING_ROOT_INPUT_SHA', sha(ready_input).encode())
    reverse = worker.replace(sha(ready_input).encode(), b'PENDING_ROOT_INPUT_SHA').replace(b'/ROOT_READY01/input_ROOT_READY.json"', b'/input_NOTREADY.json"').replace(b'const READY: bool=true', b'const READY: bool=false')
    assert reverse == originals["publish_retire_wall_NOTREADY.gd"]
    restored = ready_input.replace(b'ROOT_READY_ONE_GARDEN_WALL_RETIREMENT', b'BUILD_ONLY_ONE_GARDEN_WALL_RETIREMENT').replace(b'"ready": true', b'"ready": false')
    assert restored == source_input
    output = {"input_ROOT_READY.json": ready_input, "publish_retire_wall_ROOT_READY.gd": worker, "project.godot": originals["project.godot"]}
    DEST.mkdir()
    for name, data in output.items():
        with (DEST / name).open("xb") as handle:
            handle.write(data)
    proof = {"source_sha256": PINS, "whole_byte_inverse": True, "scope": "Only input ready/status and worker READY/input path/input SHA. Project exact copy; no function/output-root changes.", "written": {name: {"path": str(DEST / name), "sha256": sha(data)} for name, data in output.items()}, "engine_calls": 0, "canonical_writes": 0}
    with (DEST / "transport_whole_inverse_ROOT_READY.json").open("x", encoding="utf-8", newline="\n") as handle:
        json.dump(proof, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print(json.dumps(proof, ensure_ascii=False))
if __name__ == "__main__":
    main()
