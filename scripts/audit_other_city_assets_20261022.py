"""Reconcile immutable image receipts and audit the source-bound candidate batch."""
import json
import hashlib
import shutil
import argparse
from collections import Counter
from pathlib import Path
import yaml
from PIL import Image, ImageDraw, ImageFont
import other_city_assets_20261022 as batch

ROOT=batch.ROOT
BASE=batch.BASE

def reconcile():
    manifest=json.loads(batch.LEDGER.read_text("utf-8"))
    before=BASE/"manifest_before_receipt_reconcile.json"
    if not before.exists(): shutil.copyfile(batch.LEDGER,before)
    restored=[]
    for row in manifest["assets"]:
        png=ROOT/row["output"]
        meta=png.with_suffix(".meta.json")
        if not meta.exists(): continue
        receipt=json.loads(meta.read_text("utf-8"))
        assert receipt["id"]==row["id"]
        assert batch.sha(png)==receipt["sha256"]
        assert batch.sha(Path(receipt["source_path"]))==receipt["sha256"]
        assert batch.sha(ROOT/receipt["prompt_path"])==receipt["prompt_sha256"]
        if row!=receipt: restored.append(row["id"])
        row.update(receipt)
    batch.LEDGER.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n","utf-8")
    report={"status":"RECEIPTS_RECONCILED_NO_IMAGE_CHANGE","restored_from_existing_receipts":restored,
            "note":"Earlier parallel record processes lost manifest updates; original per-image receipts and PNGs retained. Writes now sequential."}
    (BASE/"receipt_reconcile.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps(report))

def finish():
    manifest=json.loads(batch.LEDGER.read_text("utf-8"))
    rows=manifest["assets"]
    assert len(rows)==22 and len({r["id"] for r in rows})==22
    checks=[]
    for row in rows:
        png=ROOT/row["output"]
        receipt=json.loads(png.with_suffix(".meta.json").read_text("utf-8"))
        assert receipt["sha256"]==batch.sha(png)==batch.sha(Path(receipt["source_path"]))
        assert batch.sha(ROOT/row["prompt_path"])==row["prompt_sha256"]
        assert row["attempts"]==1
        if row.get("dependency"):
            ref=next(r for r in rows if r["id"]==row["dependency"])
            ref_input={"id":ref["id"],"path":ref["output"],"sha256":ref["sha256"],"role":"identity_reference"}
            if row.get("reference_input"): assert row["reference_input"]==ref_input
            # One early portrait receipt omitted reference metadata; supplement exact
            # already-used reference without changing image bytes or old receipt.
            else:
                row["reference_input"]=ref_input
                (BASE/(row["id"]+"_reference_supplement.json")).write_text(json.dumps(ref_input,indent=2)+"\n","utf-8")
        with Image.open(png) as im:
            im.load(); assert im.mode=="RGBA"
            alpha=im.getchannel("A")
            bbox=alpha.getbbox(); w,h=im.size
            margins=[bbox[0]/w,bbox[1]/h,(w-bbox[2])/w,(h-bbox[3])/h]
            assert list(im.size)==row["metrics"]["size"]
            assert list(bbox)==row["metrics"]["full_alpha_bbox"]
            assert min(alpha.getextrema())==0
            assert (min(margins)>=.1)==row["metrics"]["margin_10_percent_pass"]
        row["status"]="RAW_CANDIDATE_MARGIN_NOT_READY" if min(margins)<.1 else "RAW_CANDIDATE_NOT_RUNTIME"
        checks.append({"id":row["id"],"sha256":row["sha256"],"margin_10_percent_pass":min(margins)>=.1,"raw_receipt_unchanged":True})
    source_drift=[p for p,digest in manifest["source_sha256"].items() if batch.sha(ROOT/p)!=digest]
    assert not source_drift,source_drift
    before=(ROOT/"tmp/other_city_modules_20261022/before/tasks.yaml").read_bytes()
    tasks=(ROOT/"prompts/tasks.yaml").read_bytes()
    assert tasks[:len(before)]==before
    new_tasks=[r for r in yaml.safe_load(tasks)["tasks"] if r["id"].startswith(batch.PREFIX)]
    assert len(new_tasks)==22 and {r["id"] for r in new_tasks}=={r["id"] for r in rows}
    for task in new_tasks:
        assert task["skip"] and task["attempt_budget"]==1 and task["cli_fallback_allowed"] is False
        assert task["vars"]["asset_prompt"].strip()==(ROOT/task["prompt_path"]).read_text("utf-8").strip()
    manifest["status"]="FIRST_BATCH_RAW_COMPLETE_NOT_RUNTIME_READY"
    manifest["summary"]={"generated":22,"by_kind":dict(Counter(r["kind"] for r in rows)),"by_city":dict(Counter(r["city"] for r in rows)),"full_alpha_margin_pass":sum(r["metrics"]["margin_10_percent_pass"] for r in rows),"formal_enabled":False}
    batch.LEDGER.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n","utf-8")
    report={"status":"INTEGRITY_PASS_QUALITY_NOT_RUNTIME_READY","images":checks,"source_files_sha_unchanged":len(manifest["source_sha256"]),"task_old_prefix_byte_exact":True,"new_registered_tasks":22,"reference_pairs":4,"raw_pngs_unchanged":True,"quality_margin_failures":[r["id"] for r in rows if not r["metrics"]["margin_10_percent_pass"]],"no_padding_or_alpha_edit_performed":True,"no_engine_or_game_binding_performed":True}
    (BASE/"integrity_audit.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    previews=ROOT/"assets/previews/other_city_modules_20261022"
    previews.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype("C:/Windows/Fonts/msyh.ttc",17)
    for category, subset in [("architecture",[r for r in rows if r["kind"]=="maps"]),("npc_identity_pairs",[r for r in rows if r["kind"] in ("npc_sprites","portraits")]),("enemies_props",[r for r in rows if r["kind"] in ("enemies","monsters","quest_props")])]:
        cols=4 if category=="npc_identity_pairs" else 3
        cw,ch=360,320
        sheet=Image.new("RGB",(cols*cw,((len(subset)+cols-1)//cols)*ch),(235,232,223))
        draw=ImageDraw.Draw(sheet)
        for i,row in enumerate(subset):
            x,y=(i%cols)*cw,(i//cols)*ch
            panel=Image.new("RGBA",(cw-8,ch-48),(225,228,223,255))
            with Image.open(ROOT/row["output"]) as raw:
                thumb=raw.convert("RGBA");thumb.thumbnail((cw-24,ch-56),Image.Resampling.LANCZOS)
                panel.alpha_composite(thumb,((panel.width-thumb.width)//2,(panel.height-thumb.height)//2))
            sheet.paste(panel.convert("RGB"),(x+4,y+4))
            draw.text((x+10,y+ch-40),row["label"],font=font,fill=(28,37,43))
            draw.text((x+10,y+ch-20),"原图候选 · 未接入",font=font,fill=(115,58,31))
        sheet.save(previews/(category+".jpg"),quality=92)
    print(json.dumps({"summary":manifest["summary"],"source_sha_unchanged":len(manifest["source_sha256"]),"integrity_report":str(BASE/"integrity_audit.json")},ensure_ascii=True))

if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("action",choices=["reconcile","finish"],default="reconcile",nargs="?")
    args=parser.parse_args()
    reconcile() if args.action=="reconcile" else finish()
