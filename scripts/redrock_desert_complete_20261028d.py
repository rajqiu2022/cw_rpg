"""Exclusive desert completion queue; native image bytes stay immutable."""
import argparse
import json
import sys
import yaml

import build_redrock_town_20261028a as base

ROOT=base.ROOT
NAME='redrock_desert_complete_20261028d'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
PROJECT=STAGE/'town_project'
ART=f'art/modules/{NAME}'
SCENE=f'scenes/drafts/{NAME}/redrock_town.tscn'
SCRIPT=f'scripts/drafts/{NAME}/town_controller.gd'
QUEUE=STAGE/'production/prompts'
REFS=base.REFS
COMMON='''Use case: stylized-concept
ONE original native game asset for the approved red sandstone canyon town. Reference1 is the regional design, reference2 the exact matte reddish masonry/dark weathered timber/ochre linen art style, NOT an edit target. Elevated orthographic 2.5D RPG camera, horizontal front ground line, small right depth face, upper-left warm daylight. Hand painted realistic game art, no ink outlines, no photographic background, no UI/text/logo/watermark. No Chinese tiled curved eaves, domes, palms, fantasy crystals or European medieval roofs. TRUE transparent background. Draw subject SMALL in the CENTER: subject plus every alpha pixel only in middle HALF of canvas, very wide empty alpha0 border on all four sides; no wide shadow haze, dust, ground island or clipped edges. One coherent complete object, no alternate versions or contact sheet unless the requested subject explicitly specifies a sprite sheet.
'''
ITEMS={
 'canyon':('landform','赤岩·外峡壁转角', '''ONE solid tall compact red sandstone canyon wall outcrop, roughly an L-shaped natural rock buttress in ground footprint. High rocky back mass with a left return wing descending toward the foreground, steep erosion strata and a few small rubble stones attached directly to its base. A flat-ish sunlit irregular top lip and clearly darker near-vertical fronts. Taller than the old low riser, rock width about1.5 times visible height. Rounded tapered low ends merge into terrain rather than rectangular cut faces. Transparent surroundings, no buildings, arches, roads or vegetation. No separate rock pile. A complete terrain silhouette with tiny tight contact shade; large transparent margins.'''),
 'stairs':('landform','赤岩·阶街连体石阶', '''ONE broad straight stone staircase connecting a lower street to a raised sandstone terrace. Front-facing stairs rise AWAY from viewer toward the BACK; 10 shallow readable worn ochre-red stone treads, continuous wide flat landing at top, low sloped sandstone cheeks on left/right, all structurally bonded. No wall crossing the staircase, no gate, tower or building. Stair width about3 adult shoulders and whole stair ground depth aboutsame as width. Complete staircase solid stone, 2.5D elevated orthographic, actual transparent background outside footprint. All steps aligned horizontally. Small centered object within very large transparent border.'''),
 'side_house':('building','赤岩·侧向阶巷民居', '''ONE compact asymmetrical two-storey canyon dwelling with LEFT-facing main doorway and a broad closed FRONT storage wall. Plain matte red sandstone flat parapet roofs, upper room set back, faded pale plaster panels, short straight projecting dark beams. Show wide LEFT depth face with main adult-sized door toward that face's front, small dark shuttered windows. Front wall has two slit windows and a hanging plain ochre cloth awning, no lettering. No yard wall, stairs, loose props or people. Exact regional material style, visually different silhouette from one-storey front-door house. Complete building on shallow foundation, transparent outside.'''),
 'market':('building','赤岩·遮阳商棚', '''ONE long modest desert market stall: faded russet and ochre cloth shade canopy over a dark timber frame, flat low red sandstone back storage wall, two completely open front bays. Separate shallow shelves built into the back with wrapped cloth parcels and plain baskets; front counter only at LEFT bay, RIGHT bay remains an open adult-width passage. No people, ground island, signboard or text. Around2.3 times wider than tall. Complete wood feet visible. Not an inn, not a tiled roof. Transparent surroundings.'''),
 'camel':('animal','赤岩·商队卧驼', '''ONE resting BACTRIAN CAMEL map sprite, ordinary realistic dusty tan fur, two humps, folded legs resting on ground, simple weathered brown saddle and two small tied cloth cargo bags. Facing lower left, full body, elevated orthographic same game camera. Calm ordinary pack animal, not monster or boss. No person, tether post, floor or landscape. Complete hooves, muzzle and two humps within very wide transparent margin, compact attached contact shade only.'''),
 'merchant_walk':('npc_walk','赤岩·商旅四向待机行走', '''ONE precisely aligned 4-column by4-row TRANSPARENT MAP SPRITE SHEET of the SAME ordinary middle-aged desert caravan merchant. One moderately stocky45-year-old man with round weathered face, short graying beard, simple dull tan headwrap, blue-gray waistcoat over ochre work shirt, brown loose trousers, dark closed cloth shoes, small leather satchel at belt. No weapon or ornamental armor, not a handsome young hero. EXACTLY16 separate complete full-body sprites arranged equal rectangular grid. Rows top to bottom face DOWN, LEFT, RIGHT, UP. Each row columns:1 neutral idle with both feet resting;2 left-foot forward walking;3 centered passing stride;4 right-foot forward walking. Each sprite SAME body, clothing, identity, height, foot baseline and map camera; real arm/leg changes, not translated or mirrored duplicates. Equal fixed cells; feet baseline at80% cell height, head near20%; all16 inside central80% of canvas with fully transparent outside and between cells. No cell lines, numbers, captions or background. A technical game animation atlas, not portrait panels. Square canvas.'''),
 'worker_walk':('npc_walk','赤岩·石匠四向待机行走', '''ONE precisely aligned 4-column by4-row TRANSPARENT MAP SPRITE SHEET of SAME ordinary55-year-old FEMALE sandstone craft worker: broad strong mature face, sturdy stocky body, sun-tanned skin, black/gray hair tied in low short bun, faded sage-green work jacket, muted brick-red waist sash, dark brown trousers and plain closed cloth shoes. Bare hands, no tool in hand, small worn work apron. Not glamorous, no jewelry/headdress/weapon. EXACTLY16 complete full-body map sprites in equal grid. Rows top to bottom: DOWN, LEFT, RIGHT, UP. Columns in each row:1 neutral idle;2 left-foot forward;3 passing stride;4 right-foot forward. Identical identity, proportions, clothes and height, real stride changes, same feet baseline80% and head20% within each cell. Camera fixed elevated orthographic; no perspective face portraits. Transparent gutters and outer margin, no cell borders, text, shadows cloud or ground. Square technical game atlas.'''),
 'fox':('enemy','赤岩·沙狐地图序列', '''ONE transparent horizontal FOUR-CELL animation strip of the SAME ordinary desert red FOX, map creature sprite. Four complete full-body equal-size foxes at same baseline, facing LEFT slightly toward camera: neutral standing, left foreleg forward trot, passing legs, right foreleg forward trot. Sandy rust fur, pale cream chest and tail tip, large ears, natural lean animal anatomy. SAME animal, scale and camera in every frame, distinct leg phases; no humanoid, armor, magic, blood or giant boss features. Equal cells with wide transparent gaps and generous outer padding, no grid/text/numbers, floor or scenery. Elevated orthographic 2.5D game art matching dry canyon palette. This is an ordinary wildlife map actor, not a story boss.'''),
 'waystation':('building','赤岩·关外避风小驿', '''ONE small roadside desert shade shelter/small building, weathered low red sandstone windbreak in a bonded U, flat reed-and-plank shade roof on two dark timber posts at rear half, fully open front and wide transparent center for a traveler. Modest body no taller than1.5 adult people, a plain small stone bench bonded along back wall. Complete low side walls and posts, no people, animals, water jars, vegetation or ground island. Distinct small map building for canyon approach. Orthographic game asset, large transparent margins.'''),
 'caravan_props':('scene_prop','赤岩·商路调查货箱', '''ONE compact grounded group of two worn plain wooden travel crates and a rolled ochre cloth bundle tied by dull rope. Top crate lid slightly ajar showing folded cloth, a small unmarked leather document pouch laid across it. Ordinary functional caravan cargo for placement in scene and overworld, not a backpack icon. No glowing quest marker, letters, symbols, gold, weapons, people or background. Strong simple map-readable silhouette with coherent contact and small size, true transparency around. No separate variants.'''),
}

def configure():
    for key,value in {'NAME':NAME,'RAW':RAW,'STAGE':STAGE,'PROJECT':PROJECT,'QUEUE':QUEUE,'ART':ART,'SCENE':SCENE,'SCRIPT':SCRIPT,'REFS':REFS,'COMMON':COMMON,'ART_ITEMS':ITEMS}.items():
        setattr(base,key,value)

def register_portraits():
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
    queue=yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'))
    for key,anchor,description in [
        ('merchant_portrait','merchant_walk','Same ordinary stocky middle-aged male caravan merchant: round weathered face, short gray-black beard, dull tan headwrap, blue-gray vest over ochre shirt, brown belt and small satchel. Calm ordinary face, no hero beautification.'),
        ('worker_portrait','worker_walk','Same sturdy mature female stone worker about55: broad sun-tanned face, black-gray low bun, faded sage jacket, brick-red sash, worn apron. Natural lined face, no beauty retouch, headdress or jewelry.')]:
        assert not any(r['key']==key for r in manifest['assets'])
        source=next(r['output'] for r in manifest['assets'] if r['key']==anchor)
        refs=REFS+[source]
        prompt='Use case: identity-preserve\nONE waist-up dialogue portrait of the EXACT SAME ordinary person in FINAL reference sprite sheet. First two references are style only. '+description+' Hand painted realistic 2.5D wuxia game portrait, upper-left warm natural light. Complete head, shoulders and waist silhouette, hands relaxed. True transparent background, wide alpha0 margins, no scenery, symbols, text or watermark. One person only, not a sheet.'
        ident=NAME+'_'+key+'_v1';path=QUEUE/(ident+'.txt');path.write_text(prompt+'\n','utf-8')
        template=ident
        refpaths=[str(ROOT/p) for p in refs]
        (QUEUE/'templates'/(template+'.yaml')).write_text(yaml.safe_dump({'name':template,'prompt_template':'{asset_prompt}','size':'1024x1024','quality':'high','background':'transparent','reference_images':refpaths,'require_reference_images':True},allow_unicode=True,sort_keys=False),'utf-8')
        assert renderer.render_template(template,{'asset_prompt':prompt},{})['prompt']==prompt
        manifest['assets'].append({'key':key,'id':ident,'kind':'portrait','label':'赤岩·'+('商旅同人立绘' if anchor=='merchant_walk' else '石匠同人立绘'),'prompt':path.relative_to(ROOT).as_posix(),'prompt_sha256':base.sha(path),'references':refs,'reference_sha256':{p:base.sha(ROOT/p) for p in refs},'calls':0,'status':'REGISTERED'})
        queue['tasks'].append({'id':ident,'template':template,'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':True,'reference_images':refpaths,'vars':{'asset_prompt':prompt}})
    base.save(RAW/'manifest.json',manifest)
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump(queue,allow_unicode=True,sort_keys=False),'utf-8')
    base.save(STAGE/'portrait-preflight.json',{'passed':True,'identity_refs_bound_before_dispatch':True,'registered':2})

def register_banks():
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
    queue=yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'))
    subjects={
      'west_bank':('赤岩·西侧连续峡壁','A SINGLE LONG CONTINUOUS cliff bank for the WEST/LEFT side of a playable canyon town. PORTRAIT silhouette: narrow in width, about3 times taller on canvas than wide. The cliff runs from top of canvas to bottom in map view, rock plateau is on LEFT and steep eroded red sandstone faces exposed toward RIGHT, the playable ground is transparent on RIGHT. This is a long contiguous rock wall range with bonded natural masses and no gaps through it, not a row of standalone boulders. Irregular taper at top/bottom allows overlapping another range; top ledge narrow. Large scale layered strata, silhouette variations, no stairs/buildings/people/ground island. Orthographic elevated camera, same regional light. One whole long vertical terrain component.'),
      'east_bank':('赤岩·东侧连续峡壁','A SINGLE LONG CONTINUOUS cliff bank for the EAST/RIGHT side of a playable canyon town. PORTRAIT silhouette about3 times taller on canvas than wide. The range runs top to bottom in map view, plateau on RIGHT, eroded cliff faces expose toward LEFT/front, playable empty transparent ground lies LEFT. One structurally contiguous natural wall of rock, no holes or gaps, no row of loose boulders. Same sandstone strata, upper-left warm daylight, narrow ledge, taper both ends for overlap. No objects, stairs, people, buildings, scenery or floor island. Complete long vertical terrain component in elevated orthographic game art, not a background image.'),
      'north_bank':('赤岩·北侧连续峡壁','A SINGLE VERY LONG low continuous red sandstone canyon rear wall/range for the NORTH/BACK boundary. LANDSCAPE silhouette around5 times wider than visible height. Contiguous bonded natural eroded cliff masses, a narrow sunlit top ledge and predominantly front-facing layered vertical face, no gaps that look walkable. Both ends descend and taper for overlapping side cliff banks. No pillars lined up as separate objects, stairs, houses, vegetation or floor island. Complete irregular skyline and continuous foot edge, not a rectangular texture patch. Orthographic camera, horizontal front base and upper-left light. One complete terrain module on actual transparency.')}
    for key,(label,detail) in subjects.items():
        assert not any(r['key']==key for r in manifest['assets'])
        prompt=COMMON+'\nRequested subject:\n'+detail
        ident=NAME+'_'+key+'_v1';path=QUEUE/(ident+'.txt');path.write_text(prompt+'\n','utf-8')
        template=ident;refs=[str(ROOT/p) for p in REFS]
        (QUEUE/'templates'/(template+'.yaml')).write_text(yaml.safe_dump({'name':template,'prompt_template':'{asset_prompt}','size':'1024x1536' if key!='north_bank' else '1536x1024','quality':'high','background':'transparent','reference_images':refs,'require_reference_images':True},allow_unicode=True,sort_keys=False),'utf-8')
        assert renderer.render_template(template,{'asset_prompt':prompt},{})['prompt']==prompt
        manifest['assets'].append({'key':key,'id':ident,'kind':'landform','label':label,'prompt':path.relative_to(ROOT).as_posix(),'prompt_sha256':base.sha(path),'references':REFS,'reference_sha256':{p:base.sha(ROOT/p) for p in REFS},'calls':0,'status':'REGISTERED'})
        queue['tasks'].append({'id':ident,'template':template,'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':True,'reference_images':refs,'vars':{'asset_prompt':prompt}})
    base.save(RAW/'manifest.json',manifest)
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump(queue,allow_unicode=True,sort_keys=False),'utf-8')
    base.save(STAGE/'bank-preflight.json',{'passed':True,'registered':3,'reason':'replace disconnected repeated outcrops with purpose-drawn continuous side banks'})

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('action',choices=['prepare','start','record','portraits','banks']);parser.add_argument('--key');parser.add_argument('--source');args=parser.parse_args()
    configure()
    if args.action=='prepare':
        base.prepare()
        report=json.loads((STAGE/'preflight.json').read_text('utf-8'));report['rendered']=len(ITEMS);base.save(STAGE/'preflight.json',report)
        print(f'Actual queue count: {len(ITEMS)}')
    elif args.action=='portraits':register_portraits()
    elif args.action=='banks':register_banks()
    elif args.action=='start':base.start(args.key)
    else:base.record(args.key,args.source)
