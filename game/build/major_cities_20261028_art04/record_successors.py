from pathlib import Path
import json,hashlib,shutil
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
RAW=ROOT/'assets/raw/bianzhou_enclosure_20261028d'
GENERATED=Path('C:/Users/rajqiu/.codex/generated_images/01a181b1-8918-7ad2-b405-056a75739311')
FILES={'west_longitudinal_wall_v2_edit':'exec-5e6e48fa-b8f3-4f4d-897b-931d71c43f7c.png',
'east_longitudinal_wall_v2_edit':'exec-2a3ce453-04c9-40e5-9264-6f8fd29c0d3e.png',
'compacted_earth_tile_v1':'exec-07bb8330-a012-4228-b06f-e5c44db231d0.png'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def box(mask):
 y,x=np.nonzero(mask);return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
rows=[]
for name,file in FILES.items():
 src=GENERATED/file;dst=RAW/(name+'.png')
 if not dst.exists():shutil.copyfile(src,dst)
 assert sha(src)==sha(dst)
 im=Image.open(dst);a=np.asarray(im.convert('RGBA'))[:,:,3];h,w=a.shape
 b=box(a>0);b8=box(a>=8)
 protect=[max(0,b8[0]-48),max(0,b8[1]-48),min(w,b8[2]+48),min(h,b8[3]+48)]
 outside=np.ones(a.shape,dtype=bool);outside[protect[1]:protect[3],protect[0]:protect[2]]=False
 vals,counts=np.unique(a[outside&(a>0)],return_counts=True)
 pad=[int(np.ceil(w*.27)),int(np.ceil(h*.27))]
 row={'id':name,'path':str(dst.relative_to(ROOT)).replace('\\','/'),'sha256':sha(dst),'size_px':[w,h],'native_mode':im.mode,
 'complete_A1_bbox':b,'alpha8_diagnostic_bbox_NOT_MARGIN_PASS':b8,'alpha_extrema':[int(a.min()),int(a.max())],
 'status':'RAW_CANDIDATE_NOT_IMPORTED_OR_FORMAL','execution_backend':'builtin_image_gen','actual_calls':1,'intent':'edit'if name.endswith('edit')else'generate',
 'original_builtin_path':str(src),'local_pixel_processing':False,'fallback_used':False,'model':None,'provider':None,'cost':None,
 'prompt_path':'game/build/major_cities_20261028_art04/production/prompts/rendered/bianzhou_20261028d_'+name+'.txt',
 'subject_protection_proposal_NOT_AUTHORIZED':protect,'outside_protection_alpha_histogram':dict(zip(map(str,map(int,vals)),map(int,counts))),
 'padding_proposal_NOT_EXECUTED':{'offset_px':pad,'canvas_px':[w+2*pad[0],h+2*pad[1]],'old_RGBA_RGB_unchanged':True},
 'reference_images':[] if name.startswith('compacted') else ['assets/raw/bianzhou_enclosure_20261028d/'+name.replace('v2_edit','v1')+'.png','assets/raw/bianzhou_southgate_20261028/main_gatehouse_v1.png']}
 row['prompt_sha256']=sha(ROOT/row['prompt_path'])
 if name.startswith('compacted'):row['padding_proposal_NOT_EXECUTED']=None;row['subject_protection_proposal_NOT_AUTHORIZED']=None
 (RAW/(name+'.meta.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 rows.append(row)
(HERE/'successor_raw_manifest.json').write_text(json.dumps({'status':'TWO_ONE_EDIT_SUCCESSORS_AND_ONE_RGB_TILE_RAW','assets':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Selected4 keeps original4 manifest immutable and identifies obsolete v1 walls.
initial=json.loads((HERE/'raw_manifest.json').read_text(encoding='utf-8'))['assets']
selected=[initial[0],rows[0],rows[1],initial[3]]
(HERE/'selected_four_manifest.json').write_text(json.dumps({'status':'SELECTED_GEOMETRY_CANDIDATES_NEED_JOINTS_AND_NEW_SCOPE_APPROVAL','assets':selected,'rejected_for_repetition':['west_longitudinal_wall_v1','east_longitudinal_wall_v1'],'rgb_ground':rows[2]},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
