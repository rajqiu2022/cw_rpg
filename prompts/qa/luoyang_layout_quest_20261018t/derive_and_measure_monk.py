"""Authorized one-pass full-canvas representation resize; no generation or alpha editing."""
from pathlib import Path
import hashlib, json
from PIL import Image
ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/raw/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
ORIGINAL = Path("C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-ecbb1976-b989-4596-80b1-b29f05f90fd5.png")
TARGET = ROOT / "game/art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
EXPECTED = "49a326ba8636b47adf51041deaccc9659f5ab1ac5c920940fac1211afcc99955"
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def measure(image):
    alpha = image.getchannel("A")
    hist = alpha.histogram()
    bounds = {}
    for threshold in [1,8,64]:
        bounds[str(threshold)] = alpha.point(lambda p,t=threshold: 255 if p >= t else 0).getbbox()
    def edge(values):
        values = list(values)
        return {"total":len(values),"alpha_zero":values.count(0),"alpha_one":values.count(1),"alpha_nonzero":sum(x > 0 for x in values),"min":min(values),"max":max(values)}
    w,h=image.size
    edges={"top":edge(alpha.crop((0,0,w,1)).getdata()),"bottom":edge(alpha.crop((0,h-1,w,h)).getdata()),"left":edge(alpha.crop((0,0,1,h)).getdata()),"right":edge(alpha.crop((w-1,0,w,h)).getdata())}
    margins={k:([v[0],v[1],w-v[2],h-v[3]] if v else None) for k,v in bounds.items()}
    strict={k:(v is not None and v[0]>=w*.1 and v[1]>=h*.1 and w-v[2]>=w*.1 and h-v[3]>=h*.1) for k,v in bounds.items()}
    return {"mode":image.mode,"size_px":[w,h],"alpha_min":min(i for i,v in enumerate(hist) if v),"alpha_max":max(i for i,v in enumerate(hist) if v),"alpha_zero_count":hist[0],"alpha_one_count":hist[1],"alpha_2_to_7_count":sum(hist[2:8]),"bbox_alpha_ge":bounds,"margins_ltrb_px":margins,"ten_percent_margin_pass_by_alpha_ge":strict,"edges":edges}
assert sha(SOURCE) == EXPECTED
assert sha(ORIGINAL) == EXPECTED
assert not TARGET.exists(), "No overwrite or resize retry allowed"
with Image.open(SOURCE) as source:
    assert source.mode == "RGBA"
    raw = measure(source)
    # One complete-canvas resample. No crop, mask, threshold, alpha erasure, color adjustment or repaint.
    derived = source.resize((160,160), Image.Resampling.LANCZOS)
    TARGET.parent.mkdir(parents=True,exist_ok=True)
    derived.save(TARGET)
    runtime = measure(derived)
assert sha(SOURCE) == EXPECTED and sha(ORIGINAL) == EXPECTED
bbox=runtime["bbox_alpha_ge"]["1"]
height=bbox[3]-bbox[1]
scale=140.0/height
foot_true=(bbox[3]-80)*scale
nominal=.45*160*scale
report={"status":"GENERATED_CANDIDATE_REPRESENTATION_NOT_IMPORTED_NOT_RUNTIME","source_path":str(SOURCE),"original_tool_path":str(ORIGINAL),"target_path":str(TARGET),"source_sha256":sha(SOURCE),"target_sha256":sha(TARGET),"source_bytes":SOURCE.stat().st_size,"target_bytes":TARGET.stat().st_size,"raw":raw,"runtime":runtime,"resize":{"full_canvas":True,"resample":"Pillow.Image.Resampling.LANCZOS","resize_calls":1,"crop":False,"alpha_threshold_or_erasure":False,"color_adjustment":False,"source_modified":False},"actual_target_profile":{"frames":1,"hframes":1,"visible_height_alpha_gt0_px":height,"scale_for_140":scale,"alpha_gt0_height_after_scale":height*scale,"source_ground_anchor_candidate_px":[(bbox[0]+bbox[2])/2,bbox[3]],"nominal_ground_offset_045_canvas_after_scale":nominal,"actual_visual_bottom_offset_after_scale":foot_true,"noncalibrated_visual_foot_error_abs_px":abs(nominal-foot_true),"foot_error_le12":abs(nominal-foot_true)<=12,"body_160_calibrated_scale1_px":[22.4,28.8],"noncalibrated_body_at_measured_scale_px":[160*scale*.14,160*scale*.18]},"generation":{"execution_backend":"builtin_image_gen","model":None,"provider":None,"usage":None,"cost":None,"attempts_used":1,"retries_used":0,"fallback_used":False,"returned_fields":["image_url","output_hint"],"root_unique_call":True},"requested_size_not_actual":[1024,1024],"actual_size_mismatch_recorded":raw["size_px"] != [1024,1024],"all_failures_retained":"10percent margin target, actual canvas size and one-frame-only scope retained; no alpha cleanup or retry"}
print(json.dumps(report,ensure_ascii=True,indent=2))

