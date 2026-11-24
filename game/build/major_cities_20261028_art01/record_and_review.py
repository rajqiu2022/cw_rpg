from pathlib import Path
import json
import hashlib
import shutil
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = ROOT / 'assets/raw/bianzhou_southgate_20261028'
RAW.mkdir(parents=True, exist_ok=True)
GENERATED = Path('C:/Users/rajqiu/.codex/generated_images/01a18152-0fdc-7e50-9bcd-6b4c3a1f7db5')
SOURCES = {
    'connected_barbican_v1': 'exec-2c63674f-7bf7-4fde-be7b-5e019907b4e9.png',
    'main_gatehouse_v1': 'exec-cb83e2e6-5a72-4419-b8b6-7612a9727c53.png',
    'west_barbican_sidewall_v1': 'exec-7b1498d1-bf0d-470f-9998-1df26faf9e2f.png',
    'east_barbican_sidewall_v1': 'exec-798a3dff-011a-4959-8d84-c7b1861247ee.png',
    'front_barbican_gate_v1': 'exec-9bf85dd1-9e05-4920-981d-dbe66ce808e0.png',
    'checkpoint_shelter_v1': 'exec-795914b2-ff32-4c96-9dc8-8a15f020bb29.png',
}
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def facts(path):
    im = Image.open(path).convert('RGBA')
    alpha = im.getchannel('A')
    bbox = alpha.getbbox()
    diag = alpha.point(lambda v: 255 if v >= 8 else 0).getbbox()
    return im, {'size': im.size, 'complete_A1_bbox': bbox,
                'alpha8_diagnostic_bbox_NOT_MARGIN_PASS': diag,
                'sha256': sha(path), 'alpha_extrema': alpha.getextrema()}
rows=[]
board=Image.new('RGB',(1500,1040),(96,103,94))
draw=ImageDraw.Draw(board)
for i,(name,filename) in enumerate(SOURCES.items()):
    src=GENERATED/filename
    dst=RAW/(name+'.png')
    if not dst.exists(): shutil.copyfile(src,dst)
    assert sha(src)==sha(dst)
    im,fact=facts(dst)
    row={'id':name,'raw_path':str(dst.relative_to(ROOT)).replace('\\','/'),
         'status':'RAW_ONLY_NOT_IMPORTED_NOT_FORMAL',
         'execution_backend':'builtin_image_gen','intent':'generate',
         'actual_calls':1,'edit_calls':0,'cli_calls':0,'fallback_used':False,
         'model':None,'provider':None,'cost':None,'original_builtin_path':str(src),
         'prompt_path':str((HERE/'production/prompts/rendered'/('bianzhou_20261028_'+name+'.txt')).relative_to(ROOT)).replace('\\','/'),
         'reference_path':'assets/raw/bianzhou_city_masterplan_20261022b/bianzhou_city_masterplan_overview_v1.png',
         'original_pixels_preserved':True,'local_processing':False,**fact}
    row['reference_images']=[row['reference_path']]
    if name=='connected_barbican_v1':
        row['reference_images'].append('assets/raw/bianzhou_southgate_20261028/main_gatehouse_v1.png')
    row['prompt_sha256']=sha(ROOT/row['prompt_path'])
    alpha=im.getchannel('A')
    if name in ('main_gatehouse_v1','connected_barbican_v1'):
        runs=[]
        for y in range(580,min(870,im.height),20):
            x=im.width//2
            if alpha.getpixel((x,y)) != 0:
                runs.append({'y':y,'center_alpha':alpha.getpixel((x,y)),'width_exact_zero':0})
                continue
            left=x; right=x
            while left>0 and alpha.getpixel((left-1,y))==0:left-=1
            while right<im.width and alpha.getpixel((right,y))==0:right+=1
            runs.append({'y':y,'left':left,'right':right,'width_exact_zero':right-left})
        row['door_exact_zero_crosssections_DIAGNOSTIC_NOT_FULL_PASS']=runs
    (RAW/(name+'.meta.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    rows.append(row)
    im.thumbnail((480,470))
    x=(i%3)*500+(500-im.width)//2; y=(i//3)*520+35+(470-im.height)//2
    board.paste(im,(x,y),im)
    draw.text(((i%3)*500+8,(i//3)*520+8),name,fill='white')
board.save(HERE/'southgate_true_alpha_contact.jpg',quality=92)
(HERE/'raw_manifest.json').write_text(json.dumps({'status':'SIX_RAW_REVIEW_ONLY_SELECTED_THREE_HAVE_SEPARATE_AUTHORIZED_DERIVATIVES','assets':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
