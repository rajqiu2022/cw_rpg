"""Candidate only: authorized alpha1 outside protection, full-frame integer padding.
No resizing, alpha thresholding, body edits, recoloring or formal install.
"""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
specs=[
 ('seated_man','assets/raw/npc_hd_20261106/npc_seated_man_hd_down_idle_20261106_v1.png',4,1,None,'npc_inn_tea_guest_left_seated_idle_down_25d_4f_v2_runtime.png'),
 ('seated_woman','assets/raw/npc_hd_20261106/npc_seated_woman_hd_down_idle_20261106_v1.png',4,1,None,'npc_inn_tea_guest_right_seated_idle_down_25d_4f_v2_runtime.png'),
 ('carrier','assets/raw/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_posepack_idle1_right4_v2_gait_edit.png',5,1,[0,388,863,1149,1688,2033],None),
 ('monk','assets/raw/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png',1,1,None,'luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png'),
 ('veteran_idle','assets/raw/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1.png',1,1,None,'luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1_runtime160.png'),
 ('veteran_walk','assets/raw/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1.png',2,2,None,'luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png'),
 ('young_guard_idle','assets/raw/luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1.png',1,1,None,'luoyang_city_finish_20261025i/guard_young_bluegrey_idle_v1_runtime160.png'),
 ('young_guard_walk','game/build/luoyang_city_finish_20261025i_art01/processed_authorized_output/guard_young_bluegrey_walk4_v1_local_authorized.png',4,1,None,'luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png')]
receipts=[]
for role,rel,cols,rows,cuts,source in specs:
 raw=R/rel; im=Image.open(raw); assert im.mode=='RGBA';p=np.array(im);h,w,_=p.shape
 frames=[];facts=[]
 for row in range(rows):
  for col in range(cols):
   x0=cuts[col] if cuts else col*w//cols;x1=cuts[col+1] if cuts else (col+1)*w//cols;y0=row*h//rows;y1=(row+1)*h//rows
   original=p[y0:y1,x0:x1].copy(); tile=original.copy(); yy,xx=np.where(tile[:,:,3]>=24)
   box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   # 24px guard protects complete anatomical/equipment silhouette, not just core.
   protect=[max(0,box[0]-24),max(0,box[1]-24),min(x1-x0,box[2]+24),min(y1-y0,box[3]+24)]
   outside=np.ones(tile.shape[:2],dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
   clear=outside&(tile[:,:,3]==1);tile[:,:,3][clear]=0
   by,bx=np.where(tile[max(0,box[3]-12):box[3],:,3]>=24); anchor=[int(round((int(bx.min())+int(bx.max()))/2)),box[3]]
   frames.append((tile,anchor,original,clear))
   facts.append({'partition':[x0,y0,x1,y1],'body_box_alpha24':box,'body_height':box[3]-box[1],'protected_rect':protect,'alpha1_cleared':int(clear.sum()),'source_anchor':anchor,'all_RGB_preserved':True,'protected_RGBA_preserved':True})
 # Shared cell accommodates entire source rectangles in both directions around anchor.
 left=max(a[0] for _,a,_,_ in frames)+64;right=max(t.shape[1]-a[0] for t,a,_,_ in frames)+64
 top=max(a[1] for _,a,_,_ in frames)+64;bottom=max(t.shape[0]-a[1] for t,a,_,_ in frames)+64
 cw=((left+right+15)//16)*16;ch=((top+bottom+15)//16)*16
 atlas=np.zeros((ch,cw*len(frames),4),dtype=np.uint8)
 for n,(tile,a,original,clear) in enumerate(frames):
  dx=left-a[0];dy=top-a[1];hh,ww,_=tile.shape;atlas[dy:dy+hh,n*cw+dx:n*cw+dx+ww]=tile
  restored=atlas[dy:dy+hh,n*cw+dx:n*cw+dx+ww];assert np.array_equal(original[:,:,:3],restored[:,:,:3]);assert np.array_equal(original[~clear],restored[~clear])
  facts[n]['translation']=[dx,dy];facts[n]['atlas_anchor']=[left,top]
 target=O/f'{role}_native_candidate.png';Image.fromarray(atlas).save(target)
 receipts.append({'role':role,'raw':rel,'raw_sha256':sha(raw),'original_retained':True,'source':source,'candidate':str(target),'candidate_sha256':sha(target),'cell':[cw,ch],'frames':facts,'resampled':False,'formal_installed':False,'art_status':'PENDING_NORMAL_SCALE_FRINGE_REVIEW; alpha>1 untouched'})
(O/'reuse_preparation_receipt.json').write_text(json.dumps(receipts,indent=2))
print(json.dumps([{'role':x['role'],'cell':x['cell'],'body':[f['body_height'] for f in x['frames']]} for x in receipts]))
