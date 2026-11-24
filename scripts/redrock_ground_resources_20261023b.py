"""Independent art queue for the concurrent redrock work; no production queue or engine writes."""
import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/redrock_ground_resources_20261023b'
QUEUE=ROOT/'assets/staging/redrock_gate_20261023b/production/prompts'
REFERENCE=ROOT/'assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png'

TEXTURE='''Use case: stylized-concept
Asset type: ONE square seamless ground texture for a 2.5D wuxia desert canyon town. FULLY OPAQUE texture, not a scene or transparent cutout.
Image 1 is MATERIAL/COLOUR reference only, from the selected redrock pass-town masterplan. New generated surface, no crop from reference.
Camera exactly top-down flat orthographic, texture perpendicular to camera, no horizon or perspective. Matte warm muted rust/ochre red earth, clear neutral daylight from high upper-left but no strong directional cast shadows. Fine hand-painted game art, moderate low-frequency variation, quiet readable ground at 112px adult scale. No text, frame, grid, road markings, buildings, large objects, vegetation, people, cliff silhouette, puddles, tile borders, black/white empty area or UI. Fill the ENTIRE square with surface. Opposite edges must match in tone, height cues and pattern; no dark edge vignette, central spotlight or repeated obvious large landmark.
Requested surface:
'''
CUTOUT='''Use case: stylized-concept
Asset type: ONE reusable 2.5D map component for the selected redrock canyon town. TRUE TRANSPARENT background.
Image 1 is style/material reference only. New independent component, not a full scene and not cropped concept pixels. Warm muted rough red sandstone with dusty ochre soil and plain dark wood as appropriate, no Chinese tiled roofs or European ornament. Fixed orthographic slightly overhead map camera, see top and small right depth face, light from upper-left, matte painterly game detail. Whole component centered inside central 68% of canvas WIDTH and HEIGHT, including weak alpha and shadow, at least16% clear truly transparent margin on all sides. No broad baked floor square, glow, fog, halo, people, text, UI, picture frame, labels or secondary assets. All geometry intact, no cropped ends. Shadow only tiny attached contact shade.
Requested component:
'''
ITEMS={
 'earth':('ground','赤岩·细夯土地表',False,TEXTURE+'''Dry compacted fine-grain red-ochre road earth, modest wheel polish and many tiny embedded pale stone flecks, faint shallow irregular foot wear but no recognizable footprints. Low-amplitude unevenness, small pebbles only, no giant mud clods, large cracks, brick grid, distinct ruts crossing the image or tessellated polygon look. Compatible with desert town footpaths and service yards. Full opaque seamless square.
'''),
 'rock':('ground','赤岩·裸岩地表',False,TEXTURE+'''Mostly level exposed red sandstone ground surface with shallow irregular sedimentary laminations, scattered fine windblown red dust collected in small seams, restrained pale mineral flecks. Subtle broad rock forms at ground level, no high boulders or deep ravine, no photogrammetry noise. Slightly darker/rougher than the packed-earth road but same climate and palette. Full opaque seamless square.
'''),
 'ramp':('building','赤岩·缓坡接道模块',True,CUTOUT+'''ONE low broad earthen-and-stone approach RAMP with a shallow grade, rising gently toward SCREEN TOP. Map footprint rectangular about twice as long as wide, slope about1:10; top surface warm compacted fine red earth with two subtle worn wheel tracks, retained by very low red-stone edging on left and right. Open and FLUSH at BOTH the front-low and rear-high road interfaces, no gate, railing, stairs, doorway or crossbar at either end. A short wedge's right depth face explains its SMALL rise; it must not be a tall bridge, steep staircase, raised square platform or isolated giant cliff. Narrow irregular contact strip around the stone base only, transparent outside; no broad landscape island. Practical route suitable for a pack animal/cart, no carved symbolism.
'''),
 'rail':('building','赤岩·低石护栏直段',True,CUTOUT+'''ONE short straight LOW STONE GUARDRAIL, long axis left-to-right, with THREE rough red-sandstone square posts and TWO plain dark-timber horizontal rails between each pair. Waist-high to an adult, robust practical cliff-edge safety barrier, open empty gaps between posts and rails, no solid high wall, crenellations, fort tower or gate. Posts flush to SAME ground baseline, complete plain cut ends for joining further segments. No path/ground deck beneath, no steps, rope banner or attached cliff. Width roughly3.5 times visible height, whole part small and human-scaled.
'''),
}


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')


def prepare():
    assert not (BASE/'manifest.json').exists()
    BASE.mkdir(parents=True,exist_ok=True);(QUEUE/'templates').mkdir(parents=True,exist_ok=True)
    sys.path.insert(0,str(ROOT/'scripts'));import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    tasks=[];rows=[]
    for key,(kind,label,transparent,prompt) in ITEMS.items():
        template='redrock_ground_'+key+'_20261023b'
        definition={'name':template,'prompt_template':'{asset_prompt}','size':'1024x1024','quality':'medium',
                    'background':'transparent' if transparent else 'opaque','reference_images':[str(REFERENCE)],'require_reference_images':True}
        (QUEUE/'templates'/(template+'.yaml')).write_text(yaml.safe_dump(definition,allow_unicode=True,sort_keys=False),'utf-8')
        ident='redrock_20261023b_'+key+'_v1';p=QUEUE/(ident+'.txt');p.write_text(prompt,'utf-8')
        spec=renderer.render_template(template,{'asset_prompt':prompt},{})
        assert spec['prompt']==prompt.strip() and len(spec['reference_images'])==1
        task={'id':ident,'template':template,'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,
              'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':transparent,
              'reference_images':[str(REFERENCE)],'vars':{'asset_prompt':prompt}}
        tasks.append(task);rows.append({'key':key,'id':ident,'kind':kind,'label':label,'transparent':transparent,
                   'status':'REGISTERED','calls':0,'prompt':p.relative_to(ROOT).as_posix(),
                   'reference':REFERENCE.relative_to(ROOT).as_posix(),'reference_sha256':sha(REFERENCE)})
    q=QUEUE/'tasks.yaml';assert not q.exists();q.write_text(yaml.safe_dump({'tasks':tasks},allow_unicode=True,sort_keys=False),'utf-8')
    save(BASE/'manifest.json',{'status':'REGISTERED_IN_INDEPENDENT_ART_WORKSPACE','model':None,'provider':None,'cost':None,
       'formal_enabled':False,'assets':rows,'queue':q.relative_to(ROOT).as_posix(),
       'production_queue_sha256':sha(ROOT/'prompts/tasks.yaml')})
    save(BASE/'preflight.json',{'passed':True,'rendered_tasks':4,'real_references':4,'queue_scope':'Independent art workspace only',
               'production_queue_written':False,'engine_runs':0})
    print(json.dumps({'registered':4,'queue':str(q),'shared_queue_written':False}))


def start(key):
    f=BASE/'manifest.json';m=json.loads(f.read_text('utf-8'));a=next(x for x in m['assets'] if x['key']==key)
    assert a['calls']==0 and a['status']=='REGISTERED';assert sha(ROOT/a['reference'])==a['reference_sha256']
    a.update(calls=1,status='BUILTIN_CALL_DISPATCHED');save(f,m);print(json.dumps(a))


def record(key,source):
    f=BASE/'manifest.json';m=json.loads(f.read_text('utf-8'));a=next(x for x in m['assets'] if x['key']==key)
    assert a['calls']==1 and a['status']=='BUILTIN_CALL_DISPATCHED'
    p=BASE/a['kind']/(a['id']+'.png');assert not p.exists();p.parent.mkdir(exist_ok=True);source=Path(source);shutil.copyfile(source,p)
    assert sha(p)==sha(source)
    with Image.open(p) as im:
        size=list(im.size);mode=im.mode;alpha=im.getchannel('A') if 'A' in im.getbands() else None
        bbox=list(alpha.getbbox()) if alpha is not None else None
        margins=[bbox[0]/im.width,bbox[1]/im.height,(im.width-bbox[2])/im.width,(im.height-bbox[3])/im.height] if bbox else None
    a.update(output=p.relative_to(ROOT).as_posix(),sha256=sha(p),source_path=str(source),prompt_sha256=sha(ROOT/a['prompt']),
       size=size,mode=mode,status='CANDIDATE_NOT_IMPORTED',metrics={'full_alpha_bbox':bbox,'margin_10_percent_pass':bool(margins and min(margins)>=.1) if a['transparent'] else None})
    save(p.with_suffix('.meta.json'),{**a,'model':None,'provider':None,'cost':None,'backend':'builtin_image_gen','fallback_used':False,'formal_enabled':False})
    if all(x.get('output') for x in m['assets']):m['status']='FOUR_NATIVE_CANDIDATES_NOT_IMPORTED'
    save(f,m);print(json.dumps({'key':key,'size':size,'mode':mode,'output':a['output']}))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','start','record']);p.add_argument('--key');p.add_argument('--source');a=p.parse_args()
    if a.action=='prepare':prepare()
    elif a.action=='start':start(a.key)
    else:record(a.key,a.source)
