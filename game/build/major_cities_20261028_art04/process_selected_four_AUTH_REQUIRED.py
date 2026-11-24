from pathlib import Path
import argparse,json,hashlib
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
PLAN=HERE/'processing_selected_four_PLAN.json'
ap=argparse.ArgumentParser()
ap.add_argument('--execute',action='store_true',help='Default is dry-run: no PNG or processed directory writes')
ap.add_argument('--authorization-file',type=Path)
ap.add_argument('--mode',choices=['clear-alpha1-and-padding','padding-only'],default='clear-alpha1-and-padding')
ap.add_argument('--report-name',default=None)
args=ap.parse_args()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
plan=json.loads(PLAN.read_text(encoding='utf-8'))
binding=json.loads((HERE/'selected_four_native_binding_PROPOSAL.json').read_text(encoding='utf-8'))
bind={x['id']:x for x in binding['assets']}
permission=None
if args.execute:
 assert args.authorization_file is not None and args.authorization_file.exists(), 'No actual user authorization record: STOP'
 permission=json.loads(args.authorization_file.read_text(encoding='utf-8'))
 assert permission.get('scope')==plan['scope'] and permission.get('root_explicit_authorized') is True
 assert permission.get('allow_padding') is True
 assert isinstance(permission.get('user_answer'),str) and permission['user_answer'].strip() and 'REPLACE_' not in permission['user_answer']
 if args.mode=='clear-alpha1-and-padding':assert permission.get('allow_clear_alpha1_outside_protection') is True, 'Padding-only permission cannot clear alpha'
report_path=HERE/(args.report_name or ('processing_actual.json' if args.execute else 'processing_dryrun.json'))
assert not report_path.exists(), 'CreateNew report only; retain earlier attempts'
rows=[];images=[]
for item in plan['assets']:
 src=ROOT/item['raw'];assert sha(src)==item['raw_sha256']
 im=Image.open(src);assert im.mode=='RGBA'
 original=np.asarray(im).copy();a=original[:,:,3];h,w=a.shape
 x0,y0,x1,y1=item['protect_xyxy'];outside=np.ones((h,w),dtype=bool);outside[y0:y1,x0:x1]=False
 assert not np.any(outside&(a>1)), 'Protection scope incorrect: exterior contains alpha>1'
 mask=outside&(a==1);assert int(mask.sum())==item['clear_count']
 changed=original.copy()
 if args.mode=='clear-alpha1-and-padding':changed[:,:,3][mask]=0
 assert np.array_equal(changed[:,:,:3],original[:,:,:3]), 'All original RGB must remain exact'
 assert np.array_equal(changed[y0:y1,x0:x1],original[y0:y1,x0:x1]), 'Protected subject RGBA must remain exact'
 assert np.array_equal(changed[:,:,3][~mask],a[~mask]), 'Only declared alpha1 pixels may differ'
 assert int(changed[:,:,3].max())==int(a.max()), 'Preserve source maximum, including254 walls'
 ox,oy=item['offset'];ow,oh=item['output_size'];assert [ow,oh]==[w+2*ox,h+2*oy]
 canvas=np.zeros((oh,ow,4),dtype=np.uint8);canvas[oy:oy+h,ox:ox+w]=changed
 yy,xx=np.nonzero(canvas[:,:,3]);box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
 margins=[box[0]/ow,box[1]/oh,(ow-box[2])/ow,(oh-box[3])/oh]
 assert min(margins)>=.15, 'Full A1 margin, no weak-alpha threshold substitute'
 assert np.array_equal(canvas[oy:oy+h,ox:ox+w],changed)
 outer=np.ones((oh,ow),dtype=bool);outer[oy:oy+h,ox:ox+w]=False
 assert not np.any(canvas[outer]), 'New padding must be full RGBA0'
 out=ROOT/item['processed_path']
 if args.execute:assert not out.exists(), 'Do not overwrite a processed image'
 b=bind[item['id']]
 row={'id':item['id'],'raw_path':item['raw'],'raw_sha256':item['raw_sha256'],'processed_path':item['processed_path'],
 'mode':args.mode,'subject_protection_xyxy':item['protect_xyxy'],'clear_alpha1_count':int(mask.sum()) if args.mode.startswith('clear') else 0,
 'padding_offset_px':[ox,oy],'output_size':[ow,oh],'complete_A1_bbox':box,'complete_A1_min_margin':min(margins),
 'all_original_RGB_exact':True,'protected_subject_RGBA_exact':True,'new_padding_RGBA0':True,'raw_preserved':True,'alpha_max_before_after':int(a.max()),
 'source_foot_full_before':b['source_foot_full'],'source_foot_full_after':[b['source_foot_full'][0]+ox,b['source_foot_full'][1]+oy],
 'repeat_region_before':b.get('repeat_region_source_xywh'),'repeat_region_after':b.get('repeat_region_padded_xywh'),'region_relative_foot_unchanged':b.get('region_relative_source_foot')}
 rows.append(row);images.append((out,canvas))
# All four guards have succeeded before the first possible PNG write.
if args.execute:
 for (out,canvas),row in zip(images,rows):
  out.parent.mkdir(parents=True,exist_ok=True);Image.fromarray(canvas,'RGBA').save(out)
  reread=np.asarray(Image.open(out));assert np.array_equal(reread,canvas)
  row['processed_sha256']=sha(out);row['processed_RGBA_sha256']=hashlib.sha256(reread.tobytes()).hexdigest()
 for item in plan['assets']:assert sha(ROOT/item['raw'])==item['raw_sha256']
report={'status':'PASS' if args.execute else 'PASS_DRYRUN_NO_PNG_WRITES','mode':args.mode,'execute':args.execute,
'plan_sha256':sha(PLAN),'processor_sha256':sha(Path(__file__)),'authorization_sha256':sha(args.authorization_file)if args.execute else None,
'png_writes':4 if args.execute else 0,'source_png_writes':0,'engine_runs':0,'assets':rows}
report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
