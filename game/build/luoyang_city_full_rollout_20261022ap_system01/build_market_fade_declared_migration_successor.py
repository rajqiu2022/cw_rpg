"""Root-approved missing exact fade migration declaration, NEW metadata only."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
parent=HERE/"market_two_declared_metadata_successor_READY.json"
ao=GAME/"build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/ao_manifest.json"
binding=GAME/"data/maps/luoyang_district_life_20261016f/binding.json"
assert sha(parent)=="08e3456d654cfa19442c91540d730a10fec4db1159ed5e1a8250d95e062a38be"
assert sha(ao)=="c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e"
assert sha(binding)=="8bce718d3bfb363d15b9845aeedd113e02ff7cf7ef107ca94d3983363f33b668"
original=parent.read_bytes();p=json.loads(original);a=json.loads(ao.read_bytes());d=json.loads(binding.read_bytes())
fade="res://scripts/city/luoyang_district_life_fade_20261016f.gd"
row=a["source_migration"]["source_delta"][fade]
assert "source_migration" not in p
assert row["historical_sha256"]==["f359a43a88470ff220fa095cbd7f73ea04637c55c2faadd0a3b5f325e4b7a244","bc2958cc8f9a60ac9952891c30037441a62e289d8fee2fa235e6b864abf3a1bf"]
assert row["current_before_sha256"]==row["historical_sha256"][1]
assert row["new_sha256"]=="3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7"
assert row["candidate_path"]=="res://build/luoyang_market_two_shops_20261021ao_system01/District_fade_READY.gd"
merged=p["legacy_source_sha256"]|p["runtime_authority_sha256"]|p["artifacts"]
diff=[{"path":path,"binding_prior_sha256":pin,"fixed_manifest_sha256":merged.get(path)} for path,pin in d["source_sha256"].items() if merged.get(path)!=pin]
assert len(d["source_sha256"])==93 and len(diff)==1 and diff[0]["path"]==fade
assert diff[0]["binding_prior_sha256"]==row["historical_sha256"][0] and diff[0]["fixed_manifest_sha256"]==row["new_sha256"]
assert sha(GAME/fade.removeprefix("res://"))==row["new_sha256"]
assert sha(GAME/row["candidate_path"].removeprefix("res://"))==row["new_sha256"]
eol=b"\r\n" if b"\r\n" in original else b"\n"
addition={"source_delta":{fade:row}}
body=json.dumps(addition,ensure_ascii=False,indent=2).replace("\n","\n  ")
body=body.replace("\n",eol.decode()).encode()
end=original.rfind(b"}");tail=original[end-len(eol):]
assert tail.startswith(eol+b"}")
insert=b","+eol+b'  "source_migration": '+body+tail
candidate=original[:end-len(eol)]+insert
assert candidate.replace(insert,tail)==original
typed=json.loads(candidate);restored=typed.copy();restored.pop("source_migration")
assert same(restored,p) and same(typed["source_migration"]["source_delta"][fade],row)
out=HERE/"market_fade_declared_migration_successor_READY.json"
proof=HERE/"market_fade_declared_migration_successor_proof_READY.json"
for target in (out,proof):assert not target.exists()
out.write_bytes(candidate)
result={"status":"ROOT_APPROVED_SINGLE_EXACT_MISSING_MIGRATION_ROW_NOT_DEPLOYED",
 "parent":{"path":ref(parent),"sha256":sha(parent)},"candidate":{"path":ref(out),"sha256":sha(out)},
 "authority":{"path":ref(ao),"sha256":sha(ao),"pointer":"/source_migration/source_delta/"+fade.replace("~","~0").replace("/","~1")},
 "single_inherited_row":row,"whole_strict_typed_row_equal":True,"wholebyte_inverse_to08E3_and_strict_typed_inverse":True,
 "District_binding":{"path":ref(binding),"sha256":sha(binding),"source_count":93,"exact_same_count":92,"only_difference":diff},
 "causal_consumer":"District._published_source_matches -> B.ao_fade_source_matches already accepts AP scene and live proof, but08E3 source_migration absent gives empty delta. This declaration satisfies its existing fixed F359/BC2958/3F2D checks; no runtime rule change.",
 "unchanged":["1595 complete source keys and values","all existing root fields includingmask and parent","B/C/District/fade code","native scene/layout/packet/walk PNG","NAV/doors/NPC/task/runtime authority"],
 "not_inherited":"No other11 AO source_delta rows or old deployment/bootstrap claims copied",
 "no_engine_import_geometry_or_canonical_write":True}
proof.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"candidate_path":ref(out),"candidate_sha256":sha(out),"proof_path":ref(proof),"proof_sha256":sha(proof)}))
