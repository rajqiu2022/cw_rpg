"""Four design-first concepts. Built-in tool only; preserves native originals."""
import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/raw/sect_western_map_designs_20261022d'
PROMPTS = ROOT / 'prompts/sect_western_map_designs_20261022d'
TEMPLATE = 'sect_western_masterplan_20261022d'
SOURCES = [
    'docs/luoyang-city-masterplan-20261019z.md',
    'docs/luoyang-city-masterplan-20261019z_art_proposal.md',
    'docs/luoyang-city-district-rollout-20261019aa.md',
    'docs/narrative-open-world-revision-v1.md',
    'docs/faction-martial-progression-v1.md',
    'game/data/scenes/openworld_wudang_gate.tres',
    'game/data/scenes/openworld_wudang_taiji_court.tres',
    'game/data/scenes/openworld_wudang_purple_cloud_court.tres',
    'game/data/scenes/ch7_s2_mingwu_tea_town.tres',
    'game/data/scenes/ch7_s4_mingwu_manor_outer_court.tres',
    'game/data/scenes/ch7_s6_mingwu_inner_court.tres',
    'game/data/scenes/ch8_s6_mingwu_main_hall.tres',
]

COMMON = '''Use case: stylized-concept
Asset type: an illustrated OVERALL LOCATION DESIGN for pre-production of a 2D wuxia RPG; NOT a playable background or screenshot.
Primary request: ONE complete, polished, wide landscape bird's-eye architectural masterplan, approximately 16:10, elevated three-quarter parallel perspective. Design a coherent inhabited place BEFORE modular construction. The entire settlement/sect and its access paths must fit within the frame with generous margin. Make its terrain, building silhouettes, connected lanes, entrance thresholds, courtyards and living functions readable together. High-quality hand-painted architectural game concept illustration, believable materials, detailed but visually calm. Buildings have coherent human scale, separate non-intersecting roof envelopes, attached contact shadows and real entrances; people are tiny anonymous occupation/scale cues, never portraits. Show BOTH public spaces and practical service/living areas. Strong route hierarchy and return loops with actual connections, natural transitions of ground materials, continuous inhabited built edges. Avoid detached houses scattered over empty rectangular road pads. Concept topology is suggestive, not a measured navigation contract.
'''

AVOID = '''
Constraints: use only the SIX exact numbered Simplified Chinese labels listed above, small clean cream planning tags with dark legible type and restrained number badges; keep labels off doorways and important paths. No other writing, title, fake calligraphy, coordinates, UI, HUD, buttons, arrows, player marker, watermark or logo. Anonymous people only; no newly named NPC, faction, quest, rewards, enemy boss or invented story event. No spider/web motifs, headbands, forehead ribbons, modern objects, European fantasy castles, impossible floating architecture, roof intersections, paths terminating over a precipice, objects blocking gateways, giant item icons, sprite collage, boxed asset showroom, pasted rectangular ground tiles, enormous empty plazas. Do not paste another city's rectilinear crossroads or Luoyang's city arrangement into this scene. Opaque full-scene illustration, no transparency or cutout border.
'''

SCENES = {
    'wudang': {
        'name': '武当派 · 云山层台',
        'id': 'wudang_plan_20261022d_overview_v1',
        'prompt': COMMON + '''
LOCATION: WUDANG martial sect, an airy mountainous Daoist sanctuary high above a sea of clouds. Its dominant form is an ASCENDING CHAIN OF THREE MOUNTAIN TERRACES connected by rail-protected stone stairways, set diagonally across grey limestone ridges, NOT a flat walled city. The lower mountain gate is bottom-left; a clearly visible gradual stair rises to a medium training terrace; the upper temple court sits farther back against a real broad rock shoulder. A narrower inhabited service path returns along the sheltered mountainside, with real landings and retaining walls. Keep clouds below the walkable surfaces; no cloud hiding crucial stairs, unsupported bridges or stairs directly into the sky. Overall design serene and disciplined, not imperial or monstrous.
SIX ZONES, exact labels:
"01 解剑山门": lower-left, a modest dark timber-and-grey-stone roofed gate attached to a short boundary wall, wide adult-height passage, resting ledge and small visitor shelter beside a real arrival path; two anonymous plain-robed mountain disciples, no headbands.
"02 太极道场": central broad but human-scale stone terrace, low safe perimeter rail, subtle worn circular stone inlay occupying only part of its floor, several tiny students doing EMPTY-HAND tai chi, a separate small sword-practice edge and a covered weapon rack; central circulation unobstructed.
"03 紫霄宫院": highest/main terrace, a dignified restrained Daoist timber hall, modest bronze-green aged roof and grey stone base, two smaller side halls enclosing an actual court; stair lands in front, doors and side exits legible. Do not turn it into a giant royal palace or a single pagoda.
"04 藏经静院": compact quiet side courtyard with reading room, smaller roof, one pine, stone bench and protected access from upper court.
"05 弟子居舍": sheltered lower-right cluster of connected modest dormitory wings, shared washing trough, wood store, vegetable/medicinal garden beds and tiny cooking/service court; daily life belongs to the inhabited monastery.
"06 后山清修": upper-left ridge footpath reaching a SMALL meditation pavilion, natural rock platform and scattered wind-bent pines. No oversized mysterious statue, no new named boss.
VISUAL LANGUAGE: cold blue-grey limestone, rough retaining stone, pale worn steps, weathered dark timber, muted bronze/blue-green roofs, sparse evergreen pines; low-saturation warm wood detail. Clear cool high-altitude morning light, sunlit terrace floors against a misty distant valley, clouds around the bases of cliffs. Deep vertical height and open sky distinguish this from any humid tea valley or desert settlement. Density concentrated in three realistic terrace groups, not uniform carpet of temples. Stair widths, railing height and adults share coherent scale; adult movement can be visually traced from arrival to every occupied court. Landscape makes the sect distinctive; keep architecture modest enough to sit on its actual rock support.
''' + AVOID,
    },
    'mingwu': {
        'name': '茗雾山庄 · 茶谷曲院',
        'id': 'mingwu_plan_20261022d_overview_v1',
        'prompt': COMMON + '''
LOCATION: MINGWU MANOR (茗雾山庄), a refined and lived-in martial estate in a LOW HUMID TEA VALLEY. Its dominant form is a HORIZONTAL WINDING CHAIN OF ENCLOSED COURTYARDS along an S-CURVING SMALL STREAM, with tea terraces climbing low hills behind. This is neither Wudang's mountain staircase nor a sinister cult fortress. Dense bamboo and tea groves frame the occupied valley without swallowing the paths. Whitewashed courtyard walls, dark almost-jade tiled low roofs, warm weathered timber colonnades, winding covered galleries, streamside stone banks, two modest broad stone footbridges. Roofed corridors visibly join actual door thresholds, courtyards are enclosed with accessible gates. Mist is low and thin, all route and door surfaces remain readable. A believable public tea town grades into a guest court and progressively quieter inner courtyards, with a separate TEA-WORK SERVICE LOOP outside the residential thresholds.
SIX ZONES, exact labels:
"01 茶镇入口": lower-left, a lively small tea street at the valley entrance, varied contiguous teahouse/shop fronts, awnings, tea baskets kept in setbacks, pack porter and tea buyers; modest arrival gate, no military city wall.
"02 外院客堂": left-middle, an estate entrance attached to white boundary walls, two side wings and reception hall around a compact paved guest court; one anonymous record clerk at a doorway, visiting travellers waiting by a bench. Public approach connects directly to the tea street.
"03 内院回廊": center-right, two enclosed quieter courts with a winding covered corridor, little planted corners, bamboo and plain white walls; a visible threshold differentiates public from inner circulation, but no drawn hidden passages, evidence diagram or crime markers.
"04 议事主厅": upper-right, a proportionate elegant main hall at the end of the court sequence, dark roof, warm timber doors, restrained tea-green cloth, smaller side rooms. Calm everyday human authority, no giant statues, demonic ornament, skulls, chains or red-black evil aesthetics.
"05 茶园工坊": upper-left and center-left hillside edge, stepped TEA SHRUB fields, a tea-processing shed, drying racks, covered sorting benches, tied tea chests and work courtyard; workers sort or carry tea. The chests and racks have a functional place instead of random clutter. Service lane loops back to tea street without passing through inner halls.
"06 后山小径": rear/north edge, a modest bamboo-shaded path along low tea slopes leading to a tiny resting pavilion, tied naturally into the outer service walk; no exposed secret tunnel or major cliff citadel.
VISUAL LANGUAGE: chalk-white plaster, charcoal/jade-black low roof masses, soft grey fine flagstones, natural weathered brown wood, celadon water and soft tea/bamboo greens. Diffuse bright overcast morning with gentle mist layers and occasional warm lanterns at sheltered doorways, never a night horror scene. Shallow water follows actual banks; both bridges touch land, no building sits over circulation. Many anonymous residents/tea workers wear modest light linen or muted tea-green clothing. Tiny martial residents may carry a SMALL closed equipment pouch, not all wield swords. Anonymous profession cues only, no named cast or plot spoilers. The whole composition should feel layered, intimate, lateral and human, with walls/roofs/corridors forming the spatial experience rather than mountain grandeur.
''' + AVOID,
    },
    'oasis': {
        'name': '西域绿洲商镇（设计暂名）',
        'id': 'oasis_plan_20261022d_overview_v1',
        'prompt': COMMON + '''
LOCATION: a fictional WESTERN-REGION OASIS CARAVAN TOWN, provisional visual-design location, no named historical city. Its dominant form is a COMPACT LOW FLAT-ROOF SETTLEMENT hugging a finite crescent oasis and irrigation channels amid pale dunes. No Chinese tiled-roof city with a yellow filter. Warm ochre ADOBE courtyard houses with flat parapet roofs, thick rounded mudbrick walls, timber lintels, occasional simple shaded archways, recessed doorways, small geometric turquoise ceramic accents and fabric shade canopies. At least twenty-five varied roof volumes grouped into coherent street blocks, interlocking irregular lanes, small courtyards and roof terraces. A modest enclosing adobe boundary has a legible southwestern caravan gateway and smaller eastern field opening. Primary shaded market street BENDS gently through town; side lanes form short return loops around a cistern and residential blocks. Do not draw a giant stone-cross axis or grand central palace.
SIX ZONES, exact labels:
"01 商路镇门": southwest, a simple broad mudbrick caravan gate, modest watch position, arrival lane and pack-animal rest bay at the side, with desert caravan route visibly continuing beyond the town. Passage not blocked by cargo or animals.
"02 遮阳巷市": central winding bazaar, cloth awnings stretched between proper wall supports, textile/pottery/food frontages with small stalls in recessed shop aprons, local shoppers and merchants. A few bright fabrics contrast with sandy walls but do not turn the scene into a festival rainbow.
"03 商队客院": west/northwest, an enclosed caravanserai with a genuine wide gate, human guest gallery, shaded luggage arcade, central loading court, and a separate camel/tether yard so animals do not block the market. A few camels and handlers, water trough and strapped bales suggest function.
"04 水井渠坊": east-central oasis edge, protected well/cistern head and restrained narrow irrigation channels, washing/water drawing ledges, two real low footbridges to neighborhood paths. Show WATER AS A FINITE RESOURCE, not a vast tropical lake with lush forest. Keep utility water courtyard connected to inhabited lanes.
"05 泥墙民居": south/east small contiguous adobe courtyard houses, domestic shaded patios, pottery jars, storage niches, simple ground-floor doors and a few roof-access stairs, laundry in private court, ordinary families and artisan at work.
"06 绿洲田园": north/east outside the densest blocks, small irrigated date-palm grove and vegetable plots bounded by earth channels, a low work shed and water gate. Cultivation ends visibly into pale dry dunes. Fields are modest enough for this small water source.
VISUAL LANGUAGE: pale buff sand and golden ochre rounded adobe, cool blue/turquoise only as sparse ceramic/textile accents, woven reed shades, rough timber, clay jars. Strong clear desert late-morning sunlight, short sharp shadows softened underneath practical awnings; cool refuge inside shaded lanes. Settlement clearly organized around water, trade and domestic shelter, gently irregular horizontal massing. No mountain mist, lush Chinese forest, steep canyon, red military fortress, domed monumental mosque, religious emblems, pyramids, minaret forest or European castle. Western-region clothing is practical loose layered cloth, plain soft caps or headscarves covering hair where needed, faces recognizable as varied ordinary humans; no forehead ribbons or caricature. Architectural design rather than historical reconstruction.
''' + AVOID,
    },
    'redrock': {
        'name': '西域赤岩关镇（设计暂名）',
        'id': 'redrock_plan_20261022d_overview_v1',
        'prompt': COMMON + '''
LOCATION: a fictional WESTERN-REGION RED SANDSTONE PASS TOWN, provisional visual-design location. Its dominant form is a NARROW INHABITED CANYON FORT TOWN stepping through three terraced levels between dry rust-red sandstone walls. Great layered red rock geology frames it; built structures sit on REAL broad ledges and retaining platforms, never thin knife edges. A clear southwest-to-northeast caravan pass climbs by TWO VISIBLE SWITCHBACKS with broad landings and low parapets. The lower road arrives through a squat defended stone pass gate, then enters connected stepped street terraces, continuing through a rear upper pass. A small side foot route returns between terraces using actual stairs. Use rugged RED STONE and dark timber with compact flat/low-pitched wind-resistant roofs, not an oasis bazaar recolored red and not a Chinese mountain monastery. No huge palace or fantasy tower. Group around twenty-five varied stone/adobe roof volumes into connected inhabited lanes rather than a few isolated military objects.
SIX ZONES, exact labels:
"01 峡口关门": lower-left, a thick dark rust-stone gateway spanning the real canyon road with a moderate timber gate, continuous low defensive walls and squat lookout posts attached to rock; bypass foot stair and a small inspection recess, no giant empty forecourt.
"02 阶街民巷": central terraces, compact stepped row houses of rough local stone and clay plaster, narrow sheltered pedestrian lanes, low retaining walls and connected stair landings; private work courts and roof terraces. A family at a sheltered doorway and an artisan carrying tools make it a lived-in town.
"03 驿舍马院": lower/middle terrace beside the pass road, small relay inn with enclosed animal yard, low stable, feed rack, water trough, postal baggage and one travelling caravan; room for movement between road and the yard, no animals standing across the gate.
"04 石作修坊": middle-right, a small mason's yard, cart-repair shed, dark timber braces, neatly stacked stone blocks and wheels kept to a work bay; service access from the climbing road without blocking pedestrian stairs.
"05 蓄水小院": sheltered middle-left, a SMALL covered cistern/well within windbreak walls, clay water vessels, water-drawing point and sparse thorn shrub; visibly precious stored water, no oasis lake, palm grove, broad canal, waterfall or lush farmland.
"06 高台望关": highest rear terrace, squat lookout and a modest guard rest building attached to continuous parapet, upper pass path visibly exits through a narrow notch. Limit height to believable functional structures; no huge statue, temple hall, evil banner or named boss.
VISUAL LANGUAGE: layered burnt-red geology, angular matte rusty sandstone masonry, desaturated earthen plaster, dark structural timber, muted rust/tan woven wind screens, pale dusty footpaths and minimal hardy scrub. Hard, clear late-afternoon desert sun gives readable strata and long coherent shadows without making lanes too dark. Shelters turned inward against wind, heavy low silhouettes and stair streets. Sparse anonymous guards and townspeople in practical dust-coloured layered clothing, plain cloth caps/hoods, no skull motifs or caricature. The main image must be instantly distinguishable from a flat yellow oasis: strong vertical canyon section, red stone, defended pass, switchbacks, sheltered tight town terraces and almost no vegetation. Make gate, homes, relay yard, workshops and cistern all part of one continuous inhabited environment.
''' + AVOID,
    },
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', 'utf-8')


def prepare():
    assert not (BASE / 'manifest.json').exists(), 'Already registered'
    BASE.mkdir(parents=True, exist_ok=True)
    PROMPTS.mkdir(parents=True, exist_ok=True)
    template = {'name': TEMPLATE, 'description': 'Four radically different location masterplans, design only',
                'prompt_template': '{asset_prompt}', 'size': '1536x1024', 'quality': 'medium', 'background': 'opaque'}
    (ROOT / f'prompts/templates/{TEMPLATE}.yaml').write_text(yaml.safe_dump(template, allow_unicode=True, sort_keys=False), 'utf-8')
    sys.path.insert(0, str(ROOT / 'scripts'))
    from gen_assets import render_template
    tasks, checks = [], []
    for key, s in SCENES.items():
        path = PROMPTS / f"{s['id']}.txt"
        path.write_text(s['prompt'], 'utf-8')
        rendered = render_template(TEMPLATE, {'asset_prompt': s['prompt']}, {})
        assert rendered['prompt'] == s['prompt'].strip()
        assert not rendered['reference_images'] and rendered['background'] == 'opaque'
        checks.append({'key': key, 'prompt_matches': True, 'no_reference': True, 'sha256': digest(path)})
        tasks.append({'id': s['id'], 'template': TEMPLATE, 'execution_backend': 'builtin_image_gen', 'skip': True,
                      'attempt_budget': 1, 'retries_allowed': False, 'cli_fallback_allowed': False,
                      'transparent_background': False, 'model': None, 'provider': None, 'cost': None,
                      'prompt_path': path.relative_to(ROOT).as_posix(), 'vars': {'asset_prompt': s['prompt']}})
    queue = ROOT / 'prompts/tasks.yaml'
    before = queue.read_bytes()
    old = yaml.safe_load(before.decode('utf-8'))['tasks']
    ids = {t['id'] for t in tasks}
    assert not any(t.get('id') in ids for t in old)
    (BASE / 'before-tasks.yaml').write_bytes(before)
    append = '\n' + yaml.safe_dump(tasks, allow_unicode=True, sort_keys=False, width=140)
    append = '\n'.join('  ' + line if line else '' for line in append.splitlines()) + '\n'
    with queue.open('ab') as f:
        f.write(append.encode('utf-8'))
    after = queue.read_bytes()
    assert after.startswith(before)
    parsed = yaml.safe_load(after.decode('utf-8'))['tasks']
    assert all(sum(t.get('id') == ident for t in parsed) == 1 for ident in ids)
    dump(BASE / 'preflight.json', {'passed': True, 'renderer': 'scripts/gen_assets.py:render_template',
                                  'checks': checks, 'task_old_prefix_exact': True,
                                  'tasks_before_sha256': hashlib.sha256(before).hexdigest(),
                                  'tasks_after_registration_sha256': hashlib.sha256(after).hexdigest()})
    dump(BASE / 'manifest.json', {'status': 'DESIGN_ONLY_REGISTERED', 'backend': 'builtin_image_gen',
                                'model': None, 'provider': None, 'cost': None, 'fallback_used': False,
                                'formal_enabled': False, 'source_sha256': {p: digest(ROOT / p) for p in SOURCES},
                                'items': {key: {'id': s['id'], 'name': s['name'], 'calls': 0,
                                               'prompt': f"prompts/sect_western_map_designs_20261022d/{s['id']}.txt",
                                               'status': 'REGISTERED'} for key, s in SCENES.items()}})
    print(json.dumps({'registered': list(ids), 'dry_run': 'PASS', 'old_tasks_prefix_exact': True}))


def start(key):
    m = json.loads((BASE / 'manifest.json').read_text('utf-8'))
    item = m['items'][key]
    assert item['calls'] == 0 and item['status'] == 'REGISTERED'
    item.update(calls=1, status='BUILTIN_CALL_DISPATCHED')
    dump(BASE / 'manifest.json', m)
    print(key, item['status'])


def record(key, source):
    m = json.loads((BASE / 'manifest.json').read_text('utf-8'))
    item = m['items'][key]
    assert item['calls'] == 1 and item['status'] == 'BUILTIN_CALL_DISPATCHED'
    source = Path(source)
    dest = BASE / f'{key}_masterplan_overview_v1.png'
    assert not dest.exists()
    shutil.copyfile(source, dest)
    assert digest(source) == digest(dest)
    with Image.open(dest) as im:
        size, mode = list(im.size), im.mode
        im.verify()
    item.update(status='DESIGN_PROPOSAL_AWAITING_USER_REVIEW', output=dest.relative_to(ROOT).as_posix(),
                source_path=str(source), sha256=digest(dest), size=size, mode=mode,
                prompt_sha256=digest(ROOT / item['prompt']))
    meta = {**item, 'backend': m['backend'], 'model': None, 'provider': None, 'cost': None,
            'fallback_used': False, 'formal_enabled': False, 'native_bytes_preserved': True}
    dump(dest.with_suffix('.meta.json'), meta)
    if all(i['status'] == 'DESIGN_PROPOSAL_AWAITING_USER_REVIEW' for i in m['items'].values()):
        m['status'] = 'FOUR_DESIGN_PROPOSALS_AWAITING_USER_REVIEW'
    dump(BASE / 'manifest.json', m)
    print(json.dumps({'key': key, 'output': item['output'], 'size': size, 'sha256': item['sha256']}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['prepare', 'start', 'record'])
    parser.add_argument('--key', choices=list(SCENES))
    parser.add_argument('--source')
    args = parser.parse_args()
    if args.action == 'prepare':
        prepare()
    elif args.action == 'start':
        start(args.key)
    else:
        record(args.key, args.source)
