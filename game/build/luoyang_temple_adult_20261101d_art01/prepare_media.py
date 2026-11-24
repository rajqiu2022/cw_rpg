"""One authorized deterministic alpha-one cleanup, not image generation/import.
Preserve RAW file, all source RGB, all protected RGBA and alpha>1 everywhere.
New runtime/report/raw metadata outputs are exclusive; no crop/resample.
"""
from pathlib import Path
from collections import Counter
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RAW = ROOT / 'assets/raw/city_navigation_20261101d/east_scripture_hall_v1.png'
PROMPT = ROOT / 'prompts/city_navigation_20261101d/east_scripture_hall_v1.txt'
OUT = ROOT / 'game/art/modules/city_navigation_20261101d/east_scripture_hall_v1.png'
REPORT = HERE / 'media_ACTUAL.json'
META = RAW.with_suffix('.meta.json')
EXPECTED = '82ff8ae6afbc5549c47bf0aa29a5404aef648dd11fb214d24b9a288da506596b'
PROTECTED = (8, 104, 1528, 904)
PADDING = 64

def sha(data):
    return hashlib.sha256(data).hexdigest()

def box(im, threshold):
    result = im.getchannel('A').point(lambda n:255 if n>threshold else 0).getbbox()
    return list(result) if result else None

def new_json(path, value):
    with path.open('x', encoding='utf-8', newline='\n') as stream:
        stream.write(json.dumps(value, ensure_ascii=False, indent=2)+'\n')

def main():
    assert all(not p.exists() for p in (OUT, REPORT, META)), 'NEW_OUTPUTS_ONLY'
    raw_bytes = RAW.read_bytes()
    assert sha(raw_bytes)==EXPECTED
    with Image.open(RAW) as opened:
        opened.load()
        assert opened.mode=='RGBA' and opened.size==(1536,1024)
        image=opened.copy()
    before=image.tobytes()
    original_gt1=box(image,1)
    assert original_gt1==[15,113,1520,894]
    left,top,right,bottom=PROTECTED
    assert left<=15<1520<=right and top<=113<894<=bottom
    modified=bytearray(before)
    changes=0
    for y in range(image.height):
        for x in range(image.width):
            if left<=x<right and top<=y<bottom:
                continue
            at=(y*image.width+x)*4+3
            if modified[at]==1:
                modified[at]=0
                changes+=1
    cleaned=Image.frombytes('RGBA',image.size,bytes(modified))
    assert cleaned.convert('RGB').tobytes()==image.convert('RGB').tobytes()
    assert cleaned.crop(PROTECTED).tobytes()==image.crop(PROTECTED).tobytes()
    diffs=[i for i,(a,b) in enumerate(zip(before,modified)) if a!=b]
    assert len(diffs)==changes
    for i in diffs:
        y,x=divmod(i//4,image.width)
        assert i%4==3 and before[i]==1 and modified[i]==0
        assert not(left<=x<right and top<=y<bottom)
    assert box(cleaned,1)==original_gt1
    padded=Image.new('RGBA',(image.width+2*PADDING,image.height+2*PADDING),(0,0,0,0))
    padded.paste(cleaned,(PADDING,PADDING))
    assert padded.crop((PADDING,PADDING,PADDING+image.width,PADDING+image.height)).tobytes()==bytes(modified)
    for rect in ((0,0,padded.width,PADDING),(0,padded.height-PADDING,padded.width,padded.height),(0,0,PADDING,padded.height),(padded.width-PADDING,0,padded.width,padded.height)):
        assert not any(padded.crop(rect).tobytes())
    OUT.parent.mkdir(parents=True,exist_ok=True)
    with OUT.open('xb') as stream:
        padded.save(stream,format='PNG')
    with Image.open(OUT) as reread:
        assert reread.mode=='RGBA' and reread.size==padded.size and reread.tobytes()==padded.tobytes()
    assert RAW.read_bytes()==raw_bytes
    report={
        'status':'PREPARED_NOT_IMPORTED_NOT_BOUND_ART_FIT_PENDING',
        'raw':RAW.relative_to(ROOT).as_posix(),'runtime':OUT.relative_to(ROOT).as_posix(),
        'raw_sha256':sha(raw_bytes),'runtime_sha256':sha(OUT.read_bytes()),
        'raw_bytes':len(raw_bytes),'runtime_bytes':OUT.stat().st_size,
        'raw_size':list(image.size),'runtime_size':list(padded.size),
        'raw_alpha_bboxes':{str(v):box(image,v) for v in (0,1,2,8,32,64,128,200,250)},
        'runtime_alpha_gt0_bbox':box(padded,0),'runtime_alpha_gt1_bbox':box(padded,1),
        'protected_source_RGBA_box':list(PROTECTED),'padding_RGBA0_each_side':PADDING,
        'alpha1_outside_protected_cleared':changes,
        'all_source_RGB_exact':True,'protected_RGBA_exact':True,'all_alpha_gt1_exact':True,
        'source_file_unchanged':True,'source_canvas_retained_at_offset':[PADDING,PADDING],
        'padding_all_RGBA0':True,'PNG_RGBA_roundtrip_exact':True,
        'raw_RGBA_sha256':sha(before),'cleaned_RGBA_sha256':sha(bytes(modified)),
        'runtime_RGBA_sha256':sha(padded.tobytes()),
        'alpha0_hidden_RGB_not_background':True,'higher_alpha_mist_not_removed':True,
        'no_crop':True,'no_resample':True,'no_resynthesis':True,
        'engine_runs':0,'import_writes':0,'generation_calls_by_this_script':0,
        'authorization':'Standing user authorization reported by Root: only protected-box-exterior alpha1 clear plus RGBA0 padding; preserve RAW/RGB/protected RGBA. No higher-alpha extraction.',
    }
    new_json(REPORT,report)
    metadata={
        'schema':'BUILTIN_GENERATED_MAP_ASSET_V1','asset_id':'city_navigation_20261101d_east_scripture_hall_v1',
        'status':'NATIVE_PREPARED_FIT_PENDING_NOT_ADOPTED',
        'backend':'built-in_image_gen','generation_calls_reported_by_root':1,
        'model':None,'model_status':'model_not_exposed','provider':None,'cost':None,
        'model_identity_verified':False,'fallback_used':False,
        'prompt_path':PROMPT.relative_to(ROOT).as_posix(),'prompt_sha256':sha(PROMPT.read_bytes()),
        'raw_path':report['raw'],'raw_sha256':EXPECTED,'requested_size':[1536,1024],
        'actual_size':list(image.size),'raw_bytes_preserved':True,
        'runtime_path':report['runtime'],'runtime_sha256':report['runtime_sha256'],
        'runtime_size':list(padded.size),'processing_report':REPORT.relative_to(ROOT).as_posix(),
        'processing_report_sha256':sha(REPORT.read_bytes()),
        'original_generated_path':None,'original_path_status':'Root supplied verified project RAW; original generated path not supplied to this role',
        'deterministic_processing':report,
        'visual_review':'Root and Art viewed complete five-bay hall/plaque/base. At950 visible width, height/door/base ratios differ from prompt; fit awaits Root decision and runtime normal-camera review.'
    }
    new_json(META,metadata)
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=='__main__':
    main()
