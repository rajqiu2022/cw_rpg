"""Two topology-first sect design revisions; native image output is kept unchanged."""
import json,sys,shutil,hashlib
from pathlib import Path
import yaml
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/sect_redesign_20261029j'
QUEUE=ROOT/'assets/staging/sect_redesign_20261029j/production'
COMMON='''Create one refined full-site architectural DESIGN for a 2.5D wuxia RPG, not a playable screenshot. Landscape elevated parallel three-quarter view. Use the input ONLY as a previous design reference; redraw the whole place with improved functional topology. Keep all roofs and site edges in frame. Realistic painted materials, daylight, coherent adult doorway scale. Different large halls, modest dwellings, narrow service sheds, long low corridors, tiny storage structures; NEVER repeat equally sized houses. Buildings actually sit on terrain. Clear connected foot routes with wide landings, all stairs connect real elevations and continuous retaining faces. No isolated decorative stairs, floating ledges, disconnected walls, intersecting roofs or giant empty road rectangles. Tiny ordinary people only for scale. No invented plot, names, enemies, rewards, religious villains, modern objects, headbands, spider motifs or interface. Use only the specified six numbered Chinese planning labels, positioned away from routes. Preserve natural scenic atmosphere while making settlement construction understandable. Opaque illustration.
'''
SPECS={
'wudang':COMMON+'''WUDANG: tall grey limestone mountain spine, pine trees, muted copper-green tiled Daoist roofs and dark timber. Strong VERTICAL composition of THREE visibly supported rock terraces. Lower southwest gate terrace leads by one long broad stone stair with a half-way landing to the CENTRAL training courtyard. The training courtyard leads by a second shorter northbound stair to the upper main palace courtyard. Each staircase must visibly join the two ground surfaces at both ends; cliff fronts continuous everywhere else. Main hall dominates upper central axis, twin smaller wings differ in size, no decorative waterfall. A distinct east-side switchback SERVICE PATH links modest disciple dwellings and kitchen to the training platform and scripture courtyard, avoiding the exercise center. Small west ridge meditation pavilion reached by a safely parapeted narrow connected trail. Training space contains both open hand-practice area and small sword rack at EDGE, no giant weapons. Reduce clouds to distant valleys so ground supports and all junctions remain visible. Six labels: 01 解剑山门; 02 太极道场; 03 紫霄宫院; 04 藏经静院; 05 弟子居舍; 06 后山清修. Make three terraces, two principal stairs and side circulation immediately legible.''',
'mingwu':COMMON+'''MINGWU MANOR: a LOW TEA VALLEY, completely different from steep Wudang cliffs. HORIZONTAL winding progression from small tea-town southwest through an exterior guest courtyard, a connected roofed corridor and an inner courtyard to a broad meeting hall in the northeast. White lime courtyard walls, dark grey pitched tiled roofs, warm timber, restrained bamboo groves. The entire terrain is gently undulating with ONLY TWO shallow building terraces, each connected by short 3–5-step stairs into clearly supported raised stone plinths. NO tall cliffs, cascades, giant waterfalls or wide river. One NARROW irrigation creek, about one third of a courtyard width, crosses the middle; two SHORT stone bridges actually connect both banks and paved landing paths. Boundary walls and corridors attach to building corners to enclose courts, gateways open onto paths; no detached wall stubs. A west tea-production district has low contoured tea rows, drying racks, sorting tables, baskets and small practical processing sheds. Its dedicated freight footpath reaches the outer court and tea town without passing through the inner ceremonial court. A small rear bamboo trail forms a quiet return connection. Keep public-to-private thresholds readable without inventing permissions or exposing secret passages. Six labels: 01 茶镇入口; 02 外院客堂; 03 内院回廊; 04 议事主厅; 05 茶园工坊; 06 后山小径. Strongly lower and more intimate silhouette than the reference; wide landscape composition.'''
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
def prepare():
    assert not BASE.exists();BASE.mkdir(parents=True);(QUEUE/'templates').mkdir(parents=True)
    (QUEUE/'templates/design.yaml').write_text(yaml.safe_dump({'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'opaque'}),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates';rows=[]
    for key,prompt in SPECS.items():
        assert renderer.render_template('design',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8')
        rows.append({'key':key,'prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'calls':0,'status':'REGISTERED','backend':'builtin_image_gen','model':None,'provider':None,'fallback_used':False})
    save(BASE/'manifest.json',{'assets':rows,'scope':'design revision only; 0 game consumers'})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':r['key'],'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False} for r in rows]}),'utf-8')
    save(BASE/'preflight.json',{'actual_renderer_passed':True,'tasks':2,'root_queue_changed':False})
def start(key):
    m=json.loads((BASE/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['calls']==0
    r.update(calls=1,status='DISPATCHED');save(BASE/'manifest.json',m)
def record(key,source):
    m=json.loads((BASE/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['status']=='DISPATCHED'
    src=Path(source);dst=BASE/(key+'_masterplan_v2.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    im=Image.open(dst);r.update(status='DESIGN_CANDIDATE',output=dst.relative_to(ROOT).as_posix(),sha256=sha(dst),source_path=str(src),size=list(im.size),mode=im.mode,game_consumers=0);save(BASE/'manifest.json',m)
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
