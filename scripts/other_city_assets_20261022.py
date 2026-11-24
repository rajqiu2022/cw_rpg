"""Prepare, record and audit the first source-bound other-city asset batch."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import shutil
from contextlib import contextmanager
import msvcrt
import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/raw/other_city_modules_20261022"
PROMPTS = ROOT / "prompts/other_city_modules_20261022"
LEDGER = BASE / "manifest.json"
PREFIX = "other_city_20261022_"
STYLE = ("Original Chinese wuxia RPG production asset, bright readable hand-painted realism with clear material detail, "
         "matching a consistent 2.5D orthographic game world. Not pixel art, not chibi, not a photograph, not a glossy toy. "
         "Soft upper-left daylight, restrained natural grey tile and wood colors with readable warm/cool separation. "
         "Exactly ONE isolated subject on genuinely transparent RGBA background, no painted checkerboard, no white/grey backdrop, "
         "no mist halo, no floor rectangle or landscape scenery. Keep every nontransparent pixel and any contact shadow "
         "inside the central 70 percent of the canvas, at least 15 percent fully transparent padding on every side. "
         "Complete silhouette including roof corners, hands, weapon tips and feet must remain in frame. "
         "No logos, watermark, decorative border, English letters, invented Chinese text, spiders or webs. "
         "No forehead band, bandana or ribbons across the forehead.")
ARCH = ("Fixed parallel orthographic projection looking down about 30 degrees, front facade faces screen-bottom; "
        "straight vertical posts, no horizon or vanishing point. A compact ONE-bay entrance module with limited adjoining wall, "
        "not a complete city or several buildings. A low shallow tiled roof above a tall adult-scale doorway: "
        "visible subject width at most 2.6 times the clear door height, the door opening is at least 45 percent "
        "of the facade height below the eaves. No counter, stall, tree, person, lantern or prop blocks the threshold. "
        "Threshold and architectural base clearly visible. Door interior is a dark recessed wood/stone interior, not grass "
        "and not a transparent hole. No separate pavement slab or backdrop.")
NPC = ("One full-body neutral standing exploration character, a single static idle image, NOT an animation sheet. "
       "Fixed parallel projection looking down about 25 degrees, face toward screen-bottom with a small natural turn. "
       "Seven-head adult anatomy, clear substantial feet with both soles on the same ground plane, hands relaxed. "
       "No scenic environment or surrounding furniture. Clothing and equipment are practical and readable at small size.")
ENEMY = ("One complete full-body battle-ready enemy character, a SINGLE static ready pose, not a sprite sheet and "
         "not an attack sequence. Facing screen-left in three-quarter view, slightly elevated orthographic camera. "
         "Readable stance, feet fully visible, no impact effect, no blood, no ground disk. Weapon contained within generous padding.")
PORTRAIT = ("IDENTITY-PRESERVING REFRAME of the supplied NPC idle image into a detailed waist-up dialogue portrait. "
            "Same exact person: preserve apparent age, facial structure, hair, skin tone, clothing colors, fasteners, collar "
            "and occupational equipment. Face looking gently toward the viewer, calm expression, eye-level portrait camera. "
            "Show both shoulders and complete topknot/headwear with transparent padding. One person only; no scenic background. "
            "Do not turn an older working person into a youthful hero. This is a new separate portrait asset; the reference file stays unchanged.")


def definition(name, city, kind, label, sources, detail, dependency=None):
    return {"id": PREFIX + name, "city": city, "kind": kind, "label": label,
            "sources": sources, "detail": detail, "dependency": dependency}


def definitions():
    rows = [
      definition("bianzhou_posthouse_front_v1","bianzhou","maps","汴州驿馆门脸",
        ["game/data/scenes/openworld_bianzhou_city.tres","game/data/dialogs/openworld_bianzhou_guide.tres"],
        "Northern central-plains Chinese posthouse entrance. Warm grey brick lower wall, aged dark timber double door, "
        "low grey ceramic straight ridge roof, simple sturdy timber jambs and one small dispatch window. "
        "Official postal function conveyed by a small plain dispatch rack in the SIDE window, no words or signage."),
      definition("jinling_silk_shop_front_v1","jinling","maps","金陵绸铺门脸",
        ["game/data/scenes/openworld_jinling_city.tres"],
        "Jiangnan waterside silk shop entrance, warm white lime plaster, dark grey shallow curved tiled eaves, "
        "dark brown wood framing, raised damp-stained stone threshold. A small side display window contains two neatly folded "
        "muted blue and warm ochre silk rolls; main tall doorway remains empty and fully legible. No water plane, bridge or boat."),
      definition("xiangzhou_barracks_front_v1","xiangzhou","maps","襄州校场营房门脸",
        ["game/data/scenes/openworld_xiangzhou_city.tres","game/data/dialogs/openworld_xiangzhou_guide.tres"],
        "Chinese river-garrison barracks entrance. Stout worn grey brick base, weathered dark wood plank walls, low grey roof, "
        "plain iron door fittings, one narrow lattice side window. Functional military building with a tall single double-door "
        "opening, no palace ornaments, no Western arches, no forge furnace, no weapons blocking the entrance."),
      definition("qinghe_supply_shop_front_v1","qinghe","maps","清河行旅补给铺门脸",
        ["game/data/scenes/openworld_qinghe_town.tres","game/data/dialogs/openworld_qinghe_supply.tres"],
        "Modest Chinese traveler supply shop entrance for a road town. Warm aged timber frame, grey clay tiled low roof, "
        "pale ochre plaster, shallow projecting wooden side canopy. Small enclosed side cubby with a rolled travel mat and "
        "two medicine jars, tall unobstructed doorway, economical practical construction rather than a grand urban mansion."),
      definition("yanmen_stone_gate_front_v1","yanmen","maps","雁门雪关石木门楼",
        ["game/data/scenes/openworld_yanmen_pass.tres","game/data/maps/openworld_yanmen_pass_layout.tres"],
        "A compact Chinese frontier stone-and-timber gate entrance in the same fictional wuxia world. "
        "Rough warm-grey stone piers, heavy weathered wooden lintel and shallow grey-tile roof with thin believable snow on top. "
        "One tall open gateway, clear dark interior passage and complete stone sill. No mountain panorama, no wall extending "
        "off canvas, no snow ground slab. A modular gate section, not a complete fortress."),
    ]
    people = [
      ("bianzhou_postmaster","bianzhou","汴州驿丞", "game/data/scenes/openworld_bianzhou_city.tres",
       "An experienced male postmaster about 52, lean rectangular face, lightly graying topknot, short neat moustache, "
       "plain small dark cloth official cap, faded slate-blue clerical robe, warm grey underclothes, practical dark boots. "
       "One modest dispatch scroll tucked at the belt; not a soldier, no armor or drawn weapon."),
      ("jinling_water_patrol","jinling","金陵水巡","game/data/scenes/openworld_jinling_city.tres",
       "A working river patrolman about 36, sun-browned face, sturdy athletic build, black hair in a tidy topknot. "
       "Weathered dark teal short coat over simple muted grey lamellar panels, cream trousers, dark practical calf boots, "
       "small plain sheathed side sword. A neatly rolled straw rain cape attached to the belt at the side, no modern uniform."),
      ("xiangzhou_guard","xiangzhou","襄州守备","game/data/scenes/openworld_xiangzhou_city.tres",
       "A seasoned garrison officer about 46, broad strong shoulders, square weathered face, short moustache and light beard. "
       "Dark iron-grey Chinese lamellar armor over rust-brown cloth and ochre underlayer, plain practical shoulder cape "
       "and sturdy leather boots, a small sheathed sword. Distinct from the teal river patrolman and blue postal clerk."),
      ("qinghe_supply","qinghe","行旅货郎","game/data/scenes/openworld_qinghe_town.tres",
       "An approachable traveling supplier about 43, lean sinewy physique, tanned oval face with smile lines, short black "
       "topknot and light stubble. Sand-brown knee-length coat, faded indigo vest, pale leg wraps and worn cloth boots. "
       "A compact folded pack and small cloth parcel carried at the hip, hands free at rest. No large pole across the frame."),
    ]
    for name, city, label, source, details in people:
        rows.append(definition(name+"_idle_down_1f_v1",city,"npc_sprites",label+"静态精灵",[source],details))
        rows.append(definition(name+"_portrait_v1",city,"portraits",label+"同人立绘",[source],details,
                               PREFIX+name+"_idle_down_1f_v1"))
    for name, city, label, details in [
      ("central_road_raider","bianzhou","驿道劫匪",
       "A rough central-plains road robber, adult man with tough weathered face and disheveled tied-back hair, faded ochre "
       "short jacket, dark brown trousers, rope belt, worn cloth boots; a plain practical dao blade held low at the side. "
       "Alert ready stance, not posing as an official, no heroic ornate armor."),
      ("reed_smuggler","jinling","芦荡私枭",
       "A wiry male reed-marsh smuggler about 38. Dark desaturated green short robe, patched charcoal trousers, rope belt, "
       "water-worn calf wraps and dark boots; low practical short saber, compact cloth bundle on back. "
       "Weathered sharp features, black tied-back hair, no monstrous mask or fantasy glowing blades."),
      ("mine_brute","xiangzhou","矿场力士",
       "A powerfully built adult male mine outlaw, broad shoulders, thick forearms and weathered face, rough sleeveless "
       "earth-brown work coat over a charcoal undershirt, thick dark trousers and heavy practical boots. "
       "A sturdy plain long wooden staff with simple iron-bound ends held diagonally, no giant hammer, no magic aura."),
      ("openworld_snow_raider","yanmen","关外刀匪",
       "A rugged frontier male raider in patched brown winter layers, muted dark-blue padded undercoat, restrained worn "
       "fur collar, tied black hair, broad practical boots. A plain dao blade held ready toward screen-left, "
       "wind-worn adult face; no giant fur crown, no icicles growing from the body, no snow scenery."),
    ]:
        rows.append(definition(name+"_ready_1f_v1",city,"enemies",label+"战斗待机",
            ["game/data/enemies/"+name+".tres"],details))
    rows.append(definition("snowridge_wolf_ready_1f_v1","shared","monsters","雪岭山狼静态储备",
      ["game/data/enemies/training_wolf_snowridge_lv15.tres"],
      "One realistic grey-brown mountain wolf, thick natural winter coat, anatomically grounded four-legged body, "
      "pointed ears, narrow muzzle, normal amber-brown eyes and bushy tail. All four paws complete, standing ready "
      "in three-quarter side view facing screen-left, mouth closed and alert. Slightly elevated orthographic view. "
      "NOT a new species, no horns, no white fantasy fur, no red eyes or supernatural effects. "
      "Static visual candidate for the existing opt-in snowridge wolf definition; do not imply a new city encounter."))
    for name, city, label, sources, detail in [
      ("bounty_notice_board_v1","shared","缉捕木榜亭",
       ["game/data/dialogs/openworld_bianzhou_guide.tres","game/data/dialogs/openworld_jinling_guide.tres","game/data/dialogs/openworld_xiangzhou_guide.tres"],
       "One freestanding Chinese timber bounty notice board with two stout posts, a small shallow grey tile rain roof "
       "and a rectangular wooden backing. Several muted aged paper notices without legible writing attached on the board; "
       "no portrait drawing or invented wanted person. Orthographic 30-degree game viewpoint, complete post feet. "
       "No stone plinth or large ground shadow. Existing physical board function, not a new quest."),
      ("grain_sack_world_prop_v1","bianzhou","行粮袋任务材料",
       ["game/data/items/grain_sack.tres","game/data/bounties/bianzhou_black_wolf.tres"],
       "One tightly tied weathered tan woven grain sack, plump practical shape, thick rope tie and folded fabric top, "
       "subtle grain texture and slight wear. A world-space pickup prop, not an inventory icon frame. "
       "Orthographic 30-degree view, no loose grain spread, no pallet, no other bags, no scenery."),
      ("iron_ore_world_prop_v1","xiangzhou","铁矿石任务材料",
       ["game/data/items/iron_ore.tres","game/data/enemies/mine_brute.tres"],
       "One modest cluster of naturally fractured iron ore, charcoal-grey stone with restrained rusty brown mineral "
       "flecks and uneven angular surfaces. A small world-space pickup object in orthographic 30-degree view. "
       "No gemstone shine, no magical glow, no gold veins, no ground patch, no pickaxe or extra objects."),
      ("snow_medicine_parcel_v1","yanmen","避风岩旁失物药包",
       ["game/data/maps/openworld_yanmen_pass_layout.tres","game/data/dialogs/openworld_snow_medicine.tres"],
       "One compact traveler medicine parcel wrapped in weathered waterproof ochre-brown oilcloth, crossed twine tie "
       "and a small folded cream paper note tucked beneath the string, no legible writing. "
       "Orthographic 30-degree game pickup view, folded fabric edges and complete base. No snow, rock, pills floating "
       "around it or glow. Existing lost-medicine parcel, not a new named quest item."),
    ]:
        rows.append(definition(name,city,"quest_props",label,sources,detail))
    return rows


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prompt(row):
    spec = ARCH if row["kind"]=="maps" else (NPC if row["kind"]=="npc_sprites" else
           (PORTRAIT if row["kind"]=="portraits" else (ENEMY if row["kind"]=="enemies" else "")))
    return "\n\n".join([STYLE,spec,row["detail"]]).strip()


def prepare():
    if LEDGER.exists(): raise RuntimeError("Existing batch must be continued, not re-prepared")
    BASE.mkdir(parents=True, exist_ok=True); PROMPTS.mkdir(parents=True, exist_ok=True)
    rows=definitions()
    before=ROOT/"tmp/other_city_modules_20261022/before"
    before.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/"prompts/tasks.yaml",before/"tasks.yaml")
    source_map={}
    for row in rows:
        for source in row["sources"]:
            path=ROOT/source
            if not path.is_file(): raise FileNotFoundError(source)
            source_map[source]=sha(path)
        row["prompt_path"]=(PROMPTS/(row["id"]+".txt")).relative_to(ROOT).as_posix()
        row["output"]=(BASE/row["city"]/row["kind"]/(row["id"]+".png")).relative_to(ROOT).as_posix()
        row["status"]="PLANNED_NOT_GENERATED"
        row["attempts"]=0
        (ROOT/row["prompt_path"]).write_text(prompt(row)+"\n","utf-8")
    tpl=ROOT/"prompts/templates/other_city_asset_20261022.yaml"
    tpl.write_text('size: "1024x1024"\nquality: medium\nbackground: transparent\nprompt_template: "{asset_prompt}"\n',"utf-8")
    fragment=yaml.safe_dump({"tasks":[{
        "id":r["id"],"template":"other_city_asset_20261022",
        "category":"other_city_modules_20261022/"+r["city"]+"/"+r["kind"],
        "execution_backend":"builtin_image_gen","execution_mode":"edit" if r["dependency"] else "generate",
        "transparent_background":True,"model":None,"provider":None,"cost":None,
        "status":"MANUAL_EXECUTION_TRACKED_IN_BATCH_MANIFEST","attempt_budget":1,
        "retries_allowed":False,"cli_fallback_allowed":False,
        "execution_ledger":LEDGER.relative_to(ROOT).as_posix(),
        "prompt_path":r["prompt_path"],"vars":{"asset_prompt":prompt(r)},"skip":True,
    } for r in rows]},allow_unicode=True,sort_keys=False,width=120)
    # Append only this task block; preserve every pre-existing byte.
    body=fragment.split("tasks:\n",1)[1]
    body="\n".join("  "+line if line else "" for line in body.splitlines())+"\n"
    old=(ROOT/"prompts/tasks.yaml").read_bytes()
    suffix=("\n  # Other-city source-bound assets, builtin manual calls only; skip protects CLI batches.\n"+body).encode("utf-8")
    (ROOT/"prompts/tasks.yaml").write_bytes(old+suffix)
    manifest={"schema":1,"status":"FIRST_BATCH_GENERATION_NOT_RUNTIME","formal_enabled":False,
       "created_at":datetime.now(ZoneInfo("Asia/Shanghai")).isoformat(),"assets":rows,
       "source_sha256":source_map,"task_registration":{"old_sha256":sha(before/"tasks.yaml"),
       "old_bytes":len(old),"append_sha256":hashlib.sha256(suffix).hexdigest()},
       "limits":["single static idle/ready images do not prove animation","no scene, NPC, quest, enemy or item bindings changed",
                 "no background removal or alpha threshold editing authorized","built-in model/provider/cost are unknown unless disclosed"]}
    LEDGER.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps({"prepared":len(rows),"manifest":str(LEDGER),"registered_ids":[r["id"] for r in rows]},ensure_ascii=True))


@contextmanager
def record_lock():
    # File lock prevents concurrent subprocesses from dropping ledger updates.
    with (BASE/"manifest.record.lock").open("a+b") as handle:
        handle.seek(0,2)
        if handle.tell()==0:
            handle.write(b"0");handle.flush()
        handle.seek(0)
        msvcrt.locking(handle.fileno(),msvcrt.LK_LOCK,1)
        try: yield
        finally:
            handle.seek(0)
            msvcrt.locking(handle.fileno(),msvcrt.LK_UNLCK,1)


def record(asset_id, source, recover_existing=False):
    with record_lock():
        return _record(asset_id,source,recover_existing)


def _record(asset_id, source, recover_existing=False):
    manifest=json.loads(LEDGER.read_text("utf-8"))
    row=next(r for r in manifest["assets"] if r["id"]==asset_id)
    target=ROOT/row["output"]
    reference_input=None
    if row.get("dependency"):
        reference=next(r for r in manifest["assets"] if r["id"]==row["dependency"])
        reference_path=ROOT/reference["output"]
        if sha(reference_path)!=reference["sha256"]:
            raise RuntimeError("Reference changed: "+reference["id"])
        reference_input={"id":reference["id"],"path":reference["output"],"sha256":reference["sha256"],"role":"identity_reference"}
    if target.exists():
        if not recover_existing or target.with_suffix(".meta.json").exists() or sha(target)!=sha(source):
            raise FileExistsError(target)
    else:
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source,target)
    with Image.open(target) as image:
        rgba=image.convert("RGBA")
        alpha=rgba.getchannel("A")
        bbox=alpha.getbbox()
        w,h=rgba.size
        margins=[bbox[0]/w,bbox[1]/h,(w-bbox[2])/w,(h-bbox[3])/h] if bbox else []
        metrics={"size":[w,h],"source_mode":image.mode,"has_real_alpha":image.mode in ["RGBA","LA"] and alpha.getextrema()[0]==0,
                 "full_alpha_bbox":list(bbox) if bbox else None,"margin_fractions":margins,
                 "margin_10_percent_pass":bool(margins) and min(margins)>=.1}
    row.update({"status":"RAW_GENERATED_PENDING_VISUAL_REVIEW","attempts":1,"source_path":str(source),
                "sha256":sha(target),"bytes":target.stat().st_size,"metrics":metrics,
                "model":None,"provider":None,"cost":None,"prompt_sha256":sha(ROOT/row["prompt_path"])})
    if reference_input: row["reference_input"]=reference_input
    (target.with_suffix(".meta.json")).write_text(json.dumps(row,ensure_ascii=False,indent=2)+"\n","utf-8")
    LEDGER.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps({"asset":asset_id,"output":str(target),"metrics":metrics},ensure_ascii=True))


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["prepare","record"]);p.add_argument("--id");p.add_argument("--source")
    args=p.parse_args()
    prepare() if args.action=="prepare" else record(args.id,Path(args.source))
