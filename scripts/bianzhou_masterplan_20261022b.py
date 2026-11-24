"""Register and preserve one built-in masterplan call; no engine or game writes."""
import argparse,hashlib,json,re,shutil
from pathlib import Path
import yaml
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'assets/raw/bianzhou_city_masterplan_20261022b'
PROMPTS=ROOT/'prompts/bianzhou_city_masterplan_20261022b'
IDENT='bianzhou_plan_20261022b_overview_v1'
REFERENCE='assets/raw/luoyang_city_masterplan_20261019z/luoyang_city_masterplan_overview_v1.png'
SOURCES=['docs/luoyang-city-masterplan-20261019z.md','docs/luoyang-city-masterplan-20261019z_art_proposal.md','docs/luoyang-city-district-rollout-20261019aa.md','docs/other-city-modules-plan-20261022.md','game/data/scenes/openworld_bianzhou_city.tres','game/data/maps/openworld_bianzhou_city_layout_v2.tres','game/data/scenes/openworld_bianzhou_old_post.tres',REFERENCE]

PROMPT='''Use case: stylized-concept
Asset type: pre-production illustrated CITY MASTERPLAN for a 2D Chinese wuxia RPG. Concept design for review, not a runtime map texture and not an in-game screenshot.
Primary request: Design a coherent, believable, dense BIANZHOU, a fictional northern Central Plains Chinese trading and postal city, seen as one complete walled city from an elevated bird's-eye three-quarter orthographic angle. Create ONE polished wide landscape planning illustration, 16:10 composition, north up. Show a real town made of continuous street frontages and enclosed courtyard blocks, inhabited and functional, designed before any modular construction.
Input image ONE is STYLE AND DESIGN-QUALITY REFERENCE ONLY: the approved Luoyang masterplan. Match its sophisticated architectural illustration, coherent city-scale perspective, material quality, lively street life, generous readable overview and unobtrusive numbered district labels. Invent a DISTINCT Bianzhou arrangement based on the description below. Do not reproduce Luoyang's layout, river port, palace-like mansion district, river garden or outlying temple. Do not redraw a sparse gameplay module board.

CITY IDENTITY AND REQUIRED FUNCTIONAL CONNECTIONS:
This is a fictional Da-Qian setting, not a reconstruction of historical Kaifeng or a royal capital. Its identity is a Central Plains postal-road crossroads, merchant freight exchange and bustling everyday wards. Existing meaningful places: a postal official at the eastern posthouse, a central-plains merchant on the western freight street, a public wanted-notice pavilion reachable from the main street. The southern city gate leads back to the wider world; the northern gate and outgoing country postal road lead toward the old post station. Preserve these spatial relationships. Extra shops and homes in the drawing are proposed architectural functions and anonymous inhabitants only, not new named quest NPCs, factions or plotlines.

OVERALL STRUCTURE:
Use a modest, coherent near-rectangular grey-brick perimeter wall with corner towers and two deliberate axial gates. Show the entire perimeter within the canvas with enough margin; no cropped gatehouse or roof. At bottom centre: an unmistakable fortified SOUTH GATE attached to its real city wall, a compact interior inspection court and road outside. It must read as a city entrance, never a tiny freestanding wooden arch dropped into a street.
Inside the south gate, a bright, moderately broad NORTH-SOUTH COMMERCIAL SPINE runs continuously to a much smaller north gate. Make this a street with busy built edges, not a gigantic ceremonial plaza. TWO CROSS STREETS connect western and eastern quarters, forming two clearly continuous walking loops around enclosed blocks. Side lanes are narrower and turn naturally into courtyards; every passage opens to an actual street. Close the gaps between buildings with proper courtyard walls and rear buildings, while keeping clear side alleys and non-intersecting roof envelopes.
Main street width about 6-8 adult body widths, secondary cross streets about 3-4, small alleys about 1.5-2. Buildings and people must share one coherent scale. No monumental over-wide empty avenues. Around 50-70 varied main and smaller roof volumes arranged into 8-12 courtyard/block clusters, with readable alleys between them. This is a visually compact, complete city, not six isolated buildings on a huge ground plane.

EIGHT FUNCTIONAL ZONES, with exact numbered labels:
01 南门候检: bottom centre, continuous defensive gate wall, gatehouse, compact checkpoint court, two guard shelters, travellers, a small waiting cart bay to the side. The walking spine stays open. Outside the gate show a country road, a few trees and fields, not a shopping street.
02 中轴坊市: the central spine, continuous but varied shopfronts on BOTH sides. Show an inn, grain shop, cloth shop, tea/food shop and individual market stalls fitted into setbacks beside buildings. Each business has a distinct doorway or frontage with visible threshold and different architectural silhouette. Back-of-shop courtyards and service alleys make the frontage belong to actual buildings. The shop edge, awning and stalls must leave the main thoroughfare clear.
03 东驿馆: east/upper-right of the central market, a substantial but non-palatial ENCLOSED POSTHOUSE COMPOUND with its own entrance, front hall, two side wings, luggage-handling court, stables, wagon shelter and rear service gate. One anonymous postal clerk at the entrance for scale, travellers, stablehand, one horse and one postal cart near the service yard. Freight/service access joins the eastern loop without cutting across the entrance footway.
04 西市货街: west/middle, a merchant freight exchange with SEPARATE warehouse/storefront, loading shed, tightly grouped but non-overlapping storage buildings and a small loading yard. Handcarts, a few sacks, closed chests, crates and porters explain its purpose. Freight approaches from the secondary loop; cargo stays in yards and along walls, never strewn across the main road. A travelling merchant is near a distinct street-side stall.
05 坊巷民居: southwest and pockets behind shopfronts, several enclosed small courtyard homes, shared well, cooking corner, laundry line, low walls and a tiny neighborhood tree court. Elderly residents, a parent and child, someone carrying water. Dense, inhabited lanes, not detached cottages scattered on bare mud. A small tree court is a breathing space, not a huge plaza or mansion park.
06 百工作坊: northwest, repair/cart workshop, carpenter and smithy with unmistakably different work yards, wood rack, simple timber workbench, forge area and material shed. A smaller craft lane branches from a cross street and returns into the western loop. Workshop equipment belongs to the proper business. Muted ash and worn packed earth distinguish it from market paving.
07 北街榜亭: north-central, immediately off the spine before the north gate. A small public wanted-notice pavilion against an enclosed civic service court frontage, some people reading and a patrol guard. Keep a CLEAR pedestrian approach from the main street. This is modest everyday civic infrastructure, not a grand yamen palace or a giant empty government square.
08 北门驿道: top centre, the north gate in the continuous perimeter wall, postal road continuing visibly through open country toward a SMALL DISTANT old post-station silhouette outside the city. Preserve the visual connection, but do not make an additional full urban district outside the walls. The outlying station remains a separate destination, not a new interior door inside the posthouse.

GROUND AND LIVED DETAIL:
Main spine: lightly worn, well-fitted pale stone paving with subtle drainage channels. Market: warmer worn paving, steps and limited awning shadow. Postal court: orderly stone/gravel with a slightly earthier service lane and wheel wear. Freight yards/craft lanes: compacted finer earth with subtle ruts and very local work debris, not giant lumpy mud clods. Residential alleys: fine compacted earth and scattered gravel, small greenery at walls. Integrate materials naturally into paths, thresholds, curb edges and courtyards; NO geometric rectangular texture pads, hard T-shaped road strips, broad unbuilt mud wasteland or uniformly grey open plaza. Trees and greenery belong in yard corners, along walls and in the small neighborhood court, not randomly dotted as tiny isolated props.

STYLE AND COMPOSITION:
Polished, cohesive hand-painted production-design illustration with realistic traditional Chinese timber, grey brick, dark-grey tiles, restrained warm wood and cloth, subtle muted greenery. Bright readable neutral daylight, soft consistent cast shadows attached to buildings and objects. Clear parallel/orthographic readability with sufficient roof angle to distinguish function, no vanishing-point distortion or mixed camera angles. Every wall is an enclosure boundary with real gates, all roofs have separate believable footprints and fire/side gaps. Modest roof variety, one/two-storey public and commercial buildings, mostly one-storey residences. Small readable anonymous people in varied occupations and ages, clustered naturally at work and thresholds. Busy market, quieter side lanes; population is a scale cue, not oversized character sprites.

TEXT, VERBATIM: only the eight district labels "01 南门候检", "02 中轴坊市", "03 东驿馆", "04 西市货街", "05 坊巷民居", "06 百工作坊", "07 北街榜亭", "08 北门驿道". Clear Simplified Chinese dark lettering on small cream planning tags with muted red number badges, placed without hiding important streets or entrances. If character rendering is imperfect, prioritize correct 01-08 positions and leave architectural legibility intact. No decorative pseudo-calligraphy or storefront writing. No additional title, legend, UI, HUD, controls, coordinates, player marker, ruler, compass overlay, watermark or logo.
Avoid: loose sprite collage, modular asset showroom, six isolated houses, hard-edged rectangular paving patches, enormous mud apron, repeated identical storefront or three incompatible destinations on one facade, roof/building intersections, carts blocking gates, white cutout halos, floating props, grass visible through door interiors, giant item icons, heroic portraits, imperial palaces, grand river/port/garden/temple copied from Luoyang, European buildings, modern equipment, neon colours. This image exists to establish a strong overall DESIGN to review BEFORE building modules.
'''

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def prepare():
    if (BASE/'manifest.json').exists():raise RuntimeError('Task already registered; do not duplicate')
    BASE.mkdir(parents=True,exist_ok=True);PROMPTS.mkdir(parents=True,exist_ok=True)
    (PROMPTS/(IDENT+'.txt')).write_text(PROMPT,'utf-8')
    template={'name':'bianzhou_masterplan_20261022b','description':'Design-first coherent Bianzhou city masterplan','prompt_template':'{asset_prompt}','size':'1536x1024','background':'opaque','quality':'medium','reference_images':[REFERENCE],'require_reference_images':True}
    (ROOT/'prompts/templates/bianzhou_masterplan_20261022b.yaml').write_text(yaml.safe_dump(template,allow_unicode=True,sort_keys=False),'utf-8')
    task={'id':IDENT,'template':'bianzhou_masterplan_20261022b','execution_backend':'builtin_image_gen','skip':True,'attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':False,'model':None,'provider':None,'cost':None,'prompt_path':str((PROMPTS/(IDENT+'.txt')).relative_to(ROOT)).replace('\\','/'),'reference_images':[REFERENCE],'vars':{'asset_prompt':PROMPT}}
    queue=ROOT/'prompts/tasks.yaml';before=queue.read_bytes()
    tasks=yaml.safe_load(before.decode('utf-8'))['tasks'];assert not any(t.get('id')==IDENT for t in tasks)
    (BASE/'before-tasks.yaml').write_bytes(before)
    append='\n'+yaml.safe_dump([task],allow_unicode=True,sort_keys=False,width=140)
    append='\n'.join('  '+line if line else '' for line in append.splitlines())+'\n'
    with queue.open('ab') as f:f.write(append.encode('utf-8'))
    after=queue.read_bytes();assert after[:len(before)]==before
    jobs=yaml.safe_load(after.decode('utf-8'))['tasks'];assert sum(t.get('id')==IDENT for t in jobs)==1
    manifest={'id':IDENT,'status':'REGISTERED_DESIGN_ONLY','prompt':task['prompt_path'],'prompt_sha256':sha(ROOT/task['prompt_path']),'reference':REFERENCE,'reference_role':'approved Luoyang masterplan style/quality only, not its layout','negative_example':'assets/staging/bianzhou_city_20261022a/revision2/artifacts/overview.png','source_sha256':{p:sha(ROOT/p) for p in SOURCES},'task_count':1,'attempt_budget':1,'builtin_calls':0,'model':None,'provider':None,'cost':None,'formal_enabled':False}
    (BASE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'registered':IDENT,'old_tasks_prefix_exact':True,'sources':len(SOURCES),'prompt':task['prompt_path']}))

def record(path):
    m=json.loads((BASE/'manifest.json').read_text('utf-8'));assert m['builtin_calls']==0
    for p,digest in m['source_sha256'].items():assert sha(ROOT/p)==digest,p
    source=Path(path);dest=BASE/'bianzhou_city_masterplan_overview_v1.png';assert not dest.exists();shutil.copyfile(source,dest)
    with Image.open(dest) as im:size=list(im.size);mode=im.mode
    m.update(status='DESIGN_PROPOSAL_AWAITING_USER_REVIEW',builtin_calls=1,output=str(dest.relative_to(ROOT)).replace('\\','/'),source_path=str(source),sha256=sha(dest),size=size,mode=mode)
    assert sha(source)==m['sha256']
    (BASE/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf-8')
    dest.with_suffix('.meta.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'output':m['output'],'size':size,'sha256':m['sha256'],'builtin_calls':1}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','record']);p.add_argument('--source');a=p.parse_args()
    prepare() if a.action=='prepare' else record(a.source)
