"""Check the gallery data-only synchronization for the new 22 assets."""
import argparse
import json
import re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
HTML=ROOT/"docs/equipment-skill-catalog.html"
BASE=ROOT/"tmp/other_city_modules_20261022"
SNAPSHOT=BASE/"before/catalog-core.json"

def payload():
    text=HTML.read_text("utf-8")
    match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    assert match
    return json.loads(match.group(1))

def main(action):
    data=payload()
    core={k:v for k,v in data.items() if k!="resources"}
    if action=="capture":
        assert not SNAPSHOT.exists()
        SNAPSHOT.parent.mkdir(parents=True,exist_ok=True)
        SNAPSHOT.write_text(json.dumps(core,ensure_ascii=False,indent=2)+"\n","utf-8")
        print("Captured existing non-resource catalog data")
        return
    assert core==json.loads(SNAPSHOT.read_text("utf-8")),"Original catalog core changed"
    rows=[r for r in data["resources"]["records"] if r["diskPath"].startswith("assets/raw/other_city_modules_20261022/")]
    assert len(rows)==22 and len({r["id"] for r in rows})==22
    manifest=json.loads((ROOT/"assets/raw/other_city_modules_20261022/manifest.json").read_text("utf-8"))
    by_path={r["output"]:r for r in manifest["assets"]}
    for row in rows:
        assert row["status"]=="candidate" and row["category"]=="candidate"
        assert row["usageCount"]==0 and row["usage"]==[]
        assert row["group"].startswith("其他城镇 / ")
        assert row["name"]==by_path[row["diskPath"]]["label"]
        assert (HTML.parent/unquote(row["url"])).resolve()==(ROOT/row["diskPath"]).resolve()
        assert (ROOT/row["diskPath"]).is_file()
        assert "未导入" in row["note"] and "未接入" in row["note"]
        with Image.open(HTML.parent/row["thumbnail"]) as image:
            image.load();assert image.width<=360 and image.height<=220
            assert image.mode=="RGBA"
        assert row["size"]==by_path[row["diskPath"]]["metrics"]["size"]
    report={"status":"PASS_DATA_SYNC_AND_22_THUMBNAILS","original_catalog_core_exact":True,
            "new_candidate_records":22,"groups":sorted({r["group"] for r in rows}),
            "summary":data["resources"]["summary"],"new_browser_interaction_test":False,
            "note":"Existing gallery zoom/filter controls unchanged; only candidate data and explanatory intro updated."}
    (BASE/"gallery_verify.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps(report,ensure_ascii=True))

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["capture","verify"])
    main(p.parse_args().action)
