"""Exact optional three-image padding. Execute only after this batch's explicit consent."""
import argparse
import json
import math
from pathlib import Path
from PIL import Image
from redrock_joint_trial_20261023e import ROOT, BASE, STAGE, save, sha

OUT = ROOT / "assets/processed/redrock_joint_trial_20261023e"


def propose():
    pack = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
    rows = []
    for r in pack["assets"]:
        w,h = r["size"]
        x,y = math.ceil(w/7),math.ceil(h/7)
        rows.append({"key":r["key"],"source":r["output"],"source_sha256":r["sha256"],"old_size":[w,h],"offset":[x,y],"new_size":[w+2*x,h+2*y],"output":f"assets/processed/redrock_joint_trial_20261023e/{r['key']}/{r['id']}_padded.png","source_pixel_changes":0,"new_pixels_RGBA":[0,0,0,0]})
    save(STAGE / "padding-proposal.json", {"status":"PREPARED_NOT_EXECUTED_PERMISSION_REQUIRED_FOR_THIS_THREE","items":rows,"processor":str(Path(__file__).relative_to(ROOT)).replace("\\","/"),"processor_sha256":sha(Path(__file__)),"alpha_cleanup":False,"crop_resize_rotate":False,"old_12_permission_not_reused":True,"review_image":"assets/staging/redrock_joint_trial_20261023e/trial_project/verified_artifacts/overview.png"})


def execute():
    plan_path = STAGE / "padding-proposal.json"
    auth_path = STAGE / "padding-authorization.json"
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    auth = json.loads(auth_path.read_text(encoding="utf-8"))
    assert auth["explicit_local_padding_only"] is True and auth["proposal_sha256"] == sha(plan_path)
    assert plan["processor_sha256"] == sha(Path(__file__))
    for r in plan["items"]:
        assert sha(ROOT/r["source"]) == r["source_sha256"] and not (ROOT/r["output"]).exists()
    results=[]
    for r in plan["items"]:
        source = ROOT/r["source"]
        original = Image.open(source).convert("RGBA")
        result = Image.new("RGBA",tuple(r["new_size"]),(0,0,0,0))
        result.paste(original,tuple(r["offset"]))
        out=ROOT/r["output"]
        out.parent.mkdir(parents=True,exist_ok=True)
        result.save(out)
        check=Image.open(out).convert("RGBA")
        x,y=r["offset"];w,h=r["old_size"]
        assert check.crop((x,y,x+w,y+h)).tobytes()==original.tobytes()
        assert sha(source)==r["source_sha256"]
        bbox=check.getchannel("A").getbbox()
        margins=[bbox[0]/check.width,bbox[1]/check.height,(check.width-bbox[2])/check.width,(check.height-bbox[3])/check.height]
        assert min(margins)>=.1
        row={**r,"sha256":sha(out),"original_RGBA_exact":True,"margin_10_percent_pass":True,"margins":margins,"draw_origin_rule":"old_origin-offset*original_uniform_scale; keep source pixel scale"}
        save(out.with_suffix(".meta.json"),row)
        results.append(row)
    save(OUT/"processing-report.json",{"status":"EXPLICITLY_AUTHORIZED_PADDING_ONLY","items":results,"new_alpha_cleanup_pixels":0,"source_pixel_changes":0})


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=("propose","execute"));args=p.parse_args()
    propose() if args.action=="propose" else execute()
