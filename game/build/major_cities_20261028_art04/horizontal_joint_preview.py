from pathlib import Path
from PIL import Image
import numpy as np,json
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
im=Image.open(ROOT/'assets/raw/bianzhou_enclosure_20261028d/horizontal_wall_v1.png').convert('RGBA');p=np.asarray(im);a=p[:,:,3]
def b(x):
 ys=np.flatnonzero(a[:,x]>=128);return [int(ys[0]),int(ys[-1]+1)]
matches=[]
for lo in range(220,600):
 for hi in range(1500,1950):
  if b(lo)!=b(hi):continue
  y0,y1=b(lo);mask=(a[y0:y1,lo]>=128)&(a[y0:y1,hi]>=128)
  err=float(np.abs(p[y0:y1,lo,:3].astype(float)-p[y0:y1,hi,:3].astype(float))[mask].mean())
  matches.append((err,lo,hi,y0,y1))
matches.sort();err,lo,hi,y0,y1=matches[0]
rect=[lo,190,hi-lo,375];tile=im.crop((lo,190,hi,565))
preview=Image.new('RGB',(tile.width*2,tile.height),(105,115,113));preview.paste(tile,(0,0),tile);preview.paste(tile,(tile.width,0),tile)
preview.thumbnail((1900,700));preview.save(HERE/'horizontal_native_region_repeat_PREVIEW.jpg',quality=94)
out={'region_source_xywh':rect,'repeat_pitch_native_px':hi-lo,'opaque_joint_y0_y1':[y0,y1],
'source_foot_region_relative':[(hi-lo)/2,375],'joint_RGB_MAE_diagnostic':err,
'native_scale_for_two_repeats_west_2371px':2371/(2*(hi-lo)),'status':'NATIVE_REGION_PROTOTYPE_NOT_ENGINE_ART_PASS'}
(HERE/'horizontal_repeat_candidate.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8');print(json.dumps(out,indent=2))
