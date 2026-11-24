"""Native module production for the two user-approved sect plans."""
import json,sys,shutil,hashlib
from pathlib import Path
import yaml
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
NAME='sect_maps_20261029k';RAW=ROOT/'assets/raw'/NAME;STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project';ART='art/modules/'+NAME;QUEUE=STAGE/'production'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
COMMON='''Create ONE isolated complete native game MODULE for a 2.5D hand-painted realistic Chinese wuxia RPG. Input image is style/location reference ONLY, never crop it. Elevated south-facing ORTHOGRAPHIC camera, slight right-side depth visible, vertical supports vertical, no perspective vanishing. All subject small centered on genuine TRANSPARENT alpha0 background with at least20%empty margins on ALLsides. Detailed believable subdued materials, bright daylight, complete silhouette. No people, text, labels, watermark, backdrop landscape, ground island, dramatic shadows outside the footprint, modern objects or spider motifs. Whole ordinary ADULT door height consistent relative to columns/windows; large buildings gain bays and floors, not giant doors. Complete new single module, NOT a whole settlement or asset sheet. Specification:
'''
SPECS={
'wudang_hall':('wudang','武当·五开间道殿','Broad five-bay Daoist main hall, muted aged copper-green glazed tiled sweeping roof with restrained raised corners, dark aged timber columns, THREE ordinary central human-scale doors, side shutter windows, pale-grey stone low plinth and three short entry steps. A smaller secondary roof tier above center, dignified but no imperial gold ornament, no Buddha statues or inscriptions. Wide horizontal silhouette, roof width about7ordinary door heights, fullheight about4door heights.'),
'wudang_gate':('wudang','武当·通行山门','Single Chinese Daoist mountain gateway, copper-green tiled pitched roof on TWO pale-grey stone piers with dark timber frame, one wide completely OPEN central passage showing transparency through it. Ordinary person could walk under comfortably; opening about2adult door widths. Modest connected short white-grey wing walls at each side, low stone base; no doors blocking passage, no attached stairs, no text.'),
'wudang_wing':('wudang','武当·生活厢房','Modest one-storey Daoist living quarters, THREE small bays, copper-green roof, white-grey plaster lower walls and dark timber posts, small ordinary adult door at RIGHT end, two shutter windows, attached low firewood lean-to on LEFT. Long low asymmetric side wing, roof ridge angles front-to-back slightly so gable and long elevation are both visible. No palace ornament or statues.'),
'wudang_pine':('wudang','武当·崖畔松树','ONE mature mountain pine with broad layered irregular dark-green canopy, crooked weathered trunk, exposed roots gripping a SMALL pale-grey limestone base. Whole pine and roots intact, no landscape, no ground island, realistic botanical form, mountain pine not broadleaf orchard tree.'),
'mingwu_hall':('mingwu','茗雾·议事庄厅','Broad five-bay Chinese gentry manor meeting hall: dark matte charcoal tiled pitched roof, clean weathered WHITE plaster side gables, warm brown timber veranda posts and ordinary human-scale central double doorway, low stone plinth with THREE short steps. One main roof only, two smaller side roof ends. Distinct white walls and dark tiles, understated inhabited tea estate rather than imperial or temple architecture, no statues/ritual symbols/signs.'),
'mingwu_guest':('mingwu','茗雾·转角客堂','Asymmetric L-shaped Chinese tea estate guest house with WHITE lime plaster walls, dark charcoal tiled roofs, warm wood windows. One two-storey narrow guest room block at RIGHT and a LONG LOW open front veranda at LEFT with three slim posts, benches and a small tea table. Adult ordinary doors, visibly different roof heights and ridge directions. No full courtyard or boundary wall, no text.'),
'tea_workshop':('mingwu','茗雾·低檐茶作棚','A low practical open-front tea processing shed, rough warm timber posts and a shallow grey-tiled lean-to roof, three bays with woven circular drying trays leaning at back, a sorting workbench at one end, small plain storage cupboard. One story only, rustic and much lower than a manor hall, no white palace wall. No floating tea icons or people.'),
'tea_rows':('mingwu','茗雾·曲线茶垄','A small complete cultivated TEA GARDEN bed containing FOUR short gently curved parallel rows of compact trimmed tea shrubs with rich small green leaves, narrow brown soil working paths between rows. Low tea bushes below adult waist height; shallow gently sloping bed, NO rice paddy tiers, no standing water, no large trees or cliffs. Neat complete patch edges with transparent exterior, no surrounding landscape.'),
'white_wall':('mingwu','茗雾·白墙黛瓦院界','ONE straight horizontal Chinese courtyard wall segment, white weathered lime plaster, dark-grey tiled coping roof and pale stone footing. Front view with modest top depth, both ends clean plain vertical joining ends; no end pillars, gates, doors, windows or vegetation. Wall length about5times visibleheight, ordinary adult eye-level height, subdued fine plaster texture. This is a reusable continuous wall segment.'),
'taiji_floor':('wudang','武当·太极道场石面','ONE flat walkable grey stone courtyard paving disk with a restrained black-and-pale-stone yin-yang inlay in the center, NO raised structure, NO stairs or walls, NO poles or altar. Elevated orthographic view so circular disk appears as a shallow horizontal ellipse, stone paving extends around symbol, low narrow worn stone edge at ground level, no surrounding terrain. Grey stone disk width about8adult door widths. No text or other symbols.')}
def prepare():
    assert not RAW.exists() and not STAGE.exists();RAW.mkdir(parents=True);(QUEUE/'templates').mkdir(parents=True)
    (QUEUE/'templates/native.yaml').write_text(yaml.safe_dump({'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'transparent'}),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates';rows=[]
    for key,(sect,label,spec) in SPECS.items():
        prompt=COMMON+spec;assert renderer.render_template('native',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8');rows.append({'key':key,'sect':sect,'label':label,'prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'calls':0,'status':'REGISTERED','backend':'builtin_image_gen','model':None,'provider':None,'fallback_used':False})
    save(RAW/'manifest.json',{'assets':rows});save(STAGE/'preflight.json',{'real_renderer_passed':True,'count':len(rows)})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':r['key'],'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False} for r in rows]}),'utf-8')
    prior=ROOT/'assets/staging/miao_terrain_20261029i';paths={Path(r['path']) for r in json.loads((prior/'protected-before.json').read_text('utf-8'))};paths.update(ROOT/r['path'] for r in json.loads((prior/'publication.json').read_text('utf-8'))['files'])
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths)])
def start(keys):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));out={}
    for key in keys:
        r=next(r for r in m['assets'] if r['key']==key);assert r['calls']==0;r.update(calls=1,status='DISPATCHED');out[key]={'prompt':(ROOT/r['prompt']).read_text('utf-8'),'reference':str(ROOT/'assets/raw/sect_redesign_20261029j'/(r['sect']+'_masterplan_v2.png'))}
    save(RAW/'manifest.json',m);print(json.dumps(out))
def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['status']=='DISPATCHED'
    src=Path(source);dst=RAW/(key+'.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst);im=Image.open(dst)
    r.update(status='RAW_CANDIDATE',output=dst.relative_to(ROOT).as_posix(),source_path=str(src),sha256=sha(dst),mode=im.mode,size=list(im.size));save(RAW/'manifest.json',m)
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2:]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
