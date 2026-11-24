"""Registered native additions for correcting the rejected grid-like Miao layout."""
import json
import os
import shutil
import sys
from pathlib import Path
import yaml
from PIL import Image
from build_redrock_town_20261028a import ROOT, save, sha

NAME='miao_recompose_20261029g';RAW=ROOT/'assets/raw'/NAME;STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project'
ART='art/modules/'+NAME;SCENE='scenes/drafts/'+NAME+'/miao_town.tscn';SCRIPT='scripts/drafts/'+NAME+'/town_controller.gd';QUEUE=STAGE/'production/prompts'
COMMON='''Use case: stylized-concept
Create ONE independent native game module matching the APPROVED Miao-inspired mountain town reference. Reference is STYLE/ARCHITECTURE only; do not reproduce its whole scene or labels. Realistically painted 2.5D wuxia RPG, elevated orthographic view from south with modest RIGHT depth, vertical posts remain vertical. Warm aged brown timber, matte dark gray slate, irregular cool gray mossy stone, rich natural green vegetation. Bright overcast daylight, realistic small material scale, no heavy outline or toy model. A complete isolated subject SMALL centered on actually TRANSPARENT alpha0 canvas with at least20% empty margin ALL sides. All eaves, contact feet, trees and posts intact. No people, text, label, watermark, modern objects, palace ornament, desert or red sandstone.
Specific module:
'''
ITEMS={
 'stilt_house':('building','苗风山城·高脚临坡木楼',True,'One substantial TWO-STOREY timber STILT HOUSE with an exposed tall structural timber subfloor, closely matching the large sloping-site houses in the reference. Broad asymmetric slate pitched roofs, an ordinary adult FRONT DOOR onto a narrow balcony at the UPPER END of exposed stilt posts. Woven indigo cloth over one balcony rail, small ordinary shutter windows. Tall slender braced timber legs descend about one entire room height below the usable porch, visible irregular low stone feet, NO enclosing gray masonry basement. Roof and balcony long axis horizontal, only modest right depth; the usable front balcony is a broad almost horizontal strip. No attached huge staircase, ground island, neighboring house or trees. Whole architecture intact, tall stilt supports essential.'),
 'market_stilt':('building','苗风山城·临水吊脚铺街',True,'ONE complete connected THREE-BAY waterside timber MARKET MODULE. Three modest adjoining gray slate pitched shop roofs at slightly different heights, open shaded front stalls with baskets, folded indigo cloth, pots and produce, restrained ivory/indigo awnings. A SINGLE broad continuous walkable timber FRONT BOARDWALK runs horizontally across all three stalls, with open back shop thresholds and no rail blocking shop entrances. The boardwalk and shops stand on TALL slender timber piles and cross-bracing descending one room height to irregular stone footings BELOW the front deck; no solid masonry basement. Make the boardwalk top an unbroken nearly horizontal exposed strip spanning full width and wide enough for two adults. About3times wider than total height. At the very front edge, sparse low timber rail segments with clearly open access gaps. No water, ground plane, figures, labels, surrounding town, whole market square or large background.'),
 'rock_bank':('landform','苗风山城·苔岩曲岸坡',True,'ONE broad gently CURVING IRREGULAR ROCKY SLOPE MODULE for the side of a mountain village terrace. Natural layered cool gray limestone outcrops and broken low DRY-STONE retaining fragments, rich moss and ferns in crevices, tiny shrubs at one end. The upper edge is ragged, NOT a ruler-straight wall, the visible front face varied height with sloping shoulder ends. A few embedded broad flat stone ledges at top, no constructed stairs. About3.5times wider than high, no isolated giant monolith, rectangular plinth, regular battlements, full cliff background, house, tree, water or sand. Entire irregular silhouette and contact stones preserved.'),
 'waterfall':('landform','苗风山城·山溪叠瀑',True,'ONE isolated small mountain STREAM CASCADE module, winding clear blue-green water descending over3irregular low cool-gray boulder steps toward the lower right, white narrow broken cascades and a small irregular downstream pool. Rich moss, ferns, a few small grass clumps around boulders. Elevated orthographic view, balanced compact vertical shape, complete boulders and pool edges. No large surrounding landscape, house, bridge, figures, text, giant Niagara waterfall, rectangle or floating haze. This is a small upper creek scenery module for placement into a separately rendered creek.'),
 'boardwalk':('building','苗风山城·临溪木栈道',True,'ONE straight horizontal TIMBER BOARDWALK module with a broad exposed continuous plank walking TOP and tall thin wooden supporting piles/braces underneath, no roof or shop. Long front plank edge horizontally straight, modest right-end depth. The elevated exposed floor is wide enough for two adults to pass; simple low timber railing ONLY along the far/back edge, FRONT edge open with just two sparse short rail sections at both extreme ends, broad middle entrance open. Tall support piles descend about the visible deck width below the walking surface, no stone wall. About4times wider than total height. Wood warm aged brown, no water, shore, landscape, people or text, entire board and all feet intact.'),
 'woodland_floor':('ground','苗风山城·苔草湿土底材',False,'A flat seamless TOP-DOWN terrain texture filling the entire square canvas, small natural mottled moss-green grass, damp earthy gray-brown soil with tiny limestone grit and brown leaf litter. Dense fine ground cover, subtle organically broken green patches and exposed soil, realistic scale, no large stone paving, perspective, trees, boulders, paths, borders, light vignette, objects, shadows or text. Opaque texture, natural bright woodland green and neutral earth, no desert brown carpet.')}

def prepare():
    assert not (RAW/'manifest.json').exists();QUEUE.mkdir(parents=True,exist_ok=True);RAW.mkdir(parents=True,exist_ok=True);(QUEUE/'templates').mkdir(exist_ok=True)
    templates={'native_alpha':{'name':'native_alpha','prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'transparent'},'native_opaque':{'name':'native_opaque','prompt_template':'{asset_prompt}','size':'1024x1024','quality':'high','background':'opaque'}}
    for key,value in templates.items():(QUEUE/'templates'/(key+'.yaml')).write_text(yaml.safe_dump(value,allow_unicode=True),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates';rows=[];tasks=[]
    for key,(kind,label,transparent,detail) in ITEMS.items():
        prompt=COMMON+detail
        if not transparent:prompt='Use case: stylized-concept\nOpaque environment material for the approved Miao-inspired mountain town.\n'+detail
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8');template='native_alpha' if transparent else 'native_opaque'
        assert renderer.render_template(template,{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        rows.append({'key':key,'kind':kind,'label':label,'id':NAME+'_'+key+'_v1','prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'transparent':transparent,'calls':0,'status':'REGISTERED','model':None,'provider':None,'cost':None,'fallback_used':False})
        tasks.append({'id':NAME+'_'+key+'_v1','template':template,'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'vars':{'asset_prompt':prompt}})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':tasks},allow_unicode=True,sort_keys=False),'utf-8')
    save(RAW/'manifest.json',{'status':'REGISTERED','backend':'builtin_image_gen','assets':rows})
    old=json.loads((ROOT/'assets/staging/miao_town_20261029f/protected-before.json').read_text('utf-8'))
    paths={Path(r['path']) for r in old};paths.update(ROOT/r['path'] for r in json.loads((ROOT/'assets/staging/miao_town_20261029f/publication.json').read_text('utf-8'))['files'])
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths)])
    save(STAGE/'preflight.json',{'passed':True,'tasks':6,'actual_renderer':True,'builtin_only':True,'root_queue_written':False})
    print('Six independent native modules registered, actual renderer preflight passed; previous version protected')

def start(key):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(x for x in m['assets'] if x['key']==key);assert r['calls']==0
    r['calls']=1;r['status']='DISPATCHED';save(RAW/'manifest.json',m);print((ROOT/r['prompt']).read_text('utf-8'))

def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(x for x in m['assets'] if x['key']==key);assert r['status']=='DISPATCHED'
    source=Path(source);dst=RAW/r['kind']/(r['id']+'.png');dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copyfile(source,dst)
    im=Image.open(dst);r.update(size=list(im.size),mode=im.mode)
    if r['transparent']:
        assert im.mode=='RGBA';b=im.getchannel('A').getbbox();w,h=im.size;margins=[b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h]
        r['metrics']={'full_alpha_bbox':list(b),'margins':margins,'margin_10_percent_pass':min(margins)>=.1}
    assert sha(source)==sha(dst);r.update(output=dst.relative_to(ROOT).as_posix(),source_path=str(source),sha256=sha(dst),status='RAW_CANDIDATE')
    save(RAW/'manifest.json',m);save(dst.with_suffix('.meta.json'),r);save(RAW/'resource-pack.json',{'status':'NATIVE_EDITOR_CANDIDATES','assets':[x for x in m['assets'] if x.get('output')]})
    print(json.dumps({'key':key,'size':r['size'],'raw_A1':r.get('metrics',{}).get('margin_10_percent_pass')}))

if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
