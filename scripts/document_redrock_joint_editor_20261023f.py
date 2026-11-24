"""Current source/derivative/editor usage and bounded gallery verification."""
import argparse
import json
import hashlib
import re
from integrate_redrock_joint_editor_20261023f import ROOT,STAGE,ART,SCENE,sha,save


def catalog():
    text=(ROOT/"docs/equipment-skill-catalog.html").read_text(encoding="utf-8")
    return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)[1])

def digest(v):return hashlib.sha256(json.dumps(v,ensure_ascii=False,sort_keys=True).encode()).hexdigest()


def prepare():
    report=json.loads((ROOT/"assets/processed/redrock_joint_trial_20261023e/processing-report.json").read_text(encoding="utf-8"))
    native=json.loads((ROOT/"assets/raw/redrock_joint_trial_20261023e/manifest.json").read_text(encoding="utf-8"))
    parents={r["key"]:r for r in native["assets"]}
    derived=[]
    for r in report["items"]:
        parent=parents[r["key"]]
        derived.append({**r,"id":parent["id"]+"_authorized_padding","label":parent["label"]+"·授权透明留白派生","kind":parent["kind"],"derivation":True,"transparent":True,"metrics":{"margin_10_percent_pass":True},"review_note":"本批用户明确允许仅加透明画布，原PNG和全部RGBA保持，无裁/缩/清alpha。派生供f版独立工程结构草案，保pixel scale并补偿offset；不等整城/完整五锚点艺术通过。","formal_enabled":False})
    save(ROOT/"assets/processed/redrock_joint_trial_20261023e/resource-pack.json",{"status":"AUTHORIZED_DERIVATIVES_IN_EDITOR_DRAFT","assets":derived})
    config=json.loads((STAGE/"integration.json").read_text(encoding="utf-8"))
    copies=[]
    for r in config["media"]:
        if r["key"] in parents:
            kind,label=parents[r["key"]]["kind"],parents[r["key"]]["label"]
        else:
            kind,label={"guard":("npc_sprite","匿名关卒待机"),"earth":("ground","临时夯土走域")} [r["key"]]
        copies.append({"key":r["key"],"kind":kind,"label":(label if label.startswith("赤岩·") else "赤岩·"+label)+"·结构编辑草案","source":r["source"],"output":"game/"+r["destination"],"sha256":r["sha256"],"scene":"res://"+SCENE,"formal_enabled":False,**({"parent_source":parents[r["key"]]["output"]} if r["key"] in parents else {})})
    save(ROOT/"game"/ART/"resource-pack.json",{"status":"NATIVE_EDITOR_STRUCTURE_DRAFT_IMPORTED","resource_status_label":"结构编辑草案 · 已接入工程","validated_image_count":5,"scene":"res://"+SCENE,"assets":copies})
    native["padding_permission"]="EXPLICITLY_APPROVED_AND_EXECUTED_PADDING_ONLY"
    native["processed_report"]="assets/processed/redrock_joint_trial_20261023e/processing-report.json"
    native["current_editor_scene"]="res://"+SCENE
    save(ROOT/"assets/raw/redrock_joint_trial_20261023e/manifest.json",native)
    p=catalog()
    save(STAGE/"catalog-before.json",{"non_resources":digest({k:v for k,v in p.items() if k!="resources"}),"records":{r["diskPath"]:digest(r) for r in p["resources"]["records"]}})


def verify():
    before=json.loads((STAGE/"catalog-before.json").read_text(encoding="utf-8"));p=catalog()
    records={r["diskPath"]:r for r in p["resources"]["records"]}
    copies=json.loads((ROOT/"game"/ART/"resource-pack.json").read_text(encoding="utf-8"))["assets"]
    derived=json.loads((ROOT/"assets/processed/redrock_joint_trial_20261023e/resource-pack.json").read_text(encoding="utf-8"))["assets"]
    expected_new={r["output"] for r in copies+derived}
    allowed_changed={r.get("parent_source",r["source"]) for r in copies}
    changed={path for path,old in before["records"].items() if digest(records.get(path))!=old}
    checks={"non_resources_unchanged":before["non_resources"]==digest({k:v for k,v in p.items() if k!="resources"}),"eight_new_images_only":set(records)-set(before["records"])==expected_new,"only_five_old_source_rows_changed":changed==allowed_changed,"old_records_not_removed":all(path in records for path in before["records"])}
    for row in copies+derived:
        r=records[row["output"]]
        checks[row["key"]+row["output"]+"_thumb"]=(ROOT/"docs"/r["thumbnail"]).is_file()
        checks[row["key"]+row["output"]+"_full"]=(ROOT/"docs"/r["url"]).is_file()
        checks[row["key"]+row["output"]+"_candidate"]=r["status"]=="candidate"
    checks["five_editor_consumers"]=all(any(c["label"]=="res://"+SCENE for c in records[r["output"]]["usage"]) for r in copies)
    save(STAGE/"catalog-verification.json",{"passed":all(checks.values()),"checks":checks,"changed_old_rows":sorted(changed),"summary":p["resources"]["summary"],"browser_click_acceptance":False})
    print(json.dumps({"passed":all(checks.values()),"checks":len(checks),"failed":[k for k,v in checks.items() if not v],"summary":p["resources"]["summary"]},ensure_ascii=False))
    assert all(checks.values())


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument('action',choices=('prepare','verify'));a=p.parse_args()
    prepare() if a.action=='prepare' else verify()
