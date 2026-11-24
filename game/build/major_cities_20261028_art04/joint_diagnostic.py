from pathlib import Path
from PIL import Image
import numpy as np
import json

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
rows=[]
for name in ['west_longitudinal_wall_v1','east_longitudinal_wall_v1']:
 a=np.asarray(Image.open(ROOT/'assets/raw/bianzhou_enclosure_20261028d'/(name+'.png')).convert('RGBA'))[:,:,3]
 bounds=[]
 for y in range(200,1201,100):
  xs=np.flatnonzero(a[y]>=128)
  bounds.append([y,int(xs[0]),int(xs[-1]+1),int(xs[-1]-xs[0]+1)])
 # Search noncrenel middle-shell boundaries with identical outer profiles.
 candidates=[]
 for lo in range(300,1050):
  if np.count_nonzero(a[lo]>=128)==0:continue
  for hi in range(lo+60,min(lo+240,1200)):
   l=np.flatnonzero(a[lo]>=128);r=np.flatnonzero(a[hi]>=128)
   if [int(l[0]),int(l[-1])] == [int(r[0]),int(r[-1])]:
    candidates.append([lo,hi,int(l[0]),int(l[-1]+1),hi-lo])
 candidates.sort(key=lambda x:x[-1],reverse=True)
 rows.append({'id':name,'outer128_crosssections_y_x0_x1_width':bounds,
 'identical_outer_profile_candidates_DIAGNOSTIC_NOT_TEXTURE_SEAM_PASS':candidates[:10]})
(HERE/'joint_diagnostic.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,indent=2))
