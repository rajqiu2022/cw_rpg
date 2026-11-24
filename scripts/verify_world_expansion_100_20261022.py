"""Preserve catalog core, audit raw receipts and prepare inspection-only contact sheets."""
import argparse, json, re, yaml
from pathlib import Path
from collections import Counter
from urllib.parse import unquote
from PIL import Image,ImageDraw,ImageFont
import world_expansion_100_20261022 as batch
from world100_asset_selection import select_assets

ROOT=batch.ROOT
BASE=batch.BASE
HTML=ROOT/"docs/equipment-skill-catalog.html"
TEMP=ROOT/"tmp/world_expansion_100_20261022"
CORE=TEMP/"before/catalog-core.json"

def payload():
    m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',HTML.read_text("utf-8"),re.S)
    assert m
    return json.loads(m.group(1))

def capture():
    data=payload();assert not CORE.exists()
    CORE.parent.mkdir(parents=True,exist_ok=True)
    CORE.write_text(json.dumps({k:v for k,v in data.items() if k!="resources"},ensure_ascii=False,indent=2)+"\n","utf-8")
    print("Captured original catalog core")

def audit(expected):
    ledger=json.loads(batch.LEDGER.read_text("utf-8"));rows=[r for r in ledger["assets"] if r.get("sha256")]
    assert len(rows)==expected,(len(rows),expected)
    assert len({r["sha256"] for r in rows})==len(rows),"Duplicate raw image content"
    previous=json.loads((ROOT/"assets/raw/other_city_modules_20261022/manifest.json").read_text("utf-8"))
    assert all(batch.digest(ROOT/r["output"])==r["sha256"] for r in previous["assets"])
    old=(TEMP/"before/tasks.yaml").read_bytes();assert (ROOT/"prompts/tasks.yaml").read_bytes()[:len(old)]==old
    assert all(batch.digest(ROOT/p)==d for p,d in ledger["source_sha256"].items())
    for r in rows:
        p=ROOT/r["output"];meta=json.loads(p.with_suffix(".meta.json").read_text("utf-8"))
        assert batch.digest(p)==r["sha256"]==meta["sha256"]==batch.digest(Path(r["source_path"]))
        assert batch.digest(ROOT/r["prompt_path"])==r["prompt_sha256"]
        assert r["attempts"]==1 and r["metrics"]["has_real_alpha"]
        if r.get("reference_input"): assert batch.digest(ROOT/r["reference_input"]["path"])==r["reference_input"]["sha256"]
        if r["tier"]=="story_boss": assert re.search(r'is_chapter_boss\s*=\s*true',(ROOT/r["sources"][0]).read_text("utf-8"))
        with Image.open(p) as im:
            im.load();assert list(im.size)==r["metrics"]["size"]
            assert list(im.getchannel("A").getbbox())==r["metrics"]["full_alpha_bbox"]
    report={"status":"RAW_INTEGRITY_PASS_NOT_RUNTIME_ADMISSION","generated":len(rows),"planned":100,
            "registered_main_versions":len(ledger["assets"]),"blocked_main_versions":sum(bool(r.get("generation_failure")) for r in ledger["assets"]),
            "kinds":dict(Counter(r["kind"] for r in rows)),"tiers":dict(Counter(r["tier"] for r in rows if r["tier"])),
            "source_sha_unchanged":len(ledger["source_sha256"]),"old_tasks_prefix_exact":True,
            "alpha_margin_pass":sum(r["metrics"]["margin_10_percent_pass"] for r in rows),
            "alpha_margin_fail":sum(not r["metrics"]["margin_10_percent_pass"] for r in rows),
            "pngs_byte_exact_to_builtin_originals":True,"formal_enabled":False,
            "distinct_new_raw_images":len({r["sha256"] for r in rows}),"previous_22_png_sha_unchanged":True,
            "initial_six_receipt_exception":"initial_path_receipt_failure.json: manual visual-spec mapping recovery, not original per-call path receipts"}
    (BASE/f"integrity_{expected:03d}.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    if expected==100:
        for r in ledger["assets"]:
            if r.get("generation_failure"):
                assert not r.get("sha256") and r["generation_failure"]["attempts"]==1
                r["status"]="BLOCKED_NO_IMAGE";r["attempts"]=1
        ledger["status"]="RAW_100_COMPLETE_NOT_RUNTIME_READY";ledger["summary"]=report
        batch.LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps(report,ensure_ascii=True))

def gallery(expected):
    data=payload();core={k:v for k,v in data.items() if k!="resources"}
    assert core==json.loads(CORE.read_text("utf-8"))
    rows=[r for r in data["resources"]["records"] if r["diskPath"].startswith("assets/raw/world_expansion_100_20261022/")]
    current=[r for r in rows if r["status"]!="rejected"]
    rejected=[r for r in rows if r["status"]=="rejected"]
    assert len(current)==expected and len({r["id"] for r in rows})==len(rows)
    if expected==100: assert len(rejected)==1
    for r in rows:
        assert r["status"] in ("candidate","rejected") and r["category"]=="candidate" and r["usageCount"]==0
        if r["status"]=="rejected": assert "不可选用" in r["note"] and "独立候选；" not in r["note"]
        assert r["group"].startswith("百图扩充 / ")
        assert (HTML.parent/unquote(r["url"])).resolve()==(ROOT/r["diskPath"]).resolve()
        with Image.open(HTML.parent/r["thumbnail"]) as im: im.load();assert im.width<=360 and im.height<=220 and im.mode=="RGBA"
    report={"status":"GALLERY_DATA_AND_THUMBNAIL_PASS","new_records":len(rows),"current_subjects":len(current),"rejected_originals":len(rejected),"original_catalog_core_exact":True,"summary":data["resources"]["summary"],"groups":dict(Counter(r["group"] for r in rows)),"new_browser_interaction_test":False}
    (TEMP/f"gallery_{expected:03d}.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="groups"},ensure_ascii=True))

def previews():
    ledger=json.loads(batch.LEDGER.read_text("utf-8"));rows=[r for r in ledger["assets"] if r.get("sha256")]
    rows,history=select_assets(ROOT,rows)
    dest=ROOT/"assets/previews/world_expansion_100_20261022";dest.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype("C:/Windows/Fonts/msyh.ttc",16)
    groups={}
    for r in rows:
        group=r["kind"]+(("_"+r["tier"]) if r["tier"] else "")
        groups.setdefault(group,[]).append(r)
    for group,items in groups.items():
        for page in range((len(items)+11)//12):
            subset=items[page*12:(page+1)*12];cw,ch=340,300;cols=4
            sheet=Image.new("RGB",(cw*cols,ch*((len(subset)+cols-1)//cols)),(235,232,223));draw=ImageDraw.Draw(sheet)
            for i,r in enumerate(subset):
                x,y=(i%cols)*cw,(i//cols)*ch
                panel=Image.new("RGBA",(cw-8,ch-46),(225,228,223,255))
                with Image.open(ROOT/r["output"]) as im:
                    thumb=im.convert("RGBA");thumb.thumbnail((cw-18,ch-54),Image.Resampling.LANCZOS)
                    panel.alpha_composite(thumb,((panel.width-thumb.width)//2,(panel.height-thumb.height)//2))
                sheet.paste(panel.convert("RGB"),(x+4,y+4));draw.text((x+9,y+ch-39),r["label"],font=font,fill=(25,35,40));draw.text((x+9,y+ch-19),"原图候选 · 未接入",font=font,fill=(110,55,31))
            sheet.save(dest/f"{group}_{page+1:02d}.jpg",quality=92)
    print(json.dumps({"preview_groups":list(groups),"images":len(rows)}))


def selection():
    ledger=json.loads(batch.LEDGER.read_text("utf-8"));rows,history=select_assets(ROOT,ledger["assets"])
    assert len(rows)==100 and len(history)==1
    all_rows=rows+history
    assert len({r["sha256"] for r in all_rows})==101
    tasks=yaml.safe_load((ROOT/"prompts/tasks.yaml").read_text("utf-8"))["tasks"]
    own=[t for t in tasks if t.get("id", "").startswith(batch.PREFIX)]
    assert len(own)==102 and len({t["id"] for t in own})==102
    assert all(t["skip"] and t["attempt_budget"]==1 and t["execution_backend"]=="builtin_image_gen" for t in own)
    for r in all_rows:
        p=ROOT/r["output"];meta=json.loads(p.with_suffix(".meta.json").read_text("utf-8"))
        assert batch.digest(p)==r["sha256"]==meta["sha256"]==batch.digest(Path(r["source_path"]))
        assert batch.digest(ROOT/r["prompt_path"])==r["prompt_sha256"]
        if r.get("reference_input"): assert batch.digest(ROOT/r["reference_input"]["path"])==r["reference_input"]["sha256"]
    report={"status":"100_CURRENT_VISUAL_CANDIDATES_NOT_RUNTIME_READY","subjects":100,"raw_versions":101,"rejected_versions":1,
            "kinds":dict(Counter(r["kind"] for r in rows)),"enemy_tiers":dict(Counter(r["tier"] for r in rows if r["tier"])),
            "alpha_margin_pass":sum(r["metrics"]["margin_10_percent_pass"] for r in rows),
            "alpha_margin_fail":sum(not r["metrics"]["margin_10_percent_pass"] for r in rows),
            "builtin_calls":102,"successful_image_outputs":101,"blocked_no_output_calls":1,"successful_new_generations":84,"successful_reference_or_edit_calls":17,
            "registered_unique_tasks":102,"auto_cli_skip":True,
            "assets":rows,"history":history,"formal_enabled":False}
    (BASE/"current-candidates.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in ("assets","history")}))

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["capture","audit","gallery","previews","selection"]);p.add_argument("--expected",type=int,default=100)
    args=p.parse_args()
    if args.action=="capture":capture()
    elif args.action=="audit":audit(args.expected)
    elif args.action=="gallery":gallery(args.expected)
    elif args.action=="selection":selection()
    else:previews()
