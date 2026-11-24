"""NEW candidate-only retry: source_delta67 is not merged Temple189."""
from pathlib import Path
import hashlib

original = Path(__file__).with_name("review_actual07_and_culture40_readonly.py")
assert hashlib.sha256(original.read_bytes()).hexdigest() == "aa8d44391c420aa9560d450e9cfc315bb613cd671d69b83b8ece2f45292c12fc"
text = original.read_text(encoding="utf-8")
prefix = text[:text.index("# Actual:")]
body = text[text.index("# Candidate40:"):]
old = 'check(len(oldbind["source_delta"])==len(newbind["source_delta"])==189,"binding189 total;187 untouched")'
new = '''check(len(oldbind["source_delta"])==len(newbind["source_delta"])==67,"binding delta67 remains67")
check(oldbind["parent_binding_path"]==newbind["parent_binding_path"] and oldbind["parent_binding_sha256"]==newbind["parent_binding_sha256"],"same immutable Temple parent")
check(sha(oldbind["parent_binding_path"])==oldbind["parent_binding_sha256"],"immutable Temple parent hash")
basebinding=load(oldbind["parent_binding_path"])
oldmerged={**basebinding["source_sha256"],**oldbind["source_delta"]}
newmerged={**basebinding["source_sha256"],**newbind["source_delta"]}
check(len(oldmerged)==len(newmerged)==189,"real parent+delta merged189")
check({k for k in oldmerged if oldmerged[k]!=newmerged[k]}=={CO,CON},"merged189 exactly2changed187same")'''
assert body.count(old) == 1
body = body.replace(old, new, 1)
constants = '''
C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
CO = "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
CON = "res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
TE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
contract = load(CON)
'''
exec(compile(prefix + constants + body, str(__file__) + "::candidate_only_retry", "exec"))
