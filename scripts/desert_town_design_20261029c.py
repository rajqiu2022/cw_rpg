"""A separate sand-desert city design, with no Redrock or game-scene writes."""
import json
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image
from build_redrock_town_20261028a import ROOT, sha, save

NAME='desert_town_design_20261029c'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
QUEUE=STAGE/'production/prompts'
PROMPT='''Use case: stylized-concept
Asset type: ONE complete city masterplan concept painting for a new SAND DESERT trading city in a hand-painted realistic 2.5D wuxia RPG. This is a separate new location design from the red sandstone canyon town already made. NOT a repaint of a canyon fortress.
Subject: A compact inhabited pale ochre ADOBE trading city enclosed by low thick rounded mudbrick walls, in a vast sea of golden wind-rippled sand dunes. Flat sandy terrain with shallow undulations, no canyon, no red rock cliffs, no mountain town terraces, no grand stairs. Dense low one-and-two-storey houses with flat parapet roofs, thick rounded pale sandy plaster walls, narrow shaded winding streets and inward-looking small courtyards. One readable broad caravan approach comes from the lower left into a stout modest mudbrick gate; the central commercial street curves through the city and reconnects to the caravan court, while side lanes loop to residential yards. Main cargo route and shaded pedestrian alleys are physically separate. Around thirty complete buildings, coherent connected city blocks, NOT a sparse asset placement grid or scattered isolated modules. Keep town bounds and both gate ends entirely inside image with visible sand around them.
Camera/composition: elevated orthographic architectural bird's eye view, 3/4 view from the south, landscape 16:10. The city occupies around two thirds of the image, surrounding sand dunes about one third. Show roof tops, court floors, legible gate mouths and full wall corners. The main visual focus is the cloth-covered bazaar spine and pack-camel court. Calm broad warm desert sunlight from upper left, clear midtone detail, short restrained shadows, realistic painted surfaces and no heavy ink outlines. Palette cream, pale ochre, light warm adobe, dark weathered wood; small restrained indigo, clay red and woven linen accents in fabrics. Draw six spatially distinct areas joined by believable streets:
01 lower left: broad sand-road gate and unloaded arrival yard, carts and tied ordinary pack camels outside the direct gate passage.
02 center: dense shaded bazaar with layered reed/linen shade cloths spanning narrow shop streets, pottery and cloth counters at street edges, small practical flat-roof shops; no lettering on storefronts.
03 upper left inside wall: caravan guest court with a long open camel shelter, unloading space, stacked bales, small reception building and separate pedestrian entry; camels stand away from the narrow bazaar.
04 upper right inside city: one small well and covered water-storage court, raised ceramic storage jars, a TINY covered cistern; no river, lake, long canal, waterfall or large blue oasis. Maximum three sparse date palms close to this water court, otherwise scrub and bare sand only.
05 right/lower right: compact adobe residential blocks, two or three small private courtyards with drying cloths, jars and cooking corners, irregular close-set houses, modest roof access stairs only, no monumental stone staircase.
06 back/windward edge: practical repair and pottery work yards with wood frames, wheel repair, small clay kiln and windbreak reed screens; no industrial machinery, ruined palace or temple.
People only small anonymous scale markers in plain practical low-saturation robes, loose sleeves and simple soft caps, ordinary residents and merchants, no named heroes, weapons, headbands or wrapped turbans. A few calm ordinary Bactrian pack camels, not monsters or bosses.
Text: only six small tasteful simple Chinese cartographic labels with clean simplified Chinese and short leader lines, EXACT labels: "01 沙路城门", "02 遮阳巷市", "03 驼队客院", "04 井台蓄水", "05 土坯民居", "06 防沙工坊". No other text, title, UI, coordinate grid, logo, watermark or decorative border.
Avoid domes, minarets, pyramids, palaces, European castles, red canyon geology, Chinese curved tile roofs, jungle, lush farmland, palm forests, enormous water surfaces, luxurious fantasy architecture, floating walls and disconnected streets. All foreground houses fully visible, no cropped roofs at image edges. One cohesive city design painting only, not a contact sheet, playable map texture or sprite kit.
'''


def prepare():
    assert not RAW.exists() and not STAGE.exists()
    (QUEUE/'templates').mkdir(parents=True)
    template='desert_city_masterplan_20261029c'
    (QUEUE/'templates'/(template+'.yaml')).write_text(yaml.safe_dump({'name':template,'prompt_template':'{asset_prompt}',
        'size':'1536x1024','quality':'high','background':'opaque'},allow_unicode=True,sort_keys=False),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    assert renderer.render_template(template,{'asset_prompt':PROMPT},{})['prompt']==PROMPT.strip()
    (QUEUE/'desert_masterplan_overview_v1.txt').write_text(PROMPT,'utf-8')
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':NAME+'_overview_v1','template':template,'skip':True,
        'execution_backend':'builtin_image_gen','attempt_budget':1,'cli_fallback_allowed':False,'retries_allowed':False,
        'transparent_background':False,'vars':{'asset_prompt':PROMPT}}]},allow_unicode=True,sort_keys=False),'utf-8')
    protected=[ROOT/'game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn',ROOT/'game/project.godot',
        ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'prompts/tasks.yaml',ROOT/'assets/raw/sect_western_map_designs_20261022d/manifest.json']
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in protected])
    catalog=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    import re
    payload=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',catalog,re.S)[1])
    save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
    save(STAGE/'preflight.json',{'passed':True,'rendered':1,'root_queue_written':False,'new_city_separate_from_redrock':True,
        'prompt_sha256':sha(QUEUE/'desert_masterplan_overview_v1.txt')})
    save(RAW/'manifest.json',{'status':'DESIGN_PROPOSAL_DISPATCHED','backend':'builtin_image_gen','model':None,'provider':None,
        'cost':None,'fallback_used':False,'formal_enabled':False,'items':{'desert':{'id':NAME+'_overview_v1',
        'name':'沙漠商城 · 黄沙土坯总规设计','calls':1,'status':'DESIGN_PROPOSAL_AWAITING_USER_REVIEW',
        'prompt':(QUEUE/'desert_masterplan_overview_v1.txt').relative_to(ROOT).as_posix()}}})
    print('Registered separate sand-desert city design; preflight passed; no game writes')


def record(source):
    source=Path(source)
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));row=m['items']['desert']
    assert not row.get('output')
    dest=RAW/'desert_masterplan_overview_v1.png';shutil.copyfile(source,dest)
    with Image.open(dest) as im:row.update(size=list(im.size),mode=im.mode)
    assert sha(source)==sha(dest)
    row.update(output=dest.relative_to(ROOT).as_posix(),source_path=str(source),sha256=sha(dest),
        prompt_sha256=sha(ROOT/row['prompt']))
    m['status']='DESIGN_PROPOSAL_AWAITING_USER_REVIEW'
    save(RAW/'manifest.json',m)
    save(dest.with_suffix('.meta.json'),{**row,'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,
        'fallback_used':False,'native_pixels_unchanged':True,'formal_enabled':False})
    print(json.dumps({'output':row['output'],'size':row['size'],'native_copy_exact':True}))


if __name__=='__main__':
    {'prepare':prepare,'record':lambda:record(sys.argv[2])}[sys.argv[1]]()
