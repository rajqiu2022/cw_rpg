"""Preserve 04V3 pixels; report real floor aspect failure independently of style."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
raw=ROOT/"assets/raw/world_bridges_20261030m/bridge_04_v3.png"
game=ROOT/"game/art/modules/world_bridges_20261030m/bridge_04.png"
previous=ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v2_padded.png"
processed=ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v3_padded.png"
box=[81,148,1397,978]

def fact(p):
    return {"path":p.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
            "bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns}

def new_json(p,data):
    assert not p.exists()
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

before=fact(raw);old_candidate=fact(game);archive=fact(previous)
assert game.read_bytes()==previous.read_bytes(),"Only replace explicitly rejected unbound V2 candidate"
assert old_candidate["sha256"]=="8fdc190b8a6e833cc83008fade6cf3ce0dc2e44ff86c3a5567ceb8325d91d53e"
im=Image.open(raw);assert im.mode=="RGBA"
src=np.array(im);h,w=src.shape[:2];x0,y0,x1,y1=box
outside=np.ones((h,w),bool);outside[y0:y1,x0:x1]=False
assert not np.any(outside & (src[:,:,3]>=2))
mask=outside & (src[:,:,3]==1)
altered=src.copy();altered[mask,3]=0
dst=np.zeros((h+512,w+512,4),np.uint8);dst[256:256+h,256:256+w]=altered
assert np.array_equal(src[:,:,:3],altered[:,:,:3])
assert np.array_equal(src[y0:y1,x0:x1],altered[y0:y1,x0:x1])
assert np.array_equal(src[src[:,:,3]>=2],altered[src[:,:,3]>=2])
assert not processed.exists()
Image.fromarray(dst,"RGBA").save(processed)
game.write_bytes(processed.read_bytes())
assert np.array_equal(np.array(Image.open(game)),dst)
assert fact(raw)==before and fact(previous)==archive
record={"schema_version":1,"id":"bridge_04","version":3,"raw":before,
        "raw_size":[w,h],"raw_alpha_max":int(src[:,:,3].max()),"raw_a1_margin_status":"FAIL_RETAINED",
        "protection_box_xyxy_exclusive":box,"alpha1_cleared_actual":int(mask.sum()),
        "padding_ltrb":[256]*4,"candidate_size":[w+512,h+512],"processed":fact(processed),
        "game_candidate":fact(game),"rgba_sha256":hashlib.sha256(dst.tobytes()).hexdigest(),
        "all_original_rgb_protected_rgba_and_ge2_rgba_exact":True,
        "unbound_v2_candidate_replaced_with_root_authority":old_candidate,"v2_processed_archive_preserved":archive,
        "status":"CANDIDATE_COPIED_NOT_ADOPTED_WIDTH_MISMATCH_GT15_NOT_DIMENSION_PASS"}
meta={"generation_backend":"builtin_image_gen","current_v3_builtin_calls":1,"model":None,"provider":None,"cost":None,
      "prior_discarded_versions":[{"version":1,"builtin_calls":1},{"version":2,"builtin_calls":1}],
      "promptset":"assets/staging/world_bridges_20261030m/production",
      "local_composite_reference_is_generated_output":False,"record":record}
new_json(raw.with_suffix(".meta.json"),meta)
new_json(processed.with_suffix(".meta.json"),meta)
new_json(OUT/"bridge04_v3_processing_ACTUAL.json",record)
profiles=json.loads((OUT/"source_geometry_ALL_FIVE_READY_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
profiles["bridges"][-1]={"id":"bridge_04","version":3,"raw_size":[w,h],"padded_size":[w+512,h+512],
      "game_candidate":"res://art/modules/world_bridges_20261030m/bridge_04.png",
      "deck_corners_raw":[[128,579],[1248,292],[1360,539],[221,837]],
      "open_end_centers_raw":{"west_south":[174.5,708],"east_north":[1304,415.5]},
      "clear_deck_interior_quad_raw":[[151,593],[1236,313],[1336,526],[238,815]],
      "rails_source_polygons_raw":{"far_north":[[94,499],[1233,161],[1250,296],[125,584]],
                                   "near_south":[[211,833],[1366,531],[1385,648],[238,965]]},
      "status":"REFERENCE_ONLY_ACTUAL_FLOOR_NARROW_UNIFORM_LENGTH_FIT_FAIL",
      "world_end_mapping":{"inventory_bank0_east_north":"east_north","inventory_bank1_west_south":"west_south"},
      "notes":"Measure only top floor between inner low-rail bases. Near front fascia extends to~y965 but is vertical face, not bridge floor; far rail post caps reachy160 but are not deck. V3 style looks broad but floor aspect still mismatches. Never include rail height/front fascia to fake width."}
row=profiles["bridges"][-1]
ends=np.array(list(row["open_end_centers_raw"].values()),float);delta=ends[1]-ends[0]
span=float(np.linalg.norm(delta));normal=np.array([-delta[1],delta[0]])/span
quad=np.array(row["deck_corners_raw"],float)
native_width=[abs(float(np.dot(quad[3]-quad[0],normal))),abs(float(np.dot(quad[2]-quad[1],normal)))]
target_length=275.99974056763824;scale=target_length/span
widths=[x*scale for x in native_width]
fit={"id":"bridge_04","version":3,"source_span":span,"target_world_span":target_length,
     "native_uniform_scale":scale,"source_perpendicular_widths":native_width,"fitted_world_end_widths":widths,
     "expected_world_width":100,"mean_world_width":sum(widths)/2,"mean_width_error_world_px":sum(widths)/2-100,
     "absolute_error_gt15":abs(sum(widths)/2-100)>15,"hand_measure_uncertainty_source_px":20,"reference_only_not_physics":True}
profiles["uniform_length_fit_reference"][-1]=fit
profiles["width_warning"]="04 V3 actual floor width under lengthfit remains >15px narrower than original100; copied candidate not adopted/dimension-pass. Do not include vertical fascia or rail cap height as floor width."
new_json(OUT/"source_geometry_ALL_FIVE_FINAL_REFERENCE_ONLY.json",profiles)
print(json.dumps({"processing":record,"fit":fit,"profile_sha256":hashlib.sha256((OUT/"source_geometry_ALL_FIVE_FINAL_REFERENCE_ONLY.json").read_bytes()).hexdigest()}))
