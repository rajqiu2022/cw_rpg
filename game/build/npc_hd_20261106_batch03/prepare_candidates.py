"""Batch03 merchant: raw originals, exterior A1 only, integer whole-frame padding.

Partial runs prepare available rows only; completeness is asserted by import/QA.
No engine, formal source writes, resampling, or real-save access.
"""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,shutil,math
O=Path(__file__).resolve().parent;R=O.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
specs=json.loads((O/'generated_inputs.json').read_text())
manifest={'schema':'PC_HD_SPRITE_VIEW_20261102C_V1','approved':False,'mappings':{}}
receipts=[]
for spec in specs:
 role=spec['role'];generated=Path(spec['generated_path']);mother=R/'assets/raw/npc_hd_20261106_batch03'/f'merchant_{role}_v1.png'
 mother.parent.mkdir(parents=True,exist_ok=True)
 if mother.exists():assert sha(mother)==sha(generated)
 else:shutil.copyfile(generated,mother)
 image=Image.open(mother);assert image.mode=='RGBA';p=np.array(image);h,w,_=p.shape
 n=4 if role=='down_idle' else 8;raw_rows=1 if n==4 else 2;raw_cols=4
 suffix='idle_down_4f_v3_runtime.png' if n==4 else role.replace('_walk','')+'_walk_8f_v3_runtime.png'
 source='res://art/characters/street_expansion_v1/npc_street_merchant_'+suffix
 old=R/'game'/source[6:];sp=np.array(Image.open(old).convert('RGBA'));sh,sw,_=sp.shape;assert sw==sh*n
 source_anchors=[];source_heights=[]
 for i in range(n):
  a=sp[:,i*sh:(i+1)*sh,3];sy,sx=np.where(a>=24);foot=int(sy.max()+1);source_heights.append(foot-int(sy.min()));by,bx=np.where(a[foot-3:foot]>=24)
  source_anchors.append([(int(bx.min())+int(bx.max()))/2,foot])
 frames=[];facts=[]
 for i in range(n):
  col=i%raw_cols;row=i//raw_cols;x0=round(col*w/raw_cols);x1=round((col+1)*w/raw_cols);y0=round(row*h/raw_rows);y1=round((row+1)*h/raw_rows)
  original=p[y0:y1,x0:x1].copy();tile=original.copy();yy,xx=np.where(tile[:,:,3]>=24)
  box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];bh=box[3]-box[1]
  assert box[0]>0 and box[2]<x1-x0 and box[1]>0 and box[3]<y1-y0 and bh>=320,(role,i,box)
  protect=[max(0,box[0]-24),max(0,box[1]-24),min(x1-x0,box[2]+24),min(y1-y0,box[3]+24)]
  outside=np.ones(tile.shape[:2],dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
  clear=outside&(tile[:,:,3]==1);tile[:,:,3][clear]=0
  foot_band=max(1,round(3*bh/source_heights[i]));by,bx=np.where(tile[box[3]-foot_band:box[3],:,3]>=24)
  anchor=[int(round((int(bx.min())+int(bx.max()))/2)),box[3]]
  frames.append((tile,anchor,original,clear))
  color=original[:,:,:3].astype(np.int16)
  saturated_red=(color[:,:,0]>180)&(color[:,:,0]>color[:,:,1]*1.7)&(color[:,:,0]>color[:,:,2]*1.7)
  red_alpha=original[:,:,3][saturated_red]
  facts.append({'frame':i,'partition':[x0,y0,x1,y1],'body_box_alpha24':box,'body_height':bh,'protected_rect':protect,'alpha1_cleared':int(clear.sum()),'outside_protected_alpha_gt1':int((outside&(tile[:,:,3]>1)).sum()),'red_pixel_alpha_histogram':{str(int(k)):int(v) for k,v in zip(*np.unique(red_alpha,return_counts=True))},'source_anchor':source_anchors[i],'native_anchor_before_padding':anchor,'native_foot_support_band':foot_band,'all_RGB_preserved':True,'protected_RGBA_preserved':True,'all_RGBA_above_alpha1_preserved':True})
 left=max(a[0] for _,a,_,_ in frames)+64;right=max(t.shape[1]-a[0] for t,a,_,_ in frames)+64
 top=max(a[1] for _,a,_,_ in frames)+64;bottom=max(t.shape[0]-a[1] for t,a,_,_ in frames)+64
 cw=math.ceil((left+right)/16)*16;ch=math.ceil((top+bottom)/16)*16
 atlas=np.zeros((ch,cw*n,4),dtype=np.uint8)
 for i,(tile,a,original,clear) in enumerate(frames):
  dx=left-a[0];dy=top-a[1];hh,ww,_=tile.shape;atlas[dy:dy+hh,i*cw+dx:i*cw+dx+ww]=tile
  restored=atlas[dy:dy+hh,i*cw+dx:i*cw+dx+ww]
  assert np.array_equal(original[:,:,:3],restored[:,:,:3]) and np.array_equal(original[~clear],restored[~clear])
  facts[i]['translation']=[dx,dy];facts[i]['atlas_anchor']=[left,top]
 target=O/f'merchant_{role}_native_candidate.png';Image.fromarray(atlas).save(target)
 entry={'atlas':f'res://art/characters/pc_hd_20261102c/merchant_{role}_native_20261106b03.png','source_sha256':sha(old),'atlas_sha256':sha(target),'cols':n,'rows':1,'row':0,'framecount':n,'source_hframes':n,'source_vframes':1,'source_cell':[sh,sh],'atlas_size':[cw*n,ch],'source_body_height':min(source_heights),'body_height':min(f['body_height'] for f in facts),'minimum_native_body_height':320,'source_anchors':source_anchors,'body_anchors':[f['atlas_anchor'] for f in facts]}
 manifest['mappings'][source]=entry
 prompt=R/'prompts/npc_hd_20261106_batch03'/f'merchant_{role}.txt'
 rec={'role':role,'mother':str(mother),'mother_sha256':sha(mother),'mother_size':[w,h],'raw_grid':[raw_cols,raw_rows],'candidate':str(target),'candidate_sha256':sha(target),'cell':[cw,ch],'frames':facts,'source':str(old),'source_sha256':sha(old),'source_body_heights':source_heights,'resampled':False,'RGB_edited':False,'formal_installed':False,'action':spec['pixel_facing'],'generated_path':str(generated),'prompt':str(prompt),'prompt_sha256':sha(prompt),'generation_calls':1,'model':None,'model_version':None,'cost':None,'scope':'candidate_only_existing_action_semantics','art_status':'ROOT_MOTHER_IDENTITY_ACCEPTED_NORMAL_SCALE_PENDING'}
 mother.with_suffix('.json').write_text(json.dumps(rec,indent=2),encoding='utf8');receipts.append(rec)
(O/'preparation_receipt.json').write_text(json.dumps(receipts,indent=2),encoding='utf8')
(O/'source.batch03.candidate.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
formal=R/'game/art/characters/pc_hd_20261102c/source.json';merged=json.loads(formal.read_text());assert len(merged['mappings'])==18
assert not set(merged['mappings']).intersection(manifest['mappings']);merged['mappings'].update(manifest['mappings'])
(O/'source.merged.candidate.json').write_text(json.dumps(merged,indent=2),encoding='utf8')
(O/'mapping_plan.json').write_text(json.dumps({'formal_manifest_before_sha256':sha(formal),'candidate_manifest':str(O/'source.merged.candidate.json'),'candidate_manifest_sha256':sha(O/'source.merged.candidate.json'),'old_mappings_preserved_exact':True,'old_mappings':18,'new_mappings':len(specs),'expected_new_mappings':5,'expected_new_frames':36,'complete':len(specs)==5,'new_families':1,'formal_adapter_unchanged':True,'ghost_resolution_unchanged':True,'formal_writes':0},indent=2),encoding='utf8')
print(json.dumps([{'role':r['role'],'size':r['mother_size'],'cell':r['cell'],'body':[f['body_height'] for f in r['frames']],'cleared':sum(f['alpha1_cleared'] for f in r['frames']),'outside_alpha_gt1':sum(f['outside_protected_alpha_gt1'] for f in r['frames'])} for r in receipts]))
