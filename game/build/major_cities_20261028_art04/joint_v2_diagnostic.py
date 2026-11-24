from pathlib import Path
from PIL import Image
import numpy as np,json
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
rows=[]
for name in ['west_longitudinal_wall_v2_edit','east_longitudinal_wall_v2_edit']:
 rgba=np.asarray(Image.open(ROOT/'assets/raw/bianzhou_enclosure_20261028d'/(name+'.png')).convert('RGBA'));a=rgba[:,:,3]
 def bound(y):
  xs=np.flatnonzero(a[y]>=128);return [int(xs[0]),int(xs[-1]+1)]
 bounds=[[y,*bound(y),bound(y)[1]-bound(y)[0]]for y in range(250,1251,100)]
 candidates=[]
 for lo in range(240,650):
  for hi in range(1000,1301):
   if bound(lo)==bound(hi):
    # Difference of exact RGBA edge strips is reported, not altered.
    candidates.append([lo,hi,*bound(lo),hi-lo,float(np.abs(rgba[lo].astype(float)-rgba[hi].astype(float)).mean())])
 candidates.sort(key=lambda x:(-x[4],x[5]))
 rows.append({'id':name,'outer128_crosssections_y_x0_x1_width':bounds,'long_identical_outer_profile_candidates_NOT_TEXTURE_SEAM_PASS':candidates[:10]})
(HERE/'joint_v2_diagnostic.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8');print(json.dumps(rows,indent=2))
