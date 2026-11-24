"""Read-only exact typed comparison of immutable AO declaration and actual r3."""
import json
from prepare_handoff10 import resource, sha

ao_path = "res://build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/ao_manifest.json"
raw = resource(ao_path).read_bytes()
assert sha(raw) == "c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e"
ao = json.loads(raw)
parent = ao["parent_publication"]
r3raw = resource(parent["path"]).read_bytes()
assert sha(r3raw) == parent["sha256"] == "2366dcb6461de06ef1be98f489171fb5cdf93140a3535530bbe7eedd08b159bc"
embedded, actual = parent["complete_immutable_manifest"], json.loads(r3raw)
diff = []

def walk(a, b, p=()):
    if type(a) is not type(b):
        diff.append({"pointer": list(p), "kind": "TYPE", "embedded_type": type(a).__name__, "actual_type": type(b).__name__, "embedded": a, "actual": b})
    elif isinstance(a, dict):
        for key in sorted(a.keys() | b.keys()):
            if key not in a or key not in b:
                diff.append({"pointer": list(p + (key,)), "kind": "KEY_PRESENCE", "embedded_has": key in a, "actual_has": key in b})
            else:
                walk(a[key], b[key], p + (key,))
    elif isinstance(a, list):
        if len(a) != len(b):
            diff.append({"pointer": list(p), "kind": "LENGTH", "embedded": len(a), "actual": len(b)})
        for i, (x, y) in enumerate(zip(a, b)):
            walk(x, y, p + (i,))
    elif a != b:
        diff.append({"pointer": list(p), "kind": "VALUE", "embedded": a, "actual": b})

walk(embedded, actual)
print(json.dumps({"scope": "READONLY_FROZEN_AO_EMBEDDED_PARENT_VS_PINNED_ACTUAL_R3_NOT_RELAXATION", "embedded_native_json_equality": embedded == actual, "strict_typed_difference_count": len(diff), "differences": diff}, ensure_ascii=False))
