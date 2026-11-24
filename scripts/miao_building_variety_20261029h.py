"""Registered native architecture with different massing, not random rescaling of one house."""
import json
import sys
import shutil
from pathlib import Path
import yaml
from PIL import Image
from build_redrock_town_20261028a import ROOT, save, sha
NAME='miao_building_variety_20261029h';RAW=ROOT/'assets/raw'/NAME;STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project'
ART='art/modules/'+NAME;SCENE='scenes/drafts/'+NAME+'/miao_town.tscn';SCRIPT='scripts/drafts/'+NAME+'/town_controller.gd';QUEUE=STAGE/'production/prompts'
REFERENCE='assets/raw/miao_town_design_20261029e/miao_masterplan_overview_v1.png'
COMMON='''Use case: stylized-concept
Input image1 is ONLY approved Miao-inspired mountain town architecture/style reference. Generate ONE NEW complete isolated game building module. Keep the established warm aged brown timber, matte dark-gray slate tiles, restrained indigo/ivory cloth, cool-gray mossy stone, realistic painted2.5D wuxia art, fine material detail, bright overcast light. Elevated ORTHOGRAPHIC south camera, modest side depth, all vertical posts VERTICAL; no exaggerated wide-angle lens. Whole subject SMALL centered on actual TRANSPARENT alpha0 canvas with generous20%empty margins ALLsides, all eaves and supports intact. No people, text, labels, watermark, surrounding town/ground island, palatial red/gold decoration, fantasy tower, shrine, ritual, silver crown, desert or modern tourism features. The building silhouette must strongly DIFFER from the repeated two-storey square houses in the earlier game scene. Ordinary exterior doors/windows have consistent ADULT proportions; small storage hatches may be smaller only where explicitly requested. This is original architecture, not a crop of the concept.
Specific architecture:
'''
ITEMS={
 'wide_hall':('building','苗风山城·宽檐公共木厅',COMMON+'''A BROAD LOW communal timber gathering hall with FIVE structural bays, about4ordinary adult door widths across, one long dark-gray slate pitched main roof and a lower projecting full-width OPEN veranda roof, a shallow modest loft above the central3bays. Practical plain timber joinery and squat cool-gray stone foundation, sturdy round columns, ordinary central double door at back of veranda,2plain side doors, simple benches at outer ends. Strong WIDE HORIZONTAL silhouette and varied roof depth, roughly2times wider than tall; much broader than a one-family dwelling, but everyday community building not palace/temple. A clearly visible FRONT landing with3short low steps and wide open apron edge. Center door should be aboutone fifth of full building height; do not enlarge doors to match the whole facade. No detached whole courtyard, fences or neighboring houses.'''),
 'narrow_inn':('building','苗风山城·窄高三层木楼',COMMON+'''A NARROW TALL THREE-STOREY timber lodging house with exactly THREE clearly stacked inhabited floors: ground floor ordinary adult entrance, secondfloor2small shutter windows and a narrow balcony, thirdfloor2small windows under a steep compact gray-slate gable roof. A tiny attached one-storey side kitchen roof on LEFT breaks symmetry. Woodplank facade, thin balcony rails, modest low stone feet and3short front steps, NO high stilt undercroft. Fullbuilding about1.6times taller than wide and about6ordinary entrance-door heights tall, footprint onlytwo adult doorway widths. Vertical silhouette, steep gable roof/ridge points FRONT-to-BACK, LEFT gable/depth face visible to differ from broad horizontal houses. Three window tiers essential, not one giant window and not a pagoda. No sign or writing.'''),
 'small_cottage':('building','苗风山城·低矮单间木宅',COMMON+'''A genuinely SMALL SINGLE-STOREY ONE-ROOM timber cottage, one ordinary full-height adult entrance door and one small shutter window beside it, compact low simple gray slate single gable roof with uneven modest eaves, low stone plinth, only2front steps. No upperfloor, balcony or tall stilt supports. Whole building about2entrance-door heights tall and1.8ordinary doorway widths wide. Narrow side lean-to firewood nook attached on RIGHT, a few firewood pieces below it. Low compact silhouette, intact small ordinary house, restrained warm weathered wood, not toy proportions or a shrunk mansion. Front-left gable wall slightly visible. No vegetation or separate props.'''),
 'angle_workshop':('building','苗风山城·转角长廊作坊',COMMON+'''A LOW ASYMMETRIC L-SHAPED timber craft workshop. One long one-storey open-front work porch with4slender columns and a shallow gray-slate shed roof extends LEFT, connected to one compact2storey square storage room set back at RIGHT with an ordinary adult door and2small upper shutters under a different short gable roof. The open LEFT porch holds a simple wooden loom, a worktable and a couple indigo folded cloth bundles, leaving frontentry open. Distinct re-entrant corner between two wings visible from elevated view, varied roof directions and heights; more than3times wider than the short open porch height, mostly low and horizontal. Timber on modest irregular stone feet, no enormous stair, roof connecting into whole courtyard, hanging sign, fully closed frontage or repeating 3same shop gables.'''),
 'tiny_granary':('building','苗风山城·小型高脚粮棚',COMMON+'''A TINY practical RAISED GRAIN STORE, clearly ancillary storage rather than a dwelling: small square rough timber bin on FOUR short wooden legs with round rat-guard discs, ONE steep gray-slate pyramid/gable roof, one SMALL LOCKED STORAGE HATCH on front and a short removable3rung wooden ladder resting against it. Building footprint onlyabout1.2adultbody widths, totalheight about1.8adultheights; this is intentionally much smaller than an inhabited house. No adult entrance door, windows, upperstorey, balcony, porch, masonry basement, figure or text. One complete distinct compact silhouette, all4feet and ladder intact.''')}

def prepare():
    assert not STAGE.exists() and not RAW.exists();QUEUE.mkdir(parents=True);RAW.mkdir();(QUEUE/'templates').mkdir()
    template={'name':'native_alpha','prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'transparent'}
    (QUEUE/'templates/native_alpha.yaml').write_text(yaml.safe_dump(template),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates';rows=[];tasks=[]
    for key,(kind,label,prompt) in ITEMS.items():
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8');assert renderer.render_template('native_alpha',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        rows.append({'key':key,'kind':kind,'label':label,'id':NAME+'_'+key+'_v1','prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'reference':REFERENCE,'transparent':True,'calls':0,'status':'REGISTERED','model':None,'provider':None,'cost':None,'fallback_used':False})
        tasks.append({'id':NAME+'_'+key+'_v1','template':'native_alpha','skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'vars':{'asset_prompt':prompt}})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':tasks},allow_unicode=True,sort_keys=False),'utf-8');save(RAW/'manifest.json',{'status':'REGISTERED','backend':'builtin_image_gen','assets':rows})
    prior=ROOT/'assets/staging/miao_recompose_20261029g';paths={Path(r['path']) for r in json.loads((prior/'protected-before.json').read_text('utf-8'))}
    paths.update(ROOT/r['path'] for r in json.loads((prior/'publication.json').read_text('utf-8'))['files'])
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths)])
    save(STAGE/'preflight.json',{'passed':True,'actual_renderer':True,'tasks':5,'builtin_only':True,'root_queue_written':False})
    print('Registered5nativearchitecturetypes; real renderer preflight passed; protected',len(paths))
def start(key):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(x for x in m['assets'] if x['key']==key);assert r['calls']==0 and sha(ROOT/r['prompt'])==r['prompt_sha256']
    r['calls']=1;r['status']='DISPATCHED';save(RAW/'manifest.json',m);print((ROOT/r['prompt']).read_text('utf-8').strip())
def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(x for x in m['assets'] if x['key']==key);assert r['status']=='DISPATCHED'
    src=Path(source);dst=RAW/r['kind']/(r['id']+'.png');dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    im=Image.open(dst);assert im.mode=='RGBA';w,h=im.size;b=im.getchannel('A').getbbox();margins=[b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h]
    r.update(size=[w,h],mode=im.mode,output=dst.relative_to(ROOT).as_posix(),source_path=str(src),sha256=sha(dst),status='RAW_CANDIDATE',metrics={'full_alpha_bbox':list(b),'margins':margins,'margin_10_percent_pass':min(margins)>=.1})
    save(RAW/'manifest.json',m);save(dst.with_suffix('.meta.json'),r);save(RAW/'resource-pack.json',{'status':'NATIVE_EDITOR_CANDIDATES','assets':[x for x in m['assets'] if x.get('output')]});print(json.dumps({'key':key,'size':[w,h],'raw_A1':min(margins)>=.1}))
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
