"""Independent sand-desert city: registered native art and non-destructive source records."""
import json
import os
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image
from build_redrock_town_20261028a import ROOT, save, sha

NAME='desert_town_20261029d'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
PROJECT=STAGE/'town_project'
QUEUE=STAGE/'production/prompts'
ART=f'art/modules/{NAME}'
SCENE=f'scenes/drafts/{NAME}/desert_town.tscn'
SCRIPT=f'scripts/drafts/{NAME}/town_controller.gd'
COMMON='''Use case: stylized-concept
ONE original native game map module for the approved golden SAND DESERT adobe trading city, NOT the red sandstone canyon town. Matching elevated ORTHOGRAPHIC 2.5D wuxia RPG camera, horizontal front base, visible top and restrained RIGHT depth face, upper-left warm daylight. Hand painted realistic game art, matte fine pale ochre clay-plaster over rounded mudbrick, light sandy beige/cream walls and dark aged timber, rough plain ochre linen, no heavy outlines. Keep complete subject SMALL and CENTERED with at least20% empty alpha0 canvas on ALL four sides, including every foot, beam, canopy corner and tight contact shade. Actual TRANSPARENT background; no sand rectangle, backdrop, floor island, fog, glow or detached haze. No Chinese curved tile roofs, red rock, mountains, domes, minarets, pyramids, European castles, lettering, symbols, text, signs, watermarks, UI, people or animals. One complete coherent component, not a kit sheet or scene. All doors and windows use ordinary practical adult proportions. Do not crop any ends.
Requested subject:
'''
ITEMS={
 'enclosure':('building','沙漠城·连体土坯城廓', '''ONE complete continuous low mudbrick town-wall ENCLOSURE, an empty hollow rounded-rectangle ring viewed from high elevated orthographic south camera, width about1.7 times its total screen height. Four corners connected, broad near/front wall, a rear wall and two receding side walls, six modest squared rounded adobe buttress towers integrated at corners and front. A SINGLE broad OPEN caravan gate at the LEFT THIRD of the FRONT wall; two small stout adobe gate piers, flat dark timber lintel and doors folded fully against piers, transparent clear passage wide enough for two camels abreast. All wall segments physically bonded into one unbroken ring except that one functional gate passage. Entire inside of ring truly TRANSPARENT and EMPTY, no buildings, courtyard, sand, objects, plants or floor; exterior also alpha0. Uniform rounded mudbrick coping, simple small rectangular crenels, pale ochre plaster, no roofed towers or fancy battlements. The walls are about two adult bodies tall, while the interior ground plan is large enough for a small city of30 houses. Do not draw a tiny square courtyard around one house. Broad visible opening and low sand-colored silhouette. Every corner, gate footing and wall end comfortably inside image.'''),
 'dwelling':('building','沙漠城·正向土坯民居', '''ONE modest single-storey two-room adobe dwelling, wide low mass about2.2 times wider than tall, FLAT parapet roof with softly rounded pale mud-plaster corners, small set-back storage volume behind one end. Front-center closed dark timber adult door, two small recessed square shutter windows and a few projecting straight dark ceiling beams. Door height about half the total building's visible height. Tiny two-step doorstep directly attached to foundation. No separate yard walls, outdoor loose props, canopy, stairway, palms or smoke. Ordinary inhabited plain house, complete front-facing foundation, not a palace or ruin.'''),
 'corner_house':('building','沙漠城·侧巷双层屋', '''ONE asymmetrical compact two-storey adobe corner house. Lower broad pale yellow mud-plaster room and an upper room SET BACK on the LEFT half, two independent flat parapet roofs, a short narrow practical roof stair attached at far RIGHT edge. Main full adult timber door on the FRONT near right, one recessed side doorway on the visible RIGHT depth face, small shaded square windows. A small plain rolled linen awning tied over the FRONT door, no canvas spread across the whole scene. No yard wall, loose objects or people. Complete grounded silhouette and doorstep, no grand stairs, no ornate decoration, modest residence rather than inn.'''),
 'shop':('building','沙漠城·遮阳双铺面', '''ONE long low TWO-BAY adobe marketplace shopfront, width about2.5 times height. Flat rounded pale mudbrick storage rooms at back, two recessed closed timber doors with full adult proportions. Two simple dark timber posts support one low rough reed-and-plain-linen shade roof over the front shop line. A short counter only on LEFT bay displays a few clay pots; RIGHT bay has a shallow wall shelf of folded restrained indigo/ochre cloth and no floor-blocking front rail. Three timber feet complete and visible, not a huge tent. No people, merchant signs, text, ground tile, courtyard, camels or Chinese eaves. Clearly different silhouette from a house, broad front horizontal line.'''),
 'inn':('building','沙漠城·驼队客栈接待楼', '''ONE complete two-storey caravan guesthouse reception building, pale warm adobe with a slightly taller rear room and simple flat parapet roofs. Broad main closed double timber entrance in FRONT CENTER, adult door height around40% of total visible building height, recessed side windows and straight timber beams. A short plain linen porch canopy only above the main entrance, complete dark timber supports at both sides of the door. Front porch is narrow and shallow, entrance readable. No compound wall, stable, courtyard, animals, separate furniture or floor island. Practical desert inn, light rounded mud-plaster mass, not red stone or fantasy palace.'''),
 'stable':('building','沙漠城·开放驼棚', '''ONE complete long open-front THREE-BAY pack-camel shelter. Low pale adobe back wall and short side returns, rough nearly FLAT reed-mat and weathered plank roof on dark timber posts. Front bays open down to ground with true transparency, no front crossbar, fence or closed doors. Rear has a modest hay rack. Width about3 times visible height; room for ordinary camels of adult shoulder height. No camels, people, separate trough, cargo, yard walls or baked ground. Flat practical shelter, no peaked roof or Chinese tiles. Whole roof and all footing ends intact.'''),
 'well':('building','沙漠城·井台蓄水棚', '''ONE complete small well-and-cistern installation for a dry adobe city. A round light limestone well rim with bucket and dark timber winding frame, topped by a small flat reed shade on4timber posts; at RIGHT directly attached is a low small covered rectangular cistern in pale sand-colored plaster with a simple stone lid. Human-scale practical water supply, compact about1.7 times wider than tall. No large pool, visible river or water surface beyond a little dark water inside well. No people, palms, external court wall, floor slab, loose jars or background.'''),
 'workshop':('building','沙漠城·陶作修车工棚', '''ONE low wide adobe work building for pottery and wheel repair, a two-room pale mudbrick back structure with a flat reed/timber canopy projecting over an open FRONT work bay. A small squat rounded clay kiln is attached at far RIGHT, no smoke. Large simple dark timber entrance at back wall visible in open bay, a few attached wooden shelves, one leaning wheel against the wall, no separate tabletop or loose piles in foreground. Width about2.5 times height. No sign/text, machinery, people, Chinese eaves or outside yard wall. Complete grounded practical workshop, no baked floor.'''),
 'court_wall':('building','沙漠城·低土坯院界', '''ONE complete THREE-SIDED low adobe courtyard enclosure with a front OPENING, empty inside. Native front-facing U/trapezoid ground plan: long horizontal back wall, two short diagonal side returns reaching toward viewer, two short FRONT low wall wings on left and right leaving a wide central pedestrian entrance. All corners bonded smoothly, gently rounded pale yellow clay plaster and a few plain dark exposed mud bricks. Walls just under waist high, broad proportions around4 times wider than visible height. Actual entire courtyard interior and entrance alpha0, NO ground plane, floor, doorway arch, stairs, buildings, people or loose objects. Complete all ends well inside empty border. This is a low yard boundary, not the high town enclosure.'''),
 'palm':('vegetation','沙漠城·稀疏井院枣椰', '''ONE small modest DATE PALM, slender slightly curved rough trunk, sparse dusty olive-green fan of hanging date-palm fronds, no coconuts. Full canopy tips and entire rooted trunk base intact, realistic dry sparse tree, around3 adult bodies tall. Tiny tight attached root shade only, no ground mound, grass, pots, bushes, blue water or landscape. Isolated complete tree for placement next to one small town well, not lush tropical vegetation. Large genuinely empty transparent border around all leaf tips.'''),
 'dune':('landform','沙漠城·长缓沙丘', '''ONE long LOW gentle golden-sand dune ridge module, broad coherent smooth sloping volume about5 times wider than visible height. Soft wind-rippled upper surface, a pale sunlit crest and warm gently shaded front slipface, both ends taper gradually to ground. No sharp cliff, rock, big mountain, grass, plants, dust, sky or horizon. A complete shallow soft sand landform cutout on transparent alpha0 outside its exact footprint, no rectangular base plane. No translucent haze. Meant for distant outer town edges, not a barrier across streets. Keep entire low dune small inside broad empty canvas.'''),
 'guest_hall':('building','沙漠城·空客栈前厅', '''ONE ROOFLESS EMPTY adobe guesthouse interior module viewed in the SAME elevated orthographic game camera. A full shallow trapezoid room floor of small pale sandstone slabs, pale yellow mud-plaster BACK wall with two recessed dark square windows and short LEFT and RIGHT return walls; FRONT wall removed entirely for dollhouse access. Plain dark timber lintel details on back wall, no fancy columns, no roof, door leaves, kitchen, furniture, props, rugs, people or text. Wide single room about2 times wider than tall, adult standing height enough under back lintel. Entire floor and all three walls complete; this interior's native floor is intentionally included but nothing outside its room footprint. Surroundings transparent and broad empty margins.'''),
 'sand':('ground','沙漠城·细黄沙地表', '''Use case: stylized-concept
ONE square full-bleed SEAMLESS game ground texture, exact orthographic straight-down view of dry fine warm GOLDEN BEIGE sand. Extremely subtle close fine wind ripples, low contrast diffuse light, small restrained tonal variation, no gravel forest, large dune shadow, rock, footprints, vegetation, objects, border, text or center motif. Seamless tile edges, broad even light, matte realistically hand painted sand, not a photograph or a scene. Full image filled by sand, opaque RGB texture. No transparency.'''),
}


def prepare():
    assert not STAGE.exists() and not RAW.exists()
    (QUEUE/'templates').mkdir(parents=True)
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    rows=[];tasks=[]
    for opaque in [False,True]:
        t='desert_native_opaque' if opaque else 'desert_native_alpha'
        (QUEUE/'templates'/(t+'.yaml')).write_text(yaml.safe_dump({'name':t,'prompt_template':'{asset_prompt}',
            'size':'1024x1024' if opaque else '1536x1024','quality':'high','background':'opaque' if opaque else 'transparent'},sort_keys=False),'utf-8')
    for key,(kind,label,detail) in ITEMS.items():
        prompt=detail if key=='sand' else COMMON+detail
        t='desert_native_opaque' if key=='sand' else 'desert_native_alpha'
        assert renderer.render_template(t,{'asset_prompt':prompt},{})['prompt']==prompt.strip()
        prompt_file=QUEUE/(key+'.txt');prompt_file.write_text(prompt,'utf-8')
        rows.append({'key':key,'kind':kind,'label':label,'id':NAME+'_'+key+'_v1',
            'prompt':prompt_file.relative_to(ROOT).as_posix(),'prompt_sha256':sha(prompt_file),'calls':0,'status':'REGISTERED',
            'transparent':key!='sand','model':None,'provider':None,'cost':None,'fallback_used':False})
        tasks.append({'id':NAME+'_'+key+'_v1','template':t,'skip':True,'execution_backend':'builtin_image_gen',
            'attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':key!='sand','vars':{'asset_prompt':prompt}})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':tasks},allow_unicode=True,sort_keys=False),'utf-8')
    save(RAW/'manifest.json',{'status':'REGISTERED','backend':'builtin_image_gen','formal_enabled':False,'assets':rows})
    protected=[ROOT/'game/project.godot',ROOT/'prompts/tasks.yaml',ROOT/'scripts/gen_assets.py',ROOT/'game/scripts/autoload/scene_router.gd',
        ROOT/'game/scripts/field/player.gd',ROOT/'game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn']
    protected += [p for p in (Path(os.environ['APPDATA'])/'Godot/app_userdata/云影侠传').rglob('save*') if p.is_file()]
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in sorted(set(protected))])
    save(STAGE/'preflight.json',{'passed':True,'rendered':len(rows),'root_queue_written':False,'backend':'builtin_image_gen','fallback_allowed':False})
    print('Registered 13 native city modules; renderer preflight passed; shared files protected')


def start(key):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key)
    assert r['calls']==0 and r['status']=='REGISTERED' and sha(ROOT/r['prompt'])==r['prompt_sha256']
    r['calls']=1;r['status']='DISPATCHED';save(RAW/'manifest.json',m)
    print((ROOT/r['prompt']).read_text('utf-8'))


def record(key,source):
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(r for r in m['assets'] if r['key']==key)
    assert r['status']=='DISPATCHED'
    source=Path(source);out=RAW/r['kind']/(r['id']+'.png');out.parent.mkdir(parents=True,exist_ok=True)
    assert not out.exists();shutil.copyfile(source,out)
    with Image.open(out) as im:
        r.update(size=list(im.size),mode=im.mode)
        if r['transparent']:
            assert im.mode=='RGBA'
            b=im.getchannel('A').getbbox();w,h=im.size
            r['metrics']={'full_alpha_bbox':list(b),'margins':[b[0]/w,b[1]/h,(w-b[2])/w,(h-b[3])/h]}
            r['metrics']['margin_10_percent_pass']=min(r['metrics']['margins'])>=.1
    assert sha(out)==sha(source)
    r.update(output=out.relative_to(ROOT).as_posix(),source_path=str(source),sha256=sha(out),status='RAW_CANDIDATE',
        review_note='已确认沙漠总规的独立原生组件；原PNG保持，布局/留白/脚印逐项验收。')
    save(RAW/'manifest.json',m);save(out.with_suffix('.meta.json'),r)
    save(RAW/'resource-pack.json',{'status':'EDITOR_CANDIDATES','assets':[x for x in m['assets'] if x.get('output')]})
    print(json.dumps({'key':key,'size':r['size'],'raw_margin_pass':r.get('metrics',{}).get('margin_10_percent_pass')}))


def depth_revision():
    m=json.loads((RAW/'manifest.json').read_text('utf-8'))
    assert not any(r['key']=='enclosure_v2' for r in m['assets'])
    parent=next(r for r in m['assets'] if r['key']=='enclosure')
    parent.update(rejected=True,review_note='城廓首稿内院进深过浅，保留追溯，不放大成全城围墙。')
    prompt='''Edit the supplied empty adobe wall enclosure into a DEEPER city footprint, preserving its pale mudbrick material, one open front gate, truly transparent empty interior and all continuous bonded corners. The current enclosed plan is too shallow. Make the INNER EMPTY GROUND PLAN roughly 1.6 times wider than deep on the image, so it can hold several complete streets of buildings. The inside from the foot of the BACK wall to the foot of the FRONT wall must occupy about60% of the width, not a thin slit. Keep wall vertical FACES SHORT: roughly ONE TWENTIETH of total enclosure width; towers only a little taller. A broad rounded rectangular town ring viewed from a HIGH elevated orthographic south camera. Footprint width around1200 pixels and floor depth around720 pixels if canvas is1536, while wall faces only50 to70 pixels tall. These are proportion instructions, do not draw measurements or text. Gate at left third of FRONT wall, broad transparent fully open passage; all doors folded into piers. Low practical town wall, no roof, buildings, ground, props, people, animals, shadow haze, red rock or vegetation. ENTIRE ring including corner toes fully inside at least15% empty transparent margins. Do not fill the courtyard. Keep the exact SAME orthographic high camera and one complete enclosure, not a kit. All surroundings and entire courtyard must be genuinely alpha0. No labels, UI or watermark. This is an original native depth revision of the wall enclosure only.'''
    p=QUEUE/'enclosure_v2.txt';p.write_text(prompt,'utf-8')
    row={k:parent[k] for k in ['kind','model','provider','cost','fallback_used','transparent']}
    row.update(key='enclosure_v2',label='沙漠城·连体土坯城廓深院版',id=NAME+'_enclosure_v2',prompt=p.relative_to(ROOT).as_posix(),
        prompt_sha256=sha(p),calls=0,status='REGISTERED',parent_source=parent['output'])
    m['assets'].append(row);save(RAW/'manifest.json',m)
    queue=yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'))
    queue['tasks'].append({'id':row['id'],'template':'desert_native_alpha','skip':True,'execution_backend':'builtin_image_gen',
        'attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':True,
        'reference_images':[str(ROOT/parent['output'])],'vars':{'asset_prompt':prompt}})
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump(queue,allow_unicode=True,sort_keys=False),'utf-8')
    save(STAGE/'enclosure-depth-preflight.json',{'passed':True,'registered_targeted_edit':1,'first_native_kept':True,
        'reason':'shorten vertical face while deepen empty footprint, no local warping'})
    print('Registered one depth correction; native first enclosure kept')


if __name__=='__main__':
    {'prepare':prepare,'depth_revision':depth_revision,'start':lambda:start(sys.argv[2]),'record':lambda:record(sys.argv[2],sys.argv[3])}[sys.argv[1]]()
