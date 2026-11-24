"""Independent static inverses + current exact media evidence; no engine/adoption."""
from pathlib import Path
import hashlib
import json

ROOT=Path(__file__).resolve().parents[3]
GAME=ROOT/"game"
QA=Path(__file__).resolve().parent
SYSTEM=GAME/"build/luoyang_city_full_rollout_20261022ap_system01"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def path(r):
    assert r.startswith("res://") and ".." not in r
    return GAME/r[6:]
def fixed(p,h):
    assert sha(p)==h, str(p)
    return p.read_bytes()
def inverse(blob,before,after,original_parent):
    # The candidate has three LF inserted blocks inside its CRLF parent.
    # Match only the two declared encodings of this exact explicit hunk;
    # restore to the fixed original parent's EOL. Final whole bytes must match.
    variants={after.encode(),after.replace("\n","\r\n").encode()}
    matches=[a for a in variants if blob.count(a)==1]
    assert len(matches)==1
    eol="\r\n" if b"\r\n" in original_parent else "\n"
    return blob.replace(matches[0],before.replace("\n",eol).encode())

handoff_path=SYSTEM/"visual_finish_candidates01_retry1/handoff_READY.json"
handoff=json.loads(fixed(handoff_path,"e84bff4a7ddd3b509cbdcbd1cf17a771aeb3c630a0ac022926ee3b838a64317f"))
field_receipt_path=SYSTEM/"Field_hero_exact_examiner_portrait_candidate_receipt_READY.json"
portrait=json.loads(fixed(field_receipt_path,"7b34bb015169aab91bb762f8ee4eb5cf4ccc43347ed2782e8043ad4c2967684e"))
rows={r["id"]:r for r in handoff["candidates"]}
checks=[]
for identity in ("HUD_readability","Hero_visual_only"):
    row=rows[identity]
    blob=fixed(path(row["candidate_path"]),row["candidate_sha256"])
    parent=fixed(path(row["parent_snapshot"]),row["parent_sha256"])
    for hunk in reversed(row["exact_hunks"]): blob=inverse(blob,hunk["before"],hunk["after"],parent)
    assert blob==parent
    assert blob==fixed(path(row["original_source"]),row["parent_sha256"])
    checks.append({"id":identity,"exact_hunks":len(row["exact_hunks"]),"wholebyte_inverse_to_current_original":True})
field_path=path(portrait["candidate"]["path"])
field=fixed(field_path,"a148154e8db886f508755ab91e7852c6ebe1e168a44d17badad9f3cc267499df")
h=portrait["exact_hunk"]
portrait_parent=fixed(path(portrait["parent"]["path"]),portrait["parent"]["sha256"])
assert inverse(field,h["before"],h["after"],portrait_parent)==portrait_parent
assert portrait["identity"]["only_scene"]=="ch4_s3_luoyang_market" and portrait["identity"]["only_npc_id"]=="spar_luoyang_examiner"
assert field.count(b'npc.npc_id == "spar_luoyang_examiner"')==1
assert field.count(b'npc.portrait_path = "res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png"')==1
actor_source=path("res://data/scenes/ch4_s3_luoyang_market.tres").read_text(encoding="utf-8")
assert actor_source.count('"npc_id": "spar_luoyang_examiner"')==1
assert '"interaction_action": "spar:luoyang_examiner:wulin_examiner:大会考校官:24:6"' in actor_source
hud=path(rows["HUD_readability"]["candidate_path"]).read_bytes()
validation=QA/"visual_parse_only/HUD_no_global_class_validation_READY.gd"
validation_bytes=fixed(validation,"3d31f59bd20a50916581d21475f8d7449ed9a64bab07e614057909b7c3a1123b")
assert hud==b"class_name FieldPrimaryHud\r\n"+validation_bytes

auth_path=GAME/"build/luoyang_city_full_rollout_20261022ap_root01/examiner_portrait_three_leaf_authorization_READY.json"
auth=json.loads(fixed(auth_path,"000b4cb5a742f31cfa8d75e741e5c8f9098581fbc022685609bfe5694dc8f3c2"))
assert auth["approved_by_root"] and auth["status"]=="ROOT_AUTHORIZED_EXACT_THREE_ABSENT_EXAMINER_MEDIA"
actual_path=QA/"isolate_examiner_portrait_ready01/ap_full_examiner_portrait_import_result_36012.json"
actual=json.loads(fixed(actual_path,"ee97525951a2160b8c2bd75e5e8f30273ac38362083ca4bded6b6afb87004d05"))
assert actual["passed"] and actual["checks"]==59 and not actual["failures"]
media=[]
for row in auth["targets"]:
    assert row["before"]=="ABSENT"
    leaf=path(row["path"])
    fixed(leaf,row["after_sha256"])
    isolated=QA/"isolate_examiner_portrait_ready01"/row["path"][6:]
    assert leaf.read_bytes()==isolated.read_bytes()
    media.append({"path":row["path"],"sha256":sha(leaf),"bytes":leaf.stat().st_size,"canonical_same_as_actual_isolate":True})
assert len(media)==3
sources={
    "res://project.godot":"4e49287b58d3d3c5fddbeee8db761a6ac8572a73f21d09a34d94c15d338a1cb2",
    "res://scripts/field/field_walkable_controller.gd":"24b5159b01470b571955f68a2762b9e979fc45703168e86cb8da157defea1179",
    "res://scripts/ui/field_primary_hud.gd":"9232f5a427461b127178e16eef1851e7d3960592e0dccd852f79bd714000a8ab",
    "res://build/luoyang_city_full_rollout_20261022ap_system01/visual_finish_candidates01_retry1/field_primary_hud_readability_READY.gd":rows["HUD_readability"]["candidate_sha256"],
    portrait["candidate"]["path"]:portrait["candidate"]["sha256"],
    "res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_parse_only/HUD_no_global_class_validation_READY.gd":sha(validation),
    "res://build/luoyang_city_full_rollout_20261022ap_root01/portrait_ui_finite_admission_READY.json":"d2c8470d07e834771954f8b7e2dd64ebcbeec859a417e737d29d7d9a6f47d016",
}
for p,h in sources.items(): fixed(path(p),h)
sources.update({m["path"]:m["sha256"] for m in media})
review={"status":"INDEPENDENT_STATIC_VISUAL_INVERSES_AND_CURRENT_THREE_MEDIA_NOT_RUNTIME_UI_ADMISSION","static_checks":checks,"portrait_exact_scene_id":"ch4_s3_luoyang_market","portrait_exact_npc_id":"spar_luoyang_examiner","portrait_post_catalog_priority":True,"no_other_NPC_sprite_body_spar_reward_change":True,"Hero_1_12_exact_eight_scene_visual_only_original_Player_and34x24_unchanged":True,"HUD_plain_black_alpha":0.62,"HUD_local_hover_or_left_pin_only_and_actual_wrapped_height":True,"HUD_validation_copy_only_class_name_removed_wholebyte_inverse":True,"canonical_three_media":media,"actual_import_result_sha256":sha(actual_path),"Root_promotion_authorization_sha256":sha(auth_path),"source_sha256":sources,"raw_modified":False,"engine_parse_or_UI_or_performance_executed_by_QA":False,"original_bare_HUD_duplicate_class_and_Field_autoload_domain_failures_retained":True}
review_out=QA/"visual_finish_independent_static_review_and_current_media_retry1_READY.json"
fixture_out=QA/"visual_finish_autoload_parse_two_retry1_READY.json"
assert not review_out.exists() and not fixture_out.exists()
review_out.write_text(json.dumps(review,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
sources["res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_finish_independent_static_review_and_current_media_retry1_READY.json"]=sha(review_out)
fixture={"status":"AP_TWO_VISUAL_CANDIDATES_AUTOLOAD_PARSE_ONLY","limit_ms":15000,"source_sha256":sources,"rows":[{"path":"res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_parse_only/HUD_no_global_class_validation_READY.gd","sha256":sha(validation),"methods":["_input","_sync_quest_backplate_bounds","_update_quest_backplate"]},{"path":portrait["candidate"]["path"],"sha256":portrait["candidate"]["sha256"],"methods":["_spawn_npcs","_spawn_player","_play_sparring_preface"]}],"HUD_validation_only_prefix_removed":"class_name FieldPrimaryHud\r\n","production_HUD_candidate_unchanged":True}
fixture_out.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"review":str(review_out),"review_sha256":sha(review_out),"parse_fixture":str(fixture_out),"parse_fixture_sha256":sha(fixture_out),"engine_executed":False}))
