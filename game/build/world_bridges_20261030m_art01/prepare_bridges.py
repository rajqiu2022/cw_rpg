"""Exact authorized A1-only cleanup and transparent padding; no generation/import."""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
PAD = 256
BOXES = [[30,130,1733,861], [94,86,923,1595], [106,91,886,1574],
         [130,100,691,1795], [33,194,1420,989]]

def sha(data):
    return hashlib.sha256(data).hexdigest()

def file_fact(path):
    return {"path": path.relative_to(ROOT).as_posix(), "sha256": sha(path.read_bytes()),
            "bytes": path.stat().st_size, "mtime_ns": path.stat().st_mtime_ns}

def bbox(mask):
    y, x = np.nonzero(mask)
    return [int(x.min()),int(y.min()),int(x.max())+1,int(y.max())+1] if len(x) else None

def margin(b, size):
    w,h = size
    px = [b[0],b[1],w-b[2],h-b[3]]
    fractions = [px[0]/w,px[1]/h,px[2]/w,px[3]/h]
    return {"pixels_ltrb": px, "fractions_ltrb": fractions, "all_at_least_10percent": min(fractions)>=.10}

def save_json(path, value):
    assert not path.exists(), f"Refuse to overwrite {path}"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")

parser = argparse.ArgumentParser()
parser.add_argument("--execute-four", action="store_true")
args = parser.parse_args()
rows=[]
for i,box in enumerate(BOXES):
    stem=f"bridge_{i:02d}"
    raw=ROOT/f"assets/raw/world_bridges_20261030m/{stem}_v1.png"
    before=file_fact(raw)
    image=Image.open(raw)
    assert image.mode=="RGBA"
    original=np.asarray(image).copy()
    h,w=original.shape[:2]
    alpha=original[:,:,3]
    x0,y0,x1,y1=box
    outside=np.ones((h,w),dtype=bool)
    outside[y0:y1,x0:x1]=False
    clear=outside & (alpha==1)
    assert not np.any(outside & (alpha>1)), "Protection box omits alpha>=2"
    edited=original.copy()
    edited[clear,3]=0
    padded=np.zeros((h+2*PAD,w+2*PAD,4),dtype=np.uint8)
    padded[PAD:PAD+h,PAD:PAD+w]=edited
    extract=padded[PAD:PAD+h,PAD:PAD+w]
    invariants={
        "all_original_rgb_exact": bool(np.array_equal(extract[:,:,:3],original[:,:,:3])),
        "protected_rgba_exact": bool(np.array_equal(extract[y0:y1,x0:x1],original[y0:y1,x0:x1])),
        "all_original_alpha_ge2_rgba_exact": bool(np.array_equal(extract[alpha>=2],original[alpha>=2])),
        "only_authorized_alpha1_to_zero": bool(np.array_equal((extract!=original).any(axis=2),clear)),
        "new_padding_rgba_all_zero": bool(np.count_nonzero(padded[:PAD])==0 and np.count_nonzero(padded[-PAD:])==0 and np.count_nonzero(padded[:,:PAD])==0 and np.count_nonzero(padded[:,-PAD:])==0)
    }
    assert all(invariants.values())
    a1bbox=bbox(alpha>0)
    row={"id":stem,"raw":before,"raw_size":[w,h],"raw_mode":image.mode,
         "raw_alpha_max":int(alpha.max()),"raw_bbox_alpha_gt0":a1bbox,
         "raw_bbox_alpha_ge2":bbox(alpha>=2),"raw_margin":margin(a1bbox,[w,h]),
         "raw_a1_margin_status":"FAIL_ORIGINAL_RETAINED",
         "protection_box_xyxy_exclusive":box,"alpha1_outside_box_count":int(clear.sum()),
         "padding_each_edge":PAD,"source_coordinate_offset":[PAD,PAD],
         "candidate_size":[w+2*PAD,h+2*PAD],"invariants":invariants,
         "candidate_margin":margin(bbox(padded[:,:,3]>0),[w+2*PAD,h+2*PAD]),
         "status":"AUTHORIZED_00_TO_03_PENDING_EXECUTION" if i<4 else "V1_RAW_ONLY_ROOT_ART_REJECTED_ASPECT_V2_PENDING"}
    if args.execute_four and i<4:
        processed=ROOT/f"assets/processed/world_bridges_20261030m/{stem}_v1_padded.png"
        game=ROOT/f"game/art/modules/world_bridges_20261030m/{stem}.png"
        for target in [processed,game]:
            assert not target.exists(), f"Refuse to overwrite {target}"
            target.parent.mkdir(parents=True,exist_ok=True)
        Image.fromarray(padded,"RGBA").save(processed)
        game.write_bytes(processed.read_bytes())
        assert np.array_equal(np.asarray(Image.open(processed)),padded)
        assert game.read_bytes()==processed.read_bytes()
        row.update({"processed":file_fact(processed),"game_candidate":file_fact(game),
                    "decoded_rgba_sha256":sha(padded.tobytes()),
                    "status":"PNG_CANDIDATE_NOT_IMPORTED_NOT_BOUND_NOT_FINAL_WORLD_ART"})
        provenance={"schema_version":1,"asset_id":stem,"generation_backend":"builtin_image_gen",
                    "builtin_calls_for_v1":1,"model":None,"provider":None,"cost":None,
                    "generation_evidence_scope":"Producer supplied: each V1 generated once with built-in tool; tool model/provider/cost unknown",
                    "promptset":"assets/staging/world_bridges_20261030m/production",
                    "reference_only_local_composite_is_generated_output":False,
                    "processing":"Only alpha=1 outside protected box to zero, then 256 RGBA0 padding on all edges. No crop, recolor, rescale, repaint, alpha normalization or removal of visible shadow.",
                    "record":row}
        save_json(raw.with_suffix(".meta.json"),provenance)
        save_json(processed.with_suffix(".meta.json"),provenance)
    assert file_fact(raw)==before
    rows.append(row)
report={"schema_version":1,"operation":"execute-authorized-four" if args.execute_four else "dry-run-no-png-written",
        "processor":file_fact(Path(__file__).resolve()),"rows":rows,
        "no_engine_no_import_no_gallery_no_system_binding":True,
        "root_authorization":"30m producer explicitly approved listed conservative protection boxes +256 padding for 00..03 only; 04 V1 held due aspect rejection",
        "raw_originals_sha_bytes_mtime_unchanged":True}
report_path=OUT/("processing_ACTUAL.json" if args.execute_four else "processing_DRY.json")
save_json(report_path,report)
print(json.dumps({"report":str(report_path),"sha256":sha(report_path.read_bytes()),
                  "rows":[{"id":r["id"],"cleared_a1":r["alpha1_outside_box_count"],"size":r["candidate_size"],"status":r["status"],"rgba_sha256":r.get("decoded_rgba_sha256")} for r in rows]}))
