from pathlib import Path
from PIL import Image
import hashlib,json
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).parent
reports=[]
for key,stem in [('waiter','npc_zhuwei_inn_waiter'),('vendor','npc_zhuwei_vegetable_vendor')]:
    raw=ROOT/f'assets/raw/npc_hd_20261106/npc_{key}_hd_down_idle_20261106_v1.png'
    if not raw.exists():continue
    source=ROOT/f'game/art/characters/{stem}_idle_down_25d_4f_v2_runtime.png'
    with Image.open(raw) as im,Image.open(source) as old:
        w,h=im.size; assert im.mode=='RGBA'
        a=im.getchannel('A');oa=old.convert('RGBA').getchannel('A')
        b=[]; ob=[]
        for i in range(4):
            b.append(a.crop((i*w//4,0,(i+1)*w//4,h)).point(lambda x:255 if x>=24 else 0).getbbox())
            ob.append(oa.crop((i*160,0,(i+1)*160,160)).point(lambda x:255 if x>=24 else 0).getbbox())
        report={'id':f'npc_{key}_hd_down_idle_20261106_v1','raw_path':str(raw),'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'dimensions':[w,h],'mode':im.mode,'cols':4,'rows':1,'alpha24_boxes':b,'native_body_heights':[r[3]-r[1] for r in b],'source_boxes':ob,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'alpha1_count':a.histogram()[1],'model':None,'cost':None,'approved':False,'reason':'Root ART review pending; waiter face more handsome than original. No image mutations.','prompt_sha256':hashlib.sha256((ROOT/f'prompts/npc_hd_20261106/{key}_down_idle.txt').read_bytes()).hexdigest()}
        reports.append(report)
(OUT/'generated_candidate_measurements.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(reports,ensure_ascii=False,indent=2))
