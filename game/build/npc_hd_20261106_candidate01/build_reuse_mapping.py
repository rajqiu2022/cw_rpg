"""Display-only candidates; original runtime pixels and collider inputs stay intact."""
from pathlib import Path
import json,hashlib,numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[3];O=Path(__file__).parent
receipts=json.loads((O/'reuse_preparation_receipt.json').read_text())
# Split only at already padded equal-cell seams; whole frames stay byte-exact.
carrier=next(r for r in receipts if r['role']=='carrier')
whole=np.array(Image.open(carrier['candidate']));cw=carrier['cell'][0]
for role,begin,end,source in [('carrier_idle',0,1,'luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png'),('carrier_walk',1,5,'luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_walk_right_4f_v1_runtime.png')]:
 target=O/(role+'_native_candidate.png');pixels=whole[:,begin*cw:end*cw].copy();Image.fromarray(pixels).save(target)
 assert np.array_equal(np.array(Image.open(target)),pixels)
 receipts.append(dict(carrier,role=role,source=source,candidate=str(target),candidate_sha256=hashlib.sha256(target.read_bytes()).hexdigest(),frames=carrier['frames'][begin:end]))
out={'schema':'PC_HD_SPRITE_VIEW_20261102C_V1','approved':False,'mappings':{}}
for r in receipts:
 if r['role']=='carrier':continue # Separate idle/walk textures require explicit split publication.
 path=R/'game/art/characters'/r['source'];p=np.array(Image.open(path).convert('RGBA'));h,w,_=p.shape;n=len(r['frames']);assert w==h*n
 anchors=[];heights=[]
 for i in range(n):
  a=p[:,i*h:(i+1)*h,3];yy,xx=np.where(a>=24);y=int(yy.max()+1);heights.append(y-int(yy.min()))
  fy,fx=np.where(a[max(0,y-3):y]>=24);anchors.append([(int(fx.min())+int(fx.max()))/2,y])
 out['mappings']['res://art/characters/'+r['source']]={'atlas':'res://art/characters/pc_hd_20261102c/'+r['role']+'_native_20261106.png','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'atlas_sha256':r['candidate_sha256'],'cols':n,'rows':1,'row':0,'framecount':n,'source_hframes':n,'source_vframes':1,'source_cell':[h,h],'atlas_size':[r['cell'][0]*n,r['cell'][1]],'source_body_height':min(heights),'body_height':min(f['body_height'] for f in r['frames']),'minimum_native_body_height':320,'source_anchors':anchors,'body_anchors':[f['atlas_anchor'] for f in r['frames']]}
(O/'source.reuse.candidate.json').write_text(json.dumps(out,indent=2))
print(json.dumps({p:{'frames':v['framecount'],'source_body':v['source_body_height'],'native_body':v['body_height']} for p,v in out['mappings'].items()}))
