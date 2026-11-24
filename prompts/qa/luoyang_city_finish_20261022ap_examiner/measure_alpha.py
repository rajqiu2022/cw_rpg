"""Read-only alpha QA. Never edits or saves PNGs."""
from pathlib import Path
from PIL import Image
import json, hashlib
root=Path(__file__).resolve().parents[3]
p=root/"assets/raw/luoyang_city_finish_20261022ap/portrait_luoyang_examiner_mature_same_sprite_20261022ap_v1.png"
with Image.open(p) as im:
    assert im.mode == "RGBA"
    a=im.getchannel("A"); w,h=im.size; hist=a.histogram()
    bounds={}; margins={}; passes={}
    for threshold in [1,8,64]:
        box=a.point(lambda n,t=threshold:255 if n>=t else 0).getbbox()
        key=str(threshold); bounds[key]=box
        margins[key]=[box[0],box[1],w-box[2],h-box[3]] if box else None
        passes[key]=bool(box and all(v >= extent*.1 for v,extent in zip(margins[key],[w,h,w,h])))
    edges={}
    for name,box in {"top":(0,0,w,1),"bottom":(0,h-1,w,h),"left":(0,0,1,h),"right":(w-1,0,w,h)}.items():
        values=list(a.crop(box).get_flattened_data())
        edges[name]={"total":len(values),"alpha_zero":values.count(0),"alpha_one":values.count(1),"nonzero":sum(x>0 for x in values),"max":max(values)}
    print(json.dumps({"path":str(p.relative_to(root)).replace(chr(92),"/"),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"bytes":p.stat().st_size,"actual_size_px":[w,h],"mode":im.mode,"requested_size_px":[1024,1024],"requested_size_exact":[w,h]==[1024,1024],"alpha_extrema":a.getextrema(),"alpha_zero_count":hist[0],"alpha_one_count":hist[1],"alpha_2_to_7_count":sum(hist[2:8]),"bbox_alpha_ge":bounds,"margins_ltrb_px":margins,"strict_ten_percent_margin_pass_by_alpha_ge":passes,"edge_alpha":edges,"png_modified":False,"runtime_ready":False},ensure_ascii=True,indent=2))

