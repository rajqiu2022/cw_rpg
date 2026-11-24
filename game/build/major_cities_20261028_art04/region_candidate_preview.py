from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
results=[];board=Image.new('RGB',(900,1500),(101,111,111));draw=ImageDraw.Draw(board)
for i,name in enumerate(['west_longitudinal_wall_v2_edit','east_longitudinal_wall_v2_edit']):
 im=Image.open(ROOT/'assets/raw/bianzhou_enclosure_20261028d'/(name+'.png')).convert('RGBA');p=np.asarray(im);a=p[:,:,3]
 bounds={}
 for y in range(280,1280):
  xs=np.flatnonzero(a[y]>=128);bounds[y]=(int(xs[0]),int(xs[-1]+1))
 candidates=[]
 for lo in range(280,1000):
  for hi in range(lo+280,min(lo+700,1280)):
   if bounds[lo]!=bounds[hi]:continue
   x0,x1=bounds[lo]
   # RGB error only on actual common opaque component; does not modify asset.
   mask=(a[lo,x0:x1]>=128)&(a[hi,x0:x1]>=128)
   err=float(np.abs(p[lo,x0:x1,:3].astype(float)-p[hi,x0:x1,:3].astype(float))[mask].mean())
   candidates.append((err,-(hi-lo),lo,hi,x0,x1))
 candidates.sort()
 err,neglen,lo,hi,x0,x1=candidates[0]
 # Full sideface crosssection and alpha fringe retained. Repeats native region
 # on a diagnostic checker only; never writes a replacement PNG asset.
 rect=[x0-4,lo,x1-x0+8,hi-lo];tile=im.crop((rect[0],lo,rect[0]+rect[2],hi))
 xx=i*450+(450-tile.width)//2
 for k in range(4):board.paste(tile,(xx,50+k*tile.height),tile)
 draw.text((i*450+10,10),name+' region prototype only',fill='white')
 results.append({'id':name,'region_source_xywh':rect,'repeat_pitch_native_px':hi-lo,'source_outer128_joint_x0_x1':[x0,x1],
 'source_top_y':lo,'source_bottom_y':hi,'joint_RGB_MAE_diagnostic':err,'original_full_endcaps_retained_separately':True,
 'status':'REGION_NATIVE_REPEAT_PROTOTYPE_NOT_ENGINE_ART_PASS','resize_or_transform':False})
board.save(HERE/'v2_native_region_repeat_PREVIEW.jpg',quality=94)
(HERE/'region_repeat_candidate.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8');print(json.dumps(results,indent=2))
