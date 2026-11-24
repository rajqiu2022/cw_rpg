from pathlib import Path
import hashlib,json,shutil
import numpy as np
from PIL import Image

R=Path(__file__).resolve().parents[3]; O=Path(__file__).parent
G=Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8')
RAW=R/'assets/raw/interior_identity_20261106'; RAW.mkdir(parents=True,exist_ok=True)
ROWS=[('yihongyuan_luxury_shell','exec-eb3c8d40-8e5a-4909-b8f6-0d5ef51966eb.png'),('inn_premium_shell','exec-626a673f-70ff-4b65-9b05-873f02a32c33.png'),('inn_common_shell','exec-0da85173-198b-46d0-81fe-ed88f0a5134c.png')]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
reports=[]
for role,name in ROWS:
    source=G/name; dest=RAW/(role+'_v1.png')
    if dest.exists(): assert sha(dest)==sha(source)
    else: shutil.copyfile(source,dest)
    im=Image.open(dest); pix=np.array(im.convert('RGBA')); a=pix[:,:,3]; h,w=a.shape
    ys,xs=np.where(a>=24); bbox=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
    border=np.concatenate([a[0,:],a[-1,:],a[:,0],a[:,-1]])
    alpha_detail={'global_max':int(a.max()),'subject_ge24_percentiles':np.percentile(a[a>=24],[0,25,50,75,95,100]).tolist(),'floor_patch_xyxy':[680,650,850,780],'floor_alpha_percentiles':np.percentile(a[650:780,680:850],[0,25,50,75,100]).tolist(),'rear_wall_patch_xyxy':[660,180,860,260],'rear_wall_alpha_percentiles':np.percentile(a[180:260,660:860],[0,25,50,75,100]).tolist()}
    points={f'{x},{y}':pix[y,x].tolist() for x,y in [(0,0),(w-1,0),(0,h-1),(w-1,h-1),(w//2,0),(0,h//2),(w-1,h//2)]}
    report={'role':role,'generated_path':str(source),'raw_path':str(dest),'raw_sha256':sha(dest),'generated_sha256':sha(source),'prompt_path':f'prompts/interior_identity_20261106/{role}.txt','prompt_sha256':sha(R/f'prompts/interior_identity_20261106/{role}.txt'),'backend':'builtin_image_gen','calls':1,'model':None,'model_version':None,'cost':None,'actual_mode':im.mode,'actual_size':[w,h],'alpha_counts':{str(k):int((a==k).sum()) for k in [0,1,255]},'alpha_ge24_bbox':bbox,'border_alpha_min_max':[int(border.min()),int(border.max())],'border_alpha_ge24_count':int((border>=24).sum()),'corner_and_mid_samples_rgba':points,'processing':'NONE; original byte copy only','status':'RAW_ARCHIVED_ALPHA_REVIEW; no runtime adoption'}
    report['alpha_detail']=alpha_detail
    (RAW/(role+'_v1.provenance.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    reports.append(report)
(O/'shell_alpha_report.json').write_text(json.dumps({'reports':reports,'local_background_removal':False,'formal_writes':False},ensure_ascii=False,indent=2),encoding='utf8')
for r in reports: print(json.dumps(r,ensure_ascii=False))
