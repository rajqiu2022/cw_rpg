"""Independent exact08 inverse/execution-domain review; no engine or staging."""
from pathlib import Path
import copy
import hashlib
import json

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
HERE = GAME / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08"
OUT = QA / "finite_production08_independent_static_review_READY.json"


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def read(record):
    raw = local(record["path"]).read_bytes()
    assert sha(raw) == record["sha256"], record["path"]
    if "bytes" in record: assert len(raw) == record["bytes"]
    return raw


def same(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return a.keys() == b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a) == len(b) and all(same(x,y) for x,y in zip(a,b))
    return a == b


def reverse(raw, hunks):
    for h in reversed(hunks):
        after,before = h["new"].encode(),h["old"].encode()
        assert raw.count(after) == 1, after[:80]
        raw = raw.replace(after,before,1)
    return raw


assert not OUT.exists()
hp = HERE / "handoff_PRODUCTION_PROPOSAL.json"
assert sha(hp.read_bytes()) == "8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c"
h = json.loads(hp.read_bytes())
oldpath = HERE.parent / "finite_adapter_implementation07/handoff_PENDING.json"
assert sha(oldpath.read_bytes()) == "ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32"
oldh = json.loads(oldpath.read_bytes())
assert reverse(read(h["adapter"]),h["adapter_exact_inverse_to07"]) == read(oldh["adapter"])
binding = json.loads(read(h["binding"]))
oldbinding = json.loads(read(oldh["binding"]))
inverse = copy.deepcopy(binding)
assert inverse["source_closure_ready"] is True and oldbinding["source_closure_ready"] is False
inverse["source_closure_ready"] = False
for domain in ("market","yamen"):
    assert inverse["domains"][domain]["runtime_manifest_path"] == "res://" + (HERE / f"runtime_{domain}_manifest_READY.json").relative_to(GAME).as_posix()
    inverse["domains"][domain]["runtime_manifest_path"] = oldbinding["domains"][domain]["runtime_manifest_path"]
assert same(inverse,oldbinding)
consumers = {}
for row in h["consumers"]:
    raw = read(row["candidate"])
    original = local(row["target"]).read_bytes()
    assert sha(original) == row["old_sha256"]
    assert reverse(raw,row["forward_hunks"]) == original
    consumers[row["domain"]] = {"target":row["target"],"sha256":row["candidate"]["sha256"],"exact_byte_inverse":True}
assert consumers["ENV"]["sha256"] == "a751dbd4ce014abd2e808d7c9a947dc0e4a314d4b42930a6392a1d6eb7c20a7d"
assert h["ground_shader"]["sha256"] == "e80916d7fa99218e3dc36ee1a83efd49f544ed426739941499c8500f23da14f1"
read(h["ground_shader"])
read(h["code_scope_authority"])
ground = json.loads(read(h["ground_authority"]))
assert ground["approved_by_root"] is True and ground["candidate_ENV_sha256"] == consumers["ENV"]["sha256"] and ground["candidate_shader_sha256"] == h["ground_shader"]["sha256"]

dep = json.loads(read(h["dependency_proof"]))
for key in ("contract","coordinator","temple_binding","temple"):
    row = dep[key]
    assert reverse(read(row["candidate"]),row["hunks"]) == read(row["parent"]), key
parent = json.loads(read(h["execution_parent"]))
execution = json.loads(read(h["execution_proposal"]))
assert len(parent["owned"]) == 10 and parent["owned"].keys() == execution["owned"].keys()
assert len(parent["source_sha256"]) == 50 and len(execution["source_sha256"]) == 57
assert all(execution["source_sha256"].get(k) == v for k,v in parent["source_sha256"].items())
newpins = {k:v for k,v in execution["source_sha256"].items() if k not in parent["source_sha256"]}
assert same(newpins,h["new_proof_pins"]) and len(newpins) == 7
for path,digest in newpins.items(): assert sha(local(path).read_bytes()) == digest
inverse = copy.deepcopy(execution)
for path in newpins: del inverse["source_sha256"][path]
changed = []
for delta in h["owned_changed_exactly5"]:
    path = delta["target"]
    assert path not in changed
    changed.append(path)
    row = inverse["owned"][path]
    before = parent["owned"][path]
    assert row["current_sha256"] == delta["candidate"]["sha256"] and before["current_sha256"] == delta["old_sha256"]
    assert sum(same(edge,delta["edge"]) for edge in row["edges"]) == 1
    row["edges"] = [edge for edge in row["edges"] if not same(edge,delta["edge"])]
    row["current_sha256"] = before["current_sha256"]
    assert same(row,before)
assert len(changed) == 5
assert all(same(execution["owned"][path],parent["owned"][path]) for path in parent["owned"] if path not in changed)
assert same(inverse,parent)

result = {
    "status":"INDEPENDENT08_STATIC_CODE_AND_EXECUTION_PROPOSAL_REVIEW_NOT_STAGE_OR_RUNTIME_APPROVAL",
    "handoff_sha256":sha(hp.read_bytes()),
    "adapter_byte_inverse_to_reviewed07":True,
    "binding_whole_strict_typed_inverse_to07_except_two_paths_and_ready":True,
    "consumer_whole_byte_inverses":consumers,
    "dependency_proof_sha256":h["dependency_proof"]["sha256"],
    "contract_Coordinator_Temple_binding_and_code_exact_byte_inverses":True,
    "execution_proposal_sha256":h["execution_proposal"]["sha256"],
    "owned_domain_unchanged_count":10,
    "changed_exactly5_append_one_edge_preserve_all_prior_edges":changed,
    "other5_owned_rows_whole_strict_typed_equal":True,
    "old50_proof_keys_values_unchanged":True,
    "new7_proof_keys_exact_and_current_SHA_verified":newpins,
    "final_proof_count":57,
    "execution_whole_strict_typed_inverse_to_A388":True,
    "exact_ground_ENV_and_shader_adopted":True,
    "new_logic_vs07":"Only fixed successor paths/pins and readiness literals; reviewed worker/session/wrapper/Fade behavior retained. ENV is the exact Root-approved A751 implementation, shaderE809.",
    "remaining":"Generated manifests/index/registry/dependent complete source sets and Root execution approval/actual stage, fresh-guard deployment, parse and sole Yamen actual remain separate. Ready code literals alone are not deployment authority.",
    "operations":{"engine":0,"native_decode":0,"PNG_decode":0,"geometry_sampling":0,"collector":0,"canonical_write":0}
}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"review":OUT.name,"sha256":sha(OUT.read_bytes()),"consumer_inverses":len(consumers),"owned":10,"changed":5,"proofs":57,"engine":0}))
