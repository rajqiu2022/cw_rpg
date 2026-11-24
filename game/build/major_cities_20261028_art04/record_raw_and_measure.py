from pathlib import Path
import hashlib
import json
import shutil
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = ROOT / 'assets/raw/bianzhou_enclosure_20261028d'
GENERATED = Path('C:/Users/rajqiu/.codex/generated_images/01a181b1-8918-7ad2-b405-056a75739311')
SOURCES = {
 'horizontal_wall_v1':'exec-2c42b41b-e2ed-4370-8596-ab3decf0f53b.png',
 'west_longitudinal_wall_v1':'exec-16f06c46-a5ad-455c-a52f-c676843fa9c5.png',
 'east_longitudinal_wall_v1':'exec-65b6a2bf-318a-414a-a677-d313f7292660.png',
 'post_stable_cartshed_v1':'exec-00ffca05-44e7-4d04-a5f9-92b6a4a5f148.png',
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def bbox(mask):
 y,x=np.nonzero(mask)
 return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)] if len(x) else None
RAW.mkdir(parents=True, exist_ok=True)
rows=[]
for name,filename in SOURCES.items():
 src=GENERATED/filename;dst=RAW/(name+'.png')
 if not dst.exists():shutil.copyfile(src,dst)
 assert sha(src)==sha(dst)
 a=np.asarray(Image.open(dst).convert('RGBA'))[:,:,3]
 h,w=a.shape; box=bbox(a>0); box8=bbox(a>=8); box128=bbox(a>=128)
 margins=[box[0]/w,box[1]/h,(w-box[2])/w,(h-box[3])/h]
 # Proposed generous subject protection: all alpha>=8 plus48px each side.
 # No treatment is executed; raw pixels and hidden RGB remain intact.
 protect=[max(0,box8[0]-48),max(0,box8[1]-48),min(w,box8[2]+48),min(h,box8[3]+48)]
 outside=np.ones(a.shape,dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
 values,counts=np.unique(a[outside&(a>0)],return_counts=True)
 pad=[int(np.ceil(w*.27)),int(np.ceil(h*.27))]
 after=[(box[0]+pad[0])/(w+2*pad[0]),(box[1]+pad[1])/(h+2*pad[1]),(w+pad[0]-box[2])/(w+2*pad[0]),(h+pad[1]-box[3])/(h+2*pad[1])]
 prompt=HERE/'production/prompts/rendered'/('bianzhou_20261028d_'+name+'.txt')
 row={'id':name,'status':'RAW_CANDIDATE_NOT_IMPORTED_NOT_FORMAL','path':str(dst.relative_to(ROOT)).replace('\\','/'),
  'original_builtin_path':str(src),'sha256':sha(dst),'size_px':[w,h],'alpha_extrema':[int(a.min()),int(a.max())],
  'complete_A1_bbox':box,'alpha8_diagnostic_bbox_NOT_MARGIN_PASS':box8,'alpha128_diagnostic_bbox':box128,
  'complete_A1_margins':margins,'complete_A1_min15pct_pass':min(margins)>=.15,
  'execution_backend':'builtin_image_gen','actual_calls':1,'fallback_used':False,'cli_calls':0,
  'model':None,'provider':None,'cost':None,'prompt_path':str(prompt.relative_to(ROOT)).replace('\\','/'),'prompt_sha256':sha(prompt),
  'reference_images':['assets/raw/bianzhou_southgate_20261028/main_gatehouse_v1.png'],
  'reference_role':'material_brick_scale_upper_left_daylight_fixed_camera_only',
  'source_original_pixels_preserved':True,'local_pixel_processing':False,
  'proposed_padding_ONLY_not_executed':{'offset_px':pad,'canvas_px':[w+2*pad[0],h+2*pad[1]],'complete_A1_min_margin_after':min(after),'all_old_RGBA_preserved':True},
  'subject_protection_proposal_NOT_AUTHORIZED':protect,'alpha_outside_protection_histogram':dict(zip([str(int(x))for x in values],[int(x)for x in counts]))}
 (RAW/(name+'.meta.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 rows.append(row)
(HERE/'raw_manifest.json').write_text(json.dumps({'status':'FOUR_RAW_ONLY_NO_LOCAL_PROCESSING_OR_IMPORT','assets':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
