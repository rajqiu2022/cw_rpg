"""Additional immutable AO ancestor proof for unchanged two-key candidate."""
from pathlib import Path
import json
import hashlib
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
ancestor=GAME/"build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/ao_manifest.json"
candidate=HERE/"market_two_declared_metadata_successor_READY.json"
assert sha(ancestor)=="c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e"
assert sha(candidate)=="08e3456d654cfa19442c91540d730a10fec4db1159ed5e1a8250d95e062a38be"
def extract(p):
    s=p.read_bytes().decode("utf-8");needle='"parent_publication": '
    assert s.count(needle)==1
    start=s.index(needle)+len(needle)
    obj,end=json.JSONDecoder().raw_decode(s,start)
    return obj,s[start:end].encode("utf-8")
a,ab=extract(ancestor);c,cb=extract(candidate)
assert a==c and ab==cb
result={"status":"IMMUTABLE_AO_ANCESTOR_PARENT_SUBTREE_BYTE_AND_TYPED_EXACT",
 "ancestor":{"path":ref(ancestor),"sha256":sha(ancestor),"pointer":"/parent_publication"},
 "candidate":{"path":ref(candidate),"sha256":sha(candidate),"pointer":"/parent_publication"},
 "subtree_bytes_sha256":hashlib.sha256(ab).hexdigest(),"subtree_bytes":len(ab),
 "whole_subtree_bytes_exact":True,"whole_subtree_typed_exact":True,
 "not_observed_collector_or_current_AO_authority":True,"no_candidate_or_canonical_changes":True}
out=HERE/"market_parent_publication_immutable_ao_proof_READY.json"
assert not out.exists()
out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"path":ref(out),"sha256":sha(out),"subtree_bytes":len(ab)}))
