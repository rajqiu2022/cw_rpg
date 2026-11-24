"""Source-bound 100 image expansion; builtin generation only, no game deployment."""
import argparse, hashlib, json, re, shutil, msvcrt
from pathlib import Path
from collections import Counter
from datetime import datetime
from zoneinfo import ZoneInfo
import yaml
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/"assets/raw/world_expansion_100_20261022"
LEDGER=BASE/"manifest.json"
PROMPTS=ROOT/"prompts/world_expansion_100_20261022"
PREFIX="world100_20261022_"
STYLE="""Original Chinese wuxia RPG asset, clear bright hand-painted realism, detailed natural materials, consistent with a 2.5D parallel-orthographic game. Exactly ONE isolated subject on genuinely transparent RGBA. No scenic background, white/grey backdrop, smoke, haze, ground plane, border, UI, text, watermark, spiders or webs. Upper-left soft daylight. Complete silhouette. Composition is a SMALL subject occupying ONLY the central 55 percent of the canvas: generously EMPTY transparent margin on all FOUR sides including all shadows, ears, weapon tips, roof tips and tails. Do not zoom to fill the canvas. No pixel art, chibi anatomy, modern items, forehead band, bandana, red hair ribbons or glowing magic. Single image, not a collage or sprite sheet."""
ARCH="""Map building COMPONENT, not a complete landscape or city. Fixed parallel projection looking down 30 degrees, front toward screen-bottom, straight verticals. Grey clay tile, aged timber and appropriate local stone. Entire base and roof in frame. Human-scale doors with tall clear openings and low shallow roof; no door obstructed by props. Dark inner depth, no grass or transparency inside doorways. No pavement rectangle or trees. No signboard words."""
NPC="""ONE full-body adult exploration NPC in a single static neutral idle facing screen-bottom. Orthographic camera looking down 30 degrees, clearly see top of head and both feet. Seven-head anatomy, equal ground baseline, relaxed hands. Not an animation strip. Practical period Chinese clothes; readable silhouette at small game scale."""
PORTRAIT="""Use the supplied NPC image as the EXACT IDENTITY REFERENCE. Create one separate waist-up dialogue portrait at eye level, preserving age, face, hair, skin, clothes, colors, fasteners and occupational equipment. Complete head and BOTH shoulders inside frame; do not crop sides. Lower body may end naturally at waist. Same person, not a youthful redesign. Calm individual expression. Preserve reference file unchanged."""
ENEMY="""One full-body battle-ready character facing SCREEN-LEFT, slightly elevated three-quarter orthographic view. Entire weapon, fingers and feet visible with generous padding. A SINGLE static ready frame, no motion sequence or impact effects, no ground disk, no blood."""
ANIMAL="""One anatomically grounded real animal facing SCREEN-LEFT in a slightly elevated three-quarter game battle view. Entire body including ears, tail and all FOUR paws clearly visible. Single static alert ready pose. Real fur and musculature, natural eyes, no armor, saddle, horns, extra limbs, supernatural aura or oversized fangs. No scenery, grass or floor shadow disk."""

def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def field(s,key):
    m=re.search(r'(?m)^'+key+r'\s*=\s*&?"([^"\n]*)"',s)
    return m.group(1) if m else ""
def row(key,kind,label,detail,city="shared",tier="",species="",sources=None,reference=None,dependency=None):
    return {"id":PREFIX+key,"kind":kind,"label":label,"city":city,"tier":tier,"species":species,"sources":sources or [],"detail":detail,"reference":reference,"dependency":dependency}

def definitions():
    rows=[]
    for city,label,source,parts in [
      ("bianzhou","汴州","openworld_bianzhou_city",[
       ("merchant_store_front","行商货栈门脸","A northern Chinese merchant storehouse doorway, grey brick and dark timber, sturdy double door, small closed side hatch, no crates outside."),
       ("posthouse_sidewall","驿馆侧墙模块","A straight grey-brick postal courtyard side wall with tiled coping, one narrow wood lattice window, complete wall ends, no doorway."),
       ("courtyard_corner","坊院转角模块","An L-shaped northern grey brick courtyard wall corner, restrained tile coping and clear stone foot, short lengths on both arms, no huge courtyard."),
       ("market_gateway","坊市木门模块","A modest timber street-courtyard gateway with shallow straight grey roof, open tall portal and warm-grey stone feet, no adjoining full building.")]),
      ("jinling","金陵","openworld_jinling_city",[
       ("waterside_warehouse","水巷仓门模块","Jiangnan canal warehouse entrance, white plaster dark timber and damp-stained stone sill, shallow tiled roof, clear tall doorway, no water plane."),
       ("white_wall_window","白墙花窗模块","A short Jiangnan warm-white lime-plaster wall with one circular dark wood lattice window and grey-tile coping, entire wall ends visible."),
       ("covered_corridor","水巷廊段模块","One open Chinese timber covered walkway bay with shallow grey tiled roof, two pairs of tall posts, no furniture, complete post feet, adult passage clear."),
       ("canal_steps","石埠台阶模块","A small freestanding section of worn grey stone canal landing steps, four broad shallow steps with simple edge stones, no water, bank or ground rectangle.")]),
      ("xiangzhou","襄州","openworld_xiangzhou_city",[
       ("garrison_gate","军营院门模块","A river-garrison Chinese grey stone and dark wood yard gate, shallow grey roof, plain iron fittings, clear tall open doorway, no weapons outside."),
       ("military_store","军需库门脸","A compact Chinese garrison supply store entrance, rough grey brick, heavy weathered plank door, narrow side ventilation grille, no furnace or Western forge."),
       ("drill_shelter","校场凉棚模块","One practical Chinese military yard timber shelter, low shallow grey roof on four tall robust posts, no weapons, people or floor slab."),
       ("barracks_wall","营房墙段模块","A short river-garrison grey brick wall segment with dark wood lattice high window, worn stone base and tile coping, complete ends.")]),
      ("qinghe","清河","openworld_qinghe_town",[
       ("roadside_inn","行旅客舍门脸","A modest roadside Chinese guesthouse entrance, ochre plaster and aged timber, low grey roof, tall empty doorway with interior depth, no hanging signs."),
       ("supply_awning","补给铺雨棚模块","One compact shop-side timber awning module, simple weathered wood roof shingles on sturdy posts, open underneath, no merchandise or ground slab."),
       ("courtyard_fence_gate","行旅院栅门模块","A short practical wooden slat courtyard gate with two stone-foot posts, a complete closed gate panel and small side sections, no rural landscape."),
       ("plaster_wall","土灰墙窗模块","A short pale-ochre plaster and dark timber wall section with simple rectangular wooden shutter, slight age wear, tiled coping and no plants.")]),
      ("yanmen","雁门","openworld_yanmen_pass",[
       ("watch_shelter","雪关值守棚模块","A compact Chinese frontier stone-foot timber watch shelter, thin natural snow on a shallow tiled roof, open sides, four tall posts, no mountain scenery."),
       ("stone_wall_corner","雪关石墙角模块","One short L-shaped rough grey-stone frontier wall corner, restrained snow along coping only, no snow ground slab or fortress panorama."),
       ("supply_store","关道储屋门脸","A compact Chinese frontier winter supply room entrance, stout stone piers and aged timber door, thin snow on low grey roof, clear threshold, no modern cabin."),
       ("stone_waygate","关道石门模块","A tall simple Chinese frontier stone lintel waygate, broad adult opening, short stone feet, no full city wall, snow only on top surfaces.")]),
    ]:
        src="game/data/scenes/"+source+".tres"
        for key,name,detail in parts: rows.append(row(city+"_"+key+"_v1","maps",label+name,detail,city,sources=[src]))
    for key,label,detail in [
      ("grey_brick_wall","通用灰砖直墙","One straight short grey-brick Chinese courtyard wall section with dark grey tiled coping and worn stone base, no gate or scenery."),
      ("timber_courtyard_gate","通用木院门","One compact Chinese timber courtyard gate, shallow grey tiled roof, tall dark recessed portal, simple posts and stone feet, no house behind."),
      ("grey_roof_well","通用瓦顶井亭","A small Chinese grey-tiled well shelter with four slim timber posts around a circular stone well rim and simple wood roller, no paving or bucket off canvas."),
      ("market_stall_canopy","通用市集棚架","One practical Chinese market stall canopy structure, muted tan cloth over a dark wood frame with a plain empty counter at side, no merchandise, full feet and roof.")]:
        rows.append(row("shared_"+key+"_v1","maps",label,detail,sources=["docs/luoyang-city-masterplan-20261019z.md"]))
    props=[
      ("zhuwei_map","One folded weathered paper village map, partly opened to show a few simple faint paths and building marks, NO readable writing, no modern compass."),
      ("zhouju_birdseal_copy","One aged narrow paper rubbing copy, faint abstract bird-like seal strokes, small red seal impression, no readable inscription, no actual sword."),
      ("yuanming_jade","One old pale green carved jade pendant, restrained worn relief and simple dark cord, no glowing seal or magical key effect."),
      ("xuantong_scale_weave_note","One bound craft note booklet partly open to subtle diagrams of interlocking small bronze scale plates and leather lacing, NO actual gauntlet or blade, no readable text."),
      ("xuanshuang_script","One worn incomplete exercise notebook with faded blue cloth cover, several frayed missing page corners and faint simple breathing diagrams, no readable words or magic."),
      ("wulin_invitation","One folded formal martial gathering invitation, warm cream paper and restrained deep red edging, blank central writing area, no lettering or emblem invention."),
      ("qiyun_letter","One cream paper letter folded within a worn envelope with dark red wax seal, a slightly unfolded corner, no readable writing."),
      ("qiyun_jade","One black jade pendant with a subtle weathered flame relief along its outer edge, dark red cord, no readable writing, no glow."),
      ("qiyun_incense_pouch","One small dark-red silk incense pouch, gathered neck with restrained cord ties, tiny understated flame embroidery at one corner, aged fabric, no smoke."),
      ("qingming_sword_record","One loose aged arms-catalog page, a delicate straight sword line diagram and faint ruled notation marks without readable words, slightly curled complete corners."),
      ("qingming_fragment","One incomplete pale tan folded manuscript fragment with uneven torn lower edge, faded blue margin ruling and faint abstract ink lines, no readable text or magic."),
      ("mingwu_confession","One small stack of confession manuscript paper sheets tied at one edge, dark ink strokes without readable text, a modest old fingerprint stain, no blood."),
      ("luoyang_quench_record","One workshop tempering log booklet with charcoal-stained cream paper, subtle steel cross-section and quench-vessel sketch, no readable text, no full weapon."),
      ("luoyang_clue_note","One deliberately fresh cream paper clue note with a faded red square seal mark, folded twice, abstract tiny ink lines only, no readable faction names."),
      ("linxi_old_ledger","One old medicine account ledger leaf, uneven browned edge and faint ruled columns with tiny illegible ink strokes, no readable numbers or names."),
      ("lingyue_token","One small pale jade moon-shaped pendant within restrained silver mounting, simple silk cord, traditional Chinese craft, no text or magic."),
      ("lieyun_evidence","One neatly tied set of seven aged evidence sheets with slightly offset visible corners, one muted red wax mark, illegible ink only, no new insignia."),
      ("jade_fragment","One naturally fractured dull green ancient jade fragment with a partial shallow carved curve, weathered sharp break, no glow or gems."),
      ("hanjia_water_rule_rubbing","One long narrow off-white water-gauge rubbing, charcoal-grey incised tally traces and irregular crease, no legible words, no actual sword or ruler prop."),
      ("fanxuan_letter","One creased personal handwritten letter on coarse cream paper, gripped-and-smoothed corners, faint bold illegible brush strokes, no readable statement."),
      ("faction_token","One modest non-faction traveler identification plaque, warm dark wood, simple dark cord and blank central panel, no invented faction emblem or text."),
      ("canglong_fragment_upper","One incomplete martial manuscript upper page with faint foot-position diagrams and simple dots, slightly torn lower edge and small blank title area, no readable script."),
      ("broken_mask","One torn matte black cloth lower-face mask lying naturally folded, fine tiny dark tea-leaf embroidery inside one corner, NO hard metal mask or skull."),
      ("cold_ridge_guard_breath_manual","One complete thread-bound practical breath-training manual, muted blue-grey cloth cover, cream page edges and plain blank title slip, no readable writing or aura."),
    ]
    for key,detail in props:
        source="game/data/items/"+key+".tres";s=(ROOT/source).read_text("utf-8")
        rows.append(row("prop_"+key+"_v1","quest_props",field(s,"display_name")+"道具图",detail,sources=[source]))
    people=[
      ("bianzhou_merchant","bianzhou","中原行商","openworld_bianzhou_city","A male central-plains traveling merchant about 45, stocky build, round observant face, restrained moustache, dark chestnut long coat over muted tan inner robe, modest cap and worn money pouch, no weapons."),
      ("jinling_merchant","jinling","绸缎商人","openworld_jinling_city","A male Jiangnan silk merchant about 39, lean refined face, neat short moustache, deep muted plum robe with pale grey collar, tidy topknot, small folded blue silk bolt tucked against hip."),
      ("zhuwei_gatekeeper_ch2","zhuwei","守村人","ch2_s1_zhuwei_market","An experienced male village gatekeeper about 55, weathered broad face, salt-and-pepper short beard, plain dark grey jacket, faded blue trousers, cloth boots, no armor, no drawn weapon."),
      ("zhuwei_hawker_ch2","zhuwei","货郎","ch2_s1_zhuwei_market","A cheerful male rural peddler about 31, slim wiry build, short tidy hair knot, moss-brown short coat and pale tan trousers, small cloth goods pack at hip, relaxed empty hands, no huge carrying pole."),
      ("zhuwei_apothecary_ch2","zhuwei","药铺掌柜","ch2_s1_zhuwei_market","An elderly male apothecary about 62, slim face, grey eyebrows and neat small goatee, faded dark sage long robe, cream cuffs, simple cap, small herb pouch at belt, no modern spectacles."),
      ("zhuwei_ginseng_farmer_ch2","zhuwei","参农沈伯","ch2_s1_zhuwei_market","An older male ginseng farmer about 64, sun-browned lean angular face, short grey stubble, patched ochre work coat over slate blue inner layer, pale leg wraps, compact woven herb basket on back."),
      ("zhuwei_constable_ch2","zhuwei","捕快韩策","ch2_s1_zhuwei_market","A male constable about 29, alert narrow face, clean-shaven, tidy small black cap, dark indigo practical robe and black wrist guards, plain sheathed dao at side, no ornate gold armor."),
      ("zhuwei_tournament_host_ch2","zhuwei","沈晚棠","ch2_s1_zhuwei_market","A poised young adult female tournament host about 27, oval face and clear focused eyes, black hair in a simple secure bun with plain wooden hairpin, muted warm-red jacket over cream crossed collar, dark teal practical skirt-trousers, no tiara or forehead ribbons."),
      ("zhuwei_boatman_ch2","zhuwei","船夫赵大江","ch2_s1_zhuwei_market","A male river boatman about 42, broad weathered face and strong forearms, slate-blue short shirt with rolled sleeves, brown waist sash and practical dark trousers, small coiled rope at hip, no long oar."),
      ("linxi_vendor","linxi","杂货商","ch1_s0_linxi_main_walkable","An adult MALE general-goods seller about 35, narrow weathered face, short moustache and goatee, tousled black topknot, olive travel cloak over brown robe and pale crossed collar, blue waist sash and small wooden goods box. Preserve this same established male identity wherever an identity reference is supplied. No scenic background from the reference."),
    ]
    for key,city,label,scene,detail in people:
        src="game/data/scenes/"+scene+".tres"
        idle=PREFIX+"npc_"+key+"_idle_1f_v1"
        rows.append(row("npc_"+key+"_idle_1f_v1","npc_sprites",label+"静态精灵",detail,city,sources=[src],reference="game/art/characters/npc_vendor_neutral.png" if key=="linxi_vendor" else None))
        rows.append(row("npc_"+key+"_portrait_v1","portraits",label+"同人立绘",detail,city,sources=[src],dependency=idle))
    animals={
      "tiger":("老虎",["A lean adult orange forest tiger with natural black stripes, moderate neck muscles and relatively narrow face, alert low walking-ready stance, mouth closed.","An adult cold-region tiger with pale ochre winter fur, thicker cheek ruff, natural dark stripes, sturdy four-square stance, no white fantasy coat."],["A prime broad-shouldered orange male tiger, markedly heavy neck and powerful forelegs, one old healed muzzle scar, deep dark stripes, calm dominant low stance.","A mature pale-ochre ridge tiger, thick weathered winter ruff, slightly notched left ear and broad muzzle, visibly robust muscles, low cautious ambush-ready posture."]),
      "lion":("狮子",["A tawny adult male lion with a modest sandy mane, lean natural build and natural amber eyes, entire tufted tail visible.","A tawny adult lioness, no mane, lean muscular shoulders and rounded ears, alert compact ready stance, complete tufted tail."],["A prime male lion with a broad dark-brown mane, exceptionally robust shoulders and one small healed nose scar, controlled dominant ready stance.","An experienced heavy-built tawny lioness with thicker shoulder musculature, a small old ear notch and weathered flank fur, confident low stalking-ready stance; no mane."]),
      "wild_dog":("野狗",["A rangy short-coated tan feral village dog with dark muzzle, pointed ears and a slightly curved tail, lean ordinary build, alert stance.","A mottled black-and-tan short-coated feral dog with half-flopped ears, lean small-medium body, natural dark eyes, watchful ready posture."],["A large robust brindled feral dog with deep chest, thick neck, a healed shoulder scar and one torn ear tip, grey-black muzzle, confident poised stance.","A powerful dark-brown feral dog with rusty cheeks, thick weathered coat and broad forequarters, one old healed muzzle nick, low vigilant stance."]),
      "fox":("狐狸",["A natural red fox with rusty orange fur, slender dark legs, white throat and white-tipped bushy tail, narrow muzzle, alert ordinary stance.","A grey-brown mountain fox with slightly tawny back, black lower legs and modest bushy tail, lean ordinary build, natural amber eyes."],["A large mature red fox with dense rich copper coat, pronounced dark leg markings, old tiny ear notch and exceptionally full white-tipped tail, very alert low stance.","A mature silver-grey mountain fox with thick dark-tipped winter coat, tawny cheek patches, robust shoulders for a fox and weathered ear edges, poised vigilant stance."]),
      "bear":("狗熊",["An adult Asiatic black bear with dark coarse fur, tan muzzle and restrained pale crescent chest marking, natural moderate build, standing on all four paws.","An adult brown bear with warm brown shaggy coat and natural shoulder hump, ordinary leaner forest build, relaxed-alert quadrupedal stance."],["A massive mature Asiatic black bear with deep chest, thick neck, worn dark coat and a small old healed muzzle scar, pale chest crescent, low powerful four-paw stance.","A large mature dark-brown bear with very broad shoulders and prominent natural hump, dense coarse fur and one old ear notch, wary dominant quadrupedal stance."]),
    }
    for species,(label,normal,elite) in animals.items():
        for tier,details in [("normal",normal),("elite",elite)]:
            for i,detail in enumerate(details,1):
                rarity="普通怪" if tier=="normal" else "野外精英"
                suffix=" This is a high-quality rare wilderness leveling enemy, distinguish strength by mature anatomy, fur and old healed marks only. It is NOT a story boss." if tier=="elite" else " This is an ordinary wilderness animal enemy, not an elite or boss."
                rows.append(row(f"animal_{species}_{tier}_{i:02d}_v1","animals",label+rarity+f"·{i}",detail+suffix,tier=tier,species=species))
    for key,label,detail,tier,source in [
      ("road_scout","驿道斥候普通怪","A lean adult male road scout with short black topknot, muted ochre short coat and light dark trousers, plain short saber held down, no official insignia.","normal","central_road_scout"),
      ("mine_outlaw","矿谷悍匪普通怪","A stocky adult male mine outlaw with rough square face, grey work jacket and earth-brown apron, worn short dao blade at side, dusty practical clothing.","normal","mine_outlaw"),
      ("reed_assassin","芦荡伏客普通怪","A slim adult female reed-marsh ambusher with tied black hair, desaturated moss green practical tunic and dark calf wraps, short narrow saber, no ornate jewelry.","normal","reed_assassin"),
      ("road_veteran","驿道老练刀客精英","A mature male wilderness road raider veteran, broad shoulders and weathered angular face, layered dark ochre and charcoal clothing with a small leather shoulder guard, old cheek scar and well-maintained plain dao.","elite","central_road_raider"),
      ("marsh_veteran","水泽老练私枭精英","An experienced stocky male wilderness marsh smuggler, dark green oiled short coat, reinforced brown wrist wraps, greying moustache, deep chest and heavy plain saber, confident low ready stance.","elite","reed_smuggler"),
      ("snow_veteran","雪岭老练刀客精英","A formidable mature male wilderness frontier raider, broad weathered face, dark slate padded layers and thick brown fur collar, reinforced leather belt, one old nose scar and practical dao, no noble ornaments.","elite","openworld_snow_raider"),
    ]:
        rows.append(row("human_"+key+"_v1","human_enemies",label,detail+" Single wilderness candidate, no story-boss identity or new loot implied.",tier=tier,sources=["game/data/enemies/"+source+".tres"]))
    bosses=[("boss_zhao_wuji","赵无忌剧情Boss","game/art/sprites/battle/standard_v2/zhao_wuji/zhao_wuji_ready_01.png"),
            ("masked_killer_leader","蒙面杀手首领剧情Boss","game/art/characters/battle_masked_killer_leader_v1.png"),
            ("ch5_false_banner_captain","伪旗统领剧情Boss","game/art/sprites/battle/ch5/false_banner_captain/false_banner_captain_ready_01.png"),
            ("boss_luoyang_captain","洛阳捕快头剧情Boss",None),
            ("ch8_xueying_last_guard","薛影剧情Boss","game/art/sprites/battle/ch8/xueying/xueying_ready_01.png"),
            ("ch8_su_wusheng_final","苏雾笙剧情Boss","game/art/sprites/battle/ch8/su_wusheng/su_wusheng_ready_01.png")]
    for key,label,ref in bosses:
        detail="Preserve the exact established character identity in the supplied reference: same face or mask, age, hairstyle, garment colors, weapon type and main equipment. Create one polished alternative static ready image of this SAME living character, facing left. Do not invent transformations, victory, death or new plot facts. No huge magic effects."
        if not ref: detail="An adult Chinese city constable captain, about 44, stern broad face, restrained short moustache, plain black cloth cap, muted dark indigo constable robe with iron-grey practical lamellar chest protection, dark brown belt and plain dao held ready. This is a concept for the existing unnamed Luoyang constable captain story enemy, not a new named general. No golden emperor armor."
        rows.append(row("boss_"+key+"_v1","story_bosses",label,detail,tier="story_boss",sources=["game/data/enemies/"+key+".tres"],reference=ref))
    assert len(rows)==100,Counter(r["kind"] for r in rows)
    return rows

def prompt(r):
    spec=ARCH if r["kind"]=="maps" else NPC if r["kind"]=="npc_sprites" else PORTRAIT if r["kind"]=="portraits" else ANIMAL if r["kind"]=="animals" else ENEMY if r["kind"] in ["human_enemies","story_bosses"] else "One small world-space quest prop in 30-degree orthographic view. Distinct readable material and silhouette, no inventory frame or surrounding objects. Any ink is faint non-readable texture; exact narrative text will be supplied by the game UI."
    return "\n\n".join([STYLE,spec,r["detail"]])

def prepare():
    assert not LEDGER.exists(),"Continue existing batch; never prepare twice"
    BASE.mkdir(parents=True);PROMPTS.mkdir(parents=True,exist_ok=True)
    rows=definitions();sources={}
    before=ROOT/"tmp/world_expansion_100_20261022/before";before.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(ROOT/"prompts/tasks.yaml",before/"tasks.yaml")
    for r in rows:
        for src in r["sources"]:
            assert (ROOT/src).is_file(),src
            sources[src]=digest(ROOT/src)
        if r["reference"]:
            assert (ROOT/r["reference"]).is_file(),r["reference"]
            sources[r["reference"]]=digest(ROOT/r["reference"])
        r.update({"prompt_path":(PROMPTS/(r["id"]+".txt")).relative_to(ROOT).as_posix(),"output":(BASE/r["kind"]/(r["tier"] or r["city"])/(r["id"]+".png")).relative_to(ROOT).as_posix(),"status":"PLANNED_NOT_GENERATED","attempts":0})
        (ROOT/r["prompt_path"]).write_text(prompt(r)+"\n","utf-8")
    old=(ROOT/"prompts/tasks.yaml").read_bytes()
    tasks=[{"id":r["id"],"template":"world_expansion_100_20261022","category":"world_expansion_100_20261022/"+r["kind"],"execution_backend":"builtin_image_gen","skip":True,"attempt_budget":1,"retries_allowed":False,"cli_fallback_allowed":False,"transparent_background":True,"model":None,"provider":None,"cost":None,"prompt_path":r["prompt_path"],"execution_ledger":LEDGER.relative_to(ROOT).as_posix(),"vars":{"asset_prompt":prompt(r)}} for r in rows]
    fragment=yaml.safe_dump({"tasks":tasks},allow_unicode=True,sort_keys=False,width=140).split("tasks:\n",1)[1]
    suffix=("\n  # User-authorized 100 asset expansion; builtin-only, protected from CLI re-execution.\n"+"\n".join("  "+line if line else "" for line in fragment.splitlines())+"\n").encode()
    tpl=ROOT/"prompts/templates/world_expansion_100_20261022.yaml"
    tpl.write_text('size: "1024x1024"\nbackground: transparent\nquality: medium\nprompt_template: "{asset_prompt}"\n',"utf-8")
    (ROOT/"prompts/tasks.yaml").write_bytes(old+suffix)
    ledger={"schema":1,"batch":"world_expansion_100_20261022","created_at":datetime.now(ZoneInfo("Asia/Shanghai")).isoformat(),"status":"GENERATION_IN_PROGRESS_NOT_RUNTIME","formal_enabled":False,"assets":rows,"source_sha256":sources,"old_tasks_bytes":len(old),"old_tasks_sha256":hashlib.sha256(old).hexdigest(),"classification":{"normal":"普通野外敌人","elite":"野外练级高品质怪物，不是剧情Boss","story_boss":"已有剧情敌人，is_chapter_boss=true"},"limits":["animals are user-requested visual candidates; no encounters or loot added","all images static; no animation credit","no local alpha deletion or background processing","no game data bindings, import, engine or user-process changes"]}
    LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+"\n","utf-8")
    data=yaml.safe_load((ROOT/"prompts/tasks.yaml").read_bytes());new=[r for r in data["tasks"] if r["id"].startswith(PREFIX)]
    assert len(new)==100 and len({r["id"] for r in new})==100
    assert (ROOT/"prompts/tasks.yaml").read_bytes()[:len(old)]==old
    for t in new: assert t["vars"]["asset_prompt"].strip()==(ROOT/t["prompt_path"]).read_text("utf-8").strip()
    for r in rows:
        if r["kind"]=="story_bosses": assert re.search(r'is_chapter_boss\s*=\s*true',(ROOT/r["sources"][0]).read_text("utf-8"))
    report={"status":"OFFLINE_NEW_100_PREFLIGHT_PASS","assets":100,"by_kind":dict(Counter(r["kind"] for r in rows)),"by_tier":dict(Counter(r["tier"] for r in rows if r["tier"])),"source_files":len(sources),"old_tasks_prefix_exact":True,"new_tasks_unique":True,"prompt_render_exact":True,"cli_calls":0,"canonical_boss_flags_verified":6}
    (BASE/"preflight.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps(report,ensure_ascii=True))

def record(asset_id,source):
    with (BASE/"manifest.record.lock").open("a+b") as lock:
        lock.seek(0,2)
        if not lock.tell():lock.write(b"0");lock.flush()
        lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_LOCK,1)
        try:
            ledger=json.loads(LEDGER.read_text("utf-8"));r=next(r for r in ledger["assets"] if r["id"]==asset_id)
            target=ROOT/r["output"];assert not target.exists(),target
            ref=r["reference"]
            if r["dependency"]:
                dep=next(x for x in ledger["assets"] if x["id"]==r["dependency"]);ref=dep["output"];assert digest(ROOT/ref)==dep["sha256"]
            if ref:r["reference_input"]={"path":ref,"sha256":digest(ROOT/ref),"role":"identity_reference"}
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target)
            with Image.open(target) as im:
                rgba=im.convert("RGBA");a=rgba.getchannel("A");bbox=a.getbbox();w,h=im.size
                margins=[bbox[0]/w,bbox[1]/h,(w-bbox[2])/w,(h-bbox[3])/h]
                metrics={"size":[w,h],"source_mode":im.mode,"has_real_alpha":im.mode=="RGBA" and a.getextrema()[0]==0,"full_alpha_bbox":list(bbox),"margin_fractions":margins,"margin_10_percent_pass":min(margins)>=.1}
            r.update({"status":"RAW_CANDIDATE_NOT_RUNTIME","attempts":1,"source_path":str(source),"sha256":digest(target),"bytes":target.stat().st_size,"prompt_sha256":digest(ROOT/r["prompt_path"]),"metrics":metrics,"model":None,"provider":None,"cost":None})
            target.with_suffix(".meta.json").write_text(json.dumps(r,ensure_ascii=False,indent=2)+"\n","utf-8")
            LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+"\n","utf-8")
            print(json.dumps({"id":asset_id,"size":metrics["size"],"margin_pass":metrics["margin_10_percent_pass"]}))
        finally:lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)

def reconcile():
    with (BASE/"manifest.record.lock").open("a+b") as lock:
        lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_LOCK,1)
        try:
            ledger=json.loads(LEDGER.read_text("utf-8"));restored=[]
            for r in ledger["assets"]:
                p=ROOT/r["output"];mp=p.with_suffix(".meta.json")
                if not mp.is_file():continue
                meta=json.loads(mp.read_text("utf-8"))
                assert meta["id"]==r["id"] and meta["sha256"]==digest(p)==digest(Path(meta["source_path"]))
                assert meta["prompt_sha256"]==digest(ROOT/meta["prompt_path"])
                if r.get("sha256")!=meta["sha256"]:
                    restored.append(r["id"]);r.update(meta)
            n=1
            while (BASE/f"manifest_before_reconcile_{n:02d}.json").exists():n+=1
            shutil.copyfile(LEDGER,BASE/f"manifest_before_reconcile_{n:02d}.json")
            LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+"\n","utf-8")
            report={"status":"RECEIPTS_RECONCILED_NO_IMAGE_CHANGE","restored":restored,"reason":"A pre-generation vendor wording edit overlapped running record writes; reconcile verified existing per-image receipts under the same file lock. No further manifest mutations allowed during generation except locked record writes."}
            (BASE/f"reconcile_{n:02d}.json").write_text(json.dumps(report,indent=2)+"\n","utf-8")
            print(json.dumps(report))
        finally:lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["prepare","record","reconcile"]);p.add_argument("--id");p.add_argument("--source")
    args=p.parse_args()
    if args.action=="prepare":prepare()
    elif args.action=="reconcile":reconcile()
    else:record(args.id,Path(args.source))
