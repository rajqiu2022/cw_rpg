"""Batch02: exact source pixels, authorized exterior A1, integer padding only."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,shutil,math
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
generated=Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-eae73dbf-0fd7-4163-9dcf-8dc55fd65fe0.png')
raw=R/'assets/raw/npc_hd_20261106_batch02/common_escort_guard_down_idle_v1.png'
raw.parent.mkdir(parents=True,exist_ok=True)
if raw.exists():assert sha(raw)==sha(generated)
else:shutil.copyfile(generated,raw)
specs=[
 ('paper_scholar_idle',R/'assets/staging/luoyang_scholar_20261024a/scholar_idle_v2_clean_padded1440.png','npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png',1,False),
 ('common_escort_idle',raw,'street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png',4,True),
 ('common_escort_walk',R/'assets/raw/sprite/npc/escort_guard_walk_codex_builtin_v1/npc_escort_guard_walk_right_8f_v1_alpha.png','street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png',8,True)]
out={'schema':'PC_HD_SPRITE_VIEW_20261102C_V1','approved':False,'mappings':{}};receipts=[]
for role,mother,source,n,align in specs:
 original_image=Image.open(mother);assert original_image.mode=='RGBA';p=np.array(original_image);h,w,_=p.shape
 old=R/'game/art/characters'/source;sp=np.array(Image.open(old).convert('RGBA'));sh,sw,_=sp.shape;assert sw==sh*n
 source_anchors=[];source_heights=[]
 for i in range(n):
  a=sp[:,i*sh:(i+1)*sh,3];sy,sx=np.where(a>=24);foot=int(sy.max()+1);source_heights.append(foot-int(sy.min()));by,bx=np.where(a[foot-3:foot]>=24)
  source_anchors.append([(int(bx.min())+int(bx.max()))/2,foot])
 frames=[];facts=[]
 for i in range(n):
  # Same round partition as historical process_25d_horizontal_idle_strip.py.
  x0=round(i*w/n);x1=round((i+1)*w/n);original=p[:,x0:x1].copy();tile=original.copy();yy,xx=np.where(tile[:,:,3]>=24)
  box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];bh=box[3]-box[1]
  assert box[0]>0 and box[2]<x1-x0 and bh>=320,(role,i,box)
  protect=[max(0,box[0]-24),max(0,box[1]-24),min(x1-x0,box[2]+24),min(h,box[3]+24)]
  outside=np.ones(tile.shape[:2],dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
  clear=outside&(tile[:,:,3]==1) if align else np.zeros(tile.shape[:2],dtype=bool)
  tile[:,:,3][clear]=0
  # Match the old foot support band's proportional depth, not sprite canvas center.
  foot_band=max(1,round(3*bh/source_heights[i]));by,bx=np.where(tile[box[3]-foot_band:box[3],:,3]>=24)
  anchor=[int(round((int(bx.min())+int(bx.max()))/2)),box[3]]
  frames.append((tile,anchor,original,clear))
  facts.append({'frame':i,'partition':[x0,0,x1,h],'body_box_alpha24':box,'body_height':bh,'protected_rect':protect,'alpha1_cleared':int(clear.sum()),'source_anchor':source_anchors[i],'native_anchor_before_padding':anchor,'native_foot_support_band':foot_band,'all_RGB_preserved':True,'protected_RGBA_preserved':True,'all_RGBA_above_alpha1_preserved':True})
 target=O/(role+'_native_candidate.png')
 if not align:
  shutil.copyfile(mother,target);cw=w;ch=h;facts[0]['translation']=[0,0];facts[0]['atlas_anchor']=frames[0][1]
 else:
  left=max(a[0] for _,a,_,_ in frames)+64;right=max(t.shape[1]-a[0] for t,a,_,_ in frames)+64
  top=max(a[1] for _,a,_,_ in frames)+64;bottom=max(t.shape[0]-a[1] for t,a,_,_ in frames)+64
  cw=math.ceil((left+right)/16)*16;ch=math.ceil((top+bottom)/16)*16
  atlas=np.zeros((ch,cw*n,4),dtype=np.uint8)
  for i,(tile,a,original,clear) in enumerate(frames):
   dx=left-a[0];dy=top-a[1];hh,ww,_=tile.shape;atlas[dy:dy+hh,i*cw+dx:i*cw+dx+ww]=tile
   restored=atlas[dy:dy+hh,i*cw+dx:i*cw+dx+ww]
   assert np.array_equal(original[:,:,:3],restored[:,:,:3]) and np.array_equal(original[~clear],restored[~clear])
   facts[i]['translation']=[dx,dy];facts[i]['atlas_anchor']=[left,top]
  Image.fromarray(atlas).save(target)
 native_body=min(f['body_height'] for f in facts)
 entry={'atlas':'res://art/characters/pc_hd_20261102c/'+role+'_native_20261106b02.png','source_sha256':sha(old),'atlas_sha256':sha(target),'cols':n,'rows':1,'row':0,'framecount':n,'source_hframes':n,'source_vframes':1,'source_cell':[sh,sh],'atlas_size':[cw*n,ch],'source_body_height':min(source_heights),'body_height':native_body,'minimum_native_body_height':320,'source_anchors':source_anchors,'body_anchors':[f['atlas_anchor'] for f in facts]}
 out['mappings']['res://art/characters/'+source]=entry
 rec={'role':role,'mother':str(mother),'mother_sha256':sha(mother),'mother_size':[w,h],'candidate':str(target),'candidate_sha256':sha(target),'cell':[cw,ch],'frames':facts,'source':str(old),'source_sha256':sha(old),'source_body_heights':source_heights,'resampled':False,'RGB_edited':False,'formal_installed':False,'atlas_sha256':sha(target),'action':'right_walk_original_eight_phases_left_runtime_mirror' if n==8 else 'down_idle_original_phase_count','scope':'candidate_only_not_all_directions','art_status':'ROOT_MOTHER_IDENTITY_ACCEPTED_NORMAL_SCALE_PENDING'}
 if role=='common_escort_idle':
  prompt=R/'prompts/npc_hd_20261106_batch02/escort_guard_down_idle.txt'
  rec.update(generated_path=str(generated),prompt=str(prompt),prompt_sha256=sha(prompt),generation_calls=1,model=None,model_version=None,cost=None,provider_metadata='builtin tool did not disclose model or cost')
  raw.with_suffix('.json').write_text(json.dumps(rec,indent=2),encoding='utf8')
 if role=='paper_scholar_idle':rec['inherited_authorization_receipt']='assets/staging/luoyang_scholar_20261024a/authorized_cleanup_actual.json'
 receipts.append(rec)
(O/'preparation_receipt.json').write_text(json.dumps(receipts,indent=2),encoding='utf8')
(O/'source.batch02.candidate.json').write_text(json.dumps(out,indent=2),encoding='utf8')
formal=R/'game/art/characters/pc_hd_20261102c/source.json';merged=json.loads(formal.read_text());assert len(merged['mappings'])==15
assert not set(merged['mappings']).intersection(out['mappings']);merged['mappings'].update(out['mappings'])
(O/'source.merged18.candidate.json').write_text(json.dumps(merged,indent=2),encoding='utf8')
(O/'mapping_plan.json').write_text(json.dumps({'formal_manifest_before_sha256':sha(formal),'candidate_manifest':str(O/'source.merged18.candidate.json'),'candidate_manifest_sha256':sha(O/'source.merged18.candidate.json'),'old_mappings_preserved_exact':True,'new_mappings':3,'new_families':2,'formal_adapter_unchanged':True,'ghost_resolution_unchanged':True,'formal_writes':0},indent=2),encoding='utf8')
print(json.dumps([{'role':r['role'],'size':r['mother_size'],'cell':r['cell'],'body':[f['body_height'] for f in r['frames']],'cleared':sum(f['alpha1_cleared'] for f in r['frames'])} for r in receipts]))
