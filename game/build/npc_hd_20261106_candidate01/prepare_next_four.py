"""Only authorized exterior A1 removal and whole-frame integer alignment/padding."""
from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,shutil
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
G=Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
specs=[
 ('gate_guard','exec-ff6e31c8-9574-4059-a886-c2b76f652a44.png','npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png'),
 ('martial_master','exec-58bb880c-3612-40a4-8c21-6bec50112810.png','npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png'),
 ('crying_woman','exec-b572c776-d7a3-45ab-a1c5-374e47c5ee38.png','npc_zhuwei_crying_woman_idle_down_25d_4f_v2_runtime.png'),
 ('escort','exec-0c66f4bf-382b-42a6-b03b-60b5ebd2a585.png','npc_zhuwei_escort_idle_down_25d_4f.png')]
out={'schema':'PC_HD_SPRITE_VIEW_20261102C_V1','approved':False,'mappings':{}};receipts=[]
for role,generated,source in specs:
 raw=R/f'assets/raw/npc_hd_20261106/npc_{role}_hd_down_idle_20261106_v1.png'
 if raw.exists():assert sha(raw)==sha(G/generated)
 else:shutil.copyfile(G/generated,raw)
 im=Image.open(raw);assert im.mode=='RGBA';p=np.array(im);h,w,_=p.shape
 frames=[];facts=[]
 for i in range(4):
  x0=i*w//4;x1=(i+1)*w//4;original=p[:,x0:x1].copy();tile=original.copy();yy,xx=np.where(tile[:,:,3]>=24)
  box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
  # Reject cuts through visible figure; actual frame layout must be revisited.
  assert box[0]>0 and box[2]<x1-x0,(role,i,box,'frame edge clipping risk')
  protect=[max(0,box[0]-24),max(0,box[1]-24),min(x1-x0,box[2]+24),min(h,box[3]+24)]
  outside=np.ones(tile.shape[:2],dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
  clear=outside&(tile[:,:,3]==1);tile[:,:,3][clear]=0
  by,bx=np.where(tile[max(0,box[3]-12):box[3],:,3]>=24);anchor=[int(round((int(bx.min())+int(bx.max()))/2)),box[3]]
  frames.append((tile,anchor,original,clear));facts.append({'partition':[x0,0,x1,h],'body_box_alpha24':box,'body_height':box[3]-box[1],'protected_rect':protect,'alpha1_cleared':int(clear.sum()),'source_anchor':anchor,'all_RGB_preserved':True,'protected_RGBA_preserved':True})
 left=max(a[0] for _,a,_,_ in frames)+64;right=max(t.shape[1]-a[0] for t,a,_,_ in frames)+64
 top=max(a[1] for _,a,_,_ in frames)+64;bottom=max(t.shape[0]-a[1] for t,a,_,_ in frames)+64
 cw=((left+right+15)//16)*16;ch=((top+bottom+15)//16)*16;atlas=np.zeros((ch,cw*4,4),dtype=np.uint8)
 for n,(tile,a,original,clear) in enumerate(frames):
  dx=left-a[0];dy=top-a[1];hh,ww,_=tile.shape;atlas[dy:dy+hh,n*cw+dx:n*cw+dx+ww]=tile
  restored=atlas[dy:dy+hh,n*cw+dx:n*cw+dx+ww];assert np.array_equal(original[:,:,:3],restored[:,:,:3]);assert np.array_equal(original[~clear],restored[~clear])
  facts[n]['translation']=[dx,dy];facts[n]['atlas_anchor']=[left,top]
 target=O/f'{role}_native_candidate.png';Image.fromarray(atlas).save(target)
 old=R/'game/art/characters'/source;native=np.array(Image.open(old).convert('RGBA'));nh,nw,_=native.shape;assert nw==nh*4
 anchors=[];heights=[]
 for n in range(4):
  a=native[:,n*nh:(n+1)*nh,3];yy,xx=np.where(a>=24);foot=int(yy.max()+1);heights.append(foot-int(yy.min()));by,bx=np.where(a[max(0,foot-3):foot]>=24);anchors.append([(int(bx.min())+int(bx.max()))/2,foot])
 body=min(f['body_height'] for f in facts);assert body>=320
 out['mappings']['res://art/characters/'+source]={'atlas':'res://art/characters/pc_hd_20261102c/'+role+'_native_20261106.png','source_sha256':sha(old),'atlas_sha256':sha(target),'cols':4,'rows':1,'row':0,'framecount':4,'source_hframes':4,'source_vframes':1,'source_cell':[nh,nh],'atlas_size':[cw*4,ch],'source_body_height':min(heights),'body_height':body,'minimum_native_body_height':320,'source_anchors':anchors,'body_anchors':[f['atlas_anchor'] for f in facts]}
 prompt=R/f'prompts/npc_hd_20261106/{role}_down_idle.txt'
 receipt={'role':role,'generated':str(G/generated),'raw':str(raw),'raw_sha256':sha(raw),'raw_size':[w,h],'prompt':str(prompt),'prompt_sha256':sha(prompt),'model':None,'cost':None,'root_identity_review':'accepted identity and four intact down idle frames','candidate':str(target),'candidate_sha256':sha(target),'cell':[cw,ch],'frames':facts,'source':source,'resampled':False,'formal_installed':False,'art_status':'PENDING_128PX_ART; alpha>1 unchanged'}
 (raw.with_suffix('.json')).write_text(json.dumps(receipt,indent=2));receipts.append(receipt)
(O/'next_four_preparation_receipt.json').write_text(json.dumps(receipts,indent=2))
(O/'source.next_four.candidate.json').write_text(json.dumps(out,indent=2))
print(json.dumps([{'role':r['role'],'raw_size':r['raw_size'],'body':[f['body_height'] for f in r['frames']],'cell':r['cell']} for r in receipts]))
