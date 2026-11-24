from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects
ROOT=Path(__file__).resolve().parents[3]; OUT=Path(__file__).parent
rows=[]
for role in ['seated_man','seated_woman']:
    raw=ROOT/f'assets/raw/npc_hd_20261106/npc_{role}_hd_down_idle_20261106_v1.png'
    image=Image.open(raw); p=np.array(image); h,w,_=p.shape
    frames=[]
    for i in range(4):
        tile=p[:,i*w//4:(i+1)*w//4]; a=tile[:,:,3]
        yy,xx=np.where(a>=24); box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        labels,n=label(a>=24); sizes=np.bincount(labels.ravel()); sizes[0]=0; main=int(sizes.argmax())
        extras=[]
        for ident,sl in enumerate(find_objects(labels),1):
            if sl is None or ident==main:continue
            mask=labels[sl]==ident; pixels=tile[sl][mask]
            extras.append({'area':int(mask.sum()),'box':[sl[1].start,sl[0].start,sl[1].stop,sl[0].stop],'max_alpha':int(pixels[:,3].max()),'mean_rgb':pixels[:,:3].mean(axis=0).round(1).tolist()})
        extras.sort(key=lambda row:row['area'],reverse=True)
        rgb=tile[:,:,:3].astype(int)
        warm=(rgb[:,:,0]>170)&(rgb[:,:,0]>rgb[:,:,2]*1.8)&(rgb[:,:,0]>rgb[:,:,1]*1.4)&(a>0)
        warm_alpha=np.bincount(a[warm],minlength=256)
        frames.append({'partition':[i*w//4,(i+1)*w//4],'body_alpha24_box':box,'height':box[3]-box[1],'alpha1':int((a==1).sum()),'saturated_red_alpha_histogram':{str(k):int(v) for k,v in enumerate(warm_alpha) if v},'detached_alpha24_components':extras[:25]})
    rows.append({'role':role,'raw':str(raw),'sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'actual_size':[w,h],'model':None,'cost':None,'prompt_sha256':hashlib.sha256((ROOT/f'prompts/npc_hd_20261106/{role}_down_idle.txt').read_bytes()).hexdigest(),'frames':frames,'raw_unchanged':True,'formal_installed':False})
(OUT/'seated_generated_pixel_audit.json').write_text(json.dumps(rows,indent=2),encoding='utf8')
print(json.dumps(rows))
