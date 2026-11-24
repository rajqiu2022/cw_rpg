"""Compact read-only report; no image or source writes."""
from pathlib import Path
from PIL import Image
from collections import Counter
import hashlib,json
root=Path(__file__).resolve().parents[3]
p=root/"assets/raw/luoyang_city_finish_20261022ap/portrait_luoyang_examiner_mature_same_sprite_20261022ap_v1.png"
with Image.open(p) as im:
    def sample(rect):
        pts=[(x,y,im.getpixel((x,y))) for y in range(rect[1],rect[3]) for x in range(rect[0],rect[2])]
        vivid=[v for v in pts if (v[2][0]>=120 and v[2][1]<=80 and v[2][2]<=80 and v[2][0]>=2*v[2][1]) or (v[2][0]>=100 and v[2][1]>=95 and v[2][2]<=50 and min(v[2][0:2])>=2*v[2][2])]
        h=Counter(v[2][3] for v in vivid)
        return {"rect_xyxy":rect,"pixels":len(pts),"vivid_red_yellow_count":len(vivid),"vivid_alpha_histogram":dict(sorted(h.items())),"vivid_alpha_ge8_count":sum(v[2][3]>=8 for v in vivid),"vivid_max_alpha":max((v[2][3] for v in vivid),default=None),"most_opaque_vivid_examples":[[x,y,list(rgba)] for x,y,rgba in sorted(vivid,key=lambda v:v[2][3],reverse=True)[:8]],"region_alpha_bins":{"zero":sum(v[2][3]==0 for v in pts),"1to7":sum(1<=v[2][3]<=7 for v in pts),"8to63":sum(8<=v[2][3]<=63 for v in pts),"64to255":sum(v[2][3]>=64 for v in pts)}}
    points=[[410,360],[400,370],[410,380],[420,390],[420,405],[408,374]]
    report={"raw_path":str(p.relative_to(root)).replace(chr(92),"/"),"raw_sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"raw_modified":False,"actual_size_px":list(im.size),"predicate":"R>=120,G<=80,B<=80,R>=2G OR R>=100,G>=95,B<=50,min(R,G)>=2B; excludes ordinary tan skin","regions":[sample([390,340,421,406]),sample([382,333,413,398]),sample([375,325,430,425])],"point_samples":[{"xy":xy,"rgba":list(im.getpixel(tuple(xy)))} for xy in points],"qa_composites":[{"path":str(f.relative_to(root)).replace(chr(92),"/"),"sha256":hashlib.sha256(f.read_bytes()).hexdigest(),"size_px":[1254,1254],"runtime_candidate":False} for f in [root/"prompts/qa/luoyang_city_finish_20261022ap_examiner/inspection/fullcanvas_true_alpha_white.png",root/"prompts/qa/luoyang_city_finish_20261022ap_examiner/inspection/fullcanvas_true_alpha_checker.png"]]}
print(json.dumps(report,ensure_ascii=True,indent=2))

