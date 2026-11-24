"""Native replacement assets, private queue, immutable original receipts."""
import json, sys, shutil, hashlib
from pathlib import Path
import yaml
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
NAME='desert_city_rework_20261029o'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
PROJECT=STAGE/'town_project'
ART='art/modules/'+NAME
QUEUE=STAGE/'production'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n','utf-8')
COMMON='''Use case: stylized-concept. Production native 2.5D wuxia RPG modular scenery. ONE isolated complete object, genuine transparent RGBA background, generous empty margin all around. Sharp detailed semi-realistic hand-painted materials, fixed elevated orthographic camera looking from SOUTH, front and top visible, vertical lines vertical, no perspective shrinking, neutral warm upper-right daylight. No people, text, letters, labels, watermark, scenery background, floor island or dramatic cast shadow. Do not make an atlas, miniatures or multiple disconnected objects. Actual native pixels must carry fine clear texture. '''
SPECS={
'redrock_cliff':('赤岩·近景横向崖段',COMMON+'''One SHORT BROAD continuous red sandstone cliff segment for adjoining other rock segments at full native resolution. Landscape 1536x1024 or larger native canvas. Solid terracotta red stratified rock face, broad irregular top rim with recessed upper ledge, a few vertical fissures, gently broken edges. Subject width about1200pixels, height600pixels. Left and right ends are substantial vertical natural rock faces rather than long tapered slopes, so neighboring modules overlap by about150pixels without a gap. Front rock foot extends along a mostly horizontal continuous baseline, fine shallow relief and small stone grain, no enormous soft boulders. This is a near-player rock wall segment, not an entire mountain panorama.'''),
'adobe_wall':('沙漠·正面连续土坯墙段',COMMON+'''One straight FRONT-FACING tall adobe town wall segment, whole subject around1200pixels wide and600pixels tall on landscape1536x1024canvas. Pale warm ochre plaster, weathered fine sand and tiny exposed adobe bricks, modest thick wall top visible, restrained shallow flat crenellations. A straight horizontal top ridge and horizontal ground baseline, both ends are vertical flush JOINING ends, no tower, gate, arch, bushes or loose props. Main front wall plane faces camera directly. A clean substantial monolithic segment, not an entire enclosure, no attached side walls. Repeatable architectural rhythm; end caps narrow and unobtrusive. Clear fine detail at native resolution.'''),
'adobe_side_west':('沙漠·西侧纵向土坯墙段',COMMON+'''One SHORT side-wall segment for the WEST side of a desert town enclosure, seen from the INSIDE/east of that wall, its visible tall inner face lit gently. Portrait1024x1536native canvas. Wall runs from upper-right rear end toward lower-left front end with projected centerline delta about(-240,+850)pixels. Wall is600pixels apparent vertical height, top thickness60px, both ends are flush joining cuts. Pale warm ochre adobe plaster, fine cracks and small brick chips, modest shallow crenellations, same constant height along its whole length. No corner tower, gateway, entire enclosure or front-facing horizontal wall. Orthographic, both ends equal size. Clean native detail.'''),
'adobe_side_east':('沙漠·东侧纵向土坯墙段',COMMON+'''One SHORT side-wall segment for the EAST side of a desert town enclosure, seen from the OUTSIDE/east of that wall with its visible outer face, its material consistent with warm ochre adobe. Portrait1024x1536native canvas. Wall runs from upper-left rear end toward lower-right front end with projected centerline delta about(+240,+850)pixels. Wall is600pixels apparent vertical height, top thickness60px, both ends are flush joining cuts. Fine plaster cracks and small brick chips, modest shallow crenellations, same constant height along its whole length. No corner tower, gateway, entire enclosure or front-facing horizontal wall. Orthographic, both ends equal size. Clean native detail.'''),
'adobe_gate':('沙漠·独立高精土坯城门',COMMON+'''One complete adobe city gate with two modest square bastions and one OPEN central passage. Front elevation almost frontal, top and slight right side visible. Landscape1536x1024native canvas. Overall subject width1250px, height750px. Two vertical side towers, central passage clear opening roughly440pxwide and500pxtall, truly transparent through opening, straight lintel with weathered timber beam. Pale sand ochre plaster and layered adobe brick, flat tops and shallow parapets. No attached long walls, no city background, no floor inside opening, no stairs. Outer side faces are flat join points for adjoining tall city walls. Fine sharp plaster grain and timber fibers. Door opening must be unblocked all the way to the ground.'''),
'adobe_tower':('沙漠·墙角连接圆堡',COMMON+'''One modest ROUND adobe corner tower, cylindrical slightly tapering bastion, flat circular top with low rounded parapet and one small slit window. Subject height900px,width600px on1024x1536portraitcanvas. Pale sand ochre weathered plaster, fine chips expose small adobe bricks, restrained realistic scale. Ground foot is continuous elliptical base. NO door, stairs, flag, attached walls, mountains or props. This solid round bastion covers junctions of native wall segments with consistent right-side warm light. Crisp native material, complete object all around.'''),
'world_redrock':('大地图·赤岩完整微缩关镇',COMMON+'''Dedicated WHOLE TOWN MINIATURE landmark, not a standalone building or walkable full-size module. Landscape1536x1024native canvas. Compact red sandstone fortified caravan town nestled into a low red rock shoulder behind it. One clear open front gate centered at bottom, two modest square gate towers, continuous short defensive walls enclosing MANY small flat-roofed red adobe dwellings, a narrow main street leading from the gate to a taller rear watch compound, a small canvas market and caravan courtyard. Mixed one/two storey buildings in coherent uniform miniature scale, town walls and buildings share SAME scale. City mass fills about80percent width and70percent height with no cut edges. High-angle orthographic south view matching a Chinese RPG world-map town compound, not aerial map, no vanishing perspective. Rock shoulder small and tightly behind town, no desert landscape island. Gate opening visible and transparent; clear gate doorstep at bottom center. No people/camels/text/labels. Fine red stone and dark timber details; redrock identity strongly distinct from pale yellow desert city.'''),
'world_desert':('大地图·沙漠完整微缩土坯城',COMMON+'''Dedicated WHOLE CITY MINIATURE landmark, not a standalone building or walkable full-size module. Landscape1536x1024native canvas. Compact pale golden sandy adobe city, fully enclosing short continuous perimeter wall with round corner bastions, ONE open main gate centered at bottom. INSIDE dense varied small flat-roofed dwellings, one larger caravanserai compound, narrow shaded bazaar lanes with cream fabric awnings, modest workshop yard, one small well courtyard with ONLY TWO date palms. Walls and houses all share one consistent miniature scale, no giant foreground houses. Whole city fills about80percent width and70percent height, complete silhouette and all margins. Fixed high-angle orthographic camera from SOUTH, visible roofs and front walls, matching a 2.5D RPG world-map city compound. Pale yellow ochre and warm white plaster, no red cliffs, green oasis, domes, minarets or modern details. Gate passage transparent to bottom ground line. No people, animals, text, labels, outside landscape or ground island. Crisp native rendering.''')}

def prepare():
    assert not RAW.exists() and not STAGE.exists()
    RAW.mkdir(parents=True);(QUEUE/'templates').mkdir(parents=True)
    (QUEUE/'templates/native.yaml').write_text(yaml.safe_dump({'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high'}),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'; rows=[]
    for key,(label,prompt) in SPECS.items():
        assert renderer.render_template('native',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8')
        rows.append({'key':key,'label':label,'transparent':True,'prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'calls':0,'status':'REGISTERED','backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'fallback_used':False})
    save(RAW/'manifest.json',{'assets':rows});save(STAGE/'preflight.json',{'real_renderer_passed':True,'count':len(rows)})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':r['key'],'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'cli_fallback_allowed':False} for r in rows]}),'utf-8')
    audit=json.loads((ROOT/'assets/staging/desert_city_pixel_audit_20261029n/audit.json').read_text('utf-8'))
    paths={ROOT/p for p in audit['read_only_sources_unchanged']}
    paths.update((ROOT/'game/build/three_towns_world_20261029j_system01').glob('*'))
    paths.update([ROOT/'game/project.godot',ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'prompts/tasks.yaml'])
    save(STAGE/'protected-before.json',[{'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(paths) if p.is_file()])

def start(key):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['calls']==0
    r.update(calls=1,status='DISPATCHED');save(RAW/'manifest.json',m)

def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key);assert r['status']=='DISPATCHED'
    src=Path(source);dst=RAW/(key+'.png');assert not dst.exists();shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    with Image.open(dst) as im:r.update(mode=im.mode,size=list(im.size))
    r.update(status='RAW_CANDIDATE',output=dst.relative_to(ROOT).as_posix(),source_path=str(src),sha256=sha(dst));save(RAW/'manifest.json',m)
if __name__=='__main__':{'prepare':prepare,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
