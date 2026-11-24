"""Authorized exterior alpha=1 cleanup and RGBA0 padding; no geometry/alpha normalization."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
O=Path(__file__).resolve().parent;R=O.parents[2]
reports=json.loads((O/'shell_alpha_report.json').read_text(encoding='utf8'))['reports'];out=O/'processed';out.mkdir(exist_ok=True)
results=[]
for r in reports:
    src=Path(r['raw_path']);a=np.array(Image.open(src).convert('RGBA'));h,w=a.shape[:2]
    x0,y0,x1,y1=r['alpha_ge24_bbox'];protect=[max(0,x0-2),max(0,y0-2),min(w,x1+2),min(h,y1+2)]
    mask=np.ones((h,w),dtype=bool);p,q,s,t=protect;mask[q:t,p:s]=False
    mask&=a[:,:,3]==1;b=a.copy();b[:,:,3][mask]=0
    assert np.array_equal(a[:,:,:3],b[:,:,:3]) and np.array_equal(a[q:t,p:s],b[q:t,p:s])
    assert np.array_equal(a[a[:,:,3]>1],b[a[:,:,3]>1])
    padded=np.zeros((h+128,w+128,4),dtype=np.uint8);padded[64:64+h,64:64+w]=b
    target=out/(r['role']+'_native_padded64.png');Image.fromarray(padded).save(target)
    results.append({'role':r['role'],'source':str(src),'source_sha256':r['raw_sha256'],'candidate':str(target),'candidate_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source_size':[w,h],'candidate_size':[w+128,h+128],'original_origin_in_candidate':[64,64],'draw_origin_for_original_canvas':[-64,-64],'protect_xyxy':protect,'exterior_alpha1_removed':int(mask.sum()),'all_original_rgb_exact':True,'protected_rgba_exact':True,'all_alpha_gt1_exact':True,'padding_rgba':[0,0,0,0],'alpha_normalization':False,'resize':False,'formal_adoption':False})
(O/'shell_processing_receipt.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8')
for x in results:print(x['role'],x['candidate'],x['exterior_alpha1_removed'])
