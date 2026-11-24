"""Read-only source, contact-strip and protected-file audit of the native trial."""
import json
import math
import re
import hashlib
from pathlib import Path
import numpy as np
from PIL import Image
from redrock_joint_trial_20261023e import ROOT, BASE, STAGE, save, sha


def main():
    manifest=json.loads((BASE/"manifest.json").read_text(encoding="utf-8"))
    interfaces=json.loads((STAGE/"interfaces.json").read_text(encoding="utf-8"))
    pieces={r["key"]:r for r in interfaces["pieces"]}
    alpha={r["key"]:np.array(Image.open(r["path"]).getchannel("A")) for r in pieces.values()}
    samples=[]
    core=pieces["core"]
    for key,port in interfaces["ports"].items():
        foot=np.array(port["core_foot"])*core["pixel_scale"]+core["origin"]
        top=np.array(port["core_walk_front"])*core["pixel_scale"]+core["origin"]
        # Narrow opaque facade strip only. This does not certify the wall-walk,
        # parapet, shadows, the full five-anchor profile, or whole-scene art.
        points=[(x,y) for x in np.arange(foot[0]-6,foot[0]+6,.5) for y in np.arange(top[1]+(foot[1]-top[1])*.25,top[1]+(foot[1]-top[1])*.75,.5)]
        holes=[]
        for x,y in points:
            covered=False
            for k,r in pieces.items():
                px=math.floor((x-r["origin"][0])/r["pixel_scale"])
                py=math.floor((y-r["origin"][1])/r["pixel_scale"])
                a=alpha[k]
                if 0<=py<a.shape[0] and 0<=px<a.shape[1] and a[py,px]>=128:
                    covered=True
                    break
            if not covered:holes.append([float(x),float(y)])
        samples.append({"joint":key,"scope":"12px wide middle-half opaque facade strip at 0.5px intervals, alpha>=128 union","samples":len(points),"holes":len(holes),"first_holes":holes[:5]})
    before=json.loads((STAGE/"protected-before.json").read_text(encoding="utf-8"))
    changed=[]
    for r in before:
        p=Path(r["path"])
        now={"path":str(p),"sha256":sha(p),"bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns}
        if now!=r:changed.append({"before":r,"after":now})
    native=json.loads((STAGE/"trial_project/verified_artifacts/verification.json").read_text(encoding="utf-8"))
    checks={"three_single_builtin_calls":all(r["calls"]==1 for r in manifest["assets"]),"three_native_PNGs_unchanged":all(sha(ROOT/r["output"])==r["sha256"] for r in manifest["assets"]),"native_sources_preserved":all(sha(Path(r["source_path"]))==r["sha256"] for r in manifest["assets"]),"two_facade_strips_no_holes":all(r["holes"]==0 for r in samples),"native_34_checks":native["passed"] and len(native["checks"])==34,"protected_scope_unchanged":not changed}
    text=(ROOT/"docs/equipment-skill-catalog.html").read_text(encoding="utf-8")
    catalog=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)[1])
    old=json.loads((ROOT/"assets/raw/redrock_gate_redesign_20261023d/catalog-before.json").read_text(encoding="utf-8"))
    nonres=hashlib.sha256(json.dumps({k:v for k,v in catalog.items() if k!="resources"},sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    records={r["diskPath"]:r for r in catalog["resources"]["records"]}
    gallery_checks={"non_resources_unchanged":nonres==old["non_resources"],"approved_design_status":records["assets/raw/redrock_gate_redesign_20261023d/design/redrock_gate_connected_design_20261023d_v1.png"]["statusLabel"]=="设计已确认 · 试拼中"}
    for r in manifest["assets"]:
        c=records[r["output"]]
        gallery_checks[r["key"]+"_candidate_status"]=c["status"]=="candidate" and c["statusLabel"]=="结构试拼 · 未正式接入"
        gallery_checks[r["key"]+"_thumbnail"]=(ROOT/"docs"/c["thumbnail"]).is_file()
        gallery_checks[r["key"]+"_full_image"]=(ROOT/"docs"/c["url"]).is_file()
    save(BASE/"gallery-verification.json",{"passed":all(gallery_checks.values()),"checks":gallery_checks,"summary":catalog["resources"]["summary"],"browser_click_acceptance":False})
    save(BASE/"assembly-review.json",{"status":"RAW_THREE_PIECE_TRIAL_CONNECTED_BUT_NOT_ART_FINAL","checks":checks,"passed":all(checks.values()),"facade_strip_samples":samples,"native_verification":native,"protected_files":len(before),"protected_changes":changed,"limitations":["全A1留白3图均FAIL；本报告不降低10%门槛","仅墙面中段接缝小条带，完整五锚点/墙道垛口/光影仍待","地面是默认隐藏的临时走域，不是真实峡壁层台","原生PNG只读ImageTexture，未正式import或绑定game","旧c版没有恢复；无生产公共源改动"]})
    print(json.dumps({"passed":all(checks.values()),"checks":checks,"seams":samples,"protected":len(before),"changes":len(changed)},ensure_ascii=False))


if __name__=="__main__":main()
