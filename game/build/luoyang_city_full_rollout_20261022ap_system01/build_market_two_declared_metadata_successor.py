"""Root-approved two missing declarations only; NEW outputs, no engine."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
parent=HERE/"market_declared_mask_parent_5860.json"
ao=GAME/"data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
report=HERE/"market_alpha_pin_retry6/publication/17536/result.json"
prior_audit=HERE/"market_required_metadata_static_audit_READY.json"
assert sha(parent)=="5860180aebec2eef0c8e8f7512a0a1ae4775a3bc45096e74932fb64b3bfdd0e2"
assert sha(ao)=="be7cf173c832b1e9d4ab383135700dd0284a351346fd9d1e199a9c5e623e93b9"
assert sha(report)=="0058e2da30d0b0bbccc8579724ff9e916137de583cd3495bd2fdfb6025372511"
original=parent.read_bytes();p=json.loads(original);aotext=ao.read_bytes().decode("utf-8");aoj=json.loads(aotext)
eol=b"\r\n" if b"\r\n" in original else b"\n"
mask=json.loads(report.read_bytes())["walk_candidate"]["rgba_sha256"]
assert mask=="d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e"
label='"parent_publication": '
assert aotext.count(label)==1
start=aotext.index(label)+len(label)
inherited,end=json.JSONDecoder().raw_decode(aotext,start)
assert inherited==aoj["parent_publication"]
literal=aotext[start:end].encode("utf-8")
anchor=b'  "publication_full_source_finalized": true,'
new_anchor=anchor+eol+b'  "mask_sha256": "'+mask.encode()+b'",'
assert original.count(anchor)==1
candidate=original.replace(anchor,new_anchor)
root_end=candidate.rfind(b"}")
assert candidate[root_end-len(eol):root_end]==eol
last=candidate[root_end-len(eol):]
insert=b","+eol+b'  "parent_publication": '+literal+last
candidate=candidate[:root_end-len(eol)]+insert
inverse=candidate.replace(insert,last).replace(new_anchor,anchor)
assert inverse==original
typed=json.loads(candidate);restored=typed.copy();restored.pop("mask_sha256");restored.pop("parent_publication")
assert restored==p and typed["parent_publication"]==aoj["parent_publication"]
old_r3=GAME/inherited["path"].removeprefix("res://")
assert sha(old_r3)==inherited["sha256"]
assert json.loads(old_r3.read_bytes())==inherited["complete_immutable_manifest"]
for native,h in inherited["complete_immutable_manifest"]["artifacts"].items():
    assert sha(GAME/native.removeprefix("res://"))==h
out=HERE/"market_two_declared_metadata_successor_READY.json"
proof=HERE/"market_two_declared_metadata_successor_proof_READY.json"
for target in (out,proof):assert not target.exists()
out.write_bytes(candidate)
audit=json.loads(prior_audit.read_bytes())
checks={fn:[key for key in keys if key not in typed] for fn,keys in audit["AP_manifest_root_keys_consumed_by_function"].items()}
assert all(not v for v in checks.values())
result={"status":"ROOT_AUTHORIZED_TWO_MISSING_METADATA_DECLARATIONS_CANDIDATE_ONLY",
 "parent":{"path":ref(parent),"sha256":sha(parent)},"candidate":{"path":ref(out),"sha256":sha(out)},
 "delta_only":["mask_sha256 ABSENT -> original17536 walk_candidate.rgba_sha256 D161EEAB","parent_publication ABSENT -> verbatim AO declaration subtree"],
 "mask_authority":{"path":ref(report),"sha256":sha(report),"pointer":"/walk_candidate/rgba_sha256","value":mask},
 "parent_authority":{"path":ref(ao),"sha256":sha(ao),"pointer":"/parent_publication","verbatim_UTF8_subtree_inherited":True},
 "inherited_r3_manifest":{"path":ref(old_r3),"sha256":sha(old_r3),"typed_complete_immutable_manifest_exact":True,"native_artifact_hashes_match":True},
 "wholebyte_inverse_to_5860_and_typed_key_inverse":True,
 "all_required_B_manifest_keys_present_after_candidate":checks,
 "extended_B_Field_DistrictFade_consumers":"B.run/materialize/ap_packet_valid/bound/whole_bound/describe keys covered in linked audit; Field District prepare uses B.layout_author (AP spec district_t_author pins already present) and B.restore_parent_record (old packet T fields inherited). DistrictFade calls B.parent_scene: now exact old r3 complete immutable manifest metadata restored, not guessed from current collector.",
 "static_audit":{"path":ref(prior_audit),"sha256":sha(prior_audit)},
 "all_other_original_manifest_fields_and_1595_fixed_sources_unchanged":True,
 "no_C_B_native_walk_import_geometry_or_canonical_write":True,
 "next":"Source finalizer may derive exactly Market manifest + AP city index metadata successor. Root owns approval/deployment and bounded remaining B/D/E actual; no repeated full geometry or A/C."}
proof.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"candidate_path":ref(out),"candidate_sha256":sha(out),"proof_path":ref(proof),"proof_sha256":sha(proof),"r3_sha256":sha(old_r3)}))
