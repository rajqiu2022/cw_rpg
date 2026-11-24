from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
rows=json.loads((HERE/'raw_manifest.json').read_text(encoding='utf-8'))['assets']
board=Image.new('RGB',(1600,1400));draw=ImageDraw.Draw(board)
for y in range(0,1400,40):
 for x in range(0,1600,40):
  col=(92,100,103) if (x//40+y//40)%2 else (134,141,139)
  draw.rectangle((x,y,x+39,y+39),fill=col)
report=[]
for i,row in enumerate(rows):
 im=Image.open(ROOT/row['path']).convert('RGBA');a=np.asarray(im)[:,:,3]
 x=(i%2)*800;y=(i//2)*700
 view=im.copy();view.thumbnail((780,650))
 board.paste(view,(x+(800-view.width)//2,y+40+(650-view.height)//2),view)
 draw.text((x+12,y+12),row['id'],fill='white',stroke_width=1,stroke_fill='black')
 b=row['subject_protection_proposal_NOT_AUTHORIZED'];outside=np.ones(a.shape,dtype=bool);outside[b[1]:b[3],b[0]:b[2]]=False
 hist={str(v):int(np.count_nonzero(a==v))for v in [1,2,3,4,5,6,7,8,16,32,64,128,254,255]}
 report.append({'id':row['id'],'full_exact_alpha_histogram_selected':hist,
 'alpha2_to7_total':int(np.count_nonzero((a>=2)&(a<=7))),
 'alpha2_to7_outside_protection':int(np.count_nonzero(outside&(a>=2)&(a<=7))),
 'alpha_ge8_outside_protection':int(np.count_nonzero(outside&(a>=8))),
 'no_pixel_processing':True,'preview_composite_only':True})
board.save(HERE/'four_raw_true_alpha_checker_PREVIEW.jpg',quality=94)
(HERE/'alpha_halo_diagnostic.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
