"""NEW exact examiner portrait override on the existing hero-only candidate."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
parent=HERE/"visual_finish_candidates01_retry1/Field_hero_visual_only_READY.gd"
authority=GAME/"build/luoyang_city_full_rollout_20261022ap_root01/portrait_ui_finite_admission_READY.json"
assert sha(parent)=="c089d5c3473159a50b1a58803f599fb93cdf30f517d8b88589922b6c87cd2d3f"
a=json.loads(authority.read_bytes())
target="res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png"
assert a["source_sha256"]=="4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc"
assert sha(Path(a["source"]))==a["source_sha256"]
original=parent.read_bytes();eol="\r\n" if b"\r\n" in original else "\n"
before='''		if _current_scene != null:
			npc.sprite_scale *= _current_scene.npc_visual_scale'''
after='''		# Exact existing Luoyang examiner only, after catalog portrait priority.
		# Full1254 canvas is UI-contained; no world sprite or spar payload change.
		if _current_scene.scene_id == &"ch4_s3_luoyang_market" and npc.npc_id == "spar_luoyang_examiner":
			npc.portrait_path = "'''+target+'''"
		if _current_scene != null:
			npc.sprite_scale *= _current_scene.npc_visual_scale'''
b=before.replace("\n",eol).encode();n=after.replace("\n",eol).encode()
assert original.count(b)==1
candidate=original.replace(b,n)
assert candidate.replace(n,b)==original
out=HERE/"Field_hero_exact_examiner_portrait_candidate_READY.gd"
proof=HERE/"Field_hero_exact_examiner_portrait_candidate_receipt_READY.json"
for p in (out,proof):assert not p.exists()
out.write_bytes(candidate)
result={"status":"BUILD_ONLY_EXACT_OVERRIDE_NOT_IMPORTED_NOT_ENGINE_CHECKED_NOT_SOURCE_CLOSED",
 "parent":{"path":ref(parent),"sha256":sha(parent)},"candidate":{"path":ref(out),"sha256":sha(out)},
 "portrait_finite_authority":{"path":ref(authority),"sha256":sha(authority)},
 "future_media":{"path":target,"sha256":a["source_sha256"],"native_size":[1254,1254],"full_canvas_unchanged":True,"exists_now":(GAME/target.removeprefix("res://")).exists(),"import_status":"ROOT_UNIQUE_THREE_LEAF_ISOLATION_PENDING"},
 "identity":{"only_scene":"ch4_s3_luoyang_market","only_npc_id":"spar_luoyang_examiner","unchanged_action":"spar:luoyang_examiner:wulin_examiner:大会考校官:24:6","not_affected":["spar_wulin_examiner trial retest","feng_yanqiu_ch4","otherNPCs","world sprite/scale/body/animation","dialog text/choice/spar rewards"]},
 "priority":"Set exact npc.portrait_path after existing NPC_CATALOG defaults; runtime spar preface sets that actor portrait as DialogPlayer default. Invite/ready nodes have no explicit portrait and speaker empty, so default portrait applies; explicit authored portraits on unrelated nodes keep original priority.",
 "UI_fit":"Existing dialogue portrait TextureRect stretch_mode5 uses aspect-centered contain; no raw crop/alpha cleanup/expansion included. Root actual UI fit still required.",
 "wholebyte_inverse_to_C089":True,"exact_hunk":{"before":before,"after":after},
 "hero_1_12_eight_scene_delta_inherited_unchanged":True,
 "no_canonical_media_import_engine_native_sourceclosure_write":True}
proof.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"candidate_path":ref(out),"candidate_sha256":sha(out),"receipt_path":ref(proof),"receipt_sha256":sha(proof)}))
