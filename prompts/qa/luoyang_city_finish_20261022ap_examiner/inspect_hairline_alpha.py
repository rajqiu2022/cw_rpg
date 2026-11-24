"""QA display compositing only; raw is never written/cropped/resized/padded."""
from pathlib import Path
from PIL import Image
from collections import Counter
import hashlib,json
root=Path(__file__).resolve().parents[3]
raw=root/"assets/raw/luoyang_city_finish_20261022ap/portrait_luoyang_examiner_mature_same_sprite_20261022ap_v1.png"
out=root/"prompts/qa/luoyang_city_finish_20261022ap_examiner/inspection"
assert not out.exists(), "Never overwrite inspection evidence"
before=hashlib.sha256(raw.read_bytes()).hexdigest()
assert before=="4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc"
out.mkdir()
with Image.open(raw) as source:
    assert source.mode=="RGBA"
    w,h=source.size
    white=Image.new("RGBA",source.size,(255,255,255,255))
    white.alpha_composite(source)
    white.convert("RGB").save(out/"fullcanvas_true_alpha_white.png")
    checker=Image.new("RGBA",source.size)
    checker.putdata([((232,232,232,255) if ((x//24+y//24)%2==0) else (180,180,180,255)) for y in range(h) for x in range(w)])
    checker.alpha_composite(source)
    checker.convert("RGB").save(out/"fullcanvas_true_alpha_checker.png")
    def roi(rect):
        x0,y0,x1,y1=rect
        points=[(x,y,source.getpixel((x,y))) for y in range(y0,y1) for x in range(x0,x1)]
        hist=Counter(p[2][3] for p in points)
        # Isolate conspicuous red/yellow/green-tinted hidden-color pixels, not normal tan skin.
        suspect=[p for p in points if ((p[2][0]>=120 and p[2][1]<85 and p[2][2]<85) or (p[2][0]>=110 and p[2][1]>=95 and p[2][2]<65))]
        shist=Counter(p[2][3] for p in suspect)
        return {"rect_xyxy":rect,"pixel_count":len(points),"alpha_histogram":dict(sorted(hist.items())),"warm_suspect_predicate":"R>=120,G<85,B<85 OR R>=110,G>=95,B<65","suspect_count":len(suspect),"suspect_alpha_histogram":dict(sorted(shist.items())),"suspect_alpha_ge8_count":sum(p[2][3]>=8 for p in suspect),"suspect_alpha_ge64_count":sum(p[2][3]>=64 for p in suspect),"suspect_max_alpha":max([p[2][3] for p in suspect],default=None),"suspect_examples":[[x,y,list(rgba)] for x,y,rgba in sorted(suspect,key=lambda p:p[2][3],reverse=True)[:20]]}
    points=[[390,340],[400,350],[410,360],[400,370],[410,380],[420,390],[420,405],[398,372],[408,374]]
    report={"status":"READ_ONLY_RGBA_AND_QA_COMPOSITES_NOT_ASSET_EDITS","raw_sha256_before":before,"actual_size_px":[w,h],"root_coordinates_direct":roi([390,340,421,406]),"scaled_preview_1280_to_actual1254_roi":roi([382,333,413,398]),"expanded_hairline_roi":roi([375,325,430,425]),"point_samples":[{"xy":p,"rgba":list(source.getpixel(tuple(p)))} for p in points],"qa_composites":[{"path":str(p.relative_to(root)).replace(chr(92),"/"),"size_px":[w,h],"mode":"RGB","purpose":"True alpha source-over opaque display only; NOT runtime candidate","sha256":hashlib.sha256(p.read_bytes()).hexdigest()} for p in [out/"fullcanvas_true_alpha_white.png",out/"fullcanvas_true_alpha_checker.png"]],"raw_sha256_after":hashlib.sha256(raw.read_bytes()).hexdigest(),"raw_modified":False,"no_cropping_resizing_padding_color_erasure":True}
print(json.dumps(report,ensure_ascii=True,indent=2))

