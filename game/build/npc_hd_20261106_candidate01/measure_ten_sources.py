"""Bounded ten-source read-only native-pixel audit. Does not alter images."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib
R=Path(__file__).resolve().parents[3]
specs=[
('seated_man','sprite_sheet/npc_inn_tea_guest_left_seated_idle_down_25d_4f_source_v2.png',4,1),
('seated_woman','sprite_sheet/npc_inn_tea_guest_right_seated_idle_down_25d_4f_source_v2.png',4,1),
('docks_carrier','luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_posepack_idle1_right4_v2_gait_edit.png',5,1),
('temple_monk','luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png',1,1),
('veteran_idle','luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1.png',1,1),
('veteran_walk','luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1.png',2,2),
('gate_guard','sprite_sheet/npc_zhuwei_gate_guard_idle_down_25d_4f_source_v2.png',4,1),
('martial_master','sprite_sheet/npc_linxi_martial_hall_master_idle_down_25d_4f_source_v2.png',4,1),
('duqingshan','sprite_sheet/field-25d/important-npcs/v3/sprite_duqingshan_25d_master_v3.png',4,4),
('street_merchant','character/expansion_20260805/npc_street_merchant_walk_8x4_v1_alpha.png',8,4)]
out=[]
for name,rel,cols,rows in specs:
 p=R/'assets/raw'/rel
 if not p.exists():out.append({'family':name,'missing':str(p)});continue
 im=Image.open(p);a=np.asarray(im.convert('RGBA'));w,h=im.size
 true_alpha=im.mode=='RGBA' and a[:,:,3].min()<255
 mask=a[:,:,3]>=24
 method='alpha>=24'
 if not true_alpha:
  rgb=a[:,:,:3].astype('int16');mask=~((rgb[:,:,0]>rgb[:,:,1]+35)&(rgb[:,:,2]>rgb[:,:,1]+35));method='read-only magenta exclusion estimate; NOT approved extraction'
 b=[]
 for y in range(rows):
  for x in range(cols):
   m=mask[y*h//rows:(y+1)*h//rows,x*w//cols:(x+1)*w//cols]
   yy,xx=np.nonzero(m);b.append([int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)] if len(xx) else None)
 out.append({'family':name,'raw':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':[w,h],'mode':im.mode,'transparent':bool(true_alpha),'grid':[cols,rows],'measurement':method,'boxes':b,'body_heights':[v[3]-v[1] if v else 0 for v in b],'native_body_min320':all(v and v[3]-v[1]>=320 for v in b),'reuse_requires':'Identity/action match, alpha fringe and grid review; no upscaling or local magenta keying'})
(Path(__file__).parent/'ten_source_pixels.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
for x in out:print(x['family'],x.get('size'),x.get('mode'),x.get('body_heights'),x.get('transparent'))
