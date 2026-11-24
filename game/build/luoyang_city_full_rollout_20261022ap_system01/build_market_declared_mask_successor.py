"""NEW metadata-only candidate from original publication declaration; no engine."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
def load(p):return json.loads(p.read_text(encoding="utf-8-sig"))
parent=GAME/"data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
report=HERE/"market_alpha_pin_retry6/publication/17536/result.json"
publisher=HERE/"market_alpha_pin_retry6/publish_market.gd"
ao=GAME/"data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"
bundle=GAME/"scripts/city/luoyang_precomputed_bundle_20261018r.gd"
assert sha(parent)=="5860180aebec2eef0c8e8f7512a0a1ae4775a3bc45096e74932fb64b3bfdd0e2"
assert sha(report)=="0058e2da30d0b0bbccc8579724ff9e916137de583cd3495bd2fdfb6025372511"
assert sha(publisher)=="7d1a37daba248bf150d00a12edaa6de9597b0253c8171fc00e4bb929a7446ab5"
assert sha(ao)=="be7cf173c832b1e9d4ab383135700dd0284a351346fd9d1e199a9c5e623e93b9"
p=load(parent);r=load(report);old=load(ao)
mask=r["walk_candidate"]["rgba_sha256"]
assert mask=="d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e"
assert "mask_sha256" not in p and "parent_publication" not in p
assert r["published"] is True and r["artifacts"]==p["artifacts"]
data=parent.read_bytes();eol=b"\r\n" if b"\r\n" in data else b"\n"
anchor=b'  "publication_full_source_finalized": true,'
assert data.count(anchor)==1
replacement=anchor+eol+b'  "mask_sha256": "'+mask.encode()+b'",'
candidate=data.replace(anchor,replacement)
assert candidate.replace(replacement,anchor)==data
child=json.loads(candidate)
inverse=child.copy();inverse.pop("mask_sha256")
assert inverse==p
out=HERE/"market_declared_mask_successor_READY.json"
snapshot=HERE/"market_declared_mask_parent_5860.json"
fragment=HERE/"market_inherited_parent_publication_FRAGMENT.json"
proof=HERE/"market_required_metadata_static_audit_READY.json"
for target in (out,snapshot,fragment,proof):assert not target.exists()
out.write_bytes(candidate);snapshot.write_bytes(data)
fragment.write_text(json.dumps(old["parent_publication"],ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
direct={
 "manifest":["kind","scene_id","publication_full_source_finalized","geometry_proof_basis","author_path","author_sha256","ap_two_whole_frontages_and_three_room_relocations","layout_proof","legacy_source_sha256","runtime_authority_sha256","artifacts"],
 "run":["artifacts","geometry_proof_basis","mask_sha256"],
 "materialize":["artifacts","author_sha256"],
 "ap_packet_valid":["artifacts","author_sha256"],
 "bound":["author_sha256"],"whole_bound":[],
 "describe":["legacy_source_sha256","runtime_authority_sha256","artifacts"],
 "parent_scene_consumed_by_DistrictFade":["parent_publication"]}
missing={fn:[key for key in keys if key not in p] for fn,keys in direct.items()}
required_packet={
 "run":["geometry_basis","kind","scene_id","record","size","walk_bytes","mask_sha","solids","scene_storage","layout_storage","input_storage","input_layout_storage","scene_script","layout_script"],
 "materialize":["input_storage","input_layout_storage","scene_storage","layout_storage","geometry_basis"],
 "ap_packet_valid":["geometry_basis","ap_author_sha256","ap_parent_packet_sha256","ap_parent_record","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"],
 "bound_and_whole_bound":["geometry_basis","record/walk_path","scene_storage","layout_storage"],
 "parent_scene_and_District_restore":["t_parent_scene_storage","t_parent_layout_storage","t_parent_record","ao_parent_record"]}
result={"status":"STATIC_COMPLETE_METADATA_KEY_AUDIT_AND_SINGLE_MASK_DECLARATION_CANDIDATE_NOT_DEPLOYED",
 "candidate":{"path":ref(out),"sha256":sha(out)},"parent":{"path":ref(snapshot),"sha256":sha(snapshot)},
 "one_key_delta":{"key":"mask_sha256","old":"ABSENT","new":mask,"source":{"path":ref(report),"sha256":sha(report),"pointer":"/walk_candidate/rgba_sha256"}},
 "wholebyte_and_typed_inverse":True,"unchanged_all_three_artifacts":p["artifacts"],
 "causality":"B.run prior gate already proves bytes_sha(packet.walk_bytes)==packet.mask_sha; final guard compares that packet.mask_sha with missing manifest.get(mask_sha256). Original publisher line183 sets packet.mask_sha from mask RGBA; line204 writes the identical value as walk_candidate.rgba_sha256. No PNG or observed collector hash substituted.",
 "B_source":{"path":ref(bundle),"sha256":sha(bundle)},"publisher":{"path":ref(publisher),"sha256":sha(publisher)},
 "AP_manifest_root_keys_consumed_by_function":direct,"missing_in_original_parent":missing,
 "nested_manifest_requirements":["layout_proof/passed=true","artifacts/{AP_ROOT+id/scene.res,layout.res,packet.bin}","parent_publication/complete_immutable_manifest/artifacts/{r3ROOT+id/scene.res,layout.res}"],
 "fixed_packet_contract_fields":required_packet,
 "packet_field_lineage_limit":"Static key audit only, not binary packet decoder or rerun. Frozen 17536 publisher clones AO full packet and proves whole typed inverse after replacing only seven geometry/storage keys and adding three AP keys. Required old T/input/script/storage fields inherit unchanged. Actual39372 B.run passed all packet identity/storage checks before absent manifest mask key.",
 "remaining_latent_required_metadata":{"key":"parent_publication","consumer_chain":"Field -> DistrictFade.configure_district -> B.parent_scene -> session.config.parent_publication.complete_immutable_manifest", "parent_declaration":{"path":ref(ao),"sha256":sha(ao),"pointer":"/parent_publication"},"inherited_fragment":{"path":ref(fragment),"sha256":sha(fragment)},"current_old_r3_declared_path":old["parent_publication"].get("path"),"current_old_r3_declared_sha256":old["parent_publication"].get("sha256"),"not_added_to_single_mask_candidate":True,"Root_authority_required_before_merged_metadata_successor":True},
 "no_engine_geometry_import_native_C_B_or_canonical_writes":True}
proof.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"candidate_sha256":sha(out),"proof_path":ref(proof),"proof_sha256":sha(proof),"parent_publication_fragment_sha256":sha(fragment),"direct_missing":missing}))
