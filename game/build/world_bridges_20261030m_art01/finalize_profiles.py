"""Read-only geometry arithmetic; cyclic corners differ between EW and NS views."""
from pathlib import Path
import hashlib
import json
import numpy as np

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
draft=json.loads((OUT/"source_geometry_ALL_FIVE_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
inventory=json.loads((ROOT/"game/build/world_bridges_20261030m_system01/bridge_inventory_READY.json").read_text(encoding="utf-8-sig"))
draft["prior_arithmetic_failure_retained"]="source_geometry_ALL_FIVE_REFERENCE_ONLY.json initial fit wrongly paired long edges as end width for NS01..03; reference coordinates intact, use this corrected READY arithmetic only"
fits=[]
for b,world in zip(draft["bridges"],inventory["bridges"]):
    ends=np.array(list(b["open_end_centers_raw"].values()),dtype=float)
    delta=ends[1]-ends[0];length=float(np.linalg.norm(delta));axis=delta/length
    normal=np.array([-axis[1],axis[0]])
    q=np.array(b["deck_corners_raw"],dtype=float)
    pairs=[(3,0),(2,1)] if b["id"] in ["bridge_00","bridge_04"] else [(1,0),(2,3)]
    raw_widths=[abs(float(np.dot(q[a]-q[c],normal))) for a,c in pairs]
    world_ends=np.array(world["deck_surface_bank_centers_world_px"],dtype=float)
    target_length=float(np.linalg.norm(world_ends[1]-world_ends[0]))
    scale=target_length/length;widths=[v*scale for v in raw_widths]
    expected=float(world["original_route_width_px"])
    result={"id":b["id"],"source_span":length,"target_world_span":target_length,
            "native_uniform_scale":scale,"end_corner_pairs":pairs,
            "source_perpendicular_widths":raw_widths,"fitted_world_end_widths":widths,
            "expected_world_width":expected,"mean_world_width":sum(widths)/2,
            "mean_width_error_world_px":sum(widths)/2-expected,
            "absolute_error_gt15":abs(sum(widths)/2-expected)>15,
            "hand_measure_uncertainty_source_px":20,"reference_only_not_physics":True}
    fits.append(result)
draft["uniform_length_fit_reference"]=fits
draft["width_warning"]="04 V2 mean uniform-fit width~81 vs original100: ~19px deficit exceeds15px criterion. Do not stretch image, change NAV or claim dimensions accepted; System/Root review needed."
target=OUT/"source_geometry_ALL_FIVE_READY_REFERENCE_ONLY.json"
assert not target.exists()
target.write_text(json.dumps(draft,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"path":str(target),"sha256":hashlib.sha256(target.read_bytes()).hexdigest(),"fit":fits}))
