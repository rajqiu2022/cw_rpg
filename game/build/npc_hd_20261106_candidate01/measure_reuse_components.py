from pathlib import Path
import json,numpy as np
from PIL import Image
from scipy import ndimage
R=Path(__file__).resolve().parents[3]
specs={'carrier':'assets/raw/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_posepack_idle1_right4_v2_gait_edit.png','monk':'assets/raw/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png','veteran_idle':'assets/raw/luoyang_city_finish_20261025i/guard_veteran_ochre_idle_v1.png','veteran_walk':'assets/raw/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1.png'}
report={}
for k,p in specs.items():
 a=np.array(Image.open(R/p)); labels,n=ndimage.label(a[:,:,3]>=24); sizes=np.bincount(labels.ravel()); order=np.argsort(sizes[1:])[::-1][:8]+1; items=[]
 for i in order:
  if sizes[i]<100:continue
  yy,xx=np.where(labels==i);items.append({'pixels':int(sizes[i]),'box':[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]})
 report[k]={'raw':p,'size':[a.shape[1],a.shape[0]],'components':items}
(Path(__file__).parent/'reuse_components.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
