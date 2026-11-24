"""Independent read-only pixel verification of the two authorized derived shop PNGs."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/"assets/processed/luoyang_city_space_20261024b"
checks=0
def need(value,label):
    global checks
    checks+=1
    assert value,label
rows=[]
for kind,original_sha,png_sha in [
    ("apothecary","ab3b5bfb8b35386c4521d8ea60fa912edb14c397250682409f6a14fda173cfd3","8b19a70dcaaed76f0aa5081b089caf56b584708ef71ad7870a4d0d79ef75ed5a"),
    ("bookshop","1f1a081cbda2ca85cf763e57cf267301dd7c873d5a7c7341c2751d99bbf32169","dd49811ce57208db2d7045f3a61d8515808d8b2604d1816124f688bcb4314eeb")
]:
    stem="luoyang_20261024b_complete_"+kind+"_v2_clean_padded"
    meta=json.loads((OUT/(stem+".meta.json")).read_text())
    inv=json.loads((OUT/(stem+".alpha_inverse.json")).read_text())
    src=Path(meta["source"])
    png=OUT/(stem+".png")
    need(hashlib.sha256(src.read_bytes()).hexdigest()==original_sha,"Original raw SHA unchanged")
    need(hashlib.sha256(png.read_bytes()).hexdigest()==png_sha,"Exact derived PNG")
    old=Image.open(src)
    new=Image.open(png)
    need(old.mode==new.mode=="RGBA","RGBA without conversion")
    w,h=old.size
    px,py=meta["padding_offset"]
    original=old.tobytes()
    region=new.crop((px,py,px+w,py+h))
    actual=region.tobytes()
    need(len(actual)==len(original),"Original canvas retained at exact size")
    inverse=bytearray(actual)
    changed=inv["changed_external_alpha_x_y_original"]
    seen=set()
    x0,y0,x1,y1=meta["fixed_protection_xyxy_source"]
    for x,y,a in changed:
        need((x,y) not in seen and not (x0<=x<x1 and y0<=y<y1) and 1<=a<=15,"Unique weak exterior alpha change only")
        seen.add((x,y))
        k=(y*w+x)*4+3
        need(actual[k]==0 and original[k]==a,"Exact old/new alpha operands")
        inverse[k]=a
    need(bytes(inverse)==original,"All old RGBA pixel inverse exact")
    need(region.crop((x0,y0,x1,y1)).tobytes()==old.crop((x0,y0,x1,y1)).tobytes(),"All protected RGBA exact")
    need(all(actual[k]==original[k] for k in range(len(original)) if k%4!=3),"Every original RGB byte unchanged")
    data=new.tobytes()
    for y in range(new.height):
        for x in range(new.width):
            if px<=x<px+w and py<=y<py+h: continue
            k=(y*new.width+x)*4
            if data[k:k+4] != b"\0\0\0\0": raise AssertionError("Nonzero padding RGBA")
    need(True,"Every newly added padding RGBA is zero")
    bbox=new.getchannel("A").getbbox()
    margins=[bbox[0]/new.width,bbox[1]/new.height,(new.width-bbox[2])/new.width,(new.height-bbox[3])/new.height]
    need(list(bbox)==meta["complete_a1_bbox_xyxy"] and min(margins)>=.10,"Complete A>0 margins, no threshold masking")
    rows.append({"id":kind,"raw_sha256":original_sha,"derived_png_sha256":png_sha,"changed_alpha_count":len(changed),"protected_rgba_equal":True,"all_old_rgb_equal":True,"pixel_inverse_equal":True,"padding_rgba_zero":True,"complete_a1_bbox":list(bbox),"margins":margins})
report={"status":"INDEPENDENT_TWO_AUTHORIZED_V2_PIXEL_INVERSE_PASS_NOT_RUNTIME","checks":checks,"failures":[],"rows":rows,"image_writes":0,"engine_runs":0,"formal_writes":0}
path=Path(__file__).with_name("independent_two_v2_pixel_verification.json")
need(not path.exists(),"Refuse report overwrite")
report["checks"]=checks
with path.open("x",encoding="utf-8") as file: file.write(json.dumps(report,indent=2)+"\n")
print(json.dumps({"status":report["status"],"checks":checks,"failures":0,"report":str(path),"report_sha256":hashlib.sha256(path.read_bytes()).hexdigest()},indent=2))
