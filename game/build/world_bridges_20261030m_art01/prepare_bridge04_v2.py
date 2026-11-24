"""04 V2 exact processing only; V1 remains rejected and untouched."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
RAW=ROOT/"assets/raw/world_bridges_20261030m/bridge_04_v2.png"
V1=ROOT/"assets/raw/world_bridges_20261030m/bridge_04_v1.png"
BOX=[34,156,1410,976]
PAD=256

def fact(p):
    return {"path":p.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
            "bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns}

def save_json(p,data):
    assert not p.exists(),f"Refuse to overwrite {p}"
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

before=fact(RAW);v1_before=fact(V1)
im=Image.open(RAW);assert im.mode=="RGBA"
original=np.array(im);h,w=original.shape[:2]
x0,y0,x1,y1=BOX
outside=np.ones((h,w),dtype=bool);outside[y0:y1,x0:x1]=False
assert not np.any(outside & (original[:,:,3]>=2))
mask=outside & (original[:,:,3]==1)
processed=original.copy();processed[mask,3]=0
padded=np.zeros((h+PAD*2,w+PAD*2,4),dtype=np.uint8)
padded[PAD:PAD+h,PAD:PAD+w]=processed
checks={"original_rgb_all_exact":bool(np.array_equal(original[:,:,:3],processed[:,:,:3])),
        "protected_rgba_all_exact":bool(np.array_equal(original[y0:y1,x0:x1],processed[y0:y1,x0:x1])),
        "all_alpha_ge2_rgba_exact":bool(np.array_equal(original[original[:,:,3]>=2],processed[original[:,:,3]>=2])),
        "only_outside_alpha1_to_zero":bool(np.array_equal(np.any(original!=processed,axis=2),mask))}
assert all(checks.values())
destination=ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v2_padded.png"
game=ROOT/"game/art/modules/world_bridges_20261030m/bridge_04.png"
assert not destination.exists() and not game.exists()
destination.parent.mkdir(parents=True,exist_ok=True);game.parent.mkdir(parents=True,exist_ok=True)
Image.fromarray(padded,"RGBA").save(destination)
game.write_bytes(destination.read_bytes())
assert np.array_equal(np.array(Image.open(game)),padded)
yy,xx=np.nonzero(padded[:,:,3]>0)
bbox=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1]
fractions=[bbox[0]/padded.shape[1],bbox[1]/padded.shape[0],(padded.shape[1]-bbox[2])/padded.shape[1],(padded.shape[0]-bbox[3])/padded.shape[0]]
assert min(fractions)>=.10
record={"id":"bridge_04","version":2,"raw":before,"raw_size":[w,h],"raw_mode":"RGBA",
        "raw_alpha_max":int(original[:,:,3].max()),"raw_original_a1_margin_status":"FAIL_RETAINED",
        "protection_box_xyxy_exclusive":BOX,"actual_alpha1_cleared":int(mask.sum()),
        "padding_ltrb":[PAD]*4,"source_offset":[PAD,PAD],"candidate_size":[w+2*PAD,h+2*PAD],
        "processed":fact(destination),"game_candidate":fact(game),"rgba_sha256":hashlib.sha256(padded.tobytes()).hexdigest(),
        "pixel_invariants":checks,"candidate_margin_fraction_ltrb":fractions,
        "status":"PNG_CANDIDATE_ONLY_WIDTH_MATCH_NOT_ACCEPTED_NOT_IMPORTED_NOT_BOUND",
        "rejected_v1":v1_before,"rejected_v1_reason":"Producer rejected V1 floor aspect; raw retained, no V1 processed/game image"}
metadata={"schema_version":1,"generation_backend":"builtin_image_gen","current_v2_builtin_call_count":1,
          "model":None,"provider":None,"cost":None,"prior_v1_builtin_call_count":1,
          "promptset":"assets/staging/world_bridges_20261030m/production",
          "local_composite_reference_is_generation":False,
          "processing":"Only protected-box-outside alpha=1 to zero, 256 RGBA0 padding each edge; entire original RGB and protected RGBA retained; no crop/scale/repaint.",
          "record":record}
save_json(RAW.with_suffix(".meta.json"),metadata)
save_json(destination.with_suffix(".meta.json"),metadata)
save_json(V1.with_suffix(".meta.json"),{"generation_backend":"builtin_image_gen","builtin_call_count":1,
          "model":None,"provider":None,"cost":None,"status":"DISCARDED_V1_RAW_RETAINED_NO_PIXEL_EDITS_NO_GAME_CONSUMER",
          "raw":v1_before,"superseded_by":before["path"],"reason":record["rejected_v1_reason"]})
assert fact(RAW)==before and fact(V1)==v1_before
save_json(OUT/"bridge04_v2_processing_ACTUAL.json",record)
geometry=json.loads((OUT/"source_geometry_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
geometry["bridges"][-1]={"id":"bridge_04","version":2,"raw_size":[w,h],"padded_size":[w+512,h+512],
      "game_candidate":"res://art/modules/world_bridges_20261030m/bridge_04.png",
      "deck_corners_raw":[[48,514],[1250,277],[1390,586],[177,889]],
      "open_end_centers_raw":{"west_south":[112.5,701.5],"east_north":[1320,431.5]},
      "clear_deck_interior_quad_raw":[[181,555],[1223,330],[1306,550],[264,777]],
      "rails_source_polygons_raw":{"far_north":[[98,435],[1236,166],[1266,297],[113,557]],
                                   "near_south":[[190,745],[1363,486],[1398,687],[225,914]]},
      "status":"REFERENCE_ONLY_UNIFORM_LENGTH_WIDTH_MISMATCH_NEEDS_SYSTEM_REVIEW",
      "notes":"Wider V2, still check actual aspect against original 100px deck width; do not nonuniformly stretch or change NAV to hide mismatch."}
inventory=json.loads((ROOT/"game/build/world_bridges_20261030m_system01/bridge_inventory_READY.json").read_text(encoding="utf-8-sig"))
fit=[]
for source,world in zip(geometry["bridges"],inventory["bridges"]):
    ends=np.array(list(source["open_end_centers_raw"].values()),dtype=float)
    world_ends=np.array(world["deck_surface_bank_centers_world_px"],dtype=float)
    axis=ends[1]-ends[0];length=float(np.linalg.norm(axis));axis/=length
    normal=np.array([-axis[1],axis[0]])
    quad=np.array(source["deck_corners_raw"],dtype=float)
    # Corners are far-A, far-B, near-B, near-A for these measured assets.
    widths=[abs(float(np.dot(quad[3]-quad[0],normal))),abs(float(np.dot(quad[2]-quad[1],normal)))]
    world_length=float(np.linalg.norm(world_ends[1]-world_ends[0]))
    scale=world_length/length
    actual_widths=[x*scale for x in widths]
    wanted=float(world["original_route_width_px"])
    fit.append({"id":source["id"],"raw_center_span":length,"original_world_center_span":world_length,
                "uniform_length_fit_scale":scale,"world_widths_at_two_open_ends":actual_widths,
                "original_world_width":wanted,"mean_world_width":sum(actual_widths)/2,
                "mean_width_error_world_px":sum(actual_widths)/2-wanted,
                "absolute_error_gt15":abs(sum(actual_widths)/2-wanted)>15,
                "measurement_only_not_final_geometry_or_physics":True})
geometry["uniform_length_fit_reference"]=fit
save_json(OUT/"source_geometry_ALL_FIVE_REFERENCE_ONLY.json",geometry)
print(json.dumps({"record":record,"fit":fit}))
