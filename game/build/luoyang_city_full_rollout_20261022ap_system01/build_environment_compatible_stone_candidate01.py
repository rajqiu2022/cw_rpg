"""NEW visual-only stone alias/tone successor after Root actual Market review."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
OUT=HERE/"environment_compatible_stone_candidate01"
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
author=GAME/"data/maps/luoyang_full_city_20261022ap/environment.json"
helper=HERE/"visual_finish_candidates01_retry1/environment_pawn_core_transition_READY.gd"
screen=GAME/"build/luoyang_city_full_rollout_20261022ap_qa01/bounded_remaining_fade_history_B/101568_2689/ch4_s3_luoyang_market.png"
assert sha(author)=="5a9994d84b4a2adf6d8e02048fce236bd433d6b163b1aaec5cdb8ea992cbc98f"
assert sha(helper)=="a8516e6499091fd5c2a695180f6a8e184d380336e08a71155b0fac9223d920f3"
assert not OUT.exists()
data=author.read_bytes();text=data.decode("utf-8");j=json.loads(text)
label='"road_stone": '
assert text.count(label)==1
start=text.index(label)+len(label)
prior,end=json.JSONDecoder().raw_decode(text,start)
assert prior==j["assets"]["road_stone"]
chosen=j["assets"]["court_stone"]
eol="\r\n" if b"\r\n" in data else "\n"
newliteral=json.dumps(chosen,ensure_ascii=False,indent=2).replace("\n","\n    ").replace("\n",eol)
newtext=text[:start]+newliteral+text[end:]
inverse=newtext[:start]+text[start:end]+newtext[start+len(newliteral):]
assert inverse.encode()==data
child=json.loads(newtext);restored=json.loads(newtext);restored["assets"]["road_stone"]=prior
assert restored==j and child["source_sha256"]==j["source_sha256"]
before=b'transition.set_shader_parameter("ap_core_opacity",core_opacity)'
code=helper.read_bytes();ceol=b"\r\n" if b"\r\n" in code else b"\n"
after=before+ceol+b'\t\t\tsprite.modulate=Color(1.10,1.10,1.08,1.0)'
assert code.count(before)==1
newcode=code.replace(before,after)
assert newcode.replace(after,before)==code
OUT.mkdir()
parentauthor=OUT/"environment_author_parent_5A99.json";parentauthor.write_bytes(data)
outauthor=OUT/"environment_compatible_stone_READY.json";outauthor.write_bytes(newtext.encode())
parenthelper=OUT/"environment_layer_parent_A851.gd";parenthelper.write_bytes(code)
outhelper=OUT/"environment_compatible_stone_READY.gd";outhelper.write_bytes(newcode)
result={"status":"ROOT_APPROVED_BUILD_ONLY_NOT_SOURCE_CLOSED_NOT_ENGINE_CHECKED_NOT_ART_PASSED",
 "author":{"path":ref(outauthor),"sha256":sha(outauthor),"parent":{"path":ref(parentauthor),"sha256":sha(parentauthor)},"sole_delta":"assets.road_stone becomes exact existing assets.court_stone texture/source_size; no source19 changes","wholebyte_inverse":True},
 "helper":{"path":ref(outhelper),"sha256":sha(outhelper),"parent":{"path":ref(parenthelper),"sha256":sha(parenthelper)},"sole_delta":"rect-only Sprite modulate(1.10,1.10,1.08,1), alpha unchanged","wholebyte_inverse":True},
 "actually_viewed_parent_Market":{"path":ref(screen),"sha256":sha(screen),"observed":"Independent dang sign clear, but high-frequency worn_bluestone L-path and dark large forecourt still art-rejected; orphan old small wall remains native and is not changed here"},
 "shader_unchanged":{"path":ref(HERE/"environment_rect_transition_candidate.gdshader"),"sha256":sha(HERE/"environment_rect_transition_candidate.gdshader")},
 "kept":{"all11_rects_and_uniform_scales_world_mapping":True,"pawn_core_opacity":1.0,"other10_core_opacity":0.66,"whole_rect_feather_world":32.0,"all_four_original_wholealpha_stamps":True,"all19_source_pins":True,"native_geometry_masks_NAV_doors_NPCs_tasks":True},
 "HUD_and_Hero_pending_candidates":{"handoff_path":ref(HERE/"visual_finish_candidates01_retry1/handoff_READY.json"),"handoff_sha256":sha(HERE/"visual_finish_candidates01_retry1/handoff_READY.json")},
 "known_limitations":["No runtime/visual credit before Root actual finite comparison","Orphan small native wall not modified","C native nine stone sections still need separate visual boundary decision","Hero ratio must be visually compared; body/foot formula unchanged","Portrait separate art-only task not bound"],
 "no_canonical_engine_import_geometry_tasktable_or_media_write":True}
receipt=OUT/"handoff_READY.json"
receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"author_sha256":sha(outauthor),"helper_sha256":sha(outhelper),"handoff_path":ref(receipt),"handoff_sha256":sha(receipt)}))
