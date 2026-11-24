"""Read-only new batch03 pixels, no engine or save access."""
import json, hashlib
from pathlib import Path
import numpy as np
from PIL import Image

base = Path('F:/Code/RPG_GAME/game/build/npc_hd_20261106_batch03')
records = json.loads((base/'preparation_receipt.json').read_text('utf-8'))
maps = json.loads((base/'source.batch03.candidate.json').read_text('utf-8'))['mappings']
failures=[]; frames=0; rows=[]
for r in records:
    raw=np.array(Image.open(r['mother']).convert('RGBA'))
    atlas=np.array(Image.open(r['candidate']).convert('RGBA'))
    source=np.array(Image.open(r['source']).convert('RGBA'))
    key='res://'+Path(r['source']).relative_to(Path('F:/Code/RPG_GAME/game')).as_posix()
    m=maps[key]; cw,ch=r['cell']; bounds=[]
    for f in r['frames']:
        i=f['frame']; x0,y0,x1,y1=f['partition']; dx,dy=f['translation']
        original=raw[y0:y1,x0:x1]; cell=atlas[:,i*cw:(i+1)*cw]
        expected=original.copy(); px0,py0,px1,py1=f['protected_rect']
        mask=np.ones(original.shape[:2],dtype=bool); mask[py0:py1,px0:px1]=False
        allowed=mask & (original[:,:,3]==1); expected[allowed,3]=0
        target=np.zeros((ch,cw,4),dtype=np.uint8)
        if dx<0 or dy<0 or dx+x1-x0>cw or dy+y1-y0>ch:
            failures.append([r['role'],i,'translation_out_of_cell']); continue
        target[dy:dy+y1-y0,dx:dx+x1-x0]=expected
        if not np.array_equal(target,cell):failures.append([r['role'],i,'RGBA_not_exact_permitted_transform'])
        sy,sx=np.nonzero(source[:,i*160:(i+1)*160,3]>=24)
        band=sx[sy>=sy.max()-2]
        anchor=[float((band.min()+band.max())/2),int(sy.max()+1)]
        if anchor!=m['source_anchors'][i]: failures.append([r['role'],i,'source_anchor',anchor,m['source_anchors'][i]])
        if [a+b for a,b in zip(f['native_anchor_before_padding'],f['translation'])]!=m['body_anchors'][i]:failures.append([r['role'],i,'native_anchor'])
        if f['body_height']<320:failures.append([r['role'],i,'body_under_320'])
        bounds.append(f['body_height']);frames+=1
    for field,hashfield in [('mother','mother_sha256'),('candidate','candidate_sha256'),('source','source_sha256')]:
        if hashlib.sha256(Path(r[field]).read_bytes()).hexdigest()!=r[hashfield]:failures.append([r['role'],field,'sha'])
    if m['cols']!=len(r['frames']) or m['rows']!=1 or m['body_height']!=min(bounds):failures.append([r['role'],'mapping_grid_or_ratio'])
    rows.append({'role':r['role'],'frames':len(bounds),'native_body_range':[min(bounds),max(bounds)],'runtime_scaled_height_range':[round(140*x/m['body_height'],3) for x in [min(bounds),max(bounds)]]})
print(json.dumps({'rows':rows,'new_frames_checked':frames,'failures':failures,'engine':False,'writes':False},ensure_ascii=False,indent=2))
