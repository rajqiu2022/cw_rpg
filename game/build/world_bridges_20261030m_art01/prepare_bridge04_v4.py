"""04V4: inspect real alpha, preserve hidden RGB, process only authorized A1+padding."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
raw=ROOT/"assets/raw/world_bridges_20261030m/bridge_04_v4.png"
game=ROOT/"game/art/modules/world_bridges_20261030m/bridge_04.png"
processed=ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v4_padded.png"
previous=ROOT/"assets/processed/world_bridges_20261030m/bridge_04_v3_padded.png"
box=[155,118,1487,962]
quad=np.array([[204,548],[1267,280],[1410,620],[344,900]],dtype=float)
ends=np.array([(quad[0]+quad[3])/2,(quad[1]+quad[2])/2])
delta=ends[1]-ends[0];span=float(np.linalg.norm(delta));normal=np.array([-delta[1],delta[0]])/span
scale=275.99974056763824/span
widths=[abs(float(np.dot(quad[3]-quad[0],normal)))*scale,abs(float(np.dot(quad[2]-quad[1],normal)))*scale]
fit={"basis":"Full top deck/support plane including hidden edge strip beneath low rails; not post cap height/front vertical fascia. Corners supplied by Root native view and manually checked as approximate outer footprint, uncertainty20px. Visible clear interior is separately provided and narrower.",
     "source_span":span,"target_world_span":275.99974056763824,"uniform_scale":scale,
     "fitted_world_outer_widths":widths,"mean_world_outer_width":sum(widths)/2,
     "original_world_outer_width":100,"mean_error_world_px":sum(widths)/2-100,
     "absolute_mean_error_le15":abs(sum(widths)/2-100)<=15,"not_physics_clearance_or_exact_native_adoption":True}
assert fit["absolute_mean_error_le15"]

def fact(p):
    return {"path":p.relative_to(ROOT).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
            "bytes":p.stat().st_size,"mtime_ns":p.stat().st_mtime_ns}

def save(p,data):
    assert not p.exists(),f"Refuse overwrite: {p}"
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

before=fact(raw);archive=fact(previous);replaced=fact(game)
assert game.read_bytes()==previous.read_bytes()
im=Image.open(raw);assert im.mode=="RGBA"
src=np.array(im);h,w=src.shape[:2];a=src[:,:,3]
points=[(650,200),(800,200),(1000,150),(300,360),(100,600),(450,960),(1400,750)]
regions=[(500,100,800,200),(650,160,900,230),(25,500,130,750),(400,950,800,1024),(1300,750,1500,950)]
zones=[]
for x0,y0,x1,y1 in regions:
    alpha=a[y0:y1,x0:x1]
    zones.append({"rect_xyxy":[x0,y0,x1,y1],"pixels":int(alpha.size),"alpha_min_max":[int(alpha.min()),int(alpha.max())],
                  "alpha0":int((alpha==0).sum()),"alpha1":int((alpha==1).sum()),"alpha_ge2":int((alpha>=2).sum())})
counts={"0":int((a==0).sum()),"1":int((a==1).sum()),"2..7":int(((a>=2)&(a<=7)).sum()),
        "8..31":int(((a>=8)&(a<=31)).sum()),"32..127":int(((a>=32)&(a<=127)).sum()),
        "128..253":int(((a>=128)&(a<=253)).sum()),"254":int((a==254).sum()),"255":int((a==255).sum())}
x0,y0,x1,y1=box
outside=np.ones((h,w),bool);outside[y0:y1,x0:x1]=False
assert not np.any(outside & (a>=2))
mask=outside & (a==1)
altered=src.copy();altered[mask,3]=0
dst=np.zeros((h+512,w+512,4),np.uint8);dst[256:256+h,256:256+w]=altered
assert np.array_equal(src[:,:,:3],altered[:,:,:3])
assert np.array_equal(src[y0:y1,x0:x1],altered[y0:y1,x0:x1])
assert np.array_equal(src[a>=2],altered[a>=2])
assert not processed.exists()
Image.fromarray(dst,"RGBA").save(processed)
game.write_bytes(processed.read_bytes())
decoded=np.array(Image.open(game));inner=decoded[256:256+h,256:256+w]
assert np.array_equal(decoded,dst)
assert np.array_equal(inner[:,:,:3],src[:,:,:3])
assert np.array_equal(inner[y0:y1,x0:x1],src[y0:y1,x0:x1])
changed=np.any(inner!=src,axis=2)
assert int(changed.sum())==int(mask.sum()) and np.all(src[changed,3]==1) and np.all(inner[changed,3]==0)
assert fact(raw)==before and fact(previous)==archive
record={"schema_version":1,"id":"bridge_04","version":4,"raw":before,"raw_size":[w,h],
        "alpha_min_max":[int(a.min()),int(a.max())],"alpha_histogram_bins":counts,
        "hidden_nonblack_rgb_alpha0_pixels":int(((a==0)&(src[:,:,:3].max(axis=2)>0)).sum()),
        "halo_rgba_samples":[{"xy":list(p),"rgba":src[p[1],p[0]].tolist()} for p in points],
        "halo_sampled_regions":zones,"halo_conclusion":"Sampled broad halo is alpha0 hidden RGB, not opaque matte; no background-removal edit authorized or executed. Not a claim about every unnamed region.",
        "raw_a1_margin_status":"FAIL_RETAINED","original_max_alpha_254_not_normalized":True,
        "protection_box_xyxy_exclusive":box,"alpha1_cleared_actual":int(mask.sum()),"padding_ltrb":[256]*4,
        "candidate_size":[w+512,h+512],"processed":fact(processed),"game_candidate":fact(game),
        "rgba_sha256":hashlib.sha256(dst.tobytes()).hexdigest(),
        "original_rgb_including_hidden_rgb_protected_rgba_and_ge2_rgba_exact":True,
        "pixel_check_redecoded_after_write":True,"floor_fit_reference":fit,
        "v3_processed_preserved":archive,"replaced_unbound_v3_candidate":replaced,
        "status":"V4_PNG_CANDIDATE_OUTER_FLOOR_RATIO_REFERENCE_WITHIN15_NOT_ENGINE_OR_PHYSICS_PASS",
        "producer_disclosed_v5":"Producer reports one built-in background edit occurred before alpha0 evidence arrived; result not copied or adopted. Unknown generated-output path, not independently inspected here; no false pixel-preservation claim."}
meta={"generation_backend":"builtin_image_gen","current_v4_builtin_calls":1,"model":None,"provider":None,"cost":None,
      "prior_discarded_versions":[1,2,3],"prior_calls_each":1,
      "promptset":"assets/staging/world_bridges_20261030m/production",
      "local_composite_reference_is_generated_output":False,"record":record}
save(raw.with_suffix(".meta.json"),meta);save(processed.with_suffix(".meta.json"),meta)
save(OUT/"bridge04_v4_alpha_floor_processing_ACTUAL.json",record)
profiles=json.loads((OUT/"source_geometry_ALL_FIVE_FINAL_REFERENCE_ONLY.json").read_text(encoding="utf-8"))
profiles["bridges"][-1]={"id":"bridge_04","version":4,"raw_size":[w,h],"padded_size":[w+512,h+512],
      "game_candidate":"res://art/modules/world_bridges_20261030m/bridge_04.png",
      "deck_corners_raw":quad.tolist(),
      "open_end_centers_raw":{"west_south":ends[0].tolist(),"east_north":ends[1].tolist()},
      "clear_deck_interior_quad_raw":[[230,580],[1283,305],[1380,568],[335,835]],
      "rails_source_polygons_raw":{"far_north":[[168,432],[1260,129],[1318,287],[200,576]],
                                   "near_south":[[296,794],[1420,472],[1476,655],[324,950]]},
      "world_end_mapping":{"inventory_bank0_east_north":"east_north","inventory_bank1_west_south":"west_south"},
      "source_foot_warning":"The complete support-plane outer width includes hidden strips beneath rails. Clear interior quad is narrower. Never use visual rail envelope as a ground solid; final contact/body proof is System/Root responsibility.",
      "status":"MANUAL_REFERENCE_ONLY_OUTER_FLOOR_LENGTH_FIT_WITHIN15_NO_PHYSICS_CLAIM"}
profiles["uniform_length_fit_reference"][-1]={"id":"bridge_04","version":4,**fit}
profiles["width_warning"]="V4 outer support-plane widthfit is within15px of original100. This does not certify visible inner-floor width, body margin or exact physics. Prior V1/V2/V3 rejections retained, no source image stretched or NAV changed."
save(OUT/"source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json",profiles)
print(json.dumps({"record":record,"profile_sha256":hashlib.sha256((OUT/"source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json").read_bytes()).hexdigest()}))
