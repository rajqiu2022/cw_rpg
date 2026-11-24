"""Independent read-only comparison of actual bridge candidates to original PNGs."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
report=json.loads((OUT/"processing_ACTUAL.json").read_text(encoding="utf-8"))
results=[]
for row in report["rows"]:
    raw=ROOT/row["raw"]["path"]
    assert hashlib.sha256(raw.read_bytes()).hexdigest()==row["raw"]["sha256"]
    assert raw.stat().st_mtime_ns==row["raw"]["mtime_ns"]
    if row["id"]=="bridge_04":
        assert not (ROOT/"game/art/modules/world_bridges_20261030m/bridge_04.png").exists()
        assert not (ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v1_padded.png").exists()
        results.append({"id":row["id"],"actual_alpha_edits":0,"game_processed_absent":True,
                        "report_count_275_semantics":"Dry prediction only, never executed on V1"})
        continue
    original=np.array(Image.open(raw))
    candidate=np.array(Image.open(ROOT/row["game_candidate"]["path"]))
    h,w=original.shape[:2]
    inner=candidate[256:256+h,256:256+w]
    x0,y0,x1,y1=row["protection_box_xyxy_exclusive"]
    changed=np.any(inner!=original,axis=2)
    assert np.array_equal(inner[:,:,:3],original[:,:,:3])
    assert np.array_equal(inner[y0:y1,x0:x1],original[y0:y1,x0:x1])
    assert np.all(original[changed,3]==1) and np.all(inner[changed,3]==0)
    assert int(changed.sum())==row["alpha1_outside_box_count"]
    assert not changed[y0:y1,x0:x1].any()
    assert np.array_equal(candidate,np.array(Image.open(ROOT/row["processed"]["path"])))
    assert hashlib.sha256(candidate.tobytes()).hexdigest()==row["decoded_rgba_sha256"]
    copy=candidate.copy();copy[256:256+h,256:256+w]=0
    assert not np.any(copy)
    results.append({"id":row["id"],"actual_alpha_edits":int(changed.sum()),"all_exact":True,
                    "png_sha256":hashlib.sha256((ROOT/row["game_candidate"]["path"]).read_bytes()).hexdigest(),
                    "rgba_sha256":hashlib.sha256(candidate.tobytes()).hexdigest()})
evidence={"results":results,"all_five_raw_sha_mtime_unchanged":True,
          "no_engine_no_import_no_gallery":True,"raw_a1_failure_retained":True}
target=OUT/"independent_exact_ACTUAL.json"
assert not target.exists()
target.write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(hashlib.sha256(target.read_bytes()).hexdigest())
