"""Design-first redrock gateway resource ledger; native generation is done by the built-in tool."""
import argparse
import hashlib
import json
import math
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/raw/redrock_gate_resources_20261023a'
STAGE = ROOT / 'assets/staging/redrock_gate_20261023a'
PROMPTS = ROOT / 'prompts/redrock_gate_resources_20261023a'
REF = 'assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png'
TEMPLATE = 'redrock_cutout_20261023a'

BASE_PROMPT = '''Use case: stylized-concept
Asset type: ONE standalone reusable 2.5D wuxia RPG map component, transparent PNG, not a full scene or concept collage.
Reference image 1 defines ONLY the red sandstone pass-town material, dry climate and painterly game-art quality. Extract NO pixels from it; generate the requested independent component. Correct the reference's Chinese roof tendency: red sandstone and sun-dried earthen construction, compact flat parapets and plain timber lintels, NO Chinese ceramic tiles, curved eaves, pagodas or imperial ornament. Western desert canyon settlement, believable inhabited architecture, not European fantasy.
Camera: fixed orthographic shallow bird's-eye, front facade facing screen-bottom, see top surfaces and a SMALL right-hand depth face, parallel verticals, consistent 2.5D RPG camera. Light from upper-left/front-left, warm clear desert daylight, matte rust-red stone, dusty ochre mortar, dark weathered structural wood, restrained colour. Fine hand-painted detail readable at game scale, no photoreal cutout or cartoon outline.
Composition: entire object isolated at the CENTER of a generous fully transparent canvas, subject including all shadow inside central 72% width and central 72% height. At least 14% clear transparent margin on ALL FOUR sides, also for faint alpha and shadow. No terrain island, sand rectangle, ground plane, rocks, vegetation, people, measurement ruler, text, letters, labels, logo, watermark, extra objects or asset-sheet grid. Keep only tiny attached contact shade underneath solid foot surfaces, no broad cast shadow touching canvas edges. Genuine alpha, no black/white/chessboard painted background, no opaque glow or halo. Do not crop feet, roof or side edges.
Requested component:
'''

GUARD_PROMPT = '''Use case: stylized-concept
Asset type: ONE full-body MAP IDLE SPRITE for an anonymous adult pass-town guard, not a portrait, no story NPC name.
Reference image 1 is the red sandstone town style/environment reference only. Create one distinctive believable ordinary human suitable for this place: adult man around 35-45, warm natural skin, broad nose, short neat black beard, dark charcoal SOFT ROUND CAP without forehead band or ties, short rust-brown padded vest over dusty grey-beige knee-length split-side tunic, dark trousers, worn mid-calf boots, plain leather belt and a SMALL tan crossbody document pouch at his right hip. No helmet, cape, headwrap, scarf on head, turban, forehead ribbon, red hair tie, modern item or fantasy armour. Hands empty, a small sheathed utility blade on rear belt only, no long sword/polearm extending the sprite bounds. Clothing practical, silhouette compact. No new named character or faction emblem.
Camera: orthographic map sprite facing SCREEN DOWN toward viewer, slight three-quarter view from above about 25 degrees; feet and head top visible, NOT eye-level heroic portrait. Semi-realistic painterly 2.5D game character, restrained contour, upper-left soft neutral daylight, warm natural face, stable anatomy. Relaxed natural idle, weight balanced, both boots on one horizontal ground baseline, arms relaxed separated slightly from torso; knees/boots visually distinct, no long robe concealing gait.
Exact canvas request: square 1024 by 1024, character top around y=200 and soles y=824, center x=512, apparent adult body height about 624 pixels, same fixed canvas and placement will be required for the walk frames. Entire silhouette plus tiny contact shadow inside x=320..704 and y=185..830; rest genuinely alpha zero. Generous all-sides transparent padding, no floor/terrain, no painted checkerboard, no broad shadow, text or UI. ONE character ONE pose, no portrait inset or sheet.
'''

ITEMS = {
    'gate': ('building', '赤岩·宽洞石砌关门', BASE_PROMPT + '''A squat wide red-sandstone gateway block with two thick buttressed masonry wings joined by a broad plain flat lintel and a low battlement parapet. ONE large central rectangular through-passage, completely OPEN and visibly empty through the entire depth. Opening is about 34-38% of the full solid object's visible width and at least 45% of its height, broad enough for a loaded pack animal next to a person. Gateway width about 1.8-2.1 times overall height; opening width about 1.2 times opening height. NO tall towers attached, roof pavilion, statues, flags, steps, ramp, threshold slab or paving. The bottom of the opening is at the SAME base level as the two masonry feet. Generate real transparent pixels inside the void, not a black painted arch. Two heavy dark timber door leaves fully swung inward to the SIDE WALLS, seen edge-on, do not project into/cover the central opening. Subtle sandstone weathering and simple timber hinge details. Ends are plain vertical masonry cut faces ready to meet separate wall modules. This is a full-size functional pass gate, not a small freestanding decorative arch.
'''),
    'tower': ('building', '赤岩·平顶岗楼', BASE_PROMPT + '''ONE squat rectangular two-level red-sandstone watchtower with solid stepped stone base, flat open parapet roof, low square crenellations and a tiny plain timber windscreen at the BACK of the roof terrace. NO roof above it, absolutely NO tiles/curved eaves/pavilion. Low heavy defensible silhouette, aspect visible width about .7 of height. One human-scale dark timber entrance centered low on FRONT, plain rectangular lintel, not arched cathedral architecture; door may be closed. Two narrow viewing slits on upper facade. No stairs spiraling around the outside, no attached walls or landscape. All four base corners visible and complete; simple independent component to place behind a connected wall line.
'''),
    'front_wall': ('building', '赤岩·正面厚石墙段', BASE_PROMPT + '''ONE straight red sandstone defensive wall segment running horizontally LEFT TO RIGHT across the image, front facing screen-bottom, small right depth face. Length around 3 times visible height; thick block masonry, broad flat stone parapet, regularly spaced low square merlons, a little worn stone at the base but no terrain. Plain flush vertical left/right cut ends for seamless joining, no corner tower, doorway, stair, flag or roof. No in-image repetition, just one complete segment with margins; texture scale must match the gate's large rough red stone blocks.
'''),
    'side_wall': ('building', '赤岩·纵深侧石墙段', BASE_PROMPT + '''ONE independently drawn depth-oriented wall segment, long axis goes from FRONT-LOWER-RIGHT to BACK-UPPER-LEFT in the fixed town camera, a receding side wall with a visible narrow top walkway and a broad RIGHT-facing masonry side. This is TRUE depth geometry, never a front wall image rotated 90 degrees. Red sandstone blocks, low square parapet merlons, open flat wall top, plain complete vertical cut ends. Roughly twice as long as its height, physically thick. No gate, stairs, tower, house, terrain, tiles or other objects. Match gate/front-wall material and light.
'''),
    'cargo': ('scene_prop', '赤岩·驿道货包组', BASE_PROMPT + '''ONE compact ground-placeable cargo group: three tied tan woven-cloth bales of different modest sizes stacked neatly on two low dark timber dunnage beams, one tightly rolled rust-colour bedroll bound alongside, no writing or insignia. Full 3D form from map camera, natural cloth folds and coarse rope knots, base flat, single small coherent group. Height about half an adult, footprint about one adult body width by .8 adult width; NOT a glowing inventory item icon, no circular icon frame. No cart, animal, person, sign, chest pile, terrain or broad sand base. Future gameplay meaning is unspecified, only visual prop.
'''),
    'trough': ('scene_prop', '赤岩·石制饮水槽', BASE_PROMPT + '''ONE low elongated trough hewn from rough red sandstone, shallow narrow basin with a SMALL amount of still dark water inside, two simple block supports integrated under it. Whole outline about 3 times as wide as tall, knee-height to a human, front long face toward screen-bottom and short right depth face. No faucet, metal pipe, bucket, animal, tree, well roof, steps, paving or extra jars. Interior water stays within trough and must not become a glowing pond or waterfall. Practical low desert relay-yard water infrastructure, a world prop rather than a backpack icon.
'''),
    'guard_idle': ('npc_sprite', '赤岩关卒·地图待机', GUARD_PROMPT),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', 'utf-8')


def plan():
    current = STAGE / 'revision2'
    assert not (current / 'district-plan.json').exists()
    current.mkdir(parents=True,exist_ok=True)
    # Authored working geometry, not a measurement of the concept image.
    solids = {
        'gate_west_pier': [760, 900, 360, 260], 'gate_east_pier': [1440, 900, 360, 260],
        'wall_west': [120, 900, 640, 180], 'wall_east': [1800, 900, 640, 180],
        'tower': [300, 500, 240, 260], 'side_wall': [2440, 720, 100, 360],
        'cargo': [1800, 1370, 200, 100], 'trough': [440, 1350, 240, 90],
    }
    visual = {'gate': [700, 410, 1160, 750], 'tower': [260, 180, 300, 580]}
    roads = [([1280, 1770], [1280, 240], 320), ([1280, 240], [2260, 240], 320),
             ([2260, 170], [2260, 680], 320), ([2260, 680], [1960, 680], 128),
             ([1960, 680], [1960, 240], 128),
             ([1440, 1280], [2160, 1280], 180), ([2160, 1280], [2160, 1520], 180),
             ([1280, 240], [630, 240], 128), ([630, 240], [630, 830], 128), ([630, 830], [420, 830], 128)]
    routes = {'arrival': [[1280,1770],[1280,240],[2260,240],[2260,170]],
              'return_loop': [[2260,240],[2260,680],[1960,680],[1960,240]],
              'cargo_bay': [[1280,1280],[2160,1280],[2160,1520]],
              'tower_foot': [[1280,240],[630,240],[630,830],[420,830]]}
    mask = Image.new('1', (2560,1920)); d = ImageDraw.Draw(mask)
    for x,y,w,h in solids.values(): d.rectangle((x,y,x+w-1,y+h-1),fill=1)
    checked = 0
    for points in routes.values():
        for a,b in zip(points, points[1:]):
            n=math.ceil(math.dist(a,b)/4)
            for i in range(n+1):
                x=round(a[0]+(b[0]-a[0])*i/n);y=round(a[1]+(b[1]-a[1])*i/n)
                assert mask.crop((x-17,y-12,x+18,y+13)).getbbox() is None, (x,y)
                checked += 1
    # Full road corridors, not just their center samples.
    for a,b,width in roads:
        x0=min(a[0],b[0])-width//2;y0=min(a[1],b[1])-width//2
        x1=max(a[0],b[0])+width//2;y1=max(a[1],b[1])+width//2
        assert mask.crop((x0,y0,x1,y1)).getbbox() is None,(a,b,width)
    assert mask.crop((1120,900,1440,1160)).getbbox() is None
    # The only deliberate overhead crossing is the gate passage itself.
    roof_mask=Image.new('1',(2560,1920));rd=ImageDraw.Draw(roof_mask)
    for x,y,w,h in visual.values():rd.rectangle((x,y,x+w-1,y+h-1),fill=1)
    for a,b,width in roads[1:]:
        x0=min(a[0],b[0])-width//2;y0=min(a[1],b[1])-width//2
        x1=max(a[0],b[0])+width//2;y1=max(a[1],b[1])+width//2
        assert roof_mask.crop((x0,y0,x1,y1)).getbbox() is None,(a,b,'under visual')
    data={'status':'AUTHORED_GEOMETRY_ONLY_NOT_ENGINE_ACCEPTANCE','canvas':[2560,1920],
          'adult_visual_height':112,'body_pixels':[35,25],'gate_clear_width':320,'main_road_width':320,
          'side_footway_width':128,'solids':solids,'visual_reservations':visual,'roads':roads,'routes':routes,
          'guard_feet':[980,1270],'gate_full_canvas_target_width':1160,'exit_note':'North-east joins proposed town terraces; no formal scene_id or router created.'}
    dump(current/'district-plan.json',data)
    dump(current/'geometry-check.json',{'passed':True,'full_body_route_samples':checked,'non_portal_corridors_avoid_visual':True,
         'full_corridors_checked':len(roads),'gate_clear_strip':[1120,900,320,260],
         'scope':'Authored rectangles/corridors only, no generated alpha aperture or native physics measured.'})
    pic=Image.new('RGB',(2560,1920),'#211d1a');draw=ImageDraw.Draw(pic)
    font=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',28)
    for a,b,width in roads:draw.line([tuple(a),tuple(b)],fill='#485d56',width=width)
    for name,(x,y,w,h) in solids.items():
        draw.rectangle((x,y,x+w-1,y+h-1),fill='#a06745',outline='#ecc49a',width=3)
        draw.text((x+5,y+5),name,fill='white',font=font)
    for name,(x,y,w,h) in visual.items():
        draw.rectangle((x,y,x+w,y+h),outline='#c8b7ed',width=4)
        draw.text((x+5,y+5),'visual reservation: '+name,fill='#ddc5ff',font=font)
    draw.ellipse((963,1253,997,1287),fill='#7dc5ff');draw.text((730,1290),'关卒站位 / 不堵门',font=font,fill='#b9ddff')
    draw.text((50,30),'赤岩关镇 01 峡口关门 · 技术平面（非游戏美术）',font=font,fill='#ecdac2')
    draw.text((50,80),'主路/净门320  人体112  body35×25  货湾在侧  北接阶街',font=font,fill='#ecdac2')
    pic.save(current/'district-footprint-plan.png')
    dump(STAGE/'current-plan.json',{'current':'revision2/district-plan.json','previous':'district-plan.json',
      'reason':'Moved north junction beyond entire gate visual envelope; tower and its footway moved clear. Initial body-only plan remains history.'})
    print(json.dumps({'plan':str(current/'district-plan.json'),'body_samples':checked,'full_corridors':len(roads)}))


def register(entries, ref_path, phase):
    BASE.mkdir(parents=True,exist_ok=True);PROMPTS.mkdir(parents=True,exist_ok=True)
    template={'name':TEMPLATE,'prompt_template':'{asset_prompt}','size':'1024x1024','background':'transparent',
              'quality':'medium','reference_images':['{reference_path}'],'require_reference_images':True}
    tp=ROOT/f'prompts/templates/{TEMPLATE}.yaml'
    if not tp.exists():tp.write_text(yaml.safe_dump(template,allow_unicode=True,sort_keys=False),'utf-8')
    sys.path.insert(0,str(ROOT/'scripts'));from gen_assets import render_template
    tasks=[];rows=[]
    for key,(kind,label,prompt) in entries.items():
        ident=f'redrock_20261023a_{key}_v1';p=PROMPTS/(ident+'.txt');assert not p.exists();p.write_text(prompt,'utf-8')
        rendered=render_template(TEMPLATE,{'asset_prompt':prompt,'reference_path':ref_path},{})
        assert rendered['prompt']==prompt.strip() and len(rendered['reference_images'])==1
        tasks.append({'id':ident,'template':TEMPLATE,'execution_backend':'builtin_image_gen','skip':True,
                      'attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'model':None,'provider':None,'cost':None,
                      'transparent_background':True,'prompt_path':p.relative_to(ROOT).as_posix(),
                      'reference_images':[ref_path],'vars':{'asset_prompt':prompt,'reference_path':ref_path}})
        rows.append({'key':key,'id':ident,'kind':kind,'label':label,'status':'REGISTERED','calls':0,
                     'prompt':p.relative_to(ROOT).as_posix(),'reference':ref_path,'reference_sha256':sha(ROOT/ref_path)})
    queue=ROOT/'prompts/tasks.yaml';before=queue.read_bytes();old=yaml.safe_load(before.decode('utf-8'))['tasks']
    ids={t['id'] for t in tasks};assert not any(t.get('id') in ids for t in old)
    (BASE/f'before-tasks-{phase}.yaml').write_bytes(before)
    append='\n'+yaml.safe_dump(tasks,allow_unicode=True,sort_keys=False,width=140)
    append='\n'.join('  '+s if s else '' for s in append.splitlines())+'\n'
    with queue.open('ab') as f:f.write(append.encode('utf-8'))
    assert queue.read_bytes().startswith(before)
    mf=BASE/'manifest.json'
    m=json.loads(mf.read_text('utf-8')) if mf.exists() else {'status':'FIRST_GATEWAY_RESOURCE_BATCH_IN_PROGRESS',
      'formal_enabled':False,'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'assets':[]}
    m['assets'].extend(rows);dump(mf,m)
    dump(BASE/f'preflight-{phase}.json',{'passed':True,'tasks':len(rows),'old_prefix_exact':True,
                                      'rendered_references_exist':True,'fallback_used':False})
    print(json.dumps({'registered':len(rows),'phase':phase,'dry_run':True}))


def prepare():
    assert not (BASE/'manifest.json').exists()
    plan()
    dump(BASE/'selected-design-authorization.json',{'date':'2026-10-23','user_request':'那先开始制作西域赤岩关镇',
       'reference':REF,'reference_sha256':sha(ROOT/REF),
       'scope':'User selected redrock overview as production direction; first gateway district and its assets. Other three designs unapproved; provisional town name, no new plot/canon data.'})
    register(ITEMS,REF,'map-idle')


def register_character():
    m=json.loads((BASE/'manifest.json').read_text('utf-8'));idle=next(r for r in m['assets'] if r['key']=='guard_idle')
    assert idle.get('output') and idle['mode']=='RGBA'
    common='''Use case: stylized-concept
Asset type: ONE full-body MAP WALK FRAME, truly transparent, not portrait or multi-frame sheet.
Reference image 1 is the EXACT SAME anonymous redrock guard's identity AND fixed map camera/canvas baseline. Preserve face, cap, beard, vest, pouch side, boots, tunic hem, natural skin, shoulder width, limb length, lighting and painterly detail. No headband/turban/forehead ties, no new weapons. Facing SCREEN DOWN, same slight overhead map view as idle. Arms relaxed with small opposite swing, hips stable, head/torso never bounce or turn. Legs and boots distinct. Camera and apparent human size MUST match idle exactly.
One character centered on the SAME original reference canvas; cap top and LOWEST planted boot at the SAME pixels as idle. Do not zoom, crop, reframe, change margins or fit a new silhouette. Transparent padding remains. Tiny original contact shade only, no floor, text, grid, caption or other object. ONE frame only, no repeated character. Edit only the leg/boot/forearm pose as follows:
'''
    phases=[('walk_f01','地图下行01·左脚着地','LEFT foot (on viewer RIGHT) reaches forward toward screen-bottom and plants flat. RIGHT leg (viewer LEFT) extends behind with heel lifted; clear separated contact pose. Left forearm swings slightly back, right forearm slightly forward.'),
            ('walk_f02','地图下行02·右脚经过','LEFT leg (viewer RIGHT) supports weight under hip; RIGHT knee (viewer LEFT) moves forward past support knee, right boot lifted clearly off ground with toe down. Short passing stance, NOT another wide contact pose.'),
            ('walk_f03','地图下行03·右脚着地','RIGHT foot (on viewer LEFT) reaches forward toward screen-bottom and plants flat. LEFT leg (viewer RIGHT) extends behind with heel lifted; this is the OPPOSITE contact to frame01. Right forearm back, left forearm forward.'),
            ('walk_f04','地图下行04·左脚经过','RIGHT leg (viewer LEFT) supports weight under hip; LEFT knee (viewer RIGHT) moves forward past support knee, left boot lifted clearly off ground with toe down. Passing stance opposite frame02, no torso or baseline shift.')]
    entries={key:('npc_walk','赤岩关卒·'+label,common+pose) for key,label,pose in phases}
    entries['guard_portrait']=('portrait','赤岩关卒·同人立绘','''Use case: stylized-concept
Asset type: one full-body conversation portrait of the EXACT SAME anonymous guard in reference image 1, transparent background. Reference is identity and costume, not pose or map camera.
Preserve adult man 35-45, natural warm skin, broad nose, short black beard, charcoal soft round cap WITHOUT forehead band/ties/headwrap, rust-brown short padded vest, grey-beige split tunic, dark trousers, worn boots, plain belt, small tan document pouch on HIS RIGHT hip. Plain ordinary pass guard, no named lore or emblem. Full body from cap to boots, natural standing pose in slight left-facing three-quarter eye-level portrait camera, hands relaxed and empty, restrained calm watchful expression. Semi-realistic painterly wuxia, mature natural face, upper-left neutral daylight. No heroic armour, cape, long sword, spear, decorations, turban or headband. At least 14% truly transparent clear margin around full body including small contact shade. No terrain, frame, text, UI, backdrop or additional person. This is a PORTRAIT; do not render as mini map sprite.
''')
    register(entries,idle['output'],'walk-portrait')


def start(key):
    mf=BASE/'manifest.json';m=json.loads(mf.read_text('utf-8'));a=next(r for r in m['assets'] if r['key']==key)
    assert a['status']=='REGISTERED' and a['calls']==0
    assert sha(ROOT/a['reference'])==a['reference_sha256']
    a.update(status='BUILTIN_CALL_DISPATCHED',calls=1);dump(mf,m)
    print(json.dumps({'key':key,'prompt':a['prompt'],'reference':a['reference']}))


def record(key,source):
    mf=BASE/'manifest.json';m=json.loads(mf.read_text('utf-8'));a=next(r for r in m['assets'] if r['key']==key)
    assert a['status']=='BUILTIN_CALL_DISPATCHED'
    dest=BASE/a['kind']/(a['id']+'.png');assert not dest.exists();dest.parent.mkdir(exist_ok=True)
    source=Path(source);shutil.copyfile(source,dest);assert sha(source)==sha(dest)
    with Image.open(dest) as im:
        size=list(im.size);mode=im.mode;alpha=im.getchannel('A') if 'A' in im.getbands() else None
        bbox=list(alpha.getbbox()) if alpha is not None and alpha.getbbox() else None
        margins=[bbox[0]/im.width,bbox[1]/im.height,(im.width-bbox[2])/im.width,(im.height-bbox[3])/im.height] if bbox else None
        metrics={'full_alpha_bbox':bbox,'full_alpha_margin_fraction':margins,
                 'margin_10_percent_pass':bool(margins and min(margins)>=.1),'alpha_extrema':list(alpha.getextrema()) if alpha else None}
    a.update(status='RAW_CANDIDATE_NOT_IMPORTED',output=dest.relative_to(ROOT).as_posix(),source_path=str(source),
             sha256=sha(dest),prompt_sha256=sha(ROOT/a['prompt']),size=size,mode=mode,metrics=metrics)
    dump(dest.with_suffix('.meta.json'),{**a,'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,
                                      'fallback_used':False,'formal_enabled':False,'original_preserved':True})
    dump(mf,m);print(json.dumps({'key':key,'output':a['output'],'size':size,'mode':mode,'margin_pass':metrics['margin_10_percent_pass']}))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['prepare','register-character','start','record'])
    p.add_argument('--key');p.add_argument('--source');a=p.parse_args()
    if a.action=='prepare':prepare()
    elif a.action=='register-character':register_character()
    elif a.action=='start':start(a.key)
    else:record(a.key,a.source)
