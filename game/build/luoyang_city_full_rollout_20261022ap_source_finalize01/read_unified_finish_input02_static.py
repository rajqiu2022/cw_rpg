"""Read-only old-pointer/reference audit; never imports staging code."""
import json
from prepare_handoff10 import HERE, resource, sha, same, read_pointer

raw = (HERE / "unified_finish_input02_ROOT_LOCKED.json").read_bytes()
assert sha(raw) == "37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba"
p = json.loads(raw)
pins = {r["id"]: r for r in p["pinned_inputs"]}
ids = {r["id"] for r in p["nodes"]}
refs = []
def scan(x):
    if isinstance(x, dict):
        refs.extend((k, v) for k, v in x.items() if k in ["$sha", "$pin"])
        for v in x.values():
            scan(v)
    elif isinstance(x, list):
        for v in x:
            scan(v)
scan(p)
assert all(v in (ids if k == "$sha" else pins) for k, v in refs)
n = 0
for row in p["nodes"]:
    if row["kind"] == "index":
        continue
    basepin = pins[row["base_input"]]
    basebytes = resource(basepin["path"]).read_bytes()
    assert sha(basebytes) == basepin["sha256"]
    b = json.loads(basebytes)
    ptrs = set()
    for op in row.get("operations", []):
        keys = op["pointer"]
        h = read_pointer(b, keys[:-1])
        assert tuple(keys) not in ptrs, (row["id"], keys)
        ptrs.add(tuple(keys))
        assert (keys[-1] in h) == op["existed"]
        assert not op["existed"] or same(h[keys[-1]], op["old"]), (row["id"], keys)
        n += 1
print({"static_old_pointer_checks": n, "all_refs_exist": len(refs), "target_count": len(p["root_target_allowlist"]), "no_stage": True})
