"""Native Huashan modules; independent production ledger and immutable originals."""
import json,sys,shutil,hashlib
from pathlib import Path
import yaml
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
NAME='huashan_map_20261029m';RAW=ROOT/'assets/raw'/NAME;STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project';ART='art/modules/'+NAME;QUEUE=STAGE/'production'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
COMMON='''Create ONE complete isolated native 2.5D Chinese wuxia RPG module. Reference is only architectural style; redraw an individual module, never crop the masterplan. Semi-realistic hand-painted high detail, elevated SOUTH-facing orthographic camera showing front and slight right-side depth, vertical posts vertical, no perspective vanishing. Pale cold grey granite, dark slate-grey roof tiles and muted reddish-brown aged timber. Bright neutral daylight, fine restrained texture. Complete silhouette small centered within generous 20 percent genuinely transparent alpha0 margin on every side. No people, typography, flags, logos, mountains/background/ground island, distant scenery or detached objects; no huge cast shadow, no Daoist symbols, no turquoise roofs or imperial gold. Adult doors consistent: add bays/storeys for size, never gigantic doors. One object only. Specification: '''
SPECS={
'main_hall':('华山·五开间剑院主堂','A substantial broad FIVE-BAY sword-school assembly hall, dark slate tiled roof with modest ridge and slightly upturned corners, one main roof with lower right-side veranda eave, reddish brown timber posts, pale grey plaster infill, THREE ordinary central door leaves and shutter windows. Roof width seven adult door heights; full building height about4adult door heights. Wide low grey granite plinth with only two entry steps. Spacious front veranda; no attached courtyard, banners or statues. Strong horizontal roof silhouette.',True),
'mountain_gate':('华山·双柱通行山门','ONE small open mountain gateway, a grey tiled roof on TWO square granite piers with reddish wood crossbeam. A single broad fully OPEN passage showing genuine transparency through it, passage clear width about2.5adult widths, clear height2.4metres. Two piers only, no solid center threshold, no doors, no wing walls, no staircase, no plaques. Entire object about4adult heights wide and2.5adult heights tall. Plain joinable pier sides.',True),
'dormitory':('华山·横向弟子长舍','ONE long low four-bay single-storey disciple residence, slate grey pitched roof, reddish-brown timber structure with weathered pale plaster, TWO ordinary adult doors separated by shutter windows. An open porch along front with 5 slim posts, small firewood lean-to joined at RIGHT end. Width about6adult door heights, height2.4adult door heights. Full long FRONT wall visible, right gable visible. Humble inhabited housing not temple.',True),
'tall_house':('华山·窄面两层书舍','ONE narrow TWO-STOREY mountain dwelling or study house, only two window bays wide, one ordinary adult ground-floor door, reddish brown timber upper storey over pale granite lower walls, shallow timber upper balcony and slate grey roof. Tall vertical silhouette, width about2.5adult door heights, fullheight about3.8adult door heights. FRONT and RIGHT side visible. Small plain single attached woodshed at rear barely visible. No pavilion ornament.',True),
'kitchen':('华山·低矮灶房柴棚','ONE low asymmetric service kitchen, a compact one-storey pale granite hut with one ordinary adult door, small shutter window, low dark grey tiled roof and short plain chimney, attached lower open timber lean-to at LEFT with orderly firewood and two clay storage jars. Roofheight2adult doors, width3.5adult doors. Rough ordinary cooking/workhouse, no ceremonial columns, no hanging sign.',True),
'sword_rack':('华山·练剑坪木剑架','ONE sturdy low wooden training weapon rack holding SIX plain sheathed straight Chinese swords upright with slim crossguards, restrained grey steel and plain dark scabbards, weathered red-brown wood stand with two stable feet. Rack adult chest height, swords human-sized not gigantic, wide shallow silhouette. No shields, bows, spears, flaming blades or symbols. Entire rack intact with generous transparent margins.',True),
'granite_crag':('华山·竖裂花岗岩崖体','ONE large connected irregular GRANITE CLIFF BUTTRESS module, pale cold grey naturally fissured rock, angular vertical joints and crag shoulders, taller left mass tapering to right, width2.0timesheight. A broad irregular stone top lip and tall sheer FRONT face with right depth visible, small dark moss in cracks and sparse tiny grass only. No masonry, terraces, trees, pathway or background. Entire rock mass intact, suitable for overlapping neighbors along mountain edge; no separate pebbles or arch holes.',True),
'granite_ground':('华山·细灰砂岩石地面','Create ONE seamless square TOP DOWN opaque game ground material texture. Weathered pale cool grey granite dust and flat small stone grains, broad calm low-contrast zones, almost no grass, no objects or plants, no perspective, no shadows, no cracks wider than a pebble, no distinct large boulders. Fine restrained hand-painted texture, continuous tile edge-to-edge in both axes. Readable neutral grey ground that will mix with stone courtyard paving. NOT landscape.',False)}
def prepare():
    assert not RAW.exists() and not STAGE.exists();RAW.mkdir(parents=True);(QUEUE/'templates').mkdir(parents=True)
    (QUEUE/'templates/native.yaml').write_text(yaml.safe_dump({'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high'}),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates';rows=[]
    for key,(label,spec,transparent) in SPECS.items():
        prompt=(COMMON+spec) if transparent else spec
        assert renderer.render_template('native',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8');rows.append({'key':key,'sect':'huashan','label':label,'transparent':transparent,'prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'calls':0,'status':'REGISTERED','backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'fallback_used':False})
    save(RAW/'manifest.json',{'assets':rows});save(STAGE/'preflight.json',{'real_renderer_passed':True,'count':len(rows)})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':r['key'],'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False} for r in rows]}),'utf-8')
    old=ROOT/'assets/staging/sect_maps_20261029k'
    paths={Path(r['path']) for r in json.loads((old/'protected-before.json').read_text('utf-8'))}
    paths.update(ROOT/r['path'] for r in json.loads((old/'publication.json').read_text('utf-8'))['files'])
    paths.update([ROOT/'game/project.godot',ROOT/'prompts/tasks.yaml'])
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths) if p.is_file()])
def start(key):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['calls']==0
    r.update(calls=1,status='DISPATCHED');save(RAW/'manifest.json',m)
def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['status']=='DISPATCHED'
    src=Path(source);dst=RAW/(key+'.png');assert not dst.exists();shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    with Image.open(dst) as im:r.update(mode=im.mode,size=list(im.size))
    r.update(status='RAW_CANDIDATE',output=dst.relative_to(ROOT).as_posix(),source_path=str(src),sha256=sha(dst));save(RAW/'manifest.json',m)
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
