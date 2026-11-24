"""Exactly two user-authorized v2 cutouts: exterior weak-alpha cleanup and padding only.

No crop, resize, colour change, generative edit, imports, engine, or old-asset processing.
Original RGB everywhere and complete protected RGBA are preserved. Refuse overwrite.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "assets/raw/luoyang_city_space_20261024b"
OUT = ROOT / "assets/processed/luoyang_city_space_20261024b"
JOBS = [
    {"id": "apothecary", "sha": "ab3b5bfb8b35386c4521d8ea60fa912edb14c397250682409f6a14fda173cfd3", "size": [1563,1006], "protect": [40,105,1525,935], "pad": [196,126], "door": [653,482,907,810], "threshold": [780,823], "front_ground": [780,922], "base_polygons": [[[195,794],[560,794],[560,827],[195,827]],[[1000,794],[1360,794],[1360,827],[1000,827]]]},
    {"id": "bookshop", "sha": "1f1a081cbda2ca85cf763e57cf267301dd7c873d5a7c7341c2751d99bbf32169", "size": [1562,1007], "protect": [59,105,1517,925], "pad": [196,126], "door": [715,535,950,809], "threshold": [832.5,823], "front_ground": [785,912], "base_polygons": [[[180,793],[606,793],[606,830],[180,830]],[[1010,792],[1334,792],[1334,830],[1010,830]]]},
]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

targets = []
for j in JOBS:
    stem = "luoyang_20261024b_complete_" + j["id"] + "_v2_clean_padded"
    targets.extend([OUT / (stem + ".png"), OUT / (stem + ".meta.json"), OUT / (stem + ".alpha_inverse.json")])
targets.append(OUT / "processing_report.json")
assert not any(p.exists() for p in targets), "Refuse output overwrite"
OUT.mkdir(parents=True, exist_ok=True)
results = []
for j in JOBS:
    src = RAW / ("luoyang_20261024b_complete_" + j["id"] + "_v2_edit.png")
    assert sha(src) == j["sha"]
    im = Image.open(src)
    assert im.mode == "RGBA" and list(im.size) == j["size"]
    before = im.tobytes()
    edited = bytearray(before)
    w,h = im.size
    x0,y0,x1,y1 = j["protect"]
    changed = []
    for y in range(h):
        for x in range(w):
            if x0 <= x < x1 and y0 <= y < y1: continue
            k = (y*w+x)*4+3
            a = before[k]
            if 1 <= a <= 15:
                changed.append([x,y,a])
                edited[k] = 0
            else:
                assert a == 0, "Refuse to erase strong alpha outside fixed protection"
    clean = Image.frombytes("RGBA", im.size, bytes(edited))
    assert clean.crop(tuple(j["protect"])).tobytes() == im.crop(tuple(j["protect"])).tobytes()
    assert all(edited[k] == before[k] for k in range(len(before)) if k % 4 != 3)
    inverse = bytearray(edited)
    for x,y,a in changed: inverse[(y*w+x)*4+3] = a
    assert bytes(inverse) == before
    px,py = j["pad"]
    padded = Image.new("RGBA", (w+2*px,h+2*py), (0,0,0,0))
    padded.paste(clean, (px,py))
    bbox = padded.getchannel("A").getbbox()
    margins = [bbox[0]/padded.width,bbox[1]/padded.height,(padded.width-bbox[2])/padded.width,(padded.height-bbox[3])/padded.height]
    assert min(margins) >= .10
    stem = "luoyang_20261024b_complete_"+j["id"]+"_v2_clean_padded"
    png = OUT / (stem+".png")
    padded.save(png)
    reloaded = Image.open(png)
    assert reloaded.tobytes() == padded.tobytes()
    assert reloaded.crop((px,py,px+w,py+h)).tobytes() == bytes(edited)
    assert sha(src) == j["sha"]
    door = j["door"]
    shift_point = lambda p: [p[0]+px,p[1]+py]
    shifted_door = [door[0]+px,door[1]+py,door[2]+px,door[3]+py]
    base = [[shift_point(p) for p in poly] for poly in j["base_polygons"]]
    alpha_samples = [[reloaded.getpixel((int(x),int(y)))[3] for x,y in poly] for poly in base]
    bw,bh = bbox[2]-bbox[0],bbox[3]-bbox[1]
    scale = 145/(door[3]-door[1])
    metadata = {
        "id": j["id"], "status": "AUTHORIZED_TWO_V2_LOCAL_CLEANUP_PADDING_ONLY_NOT_RUNTIME_ADMISSION",
        "source": str(src), "source_sha256": j["sha"], "output": str(png), "output_sha256": sha(png),
        "source_size": [w,h], "output_size": list(padded.size), "fixed_protection_xyxy_source": j["protect"],
        "protection_rgba_byte_equal": True, "all_original_rgb_byte_equal": True,
        "alpha_changes_only_external_1_through_15_to_zero": True, "external_alpha_changes": len(changed),
        "original_pixel_inverse_byte_equal": True, "padding_offset": [px,py],
        "complete_a1_bbox_xyxy": list(bbox), "complete_a1_size": [bw,bh], "four_margin_fractions": margins,
        "complete_a1_ten_percent_margin_pass": True,
        "manual_door_clear_xyxy_output_NOT_geometry": shifted_door,
        "manual_door_threshold_output_NOT_geometry": shift_point(j["threshold"]),
        "manual_front_step_ground_output_NOT_geometry": shift_point(j["front_ground"]),
        "manual_front_foundation_strip_polygons_output_NOT_full_building_collision": base,
        "foundation_vertex_alpha_samples": alpha_samples,
        "minimum_uniform_scale_for_conservative_manual_door_145": scale,
        "at_that_scale_complete_a1_world_size": [bw*scale,bh*scale],
        "placement_rule": "Keep original pixel scale; shift source anchors and polygon points by padding offset. Do not fit new canvas to old full-canvas width, which would shrink the real building.",
        "one_storey_only": True,
        "limitations": ["Manual conservative opening and foundation strips are authoring hints, not engine/physics validation or complete footprint.", "Window counters are not extra doors. Roof is not a second storey.", "No formal source, scene, import, task, NPC or world write by processing script."]
    }
    (OUT/(stem+".meta.json")).write_text(json.dumps(metadata,indent=2)+"\n",encoding="utf-8")
    (OUT/(stem+".alpha_inverse.json")).write_text(json.dumps({"original_size":[w,h],"padding":[px,py],"changed_external_alpha_x_y_original":changed,"original_rgba_sha256":hashlib.sha256(before).hexdigest()},separators=(",",":"))+"\n",encoding="utf-8")
    results.append(metadata)
report = {"scope":"Only two exact v2 hashes AB3B/1F1A, user explicitly authorized local cleanup and padding", "image_generation_calls_this_script":0,"engine_runs":0,"images":results}
(OUT/"processing_report.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print(json.dumps(report,indent=2))
