"""Check frozen four + current04; emit small selected-input manifest, never pixels."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
old=json.loads((OUT/"processing_ACTUAL.json").read_text(encoding="utf-8"))
v4=json.loads((OUT/"bridge04_v4_alpha_floor_processing_ACTUAL.json").read_text(encoding="utf-8"))
geometry=json.loads((OUT/"source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
initial=json.loads((OUT/"source_geometry_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
assert geometry["bridges"][:4]==initial["bridges"][:4]
rows=[]
for row in old["rows"][:4]+[v4]:
    png=ROOT/row["game_candidate"]["path"]
    src=ROOT/row["raw"]["path"]
    source=Image.open(src);dest=Image.open(png)
    src_array=np.array(source);dst_array=np.array(dest)
    h,w=src_array.shape[:2]
    inner=dst_array[256:256+h,256:256+w]
    x0,y0,x1,y1=row["protection_box_xyxy_exclusive"]
    assert np.array_equal(src_array[:,:,:3],inner[:,:,:3])
    assert np.array_equal(src_array[y0:y1,x0:x1],inner[y0:y1,x0:x1])
    expected=row.get("decoded_rgba_sha256",row.get("rgba_sha256"))
    assert hashlib.sha256(dst_array.tobytes()).hexdigest()==expected
    assert hashlib.sha256(png.read_bytes()).hexdigest()==row["game_candidate"]["sha256"]
    assert hashlib.sha256(src.read_bytes()).hexdigest()==row["raw"]["sha256"]
    assert src.stat().st_mtime_ns==row["raw"]["mtime_ns"]
    if row["id"]!="bridge_04":
        assert png.stat().st_mtime_ns==row["game_candidate"]["mtime_ns"]
    rows.append({"id":row["id"],"version":4 if row["id"]=="bridge_04" else 1,
                 "raw":row["raw"],"runtime_input":row["game_candidate"],"rgba_sha256":expected,
                 "size":list(dest.size),"source_offset":[256,256],
                 "actual_a1_edits":row.get("alpha1_outside_box_count",row.get("alpha1_cleared_actual")),
                 "rgb_protected_rgba_exact":True,"max_alpha":int(dst_array[:,:,3].max())})
value={"schema_version":1,"selected":rows,"frozen_four_png_bytes_mtime_and_profile_values_unchanged":True,
       "current04":"V4; V1/V2/V3 not adopted; producer-reported V5 unconsumed",
       "profile_path":"game/build/world_bridges_20261030m_art01/source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json",
       "profile_sha256":hashlib.sha256((OUT/"source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json").read_bytes()).hexdigest(),
       "status":"PNG_SOURCE_READY_FOR_ROOT_ISOLATED_IMPORT_AND_SYSTEM_BINDING_NOT_ENGINE_PASS",
       "no_engine_no_gallery_no_collision_no_save_write":True}
path=OUT/"selected_five_V4_SOURCE_READY.json"
assert not path.exists()
path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(hashlib.sha256(path.read_bytes()).hexdigest())
