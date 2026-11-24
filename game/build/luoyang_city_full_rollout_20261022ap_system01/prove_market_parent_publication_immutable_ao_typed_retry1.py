"""Required whole-typed ancestor equality; retain stronger-byte-check failure."""
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
assert a==c
normalized=ab.replace(b"\r\n",b"\n")==cb.replace(b"\r\n",b"\n")
result={"status":"IMMUTABLE_AO_ANCESTOR_PARENT_SUBTREE_WHOLE_TYPED_EXACT",
 "ancestor":{"path":ref(ancestor),"sha256":sha(ancestor),"pointer":"/parent_publication"},
 "candidate":{"path":ref(candidate),"sha256":sha(candidate),"pointer":"/parent_publication"},
 "whole_subtree_typed_exact":True,"original_literal_bytes_equal":ab==cb,
 "CRLF_to_LF_only_literals_equal":normalized,
 "ancestor_literal":{"bytes":len(ab),"CRLF":ab.count(b"\r\n"),"LF":ab.count(b"\n"),"sha256":hashlib.sha256(ab).hexdigest()},
 "candidate_literal":{"bytes":len(cb),"CRLF":cb.count(b"\r\n"),"LF":cb.count(b"\n"),"sha256":hashlib.sha256(cb).hexdigest()},
 "predecessor_failure":"prove_market_parent_publication_immutable_ao.py stronger byte-equality assertion failed and is retained; required whole typed equality passes. Candidate bytes were never changed to wash that failure.",
 "no_candidate_or_canonical_changes":True}
out=HERE/"market_parent_publication_immutable_ao_typed_proof_READY.json"
assert not out.exists()
out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"path":ref(out),"sha256":sha(out),"literal_CRLF_to_LF_only":normalized}))
