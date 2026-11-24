"""Authorized outer-alpha1 cleanup, integer whole-frame alignment and blank padding only."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]; OUT=Path(__file__).parent
manifest={'schema':'PC_HD_SPRITE_VIEW_20261102C_V1','approved':False,'mappings':{}}
reports=[]
for role,version,stem,prompt in [('waiter','face_v2','npc_zhuwei_inn_waiter','waiter_down_idle_face_v2.txt'),('vendor','v1','npc_zhuwei_vegetable_vendor','vendor_down_idle.txt')]:
    raw=ROOT/f'assets/raw/npc_hd_20261106/npc_{role}_hd_down_idle_20261106_{version}.png'
    im=Image.open(raw); assert im.mode=='RGBA'; p=np.array(im); h,w,_=p.shape
    atlas=np.zeros((1024,2560,4),dtype=np.uint8); anchors=[]; facts=[]; heights=[]
    for i in range(4):
        x0=i*w//4; x1=(i+1)*w//4; original=p[:,x0:x1].copy(); tile=original.copy()
        yy,xx=np.where(tile[:,:,3]>=24); assert len(xx)
        bbox=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        protect=[max(0,bbox[0]-16),max(0,bbox[1]-16),min(x1-x0,bbox[2]+16),min(h,bbox[3]+16)]
        outside=np.ones(tile.shape[:2],dtype=bool); outside[protect[1]:protect[3],protect[0]:protect[2]]=False
        clear=outside & (tile[:,:,3]==1); tile[:,:,3][clear]=0
        # Ground anchor uses the lowest solid boot, not the basket/body bounding center.
        gy,gx=np.where(tile[max(0,bbox[3]-12):bbox[3],:,3]>=24)
        fx=int(round((int(gx.min())+int(gx.max()))/2)); fy=bbox[3]
        dx=320-fx; dy=900-fy
        assert dx>=0 and dy>=0 and dx+x1-x0<=640 and dy+h<=1024
        atlas[dy:dy+h,i*640+dx:i*640+dx+x1-x0]=tile
        restored=atlas[dy:dy+h,i*640+dx:i*640+dx+x1-x0]
        assert np.array_equal(original[:,:,:3],restored[:,:,:3])
        assert np.array_equal(original[~clear],restored[~clear])
        anchors.append([320,900]); heights.append(bbox[3]-bbox[1])
        facts.append({'source_partition':[x0,0,x1,h],'protected_rect':protect,'translation':[dx,dy],'alpha1_cleared':int(clear.sum()),'source_all_RGB_unchanged':True,'protected_RGBA_unchanged':True,'native_body_height':heights[-1],'source_ground_anchor':[fx,fy]})
    target=OUT/f'{role}_idle_down.png'; Image.fromarray(atlas).save(target)
    source=f'res://art/characters/{stem}_idle_down_25d_4f_v2_runtime.png'
    mapping={'atlas':f'res://art/characters/pc_hd_20261102c/{role}_idle_down_20261106.png','source_sha256':hashlib.sha256((ROOT/'game'/source[6:]).read_bytes()).hexdigest(),'atlas_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'cols':4,'rows':1,'row':0,'framecount':4,'source_hframes':4,'source_vframes':1,'source_cell':[160,160],'atlas_size':[2560,1024],'source_body_height':120,'body_height':min(heights),'minimum_native_body_height':320,'source_anchors':[[80,152]]*4,'body_anchors':anchors}
    manifest['mappings'][source]=mapping
    reports.append({'role':role,'raw':str(raw),'raw_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'actual_raw_size':[w,h],'model':None,'cost':None,'prompt_sha256':hashlib.sha256((ROOT/'prompts/npc_hd_20261106'/prompt).read_bytes()).hexdigest(),'atlas':str(target),'atlas_sha256':mapping['atlas_sha256'],'frames':facts,'resampled':False,'original_raw_retained':True,'formal_installed':False})
(OUT/'source.candidate.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
(OUT/'atlas_preparation_receipt.json').write_text(json.dumps(reports,indent=2),encoding='utf8')
print(json.dumps([{'role':r['role'],'size':r['actual_raw_size'],'heights':[f['native_body_height'] for f in r['frames']],'cleared':sum(f['alpha1_cleared'] for f in r['frames'])} for r in reports]))
