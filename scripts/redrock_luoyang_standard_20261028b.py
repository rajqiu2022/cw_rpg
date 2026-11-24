"""Dedicated art queue and new-file-only city successor; original art is immutable."""
import argparse
import json
import sys
from pathlib import Path

import yaml

import build_redrock_town_20261028a as base

ROOT=base.ROOT
NAME='redrock_luoyang_standard_20261028b'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
PROJECT=STAGE/'town_project'
ART=f'art/modules/{NAME}'
SCENE=f'scenes/drafts/{NAME}/redrock_town.tscn'
SCRIPT=f'scripts/drafts/{NAME}/town_controller.gd'
QUEUE=STAGE/'production/prompts'
save=base.save
sha=base.sha
REFS=['assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png','assets/raw/redrock_desert_life_20261025a/building/redrock_desert_20261025a_inn_v1.png']
COMMON='''Use case: stylized-concept
ONE newly drawn native asset for a 2.5D wuxia RPG red sandstone desert town. Reference1 is the approved town masterplan for regional character; Reference2 is our native inn for matte red sandstone, plain dark timber, faded tan cloth and restrained hand-painted game texture, warm light from upper left. Orthographic elevated map view, front base and facade lines horizontal, shallow RIGHT depth face. Not a crop, collage or whole settlement. No domes, curved tiled eaves, glitter, magic, lettering, labels, watermark, UI or extra variants.
Genuine transparent background and wide empty surroundings. Entire subject and tiny attached contact shade within central60% of BOTH dimensions:20% completely alpha0 margin all4 sides. No floor island outside the object, cast shadow cloud, fog, detached dust or clipped ends. Preserve all native RGBA and draw one complete silhouette.
'''
ITEMS={
 'court_wall':('building','赤岩·三面低院界', '''ONE continuous HORSESHOE / U-shaped low courtyard boundary wall with EMPTY TRANSPARENT playable center and a broad OPEN FRONT. Very wide and shallow rectangular ground footprint: rear wall horizontal at back, LEFT and RIGHT return walls come forward toward the viewer, each turns slightly inward at its front tip as a short stone jamb. The two front tips leave a clear central entrance at least35% of total width. All3 sides structurally bonded at corners, no detached wall panels. Plain low red sandstone wall with flat uncrenellated coping, about adult chest height, small irregular block courses and stone/wood terminal posts. Short top surfaces and side volumes readable; no tiled roof, gate arch, fortification crenels, tower, buildings, trees, people, door leaves or yard floor. Rear/front widths about3 times the footprint depth. Do not add anything to the large transparent interior. True transparent background, all4 outer corners and front tips complete, landscape canvas.'''),
 'inn_room':('building','赤岩·驿舍前厅空室', '''ONE EMPTY ROOFLESS CUTAWAY INTERIOR ARCHITECTURE module for the native inn. A wide rectangular warm sandstone slab floor, thick low red sandstone BACK wall and a short LEFT and RIGHT side wall, ceiling/roof removed. Camera elevated orthographic toward the back wall, front floor edge horizontal. Back wall has two small dark shuttered windows, plain timber beams and dusty pale plaster patches. FRONT wall entirely removed for viewing; the walkable floor is unobstructed from a central front entry. Actual floor plane visible, broad usable empty center. No furniture, counter, bed, loose props, people, curtains or UI: these will be separate native nodes. Outer boundary compact, no landscape or floor extending beyond room. Three sides have consistent ground contacts and no disconnected corner. Asset width around1.5 times total visible height. Transparent OUTSIDE room, floor and walls solid inside. Landscape canvas, complete module fits central60% with large alpha0 border.'''),
 'keeper_sprite':('npc_sprite','赤岩·驿舍女掌柜待机', '''ONE ordinary middle-aged WOMAN INNKEEPER, full-body MAP IDLE SPRITE, facing down toward screen. Age about48, round broad natural face, slightly stocky sturdy build, medium sun-tanned skin, small smile lines, practical ordinary features, no beauty retouch or glamorous young face. Black hair with a few gray strands in a small low bun, no headdress, headwrap or veil. Faded blue-gray simple work tunic, sleeves tied at forearms, dark brown loose trousers, dusty russet-brown waist apron with one small cloth pocket, plain closed dark cloth shoes. Hands relaxed in front of waist, feet slightly apart and both fully visible, neutral working stance. No weapon, jewelry, luggage or background props. Same elevated map camera/ground plane as reference, detailed hand-painted game sprite with clear adult7-head proportions and compact silhouette, not chibi or portrait. Single standing person, centered in square canvas, all body and tiny contact shade inside20% transparent margins.'''),
 'keeper_portrait':('portrait','赤岩·驿舍女掌柜同人肖像', '''ONE waist-up dialogue PORTRAIT of the EXACT SAME ordinary48-year-old female innkeeper in the map-sprite reference. Preserve round broad face, slightly stocky shoulders, sun-tanned skin, small smile lines, black/gray low bun, blue-gray work tunic, dusty russet apron and cloth pocket. Keep age and ordinary practical facial features; no smoothing into a young beautiful heroine, no makeup or ornamental jewelry. Warm calm neutral expression, slight three-quarter toward screen left. Hand-painted wuxia game style, natural restrained detail and upper-left light. Waist-up silhouette complete, hands lightly folded at waist if visible, no weapons, background scenery, symbols or speech text. Portrait canvas, real alpha0 background with generous empty margins. The FINAL reference is the identity anchor; the inn reference is material/style only.'''),
}


def configure_base():
    for k,v in {'NAME':NAME,'RAW':RAW,'STAGE':STAGE,'PROJECT':PROJECT,'QUEUE':QUEUE,'ART':ART,'SCENE':SCENE,'SCRIPT':SCRIPT,'REFS':REFS,'COMMON':COMMON,'ART_ITEMS':ITEMS}.items():setattr(base,k,v)


def prepare():
    configure_base();base.prepare()
    p=STAGE/'preflight.json';v=json.loads(p.read_text('utf-8'));v['rendered']=4;save(p,v)
    p=STAGE/'protected-before.json';v=json.loads(p.read_text('utf-8'));known={r['path'] for r in v}
    publication=json.loads((ROOT/'assets/staging/redrock_town_20261028a/publication.json').read_text('utf-8'))
    for r in publication['files']+[{'path':'game/art/modules/redrock_town_20261028a/resource-pack.json'}]:
        f=ROOT/r['path']
        if str(f) not in known:v.append({'path':str(f),'sha256':sha(f),'bytes':f.stat().st_size,'mtime_ns':f.stat().st_mtime_ns})
    save(p,v)


def start(key):
    configure_base()
    if key=='keeper_portrait':
        m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=next(x for x in m['assets'] if x['key']==key)
        sprite=next(x for x in m['assets'] if x['key']=='keeper_sprite')
        assert sprite.get('output') and r['calls']==0
        r['references']=REFS+[sprite['output']];r['reference_sha256']={p:sha(ROOT/p) for p in r['references']}
        save(RAW/'manifest.json',m)
        taskfile=QUEUE/'tasks.yaml';q=yaml.safe_load(taskfile.read_text('utf-8'));t=next(x for x in q['tasks'] if x['id']==r['id'])
        t['reference_images']=[str(ROOT/p) for p in r['references']]
        taskfile.write_text(yaml.safe_dump(q,allow_unicode=True,sort_keys=False),'utf-8')
        import gen_assets as renderer
        renderer.TEMPLATES_DIR=QUEUE/'templates'
        tpl=yaml.safe_load((QUEUE/'templates/redrock_town_module_20261028a.yaml').read_text('utf-8'))
        tpl['reference_images']=t['reference_images']
        template='redrock_keeper_portrait_20261028b'
        (QUEUE/'templates'/(template+'.yaml')).write_text(yaml.safe_dump(tpl,allow_unicode=True,sort_keys=False),'utf-8')
        t['template']=template;taskfile.write_text(yaml.safe_dump(q,allow_unicode=True,sort_keys=False),'utf-8')
        spec=renderer.render_template(template,t['vars'],{})
        assert spec['prompt']==(ROOT/r['prompt']).read_text('utf-8').strip()
        save(STAGE/'portrait-reference-preflight.json',{'passed':True,'reference_sha256':r['reference_sha256'],'identity_anchor':sprite['output']})
    base.start(key)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=('prepare','start','record'));p.add_argument('--key');p.add_argument('--source');a=p.parse_args()
    if a.action=='prepare':prepare()
    elif a.action=='start':start(a.key)
    else:configure_base();base.record(a.key,a.source)
