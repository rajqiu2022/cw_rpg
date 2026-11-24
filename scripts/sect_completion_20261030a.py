"""Native modules for the user's remaining three locations; no shared queue writes."""
import json,sys,shutil,hashlib
from pathlib import Path
import yaml
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
NAME='sect_completion_20261030a';RAW=ROOT/'assets/raw'/NAME;STAGE=ROOT/'assets/staging'/NAME;PROJECT=STAGE/'town_project';ART='art/modules/'+NAME;QUEUE=STAGE/'production'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
COMMON='''Use case: stylized-concept. Produce ONE complete isolated native architectural module for a semi-realistic hand-painted 2.5D Chinese wuxia RPG. The reference is architectural style only, never crop it. Elevated SOUTH-facing orthographic camera shows front and slight RIGHT depth, vertical posts vertical, no vanishing perspective. Genuine transparent alpha0 background, whole object small centered with at least20percent EMPTY margin on ALL sides. Fine crisp believable materials, neutral daylight. Ordinary adult doors consistently proportioned; large buildings gain bays and storeys not giant doors. No people, text, flags, emblem, watermark, scenery, ground island, detached decorative objects, blurry lighting, huge shadow, or modern objects. One complete object, not an asset sheet. Specification: '''
SPECS={
'lingyue_hall':('lingyue','凌月·临潭双层竹楼','Asymmetric FIVE-bay two-storey bamboo-and-timber school lodge, pale honey-grey weathered bamboo posts and woven bamboo infill, restrained silver-grey tiled roofs, open upper balcony with slender bamboo rails, a modest taller central gable and lower side verandas. One ordinary central adult ground-floor doorway, small shutter windows, three shallow pale stone entry steps. Width7adult door heights, totalheight4adult door heights. Light graceful silhouette, no monumental masonry, no temple decoration.'),
'lingyue_dorm':('lingyue','凌月·低檐竹舍','Long low THREE-bay single-storey bamboo residence, silver-grey shallow tiled roof, pale weathered bamboo framing and woven panels, one ordinary adult door at RIGHT, two shutter windows and a small open bamboo work porch LEFT with modest bench. Fine structural bamboo nodes and tied joints. Humble living quarters, fullheight2.3adult door heights, width5adult door heights. No giant stilts, no full courtyard.'),
'lingyue_gate':('lingyue','凌月·竹径通行山门','One open gateway with TWO paired pale bamboo-and-timber piers on low grey stone feet, a light silver-grey Chinese tiled roof with modest upturned ends, completely EMPTY open center passage genuine transparency. Passage clearheight2.3metres andwidth2.2metres. No door panels, center supports, wing walls, stairs, plaque or banner. Graceful small mountain entrance, visible bamboo construction.'),
'staff_rack':('lingyue','凌月·演棍坪长棍架','One low weathered bamboo training rack holding SIX plain smooth wooden long staffs vertically, each staff human height, no blades or spearheads, stable two-foot horizontal rack. Pale bamboo rails and brown wooden staffs, realistic restrained rope joints. One complete small practical outdoor weapon rack, no decorations or attached terrain.'),
'lieyun_gate':('lieyun','烈云·木石关寨门','One rugged broad mountain stockade gate, TWO chunky irregular dark-grey shale masonry piers supporting a heavy weathered warm-brown timber beam and shallow dark timber shingle roof. Completely OPEN central passage transparent, ordinary adult passageheight2.5metres,width3metres. Short attached wooden rail ends at sides, no full wall, no spiked skull decoration, no flags, no attached stairs. Practical inhabited canyon checkpoint, sturdy asymmetric worn stones.'),
'lieyun_hall':('lieyun','烈云·宽面寨厅','One broad FOUR-bay canyon assembly lodge, dark-grey rough shale lower walls, heavy warm aged timber frame and deep dark timber-shingle pitched roof, two ordinary adult double doors, shallow front veranda on four timber posts, low rough stone plinth with two shallow entry steps. Substantial horizontal silhouette width6adult door heights,totalheight3.4adult door heights. Inhabited practical hall, no palace eaves, no red desert adobe, no skulls or banners.'),
'lieyun_store':('lieyun','烈云·渡口货舍','One asymmetric small canyon ferry storehouse: narrow TWO-storey dark-grey rubble stone and warm timber dwelling at LEFT, lower open timber shingle lean-to at RIGHT containing a workbench, coiled rope and three plain crates. One ordinary ground-floor adult door, small upper wooden balcony with simple railing. Distinct roof heights, totalwidth4adult door heights,totalheight3.5adult door heights. Practical river freight building, no surrounding dock or ground.'),
}
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
def start(key):
 m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['calls']==0;r.update(calls=1,status='DISPATCHED');save(RAW/'manifest.json',m)
 print((ROOT/r['prompt']).read_text('utf-8'))
def record(key,source):
 m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['status']=='DISPATCHED'
 src=Path(source);dst=RAW/(key+'.png');assert not dst.exists();shutil.copyfile(src,dst);im=Image.open(dst)
 r.update(status='RAW_CANDIDATE',output=dst.relative_to(ROOT).as_posix(),source_path=str(src),sha256=sha(dst),mode=im.mode,size=list(im.size));save(RAW/'manifest.json',m)
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
