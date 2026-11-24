"""Native masterplan proposal for a distinct Miao-inspired mountain market city."""
import json
import re
import shutil
import sys
from pathlib import Path
import yaml
from PIL import Image
from build_redrock_town_20261028a import ROOT, save, sha

NAME='miao_town_design_20261029e'
RAW=ROOT/'assets/raw'/NAME
STAGE=ROOT/'assets/staging'/NAME
QUEUE=STAGE/'production/prompts'
PROMPT='''Use case: stylized-concept
ONE finished city masterplan concept painting for a MIAO-INSPIRED MOUNTAIN MARKET CITY in a hand-painted realistic 2.5D wuxia RPG. A new independent regional city, with the architectural grounding of the wooden stilt houses of Xijiang, Leishan, southeastern Guizhou. An original fictional layout, not a copy of a real tourist village. Inhabited peaceful everyday life, medium town scale, around35 complete buildings. The main identity is timber stilt architecture following terrain contours, slate roof clusters, blue-white wax-resist textiles, modest embroidery craft and a small lusheng gathering square.
Camera and composition: elevated ORTHOGRAPHIC three-quarter architectural bird's-eye view from the south, landscape16:10. The whole irregular town, its two bridge approaches and surrounding slopes fully inside the image, no clipped foreground roof or bridge. Strong clear game-map composition and believable continuous foot routes. The town fills roughly75% of the frame, with a narrow margin of wooded hills, small agricultural terraces and an upstream creek. No distant photographic skyline or cinematic vanishing point. Readable ground, doors, small courtyard floors, steps and river banks. Fine realistic painted material detail, calm diffuse afternoon light with gentle upper-left highlights, no heavy outlines, no overwhelming fog.
Terrain and massing: a narrow shallow green-gray creek runs from middle-left toward the lower-right foreground. Irregular clustered dark honey-brown TIMBER houses stand on STONE footings or exposed wooden stilt frames at the slope edge, usually2or3storeys, simple overlapping gray slate-tile pitched roofs with restrained local ridge details, horizontal balconies, practical timber rails and side stairs. Upper storeys face the contour lanes, lower support frames step down onto the natural slope; posts truly meet ground, no floating houses. Floors and paths have a coherent local height. Create THREE modest connected hillside terraces with short staggered stone stair flights and landing courts, never one giant straight staircase or a city built on sheer cliffs. Buildings cluster into5or6 irregular neighborhood groups with close-set roofs, small inner yards and narrow alleys; NOT equal-spaced rows, chessboard plots or a sparse asset kit. Natural forest/retaining walls bound the town, no monumental city-wall rectangle.
Spatial plan and circulation: lower-left mountain approach enters through a modest practical wooden village gate, then one SHORT SIMPLE ROOFED TIMBER FOOTBRIDGE crosses the narrow creek into a riverside commercial lane. Bridge has one continuous plain gray pitched roof, open sides and flat walkable deck, human-scale timber posts; no tall multi-pavilion towers or elaborate pagoda. Both bridge ends firmly join visible stone landings and paths. A smaller UNCOVERED timber footbridge upstream links back to the weaving quarter, forming a complete loop. Riverside lane curls toward the central plaza, climbs in short switchbacks through residential lanes and returns via the upper craft yard; every section has a clearly visible destination. Cargo and laundry props stay beside paths, not in the passage or at stair mouths. Main path wider, small residential paths narrower, no drawn route arrows or grid.
Six connected identifiable districts, with these EXACT small simple Chinese map labels placed clearly beside their areas, short thin leader lines only:
"01 山口寨门" at lower left: small timber entrance gate and arrival clearing, stone approach, pack baskets and a plain handcart off to one side, no military fortress.
"02 临溪街市" at lower center/right: clustered timber shop houses, narrow covered porches and modest cloth awnings following the creek bank, small baskets, produce and textile counters set back from the pedestrian lane. Only a little water surface, no huge river or lake.
"03 芦笙坪" at center: a modest open oval stone-and-compacted-earth gathering square, a few tiny adult residents carrying simple bamboo lusheng instruments or resting, edged by timber homes and shade trees; this is the main visual landmark, no tower at its center.
"04 蜡染绣坊" at left-middle slope: practical open work porches, waist-high work tables, indigo dye vats, blue-and-white wax-resist cloth hanging from low drying rails in one courtyard, restrained geometric and plant patterns; clean water kept separate from dye vats. Textile strips are real cloth, not flags covering the whole town.
"05 吊脚民巷" on the upper and right hillside: dense but legible staggered timber stilt houses, two or three private yards, cooking jars, firewood storage, everyday laundry, short safe timber balcony steps and stone retaining edges; keep a few front doors and uphill lane mouths visible between roofs.
"06 梯田粮院" on the right outer slope: three or four small green rice terraces following contours, a modest raised timber granary and a shared drying yard, a narrow irrigation runnel, fields separated from dense house blocks, no giant scenic terrace panorama.
People: small anonymous adult residents for scale, practical dark-indigo everyday garments with modest woven/embroidered trim, a few restrained silver necklaces/ear ornaments, farmers and craft workers with bamboo baskets. A few women in practical pleated skirts, men in plain jackets or dark headcloths. No carnival costumes everywhere, no giant silver headdresses on all residents, no named heroes or weapons. People only indicate scale and activity; not a character sheet.
Palette: warm weathered timber, charcoal/slate gray roofs, moist moss-green stone, indigo and ivory cloth accents, layered muted mountain foliage and small green paddy patches. A few low orange cooking embers inside sheltered work areas, no neon illumination. No desert sand, red canyon rocks, palm trees, adobe blocks, domes, enormous fortress, European castle, generic red-and-gold palace, giant Dong-style multi-tier drum tower, horror tribal symbols, skull totems, fantasy ritual altar, modern tourist signage, electric lights, road vehicles, staged performance stands or huge crowds.
Only the SIX exact simplified Chinese district labels above. No title, extra text, labels on shops, legend, UI, logo, watermark or decorative frame. One coherent complete design painting, not a contact sheet, playable background texture, extracted asset sheet or collage.
'''
SOURCES=[
 {'title':'苗寨吊脚楼营造技艺','url':'https://www.ihchina.cn/project_details/14316/','use':'木构、依山错落与吊脚支撑的建筑参考'},
 {'title':'苗族芦笙舞','url':'https://www.ihchina.cn/project_details/12959/','use':'芦笙活动空间的生活参考，不指定新游戏节庆或仪式'},
 {'title':'苗族芦笙制作技艺','url':'https://www.ihchina.cn/project_details/14318.html','use':'普通手艺生活与芦笙道具参考'},
 {'title':'苗族蜡染非遗工坊案例','url':'https://www.ihchina.cn/news_1_details/26903.html','use':'点蜡、浸染、晾布等生产院落参考，现代营销内容不进入古代场景'},
]

def prepare():
    assert not RAW.exists() and not STAGE.exists()
    (QUEUE/'templates').mkdir(parents=True)
    name='miao_masterplan_20261029e'
    (QUEUE/'templates'/(name+'.yaml')).write_text(yaml.safe_dump({'name':name,'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'opaque'},allow_unicode=True,sort_keys=False),'utf-8')
    import gen_assets as renderer
    renderer.TEMPLATES_DIR=QUEUE/'templates'
    assert renderer.render_template(name,{'asset_prompt':PROMPT},{})['prompt']==PROMPT.strip()
    prompt=QUEUE/'miao_masterplan_overview_v1.txt';prompt.write_text(PROMPT,'utf-8')
    (QUEUE/'tasks.yaml').write_text(yaml.safe_dump({'tasks':[{'id':NAME+'_overview_v1','template':name,'skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'transparent_background':False,'vars':{'asset_prompt':PROMPT}}]},allow_unicode=True,sort_keys=False),'utf-8')
    protected=[ROOT/'game/project.godot',ROOT/'game/scripts/autoload/scene_router.gd',ROOT/'prompts/tasks.yaml',ROOT/'scripts/gen_assets.py',ROOT/'game/scenes/drafts/desert_town_20261029d/desert_town.tscn',ROOT/'game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn']
    save(STAGE/'protected-before.json',[{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} for p in protected])
    html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8');data=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',html)[1])
    save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in data.items() if k!='resources'})
    save(STAGE/'references.json',{'accessed':'2026-10-29','sources':SOURCES,'purpose':'Original fictional game design inspired by referenced crafts and architecture; not a historical or single-village reconstruction'})
    save(STAGE/'preflight.json',{'passed':True,'rendered':1,'root_queue_written':False,'prompt_sha256':sha(prompt)})
    save(RAW/'manifest.json',{'status':'DESIGN_PROPOSAL_DISPATCHED','backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'fallback_used':False,'formal_enabled':False,'items':{'miao':{'id':NAME+'_overview_v1','name':'苗族风情山城 · 沿溪吊脚街寨总规','calls':1,'status':'DESIGN_PROPOSAL_AWAITING_USER_REVIEW','prompt':prompt.relative_to(ROOT).as_posix(),'prompt_sha256':sha(prompt)}}})
    print('Registered one native Miao-inspired city design; preflight passed; no game or shared queue writes')

def record(source):
    source=Path(source);m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=m['items']['miao'];assert not r.get('output')
    dest=RAW/'miao_masterplan_overview_v1.png';shutil.copyfile(source,dest);assert sha(source)==sha(dest)
    with Image.open(dest) as im:r.update(size=list(im.size),mode=im.mode)
    r.update(output=dest.relative_to(ROOT).as_posix(),source_path=str(source),sha256=sha(dest),native_pixels_unchanged=True)
    m['status']='DESIGN_PROPOSAL_AWAITING_USER_REVIEW';save(RAW/'manifest.json',m)
    save(dest.with_suffix('.meta.json'),{**r,'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'fallback_used':False,'formal_enabled':False})
    print(json.dumps({'output':r['output'],'size':r['size'],'mode':r['mode'],'native_copy_exact':True}))

if __name__=='__main__':{'prepare':prepare,'record':lambda:record(sys.argv[2])}[sys.argv[1]]()
